# conformist justfile. Conventions: eng-design_patterns-justfile(7),
# eng-versioning(7). `default` runs the full local CI lane.

default: validate lint build test

# --- validate (cheap pre-build gate) ---

validate: validate-devshell

# The devShell must evaluate and build before anything else is worth trying.
validate-devshell:
    nix build --no-link .#devShells.{{ arch() }}-linux.default

# --- lint ---

lint: lint-fmt

# Read-only formatting gate via the treefmt-nix `checks.formatting` derivation
# (the sandboxed counterpart to the writing `nix fmt`).
lint-fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    system=$(nix eval --raw --impure --expr 'builtins.currentSystem')
    nix build ".#checks.${system}.formatting" --no-link --print-build-logs

# --- build ---

build: build-gomod2nix build-go build-nix

# Regenerate gomod2nix.toml from go.mod/go.sum. Run after changing deps.
build-gomod2nix:
    nix develop --command gomod2nix

# Out-of-nix go build for a fast inner loop. Injects the version from
# version.env (commit stays "dev"); the nix build derives both authoritatively
# from the fork's buildGoApplication (eng-versioning(7)).
build-go: build-gomod2nix
    #!/usr/bin/env bash
    set -euo pipefail
    . version.env
    nix develop --command go build \
        -ldflags "-X main.version=${ANDSOCANYOU_VERSION} -X main.commit=dev" \
        -o build/conformist ./cmd/conformist

build-nix:
    nix build --show-trace

run-nix *ARGS:
    nix run . -- {{ ARGS }}

# --- test ---

test: test-go test-bats

test-go:
    nix develop --command go test ./...

# run the bats suite against the freshly built binary (./build/conformist)
test-bats: build-go
    nix develop --command bats zz-tests_bats

# --- inspection ---

# list every conformist rule and the eng-*(7) clause it enforces
[group("inspection")]
list-rules:
    nix run . -- rules

# scaffold an eng-conformant repo into DIR (e.g. `just bootstrap-repo /tmp/demo`)
[group("inspection")]
bootstrap-repo dir:
    nix run . -- bootstrap {{ dir }}

# --- format ---

codemod-fmt: codemod-fmt-treefmt

codemod-fmt-treefmt:
    nix fmt

# --- maintenance ---

update-go: && build-gomod2nix
    nix develop --command go mod tidy

[group("maintenance")]
bump-version new_version:
    sed -E -i "s/^(export ANDSOCANYOU_VERSION)=.*/\1={{ new_version }}/" version.env

[group("maintenance")]
tag message:
    #!/usr/bin/env bash
    set -euo pipefail
    . version.env
    tag="v${ANDSOCANYOU_VERSION:?missing ANDSOCANYOU_VERSION in version.env}"
    git tag -s -m "{{ message }}" "$tag"
    echo "Created tag: $tag"
    git push origin "$tag"
    echo "Pushed $tag"
    git tag -v "$tag"

[group("maintenance")]
release new_version:
    #!/usr/bin/env bash
    set -euo pipefail

    # Release only from the default branch.
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$branch" != "master" ]]; then
        echo "release only allowed from master (on '$branch')" >&2
        exit 1
    fi

    # Generate the changelog BEFORE bump-version — the release-bump commit
    # MUST NOT appear in the changelog it announces.
    prev=$(git tag --sort=-v:refname -l "v*" | head -1)
    header="release v{{ new_version }}"
    if [[ -n "$prev" ]]; then
        summary=$(git log --format='- %s' "$prev"..HEAD)
        msg="$header"$'\n\n'"$summary"
    else
        msg="$header"
    fi

    just bump-version "{{ new_version }}"
    git add version.env
    git commit -m "$header"

    just tag "$msg"

    gh release create "v{{ new_version }}" --title "$header" --notes "$msg"

# --- clean ---

clean: clean-build

clean-build:
    rm -rf result build/
