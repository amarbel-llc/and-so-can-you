# AGENTS.md — andsocanyou (conformist)

Guidance for coding agents working in this repository.

## What this is

`conformist`: a Go CLI that lints a repo against the `eng-*(7)` conventions
(`conformist check`) and scaffolds eng-conformant repos (`conformist bootstrap`).
It encodes the mechanically-checkable subset of the `eng-*(7)` manpages from
[amarbel-llc/eng](https://github.com/amarbel-llc/eng) as Go rules.

## Ground rules

- The `justfile` is the entrypoint. Use `just <recipe>`; add a recipe rather
  than documenting an ad-hoc command. Follow the verb-noun naming and lifecycle
  groups in `eng-design_patterns-justfile(7)`.
- **This repo lints itself.** The flake's `checks.conformance` runs `conformist
  check` over the tree, so CI fails if the repo stops being eng-conformant.
- The version source of truth is `version.env` (`export ANDSOCANYOU_VERSION=`,
  see `eng-versioning(7)`). The nix build injects it into the binary; bump it via
  `just bump-version`.
- `flake.lock` and `gomod2nix.toml` are committed (generated, not hand-edited);
  regenerate with `just update-go` / `just build-gomod2nix`.

## Where the rules live

- `internal/rule/` — the `Rule` model. A rule carries its own spec citation, so
  `conformist rules` cannot drift from what the checks enforce.
- `internal/rules/` — one file per concern (layout, versioning, justfile,
  manpages, flake, direnv, bats). When you add or change a rule, set an accurate
  `Spec` citation (a real `eng-*(7)` page + section) and add it to the manpage
  RULES section — a Go test asserts every rule id appears in
  `doc/conformist.7.scd`.
- `internal/repo/` — typed parsers for the meta files. Prefer adding a parser
  here over grepping in a rule.
- `internal/bootstrap/templates/` — the scaffold. Anything bootstrap emits must
  pass `conformist check`; if you add a rule, keep the templates conformant.

## Tests

- Go unit tests live beside the code (`go test ./...`, `just test-go`).
- bats smoke tests in `zz-tests_bats/`. **Use the shfmt-compatible form**
  `function NAME { # @test` — never bats-native `@test "..."` (enforced by the
  `conformist/bats-shfmt-compat` rule, see `eng#123`).

## Documentation

`doc/conformist.7.scd` is the hand-written section-7 conventions page; the
section-1 CLI reference is generated from the cobra command tree by `conformist
gen-man` inside the Nix manpages derivation. Rendered roff is never committed
(`eng-manpages(7)`). Update the section-7 page when you change the rule set.
