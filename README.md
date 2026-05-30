# andsocanyou

> owner: `friedenberg` · contact: `eng@amarbel.example`

**conformist** — a whole-repo, cross-format linter and bootstrapper that makes a
repository conform to the [`eng-*(7)`](https://github.com/amarbel-llc/eng/tree/master/doc)
engineering conventions, and scaffolds new repositories that already do.

This is a ground-up redesign of `andsocanyou` (formerly a Homebrew-bootstrap
template) around two ideas from [amarbel-llc/eng#100](https://github.com/amarbel-llc/eng/issues/100):

1. **Lint** — treat a repo's heterogeneous "meta" files (`justfile`, `README.md`,
   `flake.nix`, `VERSION`, `identity.toml`, `doc/*.7.scd`) as first-class
   lintable artifacts under one ruleset, mechanically encoding the `eng-*(7)`
   manpages (`eng(7)`'s CONFORMANCE section is the contract).
2. **Bootstrap** — scaffold a new repo that is eng-conformant from the first
   commit, then immediately lint the scaffold so bootstrap *proves its own
   output* (self-consumption).

Lint and bootstrap feed each other: bootstrap emits a repo that `conformist
check` passes, and conformist's own repo is itself a conformant repo it can
lint — the tool eats its own dog food.

## Usage

```sh
conformist check [dir]              # lint a repo against the eng-*(7) rules
conformist bootstrap [opts] [dir]   # scaffold an eng-conformant repo
conformist rules                    # list every rule and its spec citation
conformist version                  # print version
```

With no arguments, `conformist` checks the current directory.

### Bootstrap options

```
--name NAME       canonical repo name   (default: target dir basename)
--owner OWNER     github org or user    (default: amarbel-llc)
--contact ADDR    role contact address  (default: eng@amarbel.example)
--force           write into a non-empty directory
```

## What it checks

Every rule cites the normative `eng-*(7)` clause it enforces (`conformist
rules` prints the full map). Summary:

| concern | rule(s) | source |
| --- | --- | --- |
| layout | `justfile`, `README.md`, `VERSION`, `identity.toml`, `doc/` present | `eng(7)` LAYOUT/CONFORMANCE |
| versioning | single bare-semver line, no leading `v` | `eng-versioning(7)` |
| identity | `name`/`owner`/`contact` keys; role contact | `eng-identity(7)` |
| justfile | `_default` runs `just --list`; doc comments; verb-noun names | `eng-design_patterns-justfile(7)` |
| manpages | `topic.SECTION.scd` naming; NAME + DESCRIPTION; no rendered roff | `eng-manpages(7)` |
| nix | `flake.lock` committed; `devShells.default`; treefmt formatter | `eng-nix(7)` |
| direnv | `.envrc` uses `use flake`; no secrets in `.envrc` | `eng-direnv(7)` |
| bats | tests use `function NAME { # @test` form | [eng#123](https://github.com/amarbel-llc/eng/issues/123) |

Findings are `error` (fails the run, non-zero exit) or `warn` (reported, exit 0).

## Layout

- `bin/conformist` — CLI entrypoint
- `lib/conformist/` — `common.sh` (reporting), `rules.sh` (the encoded rules),
  `check.sh`, `bootstrap.sh`, and `templates/` (scaffold sources)
- `doc/conformist.7.scd` — the manpage (normative for conformist's own behaviour)
- `zz-tests_bats/` — bats test suite
- `flake.nix` / `treefmt.nix` — nix devshell, `conformist` package, `nix fmt`

## Development

```sh
just            # list recipes
just lint       # conformist checks itself
just test       # bats suite
just check-shell# shellcheck
just format     # nix fmt (treefmt)
```

The flake's `checks.conformance` runs `conformist check` against this repo's own
source, so CI fails if andsocanyou stops being conformant.

## Relationship to eng

The `eng-*(7)` manpages in [amarbel-llc/eng](https://github.com/amarbel-llc/eng)
remain the source of truth. conformist encodes the mechanically-checkable subset
of those clauses directly (per the design decision to encode rules rather than
parse the manpages at runtime). Formatting is delegated to `treefmt`; conformist
owns the *structural / semantic* rules that formatters don't cover.
