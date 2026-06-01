set shell := ["bash", "-uc"]

# CI-equivalent entrypoint: chains the lifecycle aggregates. `just` (no args)
# passing means the repo is in a good state.
default: lint build test

### pre-build

lint: lint-fmt

# read-only formatting gate (treefmt via the flake's checks.formatting)
[group("pre-build")]
lint-fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    system=$(nix eval --raw --impure --expr 'builtins.currentSystem')
    nix build ".#checks.${system}.formatting" --no-link --print-build-logs

### build

build: build-flake

# build the flake's default package
[group("build")]
build-flake:
    nix build --show-trace

### post-build

test: test-bats

# run the bats suite
[group("post-build")]
test-bats:
    bats zz-tests_bats

### codemod

codemod-fmt: codemod-fmt-treefmt

# format the worktree in place (nix fmt)
[group("codemod")]
codemod-fmt-treefmt:
    nix fmt

### maintenance

# rewrite the @@VAR@@_VERSION line in version.env (pure mutation)
[group("maintenance")]
bump-version new_version:
    sed -E -i "s/^(export @@VAR@@_VERSION)=.*/\\1={{ new_version }}/" version.env

# create and push the signed v<sem> tag, then verify it
[group("maintenance")]
tag message:
    #!/usr/bin/env bash
    set -euo pipefail
    . version.env
    t="v${@@VAR@@_VERSION:?missing @@VAR@@_VERSION in version.env}"
    git tag -s -m "{{ message }}" "$t"
    git push origin "$t"
    git tag -v "$t"
