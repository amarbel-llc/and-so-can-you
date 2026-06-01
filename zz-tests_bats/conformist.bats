#!/usr/bin/env bats
# Smoke tests for conformist. Tests use the shfmt-compatible
# `function NAME { # @test` form, never bats-native `@test "..."`
# (enforced by the conformist/bats-shfmt-compat rule; see amarbel-llc/eng#123).

setup() {
  if [[ -x "$BATS_TEST_DIRNAME/../build/conformist" ]]; then
    CF="$BATS_TEST_DIRNAME/../build/conformist"
  else
    CF="conformist"
  fi
}

function version_prints_semver { # @test
  run "$CF" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

function rules_lists_specs { # @test
  run "$CF" rules
  [ "$status" -eq 0 ]
  [[ "$output" == *"eng-versioning/semver"* ]]
  [[ "$output" == *"conformist/bats-shfmt-compat"* ]]
}

function self_check_passes_clean { # @test
  # The repo lints itself clean (flake.lock + gomod2nix.toml are committed).
  run "$CF" check "$BATS_TEST_DIRNAME/.."
  [ "$status" -eq 0 ]
  [[ "$output" == *"checks passed"* ]]
}

function bootstrap_emits_conformant_repo { # @test
  d="$(mktemp -d)"
  run "$CF" bootstrap --name demo "$d"
  [ "$status" -eq 0 ]
  [ -f "$d/version.env" ]
  [ -f "$d/justfile" ]
  [ -f "$d/doc/demo.7.scd" ]
  grep -q '^export DEMO_VERSION=' "$d/version.env"
  rm -rf "$d"
}

function bootstrap_output_passes_check { # @test
  # A freshly bootstrapped repo passes its own rules; the only finding is the
  # flake.lock warning (needs nix), which does not fail the run.
  d="$(mktemp -d)"
  "$CF" bootstrap --name demo "$d" >/dev/null 2>&1
  run "$CF" check "$d"
  [ "$status" -eq 0 ]
  rm -rf "$d"
}

function bats_native_form_is_rejected { # @test
  d="$(mktemp -d)"
  mkdir -p "$d/zz-tests_bats"
  printf '@test "x" {\n  true\n}\n' >"$d/zz-tests_bats/bad.bats"
  run "$CF" check "$d"
  [ "$status" -ne 0 ]
  [[ "$output" == *"conformist/bats-shfmt-compat"* ]]
  rm -rf "$d"
}
