package rules

import (
	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

// layoutRules enforce repo-root presence of the eng "meta" files. These fire
// unconditionally (they are about what must exist).
func layoutRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "eng/layout-justfile",
			Spec:     "eng-design_patterns-justfile(7) — the justfile is the single task entrypoint",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				if r.IsFile("justfile") {
					return nil
				}

				return []rule.Finding{rule.F("justfile",
					"no justfile at repo root; the justfile is the single task entrypoint")}
			},
		},
		{
			ID:       "eng/layout-agents",
			Spec:     "eng(7) AGENT ORIENTATION — agent operating notes live in AGENTS.md at the repo root",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				if r.IsFile("AGENTS.md") {
					return nil
				}

				return []rule.Finding{rule.F("AGENTS.md",
					"no AGENTS.md at repo root; eng(7) AGENT ORIENTATION expects agent notes there")}
			},
		},
		{
			ID:       "eng/layout-readme",
			Spec:     "eng(7) — README.md at the repo root (general convention; not normative)",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				if r.IsFile("README.md") {
					return nil
				}

				return []rule.Finding{rule.F("README.md",
					"no README.md at repo root describing purpose and entrypoints")}
			},
		},
		{
			ID:       "eng/layout-version",
			Spec:     "eng-versioning(7) SINGLE VERSION SOURCE OF TRUTH — version.env at the repo root",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				if r.IsFile("version.env") {
					return nil
				}

				return []rule.Finding{rule.F("version.env",
					"no version.env; eng-versioning(7) requires a single version source of truth")}
			},
		},
		{
			ID:       "eng/layout-doc-dir",
			Spec:     "eng-manpages(7) PRINCIPLES — source files live in doc/",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				if r.HasDocDir() {
					return nil
				}

				return []rule.Finding{rule.F("doc/",
					"no doc/ directory; scdoc manpage sources live under doc/ (eng-manpages(7))")}
			},
		},
	}
}
