package repo

import (
	"strings"
	"testing"
)

// TestStripNixCommentsPreservesGlobs guards against the bug where naive /* */
// block stripping truncated the source at a shell glob like doc/*.scd.
func TestStripNixCommentsPreservesGlobs(t *testing.T) {
	src := "a = 1; # comment\nbuild = ''for f in ${self}/doc/*.scd; do :; done'';\ndevShells.default = {};\n"

	out := stripNixComments(src)

	if !strings.Contains(out, "devShells.default") {
		t.Fatalf("stripNixComments dropped content after a glob: %q", out)
	}

	if strings.Contains(out, "# comment") {
		t.Errorf("stripNixComments did not strip a # line comment: %q", out)
	}
}
