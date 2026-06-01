package cli

import (
	"github.com/amarbel-llc/and-so-can-you/internal/check"
	"github.com/amarbel-llc/and-so-can-you/internal/report"
	"github.com/spf13/cobra"
)

func newCheckCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "check [dir]",
		Short: "Lint a repo against the eng-*(7) rules",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runCheck(cmd, firstArgOrDot(args))
		},
	}
}

// runCheck lints dir and translates the outcome into the cli's error contract:
// nil on clean, errFindings on error-severity findings, the raw error on
// operational failure.
func runCheck(cmd *cobra.Command, dir string) error {
	w := cmd.ErrOrStderr()

	clean, err := check.Run(dir, report.New(w, useColor(w)))
	if err != nil {
		return err
	}

	if !clean {
		return errFindings
	}

	return nil
}
