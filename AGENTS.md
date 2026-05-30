# AGENTS.md — andsocanyou (conformist)

Guidance for coding agents working in this repository.

## What this is

`conformist`: an eng-conformance linter (`conformist check`) and repo
bootstrapper (`conformist bootstrap`). It encodes the `eng-*(7)` manpages from
[amarbel-llc/eng](https://github.com/amarbel-llc/eng) as mechanical rules.

## Ground rules

- The `justfile` is the entrypoint. Use `just <recipe>`; add a recipe rather
  than documenting an ad-hoc command.
- **This repo lints itself.** Before committing, run `just lint` (conformist
  against its own tree) and `just test`. The flake's `checks.conformance` will
  fail CI if the repo stops being eng-conformant.
- Shell is the implementation language. Keep it bash 4+ (associative arrays in
  `common.sh`), pass `shellcheck` (`just check-shell`), and keep it
  `shfmt`-formatted at 2-space indent (`just format`).
- The version source of truth is `VERSION` (see `eng-versioning(7)`): one bare
  semver line. Bump via `just bump-version`.
- Canonical identity is `identity.toml` (see `eng-identity(7)`).

## Where the rules live

- `lib/conformist/rules.sh` — every rule, each registered with `cf_spec` citing
  the `eng-*(7)` clause it enforces. When you add or change a rule, update its
  `cf_spec` citation and add a bats case under `zz-tests_bats/`.
- `lib/conformist/templates/` — the bootstrap scaffold. Anything bootstrap emits
  must itself pass `conformist check` (self-consumption); if you add a rule,
  make sure the templates still satisfy it.

## Tests

bats suite in `zz-tests_bats/`. **Use the shfmt-compatible form**
`function NAME { # @test` — never bats-native `@test "..."` (enforced by the
`conformist/bats-shfmt-compat` rule, see `eng#123`).

## Documentation

`doc/conformist.7.scd` is the manpage and is normative for conformist's
behaviour. Update it when you change the CLI or the rule set. It is authored in
scdoc; rendered roff is never committed (see `eng-manpages(7)`).
