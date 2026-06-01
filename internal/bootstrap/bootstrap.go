// Package bootstrap scaffolds an eng-conformant repository from embedded
// templates, then runs the conformist rules on the result (self-proof).
package bootstrap

import (
	"embed"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/amarbel-llc/and-so-can-you/internal/check"
	"github.com/amarbel-llc/and-so-can-you/internal/report"
)

//go:embed templates/*.tpl
var templatesFS embed.FS

// nameRE constrains scaffold names so generated manpages and version variables
// stay conformant.
var nameRE = regexp.MustCompile(`^[a-z0-9][a-z0-9-]*$`)

// Options configures a bootstrap run.
type Options struct {
	Dir    string
	Name   string // canonical repo name; defaults to the target dir basename
	Force  bool   // scaffold into a non-empty directory
	Year   int    // copyright year; 0 means use the current year
	Stderr io.Writer
	Color  bool
}

// Run scaffolds a repository per opt. It returns an error only on operational
// failure (invalid name, non-empty target without --force, write error);
// self-proof findings do not fail the run.
func Run(opt Options) error {
	dir := opt.Dir
	if dir == "" {
		dir = "."
	}

	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("cannot create %s: %w", dir, err)
	}

	abs, err := filepath.Abs(dir)
	if err != nil {
		return fmt.Errorf("resolving %s: %w", dir, err)
	}

	name := opt.Name
	if name == "" {
		name = filepath.Base(abs)
	}

	if !nameRE.MatchString(name) {
		return fmt.Errorf("name %q must be lowercase letters, digits, and hyphens only", name)
	}

	if !opt.Force {
		if entries, _ := os.ReadDir(abs); len(entries) > 0 {
			return fmt.Errorf("%s is not empty (use --force to scaffold anyway)", abs)
		}
	}

	year := opt.Year
	if year == 0 {
		year = time.Now().Year()
	}

	repl := strings.NewReplacer(
		"@@NAME@@", name,
		"@@TITLE@@", name,
		"@@VAR@@", strings.NewReplacer("-", "_").Replace(strings.ToUpper(name)),
		"@@YEAR@@", fmt.Sprintf("%d", year),
	)

	if err := os.MkdirAll(filepath.Join(abs, "doc"), 0o755); err != nil {
		return fmt.Errorf("creating doc/: %w", err)
	}

	files := []struct{ tpl, dest string }{
		{"version.env.tpl", "version.env"},
		{"LICENSE.tpl", "LICENSE"},
		{"README.md.tpl", "README.md"},
		{"AGENTS.md.tpl", "AGENTS.md"},
		{"justfile.tpl", "justfile"},
		{"flake.nix.tpl", "flake.nix"},
		{"treefmt.nix.tpl", "treefmt.nix"},
		{"envrc.tpl", ".envrc"},
		{"gitignore.tpl", ".gitignore"},
		{"topic.7.scd.tpl", filepath.Join("doc", name+".7.scd")},
	}

	for _, f := range files {
		if err := render(f.tpl, filepath.Join(abs, f.dest), repl); err != nil {
			return err
		}
	}

	stderr := opt.Stderr
	fmt.Fprintf(stderr, "conformist bootstrapped %s in %s\n\n", name, abs)
	fmt.Fprintf(stderr, "verifying with the conformist rules (self-proof)…\n\n")

	rp := report.New(stderr, opt.Color)
	if _, cErr := check.Run(abs, rp); cErr != nil {
		fmt.Fprintf(stderr, "  (self-proof incomplete: %v)\n", cErr)
	}

	fmt.Fprintf(stderr, "\nnext: cd %s && nix flake lock && just\n", abs)

	return nil
}

func render(tplName, dest string, repl *strings.Replacer) error {
	raw, err := templatesFS.ReadFile("templates/" + tplName)
	if err != nil {
		return fmt.Errorf("reading template %s: %w", tplName, err)
	}

	if err := os.WriteFile(dest, []byte(repl.Replace(string(raw))), 0o644); err != nil { //nolint:gosec // scaffolded files are not secrets
		return fmt.Errorf("writing %s: %w", dest, err)
	}

	return nil
}
