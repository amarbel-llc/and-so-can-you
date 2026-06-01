// Package rule defines conformist's rule model: a Rule is one
// mechanically-checkable eng-*(7) clause that carries its own normative
// citation, so `conformist rules` can never drift from what the checks enforce
// (the failure mode of the bash predecessor, where citations lived in a separate
// registry function).
package rule

import "github.com/amarbel-llc/and-so-can-you/internal/repo"

// Severity classifies a finding. Error-severity findings fail the run
// (non-zero exit); warn-severity findings are reported but do not fail.
type Severity int

const (
	SeverityWarn Severity = iota
	SeverityError
)

func (s Severity) String() string {
	if s == SeverityError {
		return "error"
	}

	return "warn"
}

// Finding is a single violation. A Check body sets only Path and Message; the
// registry stamps RuleID, Severity, and Spec from the owning Rule so those
// stay in lockstep with the rule definition.
type Finding struct {
	RuleID   string
	Severity Severity
	Path     string
	Message  string
	Spec     string
}

// F is the constructor a Check body uses to report a violation.
func F(path, message string) Finding {
	return Finding{Path: path, Message: message}
}

// Rule is one eng-*(7) clause conformist enforces. Spec is the normative
// citation (page + section). Check returns one Finding per violation, or nil
// when the rule passes; it must return nil when the rule's subject does not
// apply to the repo (conditional firing).
type Rule struct {
	ID       string
	Spec     string
	Severity Severity
	Check    func(r *repo.Repo) []Finding
}

// Result is the outcome of running a registry against a repo.
type Result struct {
	Findings []Finding
	Checked  int // number of rules evaluated
}

// Errors counts error-severity findings.
func (res Result) Errors() int {
	n := 0
	for _, f := range res.Findings {
		if f.Severity == SeverityError {
			n++
		}
	}

	return n
}

// Warnings counts warn-severity findings.
func (res Result) Warnings() int {
	n := 0
	for _, f := range res.Findings {
		if f.Severity == SeverityWarn {
			n++
		}
	}

	return n
}

// Registry is an ordered collection of rules.
type Registry struct {
	rules []Rule
}

// NewRegistry returns an empty registry.
func NewRegistry() *Registry { return &Registry{} }

// Add appends rules in the order they will run.
func (reg *Registry) Add(rules ...Rule) { reg.rules = append(reg.rules, rules...) }

// Rules returns the registered rules in order.
func (reg *Registry) Rules() []Rule { return reg.rules }

// Run evaluates every rule against r, stamping each finding with its rule's
// metadata.
func (reg *Registry) Run(r *repo.Repo) Result {
	res := Result{Checked: len(reg.rules)}

	for _, rl := range reg.rules {
		findings := rl.Check(r)
		for i := range findings {
			findings[i].RuleID = rl.ID
			findings[i].Severity = rl.Severity
			findings[i].Spec = rl.Spec
		}

		res.Findings = append(res.Findings, findings...)
	}

	return res
}
