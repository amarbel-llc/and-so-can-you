// Package report renders rule findings and a run summary to a writer, with
// optional ANSI color.
package report

import (
	"fmt"
	"io"
	"sort"

	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

const (
	red    = "\033[31m"
	yellow = "\033[33m"
	blue   = "\033[34m"
	dim    = "\033[2m"
	bold   = "\033[1m"
	reset  = "\033[0m"
)

// Reporter writes findings and summaries.
type Reporter struct {
	w     io.Writer
	color bool
}

// New returns a Reporter writing to w. When color is false, no ANSI codes are
// emitted (honoring NO_COLOR and non-tty output).
func New(w io.Writer, color bool) *Reporter { return &Reporter{w: w, color: color} }

func (rp *Reporter) paint(code, s string) string {
	if !rp.color {
		return s
	}

	return code + s + reset
}

// Header announces the repo being checked.
func (rp *Reporter) Header(dir string) {
	fmt.Fprintf(rp.w, "%s checking %s against eng-*(7)\n",
		rp.paint(blue, "conformist"), rp.paint(bold, dir))
}

func (rp *Reporter) finding(f rule.Finding) {
	color := yellow
	if f.Severity == rule.SeverityError {
		color = red
	}

	fmt.Fprintf(rp.w, "%s %s %s\n", rp.paint(color, f.Severity.String()), rp.paint(bold, f.RuleID), f.Path)
	fmt.Fprintf(rp.w, "  %s\n", f.Message)

	if f.Spec != "" {
		fmt.Fprintf(rp.w, "  %s %s\n", rp.paint(dim, "spec:"), f.Spec)
	}
}

// Report prints every finding (errors first, then by rule id) and a summary
// line. It returns true when the run is clean of error-severity findings.
func (rp *Reporter) Report(res rule.Result) bool {
	findings := make([]rule.Finding, len(res.Findings))
	copy(findings, res.Findings)

	sort.SliceStable(findings, func(i, j int) bool {
		if findings[i].Severity != findings[j].Severity {
			return findings[i].Severity > findings[j].Severity // errors first
		}

		return findings[i].RuleID < findings[j].RuleID
	})

	for _, f := range findings {
		rp.finding(f)
	}

	errors := res.Errors()
	warnings := res.Warnings()

	if errors == 0 && warnings == 0 {
		fmt.Fprintf(rp.w, "%s %d checks passed, repo is eng-conformant\n",
			rp.paint(blue, "conformist:"), res.Checked)

		return true
	}

	fmt.Fprintln(rp.w)
	fmt.Fprintf(rp.w, "%s %d error(s), %d warning(s) across %d checks\n",
		rp.paint(blue, "conformist:"), errors, warnings, res.Checked)

	return errors == 0
}
