package cli

import (
	"fmt"
	"sort"

	"github.com/amarbel-llc/and-so-can-you/internal/rules"
	"github.com/spf13/cobra"
)

func newRulesCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "rules",
		Short: "List every rule and the eng-*(7) clause it enforces",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			out := cmd.OutOrStdout()
			color := useColor(out)

			specByID := map[string]string{}
			ids := make([]string, 0)

			for _, rl := range rules.Registry().Rules() {
				specByID[rl.ID] = rl.Spec
				ids = append(ids, rl.ID)
			}

			sort.Strings(ids)

			for _, id := range ids {
				label := id
				if color {
					label = "\033[1m" + id + "\033[0m"
				}

				fmt.Fprintf(out, "%s\n  %s\n", label, specByID[id])
			}

			return nil
		},
	}
}
