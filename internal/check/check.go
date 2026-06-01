// Package check orchestrates a lint run: build a repo model, run the rule
// registry, and report. It is shared by the `check` command and by bootstrap's
// self-proof.
package check

import (
	"fmt"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/report"
	"github.com/amarbel-llc/and-so-can-you/internal/rules"
)

// Run lints dir, printing a header, findings, and a summary via rp. It returns
// clean=true when there are no error-severity findings. An operational failure
// (bad directory, or a justfile present without the `just` parser available) is
// returned as err and should map to a non-finding exit code.
func Run(dir string, rp *report.Reporter) (clean bool, err error) {
	r, err := repo.New(dir)
	if err != nil {
		return false, err
	}

	if jf := r.Justfile(); jf.Present && jf.ToolMissing {
		return false, fmt.Errorf("`just` not found on PATH; it is required to lint the justfile")
	}

	rp.Header(dir)

	return rp.Report(rules.Registry().Run(r)), nil
}
