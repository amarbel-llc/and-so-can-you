package repo

import (
	"bufio"
	"bytes"
	"io/fs"
	"path/filepath"
	"regexp"
	"strings"
)

var (
	scdNameRE      = regexp.MustCompile(`^[a-z0-9_-]+\.[1-9]\.scd$`)
	scdHeaderRE    = regexp.MustCompile(`^[a-z0-9_-]+\([1-9]\)$`)
	scdNameSecRE   = regexp.MustCompile(`(?m)^#[[:space:]]+NAME`)
	scdNameLineRE  = regexp.MustCompile(`(?m)^[a-z0-9_-]+ - .+`)
	scdDescSecRE   = regexp.MustCompile(`(?m)^#[[:space:]]+DESCRIPTION`)
	renderedRoffRE = regexp.MustCompile(`\.[1-9]$`)
)

// Manpage is the parsed shape of a scdoc source under doc/.
type Manpage struct {
	Rel            string // repo-relative path, e.g. doc/conformist.7.scd
	Base           string // conformist.7.scd
	ValidName      bool   // matches name.SECTION.scd
	HasHeader      bool   // first line is name(N) and a NAME section with 'topic - desc' exists
	HasDescription bool   // a DESCRIPTION section exists
}

// HasDocDir reports whether the repo has a doc/ directory.
func (r *Repo) HasDocDir() bool { return r.IsDir("doc") }

// Manpages parses every scdoc source under doc/ once and caches the result.
func (r *Repo) Manpages() []Manpage {
	if r.manpages != nil {
		return r.manpages
	}

	r.manpages = []Manpage{}

	for _, rel := range r.findByExt("doc", ".scd") {
		data, err := r.ReadFile(rel)
		if err != nil {
			continue
		}

		mp := Manpage{Rel: rel, Base: filepath.Base(rel)}
		mp.ValidName = scdNameRE.MatchString(mp.Base)
		mp.HasHeader = scdHeaderRE.MatchString(firstNonBlankLine(data)) &&
			scdNameSecRE.Match(data) && scdNameLineRE.Match(data)
		mp.HasDescription = scdDescSecRE.Match(data)

		r.manpages = append(r.manpages, mp)
	}

	return r.manpages
}

// RenderedRoff returns repo-relative paths of committed rendered roff under
// doc/ (files ending in .1 .. .9), which eng-manpages(7) says should be built
// by Nix rather than committed.
func (r *Repo) RenderedRoff() []string {
	var out []string

	root := r.Path("doc")

	_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil //nolint:nilerr // unreadable entries are skipped
		}

		if d.IsDir() {
			if path != root && skipDir(d.Name()) {
				return filepath.SkipDir
			}

			return nil
		}

		if renderedRoffRE.MatchString(d.Name()) {
			if rel, relErr := filepath.Rel(r.Root, path); relErr == nil {
				out = append(out, rel)
			}
		}

		return nil
	})

	return out
}

func firstNonBlankLine(data []byte) string {
	sc := bufio.NewScanner(bytes.NewReader(data))
	for sc.Scan() {
		if line := strings.TrimSpace(sc.Text()); line != "" {
			return line
		}
	}

	return ""
}
