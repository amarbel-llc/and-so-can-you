# andsocanyou

**conformist** — a whole-repo linter and bootstrapper that checks whether a
repository follows the [`eng-*(7)`](https://github.com/amarbel-llc/eng/tree/master/doc)
engineering conventions, and scaffolds new repositories that already do.

Two halves that feed each other:

1. **Lint** — `conformist check` treats a repo's heterogeneous "meta" files
   (`justfile`, `version.env`, `flake.nix`, `.envrc`, `doc/*.scd`, `*.bats`) as
   first-class lintable artifacts under one ruleset. Each rule encodes a
   mechanically-checkable clause from an `eng-*(7)` page and **carries that
   citation with it** (`conformist rules` prints the full map).
2. **Bootstrap** — `conformist bootstrap` scaffolds a new repo that is
   eng-conformant from the first commit, then immediately lints the scaffold so
   bootstrap *proves its own output*.

conformist's own repo is itself a conformant repo it lints (`nix build
.#checks.<sys>.conformance`), so CI fails if andsocanyou stops conforming.

## Why Go

The rules are parsers, not greps. The justfile is read from the authoritative
`just --dump` JSON AST (recipe order, body presence, names); `version.env` and
scdoc sources go through dedicated parsers. Each rule is a Go value whose spec
citation lives on the rule, so `conformist rules` can never drift from what the
checks enforce.

## Usage

```sh
conformist [dir]                    # lint dir (default: .)
conformist check [dir]              # same, explicit
conformist bootstrap [opts] [dir]   # scaffold an eng-conformant repo
conformist rules                    # list every rule and its spec citation
conformist version                  # print version
```

### Bootstrap options

```
--name NAME   canonical repo name (default: target dir basename)
--force       write into a non-empty directory
```

## What it checks

`conformist rules` prints the full rule-to-clause map; the rules cover repo
layout, `version.env` (single bare-semver source of truth), the justfile
(`default` aggregate, no generic names), scdoc manpages, the flake
(`flake.lock`, `devShells.default`, treefmt formatter), `.envrc`, and bats test
form. Findings are `error` (fails the run, non-zero exit) or `warn` (reported,
exit 0). See `conformist`(7) for the full list and severities.

## Layout

- `cmd/conformist/` — CLI entrypoint
- `internal/rule/` — the rule model (`Rule`, `Finding`, `Registry`)
- `internal/rules/` — the encoded rules, one file per concern; each cites its
  `eng-*(7)` clause
- `internal/repo/` — lazily-parsed, typed views of the repo's meta files
- `internal/bootstrap/` — the scaffolder and its embedded `templates/`
- `internal/check/`, `internal/report/`, `internal/cli/` — orchestration, output, CLI
- `doc/conformist.7.scd` — the manpage (section 1 is generated from the cobra tree)
- `zz-tests_bats/` — bats smoke tests
- `flake.nix` / `treefmt.nix` — nix devshell, `conformist` package, `nix fmt`

## Development

```sh
just              # validate + lint + build + test (the full local CI lane)
just build-go     # fast out-of-nix go build to ./build/conformist
just test-go      # go test ./...
just test-bats    # bats suite
just lint-fmt     # read-only formatting gate
just codemod-fmt  # nix fmt (treefmt)
just list-rules   # conformist rules
```

## Relationship to eng and treelint

The `eng-*(7)` manpages in [amarbel-llc/eng](https://github.com/amarbel-llc/eng)
remain the source of truth; conformist encodes the mechanically-checkable subset.
It is whole-tree-granularity and ships its own rules, which is why it is a
separate tool rather than a [treelint](https://github.com/amarbel-llc/treelint)
mode (treelint is a per-file, external-tool multiplexer). A `conformist <dir>`
binary that exits non-zero on findings drops cleanly into treelint as a
`[linter.conformist]`.
