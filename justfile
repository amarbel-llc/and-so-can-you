set shell := ["bash", "-uc"]

set dotenv-load := false

conformist := justfile_directory() / "bin/conformist"

# list recipes
_default:
    @just --list

### nix

# build the conformist package
build-flake:
    nix build

# enter the dev shell
develop:
    nix develop

### testing

# run the bats test suite
test:
    bats zz-tests_bats

# run conformist against this repo (self-check)
self-check:
    {{ conformist }} check .

### formatting

# format all files via treefmt
format:
    nix fmt

# check formatting without writing
format-check:
    nix fmt -- --fail-on-change

# lint shell sources with shellcheck
lint-shell:
    shellcheck bin/conformist lib/conformist/*.sh

### manpages

# render a manpage to stdout (e.g. `just man conformist`)
man page:
    scdoc < doc/{{ page }}.7.scd | man -l -

### conformance

# check this repo for eng-conformance
lint:
    {{ conformist }} check .

# list every conformist rule and its spec citation
rules:
    {{ conformist }} rules

### versioning

# edit VERSION and commit the bump
bump-version:
    "${EDITOR:-vi}" VERSION
    git add VERSION
    git commit -m "bumped version to $(cat VERSION)"

# create the annotated v$(cat VERSION) release tag
release-tag:
    git tag -a "v$(cat VERSION)" -m "v$(cat VERSION)"
