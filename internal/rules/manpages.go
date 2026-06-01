package rules

import (
	"strings"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

// manpageRules check scdoc sources under doc/. They fire only when the repo has
// a doc/ directory (shape rules are conditional on their subject).
func manpageRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "eng-manpages/no-rendered",
			Spec:     "eng-manpages(7) PRINCIPLES — pages are built by Nix; rendered roff is not committed",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				if !r.HasDocDir() {
					return nil
				}

				rendered := r.RenderedRoff()
				if len(rendered) == 0 {
					return nil
				}

				return []rule.Finding{rule.F("doc/",
					"rendered manpage(s) committed; build them with scdoc via Nix instead: "+strings.Join(rendered, ", "))}
			},
		},
		{
			ID:       "eng-manpages/source-naming",
			Spec:     "eng-manpages(7) FILE NAMING — name.SECTION.scd under doc/",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				var findings []rule.Finding

				for _, mp := range r.Manpages() {
					if !mp.ValidName {
						findings = append(findings, rule.F(mp.Rel,
							"manpage source must be named lowercase 'name.SECTION.scd'"))
					}
				}

				return findings
			},
		},
		{
			ID:       "eng-manpages/header-name",
			Spec:     "eng-manpages(7) SCDOC PATTERN — first line name(N) and a NAME section 'topic - description'",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				var findings []rule.Finding

				for _, mp := range r.Manpages() {
					if !mp.HasHeader {
						findings = append(findings, rule.F(mp.Rel,
							"missing 'name(N)' header line or NAME section of the form 'topic - description'"))
					}
				}

				return findings
			},
		},
		{
			ID:       "eng-manpages/description",
			Spec:     "eng-manpages(7) — generated page structure includes a DESCRIPTION section",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				var findings []rule.Finding

				for _, mp := range r.Manpages() {
					if !mp.HasDescription {
						findings = append(findings, rule.F(mp.Rel, "missing DESCRIPTION section"))
					}
				}

				return findings
			},
		},
	}
}
