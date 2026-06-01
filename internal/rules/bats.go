package rules

import (
	"fmt"
	"regexp"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

// batsNativeRE matches the bats-native test form that breaks shfmt parsing.
var batsNativeRE = regexp.MustCompile(`(?m)^@test `)

func batsRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "conformist/bats-shfmt-compat",
			Spec:     "amarbel-llc/eng#123 — bats use the 'function NAME { # @test' form",
			Severity: rule.SeverityError,
			Check: func(r *repo.Repo) []rule.Finding {
				files := r.BatsFiles()
				if len(files) == 0 {
					return nil
				}

				var bad []string

				for _, rel := range files {
					data, err := r.ReadFile(rel)
					if err != nil {
						continue
					}

					if batsNativeRE.Match(data) {
						bad = append(bad, rel)
					}
				}

				if len(bad) == 0 {
					return nil
				}

				return []rule.Finding{rule.F(bad[0], fmt.Sprintf(
					"bats test(s) use the native '@test \"...\"' form; use 'function NAME { # @test' (%d file(s))",
					len(bad)))}
			},
		},
	}
}
