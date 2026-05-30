# @@NAME@@

An [eng-conformant](https://github.com/amarbel-llc/eng) repository scaffolded by
[conformist](https://github.com/friedenberg/andsocanyou).

## Entrypoints

The `justfile` is the single task entrypoint. Run `just` to list recipes; `just`
with no arguments runs the CI-equivalent `default` pipeline (`lint build test`).

```sh
just            # list recipes
just lint       # read-only formatting gate
just build      # nix build
just test       # bats suite
just codemod-fmt# format the worktree (nix fmt)
```

## Layout

- `version.env` — version source of truth, `export @@VAR@@_VERSION=...` (see `eng-versioning(7)`)
- `flake.nix` / `flake.lock` — nix devshell and packages (see `eng-nix(7)`)
- `treefmt.nix` — formatter configuration
- `doc/` — section-7 manpages in scdoc (see `eng-manpages(7)`)

## Conformance

This repo follows the conventions in the `eng-*(7)` manpages. Check it with:

```sh
conformist check .
```
