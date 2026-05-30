# shellcheck shell=bash
# common.sh — shared helpers for conformist: logging, reporting, rule registry.
#
# This file is sourced, never executed. It assumes bash 4+ (associative arrays).

# --- output -----------------------------------------------------------------

# Honour NO_COLOR (https://no-color.org) and non-tty output.
if [[ -t 2 && -z ${NO_COLOR:-} ]]; then
  CF_RED=$'\033[31m'
  CF_YELLOW=$'\033[33m'
  CF_BLUE=$'\033[34m'
  CF_DIM=$'\033[2m'
  CF_BOLD=$'\033[1m'
  CF_RESET=$'\033[0m'
else
  CF_RED=
  CF_YELLOW=
  CF_BLUE=
  CF_DIM=
  CF_BOLD=
  CF_RESET=
fi

cf_info() { printf '%s\n' "$*" >&2; }
cf_warn() { printf '%swarning:%s %s\n' "$CF_YELLOW" "$CF_RESET" "$*" >&2; }
cf_err() { printf '%serror:%s %s\n' "$CF_RED" "$CF_RESET" "$*" >&2; }
cf_die() {
  cf_err "$@"
  exit 2
}

# --- portable search --------------------------------------------------------

# cf_grep PATTERN FILE... — prefer ripgrep when present, fall back to grep -E.
# Returns grep's exit status (0 = match, 1 = no match, >1 = error).
cf_grep() {
  local pattern=$1
  shift
  if command -v rg >/dev/null 2>&1; then
    rg --no-config -n "$pattern" "$@"
  else
    grep -En "$pattern" "$@"
  fi
}

# cf_has_match PATTERN FILE — quiet boolean test.
cf_has_match() {
  local pattern=$1 file=$2
  [[ -f $file ]] || return 1
  grep -Eq "$pattern" "$file"
}

# --- rule registry & reporting ----------------------------------------------

# Spec citations: rule id -> normative manpage clause that backs it.
declare -gA CF_SPEC=()
# Per-run violation tallies by severity.
declare -gi CF_ERRORS=0
declare -gi CF_WARNINGS=0
declare -gi CF_CHECKED=0

# cf_spec ID "eng-foo(7) SECTION" — register the citation for a rule.
cf_spec() { CF_SPEC[$1]=$2; }

# cf_ok ID — record that a rule ran and passed (for the summary count).
cf_ok() { CF_CHECKED+=1; }

# cf_violation ID SEVERITY PATH MESSAGE
# SEVERITY is "error" or "warn". Prints a single grouped finding and tallies it.
cf_violation() {
  local id=$1 severity=$2 path=$3 message=$4
  local marker color
  CF_CHECKED+=1
  case $severity in
  error)
    color=$CF_RED
    marker="error"
    CF_ERRORS+=1
    ;;
  warn)
    color=$CF_YELLOW
    marker="warn"
    CF_WARNINGS+=1
    ;;
  *) cf_die "internal: unknown severity '$severity' for rule '$id'" ;;
  esac

  printf '%s%s%s %s%s%s %s\n' \
    "$color" "$marker" "$CF_RESET" "$CF_BOLD" "$id" "$CF_RESET" "$path" >&2
  printf '  %s\n' "$message" >&2
  if [[ -n ${CF_SPEC[$id]:-} ]]; then
    printf '  %sspec:%s %s\n' "$CF_DIM" "$CF_RESET" "${CF_SPEC[$id]}" >&2
  fi
}

# cf_summary — print the run tally; return 1 if any error-severity findings.
cf_summary() {
  local n=$CF_CHECKED
  if ((CF_ERRORS == 0 && CF_WARNINGS == 0)); then
    cf_info "${CF_BLUE}conformist:${CF_RESET} ${n} checks passed, repo is eng-conformant"
    return 0
  fi
  cf_info ""
  cf_info "${CF_BLUE}conformist:${CF_RESET} ${CF_ERRORS} error(s), ${CF_WARNINGS} warning(s) across ${n} checks"
  ((CF_ERRORS == 0))
}
