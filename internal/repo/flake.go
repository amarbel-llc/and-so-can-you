package repo

import (
	"regexp"
	"strings"
)

// Flake is the parsed view of flake.nix. Nix is not fully parsed (that needs a
// Nix evaluator); structural rules match against a comment-stripped copy of the
// source, which is honest about being a heuristic but avoids the bash version's
// false matches on commented-out text. flake.lock presence is exact.
type Flake struct {
	Present bool
	HasLock bool
	source  string // flake.nix with comments removed
}

// Flake parses flake.nix once and caches the result.
func (r *Repo) Flake() *Flake {
	if r.flake != nil {
		return r.flake
	}

	f := &Flake{}
	r.flake = f

	if !r.IsFile("flake.nix") {
		return f
	}

	f.Present = true
	f.HasLock = r.IsFile("flake.lock")

	if data, err := r.ReadFile("flake.nix"); err == nil {
		f.source = stripNixComments(string(data))
	}

	return f
}

// MatchString reports whether the comment-stripped flake source matches re.
func (f *Flake) MatchString(re *regexp.Regexp) bool { return re.MatchString(f.source) }

// stripNixComments removes #-to-end-of-line comments so the presence checks do
// not match commented-out attributes. It deliberately does NOT strip /* */
// blocks: Nix shell-command strings and globs contain "/*" (e.g. doc/*.scd),
// and a naive block stripper truncates the source at the first unmatched "/*".
// The line-comment removal is a heuristic — a literal # inside a Nix string is
// also stripped — which is acceptable for these presence checks.
func stripNixComments(src string) string {
	var b strings.Builder

	for _, line := range strings.Split(src, "\n") {
		if k := strings.IndexByte(line, '#'); k >= 0 {
			line = line[:k]
		}

		b.WriteString(line)
		b.WriteByte('\n')
	}

	return b.String()
}
