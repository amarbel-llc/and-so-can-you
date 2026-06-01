package rules

import (
	"fmt"
	"strings"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

func justfileRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "eng-justfile/parse",
			Spec:     "eng-design_patterns-justfile(7) — the justfile must be valid",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				jf := r.Justfile()
				if !jf.Present || jf.ToolMissing || jf.ParseErr == nil {
					return nil
				}

				return []rule.Finding{rule.F("justfile",
					"justfile could not be parsed: "+jf.ParseErr.Error())}
			},
		},
		{
			ID:       "eng-justfile/default-recipe",
			Spec:     "eng-design_patterns-justfile(7) DEFAULT RECIPE — the first recipe is 'default'",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				jf := r.Justfile()
				// Skip when unparseable / first recipe unknown: don't guess.
				if !jf.Present || jf.First == "" || jf.First == "default" {
					return nil
				}

				return []rule.Finding{rule.F("justfile",
					fmt.Sprintf("the first recipe must be 'default' (found %q)", jf.First))}
			},
		},
		{
			ID:       "eng-justfile/default-aggregate",
			Spec:     "eng-design_patterns-justfile(7) DEFAULT RECIPE — default lists aggregates, has no body",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				jf := r.Justfile()

				d, ok := jf.Recipes["default"]
				if !ok || !d.HasBody {
					return nil
				}

				return []rule.Finding{rule.F("justfile",
					"default recipe has a body; it should only list aggregate dependencies")}
			},
		},
		{
			ID:       "eng-justfile/generic-name",
			Spec:     "eng-design_patterns-justfile(7) ANTI-PATTERNS — no generic names (all/dev/check/compile)",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				jf := r.Justfile()

				var generic []string

				for _, g := range []string{"all", "dev", "check", "compile"} {
					if _, ok := jf.Recipes[g]; ok {
						generic = append(generic, g)
					}
				}

				if len(generic) == 0 {
					return nil
				}

				return []rule.Finding{rule.F("justfile",
					"generic recipe name(s) "+strings.Join(generic, ", ")+"; use verb-noun names instead")}
			},
		},
	}
}
