package rules

import (
	"regexp"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

var (
	useFlakeRE     = regexp.MustCompile(`(?m)^[[:space:]]*use flake`)
	secretAssignRE = regexp.MustCompile(`(?i)(secret|token|password|api[_-]?key|_KEY)\s*=`)
)

// direnvRules check the .envrc of a repo that ships a flake. They fire only
// when flake.nix exists.
func direnvRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "eng-direnv/use-flake",
			Spec:     "eng-direnv(7) CHILD REPO ENVRC — .envrc activates the flake devshell via 'use flake'",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				if !r.IsFile("flake.nix") {
					return nil
				}

				if data, err := r.ReadFile(".envrc"); err == nil && useFlakeRE.Match(data) {
					return nil
				}

				return []rule.Finding{rule.F(".envrc",
					"flake devshell present but .envrc does not 'use flake'")}
			},
		},
		{
			ID:       "eng-direnv/secrets",
			Spec:     "eng-direnv(7) ENV FILE CONVENTIONS — secrets live in gitignored .secrets.env, never in .envrc/.env",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				if !r.IsFile("flake.nix") {
					return nil
				}

				var findings []rule.Finding

				for _, name := range []string{".envrc", ".env"} {
					data, err := r.ReadFile(name)
					if err != nil {
						continue
					}

					if secretAssignRE.Match(data) {
						findings = append(findings, rule.F(name,
							"possible secret assignment in "+name+"; load secrets from gitignored .secrets.env instead"))
					}
				}

				return findings
			},
		},
	}
}
