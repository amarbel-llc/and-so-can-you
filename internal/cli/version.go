package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

// newVersionCmd implements the version subcommand mandated by eng-versioning(7)
// PRINCIPLES #4: emit "conformist <version>+<commit>".
func newVersionCmd(version, commit string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			_, err := fmt.Fprintf(cmd.OutOrStdout(), "conformist %s+%s\n", version, commit)

			return err
		},
	}
}
