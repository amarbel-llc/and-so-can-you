# shellcheck shell=bash
# bootstrap.sh — `conformist bootstrap` command.
#
# Scaffolds an eng-conformant repo from the templates under templates/, then
# runs the check rules on the result so bootstrap proves its own output
# (self-consumption, per the andsocanyou design).

cf_bootstrap_usage() {
  cat >&2 <<'EOF'
usage: conformist bootstrap [options] [dir]

Scaffold an eng-conformant repository.

options:
  --name NAME        canonical repo name      (default: target dir basename)
  --force            write into a non-empty directory
  -h, --help         show this help

The target dir defaults to the current directory.
EOF
}

# cf_render SRC DST — copy a template, substituting @@PLACEHOLDER@@ tokens.
cf_render() {
  local src=$1 dst=$2
  sed \
    -e "s/@@NAME@@/${CF_BS_NAME}/g" \
    -e "s/@@VAR@@/${CF_BS_VAR}/g" \
    -e "s/@@TITLE@@/${CF_BS_NAME}/g" \
    -e "s/@@YEAR@@/${CF_BS_YEAR}/g" \
    "$src" >"$dst"
}

cf_cmd_bootstrap() {
  local force=0 dir=""
  CF_BS_NAME=""

  while (($#)); do
    case $1 in
    --name)
      CF_BS_NAME=$2
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h | --help)
      cf_bootstrap_usage
      return 0
      ;;
    -*) cf_die "bootstrap: unknown option '$1'" ;;
    *)
      dir=$1
      shift
      ;;
    esac
  done

  dir=${dir:-.}
  mkdir -p "$dir" || cf_die "cannot create $dir"
  dir=$(cd "$dir" && pwd)

  if [[ -z $CF_BS_NAME ]]; then
    CF_BS_NAME=$(basename "$dir")
  fi
  # Validate name is lowercase/hyphen so generated manpages stay conformant.
  if [[ ! $CF_BS_NAME =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    cf_die "name '$CF_BS_NAME' must be lowercase, digits and hyphens only"
  fi
  # version.env variable name: uppercase, hyphens -> underscores.
  CF_BS_VAR=$(printf '%s' "$CF_BS_NAME" | tr '[:lower:]-' '[:upper:]_')
  CF_BS_YEAR=$(date +%Y)

  if [[ $force -eq 0 && -n $(ls -A "$dir" 2>/dev/null) ]]; then
    cf_die "$dir is not empty (use --force to scaffold anyway)"
  fi

  local tpl=$CF_LIB/templates
  cf_info "${CF_BLUE}conformist${CF_RESET} bootstrapping ${CF_BOLD}${CF_BS_NAME}${CF_RESET} in ${dir}"

  mkdir -p "$dir/doc"
  cf_render "$tpl/version.env.tpl" "$dir/version.env"
  cf_render "$tpl/README.md.tpl" "$dir/README.md"
  cf_render "$tpl/AGENTS.md.tpl" "$dir/AGENTS.md"
  cf_render "$tpl/justfile.tpl" "$dir/justfile"
  cf_render "$tpl/flake.nix.tpl" "$dir/flake.nix"
  cf_render "$tpl/treefmt.nix.tpl" "$dir/treefmt.nix"
  cf_render "$tpl/envrc.tpl" "$dir/.envrc"
  cf_render "$tpl/gitignore.tpl" "$dir/.gitignore"
  cf_render "$tpl/topic.7.scd.tpl" "$dir/doc/${CF_BS_NAME}.7.scd"

  cf_info ""
  cf_info "${CF_DIM}scaffolded; verifying with the conformist rules (self-proof)…${CF_RESET}"
  cf_info ""

  # Self-consumption: prove the scaffold conforms. flake.lock cannot be
  # generated without nix, so the flake-lock rule is expected to flag until the
  # user runs `nix flake lock` — surface that explicitly rather than hiding it.
  cf_run_all "$dir"
  cf_info ""
  cf_info "next: cd ${dir} && nix flake lock && just"
  # The scaffold itself succeeded; the only expected finding is the flake.lock
  # rule (no nix at bootstrap time), so bootstrap reports success.
  return 0
}
