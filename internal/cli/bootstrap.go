package cli

import (
	"github.com/amarbel-llc/and-so-can-you/internal/bootstrap"
	"github.com/spf13/cobra"
)

func newBootstrapCmd() *cobra.Command {
	var (
		name  string
		force bool
	)

	cmd := &cobra.Command{
		Use:   "bootstrap [dir]",
		Short: "Scaffold an eng-conformant repository",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			errw := cmd.ErrOrStderr()

			return bootstrap.Run(bootstrap.Options{
				Dir:    firstArgOrDot(args),
				Name:   name,
				Force:  force,
				Stderr: errw,
				Color:  useColor(errw),
			})
		},
	}

	cmd.Flags().StringVar(&name, "name", "", "canonical repo name (default: target dir basename)")
	cmd.Flags().BoolVar(&force, "force", false, "write into a non-empty directory")

	return cmd
}
