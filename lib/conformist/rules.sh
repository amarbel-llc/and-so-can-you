# shellcheck shell=bash
# rules.sh — eng-conformance rules, encoded directly from the eng-*(7) manpages.
#
# Each rule cites the normative clause it enforces. The manpages in
# amarbel-llc/eng/doc remain the source of truth; this file is the mechanical
# subset that conformist can check (see eng(7) and #100).
#
# A "concern" is checked only when the repo opts into it: shape rules for a file
# fire only when that file exists. Layout rules in eng(7) that are unconditional
# fire always.

# cf_register_specs — bind every rule id to its backing manpage clause.
cf_register_specs() {
  cf_spec eng/layout-justfile "eng(7) REPOSITORY LAYOUT — justfile at the repo root"
  cf_spec eng/layout-readme "eng(7) AGENT ORIENTATION — README.md at the repo root"
  cf_spec eng/layout-version "eng-versioning(7) SINGLE VERSION SOURCE OF TRUTH — version.env"
  cf_spec eng/layout-doc-dir "eng(7) REPOSITORY LAYOUT — doc/ holds scdoc manpages"

  cf_spec eng-versioning/source-of-truth "eng-versioning(7) SINGLE VERSION SOURCE OF TRUTH — export <REPO>_VERSION="
  cf_spec eng-versioning/semver "eng-versioning(7) PRINCIPLES — semantic versioning MAJOR.MINOR.PATCH"
  cf_spec eng-versioning/deprecated-file "eng-versioning(7) DEPRECATED ALTERNATIVES — version.txt/VERSION superseded by version.env"

  cf_spec eng-justfile/default-recipe "eng-design_patterns-justfile(7) DEFAULT RECIPE — first recipe is 'default'"
  cf_spec eng-justfile/default-aggregate "eng-design_patterns-justfile(7) DEFAULT RECIPE — default lists aggregates, has no body"
  cf_spec eng-justfile/generic-name "eng-design_patterns-justfile(7) ANTI-PATTERNS — no generic names (all/dev/check/compile)"

  cf_spec eng-manpages/source-naming "eng-manpages(7) FILE NAMING — name.N.scd under doc/"
  cf_spec eng-manpages/no-rendered "eng-manpages(7) PRINCIPLES — pages built by Nix; rendered roff not committed"
  cf_spec eng-manpages/header-name "eng-manpages(7) SCDOC SYNTAX — first line name(N) + a NAME section 'topic - desc'"
  cf_spec eng-manpages/description "eng-manpages(7) generated-page structure — DESCRIPTION section present"

  cf_spec eng-nix/flake-lock "eng-nix(7) — flake.lock is committed alongside flake.nix"
  cf_spec eng-nix/devshell "eng-design_patterns-justfile(7) VALIDATE-DEVSHELL — devShells.default"
  cf_spec eng-nix/formatter "eng-design_patterns-justfile(7) LINT-FMT — formatter wired to treefmt"

  cf_spec eng-direnv/use-flake "eng-direnv(7) — .envrc activates the flake devshell via 'use flake'"
  cf_spec eng-direnv/no-secrets "eng-direnv(7) — secrets never live in .envrc"

  cf_spec conformist/bats-shfmt-compat "amarbel-llc/eng#123 — bats use 'function NAME { # @test' form"
}

# --- eng(7) / eng-versioning(7): LAYOUT -------------------------------------

cf_check_layout() {
  local repo=$1

  if [[ -f $repo/justfile ]]; then cf_ok; else
    cf_violation eng/layout-justfile error "justfile" \
      "no justfile at repo root; the justfile is the single task entrypoint"
  fi

  if [[ -f $repo/README.md ]]; then cf_ok; else
    cf_violation eng/layout-readme error "README.md" \
      "no README.md at repo root describing purpose and entrypoints"
  fi

  if [[ -f $repo/version.env ]]; then cf_ok; else
    cf_violation eng/layout-version error "version.env" \
      "no version.env; eng-versioning(7) requires a single version source of truth"
  fi

  if [[ -d $repo/doc ]]; then cf_ok; else
    cf_violation eng/layout-doc-dir warn "doc/" \
      "no doc/ directory; scdoc manpages live under doc/ (eng-manpages(7))"
  fi
}

# --- eng-versioning(7) ------------------------------------------------------

cf_check_versioning() {
  local repo=$1 file=$repo/version.env

  # Deprecated version files (eng-versioning(7) DEPRECATED ALTERNATIVES).
  local dep
  for dep in VERSION version.txt; do
    if [[ -f $repo/$dep ]]; then
      cf_violation eng-versioning/deprecated-file warn "$dep" \
        "deprecated version file; migrate to version.env (export <REPO>_VERSION=...)"
    fi
  done

  [[ -f $file ]] || return 0

  # Source of truth: a line `export <REPO>_VERSION=<value>` (export optional).
  local line
  line=$(grep -E '^[[:space:]]*(export[[:space:]]+)?[A-Z][A-Z0-9_]*_VERSION=' "$file" | head -n1)
  if [[ -z $line ]]; then
    cf_violation eng-versioning/source-of-truth error "version.env" \
      "version.env must declare 'export <REPO>_VERSION=<semver>'"
    return 0
  fi
  cf_ok

  local v=${line#*=}
  v=${v%\"}
  v=${v#\"}
  v=${v//[[:space:]]/}
  if [[ $v =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    cf_ok
  else
    cf_violation eng-versioning/semver error "version.env" \
      "version '${v}' is not MAJOR.MINOR.PATCH semantic versioning"
  fi
}

# --- eng-design_patterns-justfile(7) ----------------------------------------

# cf_first_recipe FILE — echo the name of the first recipe target, skipping
# comments, blank lines, `set`/assignment lines, and `[attribute]` lines.
cf_first_recipe() {
  local file=$1 line name
  while IFS= read -r line; do
    case $line in
    '' | '#'* | ' '* | $'\t'*) continue ;;     # blank, comment, indented body
    'set '* | 'set' | export\ *) continue ;;    # settings / exports
    '['*) continue ;;                           # [group(...)] / [private] attrs
    esac
    # Variable assignment: NAME := ... or NAME = ...
    if [[ $line =~ ^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:?= ]]; then continue; fi
    # Recipe: NAME [params]:   (a single ':' introducing the recipe)
    if [[ $line =~ ^([A-Za-z_][A-Za-z0-9_-]*) ]]; then
      name=${BASH_REMATCH[1]}
      printf '%s\n' "$name"
      return 0
    fi
  done <"$file"
}

cf_check_justfile() {
  local repo=$1 file=$repo/justfile
  [[ -f $file ]] || return 0

  local first
  first=$(cf_first_recipe "$file")
  if [[ $first == "default" ]]; then
    cf_ok
  else
    cf_violation eng-justfile/default-recipe error "justfile" \
      "the first recipe must be 'default' (found '${first:-none}')"
  fi

  # The default recipe is an aggregate: 'default: dep dep ...' with no body
  # (eng-design_patterns-justfile(7): "Logic in aggregates" is an anti-pattern).
  local default_line nextline=""
  default_line=$(grep -nE '^default[[:space:]]*:' "$file" | head -n1)
  if [[ -n $default_line ]]; then
    local lineno=${default_line%%:*}
    nextline=$(sed -n "$((lineno + 1))p" "$file")
    if [[ $nextline == $'\t'* || $nextline == "    "* ]]; then
      cf_violation eng-justfile/default-aggregate warn "justfile" \
        "default recipe has a body; it should only list aggregate dependencies"
    else
      cf_ok
    fi
  fi

  # Generic recipe names are an anti-pattern: all, dev, check, compile.
  local generic=()
  local g
  for g in all dev check compile; do
    if grep -Eq "^${g}([[:space:]].*)?:" "$file"; then
      generic+=("$g")
    fi
  done
  if ((${#generic[@]} == 0)); then
    cf_ok
  else
    cf_violation eng-justfile/generic-name warn "justfile" \
      "generic recipe name(s) ${generic[*]}; use verb-noun names instead"
  fi
}

# --- eng-manpages(7) --------------------------------------------------------

cf_check_manpages() {
  local repo=$1
  [[ -d $repo/doc ]] || return 0

  # Rendered roff committed under doc/ violates "pages built by Nix derivations".
  local rendered=()
  local f
  while IFS= read -r f; do
    [[ -n $f ]] && rendered+=("${f#"$repo"/}")
  done < <(find "$repo/doc" -type f -regextype posix-extended \
    -regex '.*\.[1-9]' 2>/dev/null)
  if ((${#rendered[@]} == 0)); then
    cf_ok
  else
    cf_violation eng-manpages/no-rendered warn "doc/" \
      "rendered manpage(s) committed; build them with scdoc via Nix instead: ${rendered[*]}"
  fi

  # Every scdoc source must be name.N.scd and carry header + NAME + DESCRIPTION.
  # The topic may contain hyphens and underscores (e.g.
  # eng-design_patterns-justfile.7.scd).
  local scd
  while IFS= read -r scd; do
    [[ -n $scd ]] || continue
    local rel=${scd#"$repo"/}
    local base=${scd##*/}
    if [[ ! $base =~ ^[a-z0-9_-]+\.[1-9]\.scd$ ]]; then
      cf_violation eng-manpages/source-naming error "$rel" \
        "manpage source must be named lowercase 'name.SECTION.scd'"
    else
      cf_ok
    fi

    # First non-blank line is the page header 'name(N)'; a NAME section follows
    # with a 'topic - description' line.
    local header
    header=$(grep -vE '^[[:space:]]*$' "$scd" | head -n1)
    if [[ $header =~ ^[a-z0-9_-]+\([1-9]\)$ ]] &&
      grep -Eq '^#[[:space:]]+NAME' "$scd" &&
      grep -Eq '^[a-z0-9_-]+ - .+' "$scd"; then
      cf_ok
    else
      cf_violation eng-manpages/header-name error "$rel" \
        "missing 'name(N)' header line or NAME section of the form 'topic - description'"
    fi

    if grep -Eq '^#[[:space:]]+DESCRIPTION' "$scd"; then
      cf_ok
    else
      cf_violation eng-manpages/description error "$rel" \
        "missing DESCRIPTION section"
    fi
  done < <(find "$repo/doc" -type f -name '*.scd' 2>/dev/null)
}

# --- eng-nix(7) / justfile(7) -----------------------------------------------

cf_check_nix() {
  local repo=$1 flake=$repo/flake.nix
  [[ -f $flake ]] || return 0

  if [[ -f $repo/flake.lock ]]; then cf_ok; else
    cf_violation eng-nix/flake-lock error "flake.lock" \
      "flake.nix present but flake.lock is not committed; pin inputs"
  fi

  if cf_has_match 'devShells\.default|devShell' "$flake"; then cf_ok; else
    cf_violation eng-nix/devshell warn "flake.nix" \
      "flake does not expose devShells.default (see VALIDATE-DEVSHELL)"
  fi

  if cf_has_match 'treefmt|formatter' "$flake" &&
    { [[ -f $repo/treefmt.nix ]] || [[ -f $repo/treefmt.toml ]]; }; then
    cf_ok
  else
    cf_violation eng-nix/formatter warn "flake.nix" \
      "formatter not wired to treefmt (need a formatter output + treefmt.nix/treefmt.toml)"
  fi
}

# --- eng-direnv(7) ----------------------------------------------------------

cf_check_direnv() {
  local repo=$1
  [[ -f $repo/flake.nix ]] || return 0
  local envrc=$repo/.envrc

  if cf_has_match '^[[:space:]]*use flake' "$envrc"; then
    cf_ok
  else
    cf_violation eng-direnv/use-flake warn ".envrc" \
      "flake devshell present but .envrc does not 'use flake'"
  fi

  if [[ -f $envrc ]]; then
    if grep -Eiq '(secret|token|password|api[_-]?key|_KEY)[[:space:]]*=' "$envrc"; then
      cf_violation eng-direnv/no-secrets warn ".envrc" \
        "possible secret assignment in .envrc; load secrets from an ignored env-file"
    else
      cf_ok
    fi
  fi
}

# --- amarbel-llc/eng#123: bats stay shfmt-compatible ------------------------

cf_check_bats() {
  local repo=$1

  # Only meaningful when the repo has a bats suite at all.
  if ! find "$repo" -name '*.bats' -print -quit 2>/dev/null | grep -q .; then
    return 0
  fi

  local hits=()
  local hit
  while IFS= read -r hit; do
    [[ -n $hit ]] && hits+=("${hit#"$repo"/}")
  done < <(grep -rEl '^@test ' --include='*.bats' "$repo" 2>/dev/null)

  if ((${#hits[@]} == 0)); then
    cf_ok
  else
    cf_violation conformist/bats-shfmt-compat error "${hits[0]}" \
      "bats test(s) use the bats-native '@test \"...\"' form; use 'function NAME { # @test' (${#hits[@]} file(s))"
  fi
}

# cf_run_all REPO — run every concern's checks in eng(7) SEE ALSO order.
cf_run_all() {
  local repo=$1
  cf_register_specs
  cf_check_layout "$repo"
  cf_check_versioning "$repo"
  cf_check_justfile "$repo"
  cf_check_manpages "$repo"
  cf_check_nix "$repo"
  cf_check_direnv "$repo"
  cf_check_bats "$repo"
}
