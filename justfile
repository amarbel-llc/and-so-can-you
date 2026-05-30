set shell := ["bash", "-uc"]

# CI-equivalent entrypoint: chains the lifecycle aggregates (see
# eng-design_patterns-justfile(7)). `just` (no args) passing means the repo is
# in a good state.
default: lint build test

### pre-build

lint: lint-conformance lint-shell

# conformist checks itself (self-consumption)
[group("pre-build")]
lint-conformance:
    ./bin/conformist check .

# shellcheck the shell sources
[group("pre-build")]
lint-shell:
    shellcheck bin/conformist lib/conformist/*.sh

### build

build: build-man

# render the conformist manpage with scdoc (build-check, output discarded)
[group("build")]
build-man:
    scdoc < doc/conformist.7.scd >/dev/null

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

### inspection

# list every conformist rule and the manpage clause it enforces
[group("inspection")]
list-rules:
    ./bin/conformist rules

# scaffold an eng-conformant repo into DIR (e.g. `just bootstrap-repo /tmp/demo`)
[group("inspection")]
bootstrap-repo dir:
    ./bin/conformist bootstrap {{ dir }}

### maintenance

# rewrite the ANDSOCANYOU_VERSION line in version.env (pure mutation)
[group("maintenance")]
bump-version new_version:
    sed -E -i "s/^(export ANDSOCANYOU_VERSION)=.*/\\1={{ new_version }}/" version.env

# create and push the signed v<sem> tag, then verify it
[group("maintenance")]
tag message:
    #!/usr/bin/env bash
    set -euo pipefail
    . version.env
    t="v${ANDSOCANYOU_VERSION:?missing ANDSOCANYOU_VERSION in version.env}"
    git tag -s -m "{{ message }}" "$t"
    git push origin "$t"
    git tag -v "$t"
