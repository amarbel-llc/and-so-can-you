package rules

import (
	"regexp"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

var (
	flakeDevShellRE = regexp.MustCompile(`devShells\.default|devShell`)
	flakeFmtRE      = regexp.MustCompile(`treefmt|formatter`)
)

// flakeRules check a repo that ships a flake.nix. They fire only when flake.nix
// exists. Nix is not fully evaluated; the devShell/formatter checks are
// presence heuristics over comment-stripped source (an honest limitation —
// true output verification would need `nix flake show`).
func flakeRules() []rule.Rule {
	return []rule.Rule{
		{
			ID:       "flake/lock",
			Spec:     "Nix hygiene — commit flake.lock to pin inputs (baseline convention; eng-nix(7) ANTI-PATTERNS notes the lock only resolves inputs)",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				f := r.Flake()
				if !f.Present || f.HasLock {
					return nil
				}

				return []rule.Finding{rule.F("flake.lock",
					"flake.nix present but flake.lock is not committed; pin inputs")}
			},
		},
		{
			ID:       "flake/devshell",
			Spec:     "eng-design_patterns-justfile(7) VALIDATE-DEVSHELL — expose devShells.default",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				f := r.Flake()
				if !f.Present || f.MatchString(flakeDevShellRE) {
					return nil
				}

				return []rule.Finding{rule.F("flake.nix",
					"flake does not expose devShells.default (see VALIDATE-DEVSHELL)")}
			},
		},
		{
			ID:       "flake/formatter",
			Spec:     "eng-design_patterns-justfile(7) LINT-FMT — wire the formatter to treefmt",
			Severity: rule.SeverityWarn,
			Check: func(r *repo.Repo) []rule.Finding {
				f := r.Flake()
				if !f.Present {
					return nil
				}

				if f.MatchString(flakeFmtRE) && (r.IsFile("treefmt.nix") || r.IsFile("treefmt.toml")) {
					return nil
				}

				return []rule.Finding{rule.F("flake.nix",
					"formatter not wired to treefmt (need a formatter output + treefmt.nix/treefmt.toml)")}
			},
		},
	}
}
