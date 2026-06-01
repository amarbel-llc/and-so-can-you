// Package cli wires conformist's cobra command tree and maps command outcomes
// to process exit codes.
package cli

import (
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/spf13/cobra"
)

// errFindings is the sentinel returned when a check produced error-severity
// findings. Main maps it to exit code 1 without printing (the reporter already
// printed the findings).
var errFindings = errors.New("conformance findings")

// Main builds and executes the root command, returning a process exit code:
// 0 = clean, 1 = error-severity findings, 2 = usage/operational error.
func Main(version, commit string) int {
	root := newRoot(version, commit)

	switch err := root.Execute(); {
	case err == nil:
		return 0
	case errors.Is(err, errFindings):
		return 1
	default:
		fmt.Fprintln(os.Stderr, "conformist:", err)

		return 2
	}
}

func newRoot(version, commit string) *cobra.Command {
	root := &cobra.Command{
		Use:           "conformist",
		Short:         "Whole-repo linter and bootstrapper for the eng-*(7) conventions",
		Long:          "conformist lints a repository against the amarbel-llc eng-*(7) conventions and scaffolds new repositories that already conform. With no arguments it checks the current directory.",
		Version:       version + "+" + commit,
		Args:          cobra.ArbitraryArgs,
		SilenceErrors: true, // Main owns error printing and exit codes
		SilenceUsage:  true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runCheck(cmd, firstArgOrDot(args))
		},
		CompletionOptions: cobra.CompletionOptions{DisableDefaultCmd: true},
	}

	root.SetVersionTemplate("conformist {{.Version}}\n")
	root.AddCommand(
		newCheckCmd(),
		newBootstrapCmd(),
		newRulesCmd(),
		newVersionCmd(version, commit),
		newGenManCmd(),
	)

	return root
}

func firstArgOrDot(args []string) string {
	if len(args) > 0 {
		return args[0]
	}

	return "."
}

// useColor reports whether ANSI color should be emitted to w: only when w is a
// terminal and NO_COLOR is unset.
func useColor(w io.Writer) bool {
	if os.Getenv("NO_COLOR") != "" {
		return false
	}

	f, ok := w.(*os.File)
	if !ok {
		return false
	}

	info, err := f.Stat()
	if err != nil {
		return false
	}

	return info.Mode()&os.ModeCharDevice != 0
}
