# shellcheck shell=bash
# check.sh — `conformist check` command.

cf_cmd_check() {
  local repo=${1:-.}
  [[ -d $repo ]] || cf_die "not a directory: $repo"
  repo=${repo%/}

  cf_info "${CF_BLUE}conformist${CF_RESET} checking ${CF_BOLD}${repo}${CF_RESET} against eng-*(7)"
  cf_run_all "$repo"
  cf_summary
}
