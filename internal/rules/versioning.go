package rules

import (
	"fmt"
	"regexp"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

// semverRE matches a bare MAJOR.MINOR.PATCH with optional prerelease, no leading
// "v" (eng-versioning(7) PRINCIPLES #2).
var semverRE = regexp.MustCompile(`^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$`)

func versioningRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "eng-versioning/deprecated-file",
			Spec:     "eng-versioning(7) SINGLE VERSION SOURCE OF TRUTH (Deprecated alternatives) — version.env supersedes VERSION/version.txt",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				var findings []rule.Finding

				for _, dep := range []string{"VERSION", "version.txt"} {
					if r.IsFile(dep) {
						findings = append(findings, rule.F(dep,
							"deprecated version file; migrate to version.env (export <REPO>_VERSION=...)"))
					}
				}

				return findings
			},
		},
		{
			ID:       "eng-versioning/source-of-truth",
			Spec:     "eng-versioning(7) SINGLE VERSION SOURCE OF TRUTH — export <REPO>_VERSION=",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				ve := r.VersionEnv()
				if !ve.Present || ve.HasDecl {
					return nil
				}

				return []rule.Finding{rule.F("version.env",
					"version.env must declare 'export <REPO>_VERSION=<semver>'")}
			},
		},
		{
			ID:       "eng-versioning/semver",
			Spec:     "eng-versioning(7) PRINCIPLES — semantic versioning MAJOR.MINOR.PATCH",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				ve := r.VersionEnv()
				if !ve.Present || !ve.HasDecl || semverRE.MatchString(ve.Value) {
					return nil
				}

				return []rule.Finding{rule.F("version.env",
					fmt.Sprintf("version %q is not MAJOR.MINOR.PATCH semantic versioning", ve.Value))}
			},
		},
	}
}
