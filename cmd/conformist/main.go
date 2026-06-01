// Command conformist is a whole-repo, cross-format linter and bootstrapper for
// the amarbel-llc eng-*(7) conventions. See doc/conformist.7.scd.
package main

import (
	"os"

	"github.com/amarbel-llc/and-so-can-you/internal/cli"
)

// version and commit are injected at build time by the amarbel-llc/nixpkgs fork's
// buildGoApplication: -X main.version (read from version.env) and -X main.commit
// (from the flake's self.rev). A plain `go build` leaves the defaults below.
// See eng-versioning(7).
var (
	version = "dev"
	commit  = "unknown"
)

func main() {
	os.Exit(cli.Main(version, commit))
}
