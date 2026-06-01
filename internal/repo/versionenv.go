package repo

import (
	"regexp"
	"strings"
)

// versionLineRE matches the eng-versioning(7) source-of-truth line:
// `export <REPO>_VERSION=<value>` (the `export` prefix is tolerated, per the
// page). The variable name must be uppercase ending in _VERSION.
var versionLineRE = regexp.MustCompile(`(?m)^[[:space:]]*(?:export[[:space:]]+)?([A-Z][A-Z0-9_]*_VERSION)=(.*)$`)

// VersionEnv is the parsed view of version.env.
type VersionEnv struct {
	Present bool   // version.env exists at the repo root
	HasDecl bool   // a `<REPO>_VERSION=` line was found
	VarName string // the matched variable name, e.g. ANDSOCANYOU_VERSION
	Value   string // the version value with quotes/whitespace stripped
}

// VersionEnv parses version.env once and caches the result.
func (r *Repo) VersionEnv() *VersionEnv {
	if r.versionEnv != nil {
		return r.versionEnv
	}

	ve := &VersionEnv{}
	r.versionEnv = ve

	data, err := r.ReadFile("version.env")
	if err != nil {
		return ve
	}

	ve.Present = true

	m := versionLineRE.FindSubmatch(data)
	if m == nil {
		return ve
	}

	ve.HasDecl = true
	ve.VarName = string(m[1])

	value := strings.TrimSpace(string(m[2]))
	value = strings.Trim(value, `"`)
	value = strings.ReplaceAll(value, " ", "")
	ve.Value = value

	return ve
}
