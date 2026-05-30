#!/usr/bin/env bats
# Smoke tests for conformist. Tests use the shfmt-compatible
# `function NAME { # @test` form, never bats-native `@test "..."`
# (enforced by the conformist/bats-shfmt-compat rule; see amarbel-llc/eng#123).

setup() {
  CF="$BATS_TEST_DIRNAME/../bin/conformist"
}

function version_prints_semver { # @test
  run bash "$CF" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}

function rules_lists_specs { # @test
  run bash "$CF" rules
  [ "$status" -eq 0 ]
  [[ "$output" == *"eng-versioning/semver"* ]]
  [[ "$output" == *"conformist/bats-shfmt-compat"* ]]
}

function check_self_only_flags_flake_lock { # @test
  # The repo lints itself; the sole expected error is the missing flake.lock
  # (which needs nix to generate). No other error-severity findings.
  run bash "$CF" check "$BATS_TEST_DIRNAME/.."
  [[ "$output" != *"error eng-justfile"* ]]
  [[ "$output" != *"error eng-versioning"* ]]
  [[ "$output" != *"error eng-manpages"* ]]
}

function bootstrap_emits_conformant_repo { # @test
  d="$(mktemp -d)"
  run bash "$CF" bootstrap --name demo "$d"
  [ "$status" -eq 0 ]
  [ -f "$d/version.env" ]
  [ -f "$d/justfile" ]
  [ -f "$d/doc/demo.7.scd" ]
  grep -q '^export DEMO_VERSION=' "$d/version.env"
  # default recipe is the first recipe (aggregate, no body)
  grep -Eq '^default:' "$d/justfile"
  rm -rf "$d"
}

function bootstrap_output_passes_check { # @test
  # Self-consumption: a freshly bootstrapped repo passes its own rules
  # (modulo the flake.lock error, which needs nix).
  d="$(mktemp -d)"
  bash "$CF" bootstrap --name demo "$d" >/dev/null 2>&1
  run bash "$CF" check "$d"
  [[ "$output" != *"error eng-justfile"* ]]
  [[ "$output" != *"error eng-versioning"* ]]
  [[ "$output" != *"error eng-manpages"* ]]
  rm -rf "$d"
}

function bats_native_form_is_rejected { # @test
  # A repo whose bats use the native `@test "..."` form must fail the
  # conformist/bats-shfmt-compat rule.
  d="$(mktemp -d)"
  mkdir -p "$d/zz-tests_bats"
  printf '@test "x" {\n  true\n}\n' >"$d/zz-tests_bats/bad.bats"
  run bash "$CF" check "$d"
  [[ "$output" == *"conformist/bats-shfmt-compat"* ]]
  rm -rf "$d"
}
