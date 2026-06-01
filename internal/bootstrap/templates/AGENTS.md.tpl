# AGENTS.md — @@NAME@@

Guidance for coding agents working in this repository.

## Ground rules

- The `justfile` is the entrypoint. Prefer `just <recipe>` over ad-hoc commands;
  add a recipe when a new cross-cutting operation appears. Follow the verb-noun
  naming and lifecycle groups in `eng-design_patterns-justfile(7)`.
- This repo is **eng-conformant**. Before committing, run `conformist check .`
  and `just codemod-fmt`. Do not introduce conventions the `eng-*(7)` manpages
  contradict.
- The version source of truth is `version.env` (`export @@VAR@@_VERSION=...`, see
  `eng-versioning(7)`). Never hard-code the version elsewhere; bump it via
  `just bump-version`.

## Documentation

Conventions and interfaces are documented as manpages under `doc/`, authored in
scdoc and built by Nix (see `eng-manpages(7)`). Rendered roff is never
committed. Update the manpage when you change the behaviour it describes.

## Tests

bats suite under `zz-tests_bats/`. Use the shfmt-compatible
`function NAME { # @test` form, never bats-native `@test "..."` (amarbel-llc/eng#123).
