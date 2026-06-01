package cli

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/cobra/doc"
)

// newGenManCmd generates the section-1 CLI reference pages from the cobra
// command tree (eng-manpages(7) PRINCIPLES #3). It is hidden: it exists for the
// Nix manpages derivation, not for end users, and GenManTree skips it because
// hidden commands are not "available".
func newGenManCmd() *cobra.Command {
	return &cobra.Command{
		Use:    "gen-man <dir>",
		Short:  "Generate section-1 man pages from the command tree",
		Hidden: true,
		Args:   cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			root := cmd.Root()
			root.DisableAutoGenTag = true

			header := &doc.GenManHeader{
				Title:   "CONFORMIST",
				Section: "1",
				Source:  "conformist",
			}

			if err := doc.GenManTree(root, header, args[0]); err != nil {
				return fmt.Errorf("generating man pages: %w", err)
			}

			return nil
		},
	}
}
