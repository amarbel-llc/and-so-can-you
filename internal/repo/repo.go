// Package repo models a repository on disk and exposes lazily-parsed, typed
// views of the "meta" files conformist's rules inspect (version.env, justfile,
// flake.nix, scdoc manpages, bats tests). Each view is parsed once on first
// access and cached. Going through real parsers — rather than grep — is the
// reason conformist is written in Go.
package repo

import (
	"fmt"
	"os"
	"path/filepath"
)

// Repo is a handle to a repository root plus its cached parsed views.
type Repo struct {
	Root string

	versionEnv *VersionEnv
	justfile   *Justfile
	manpages   []Manpage
	flake      *Flake
}

// New returns a Repo rooted at dir, which must be an existing directory.
func New(dir string) (*Repo, error) {
	info, err := os.Stat(dir)
	if err != nil {
		return nil, fmt.Errorf("not a directory: %s: %w", dir, err)
	}

	if !info.IsDir() {
		return nil, fmt.Errorf("not a directory: %s", dir)
	}

	abs, err := filepath.Abs(dir)
	if err != nil {
		return nil, fmt.Errorf("resolving %s: %w", dir, err)
	}

	return &Repo{Root: abs}, nil
}

// Path joins rel onto the repo root.
func (r *Repo) Path(rel string) string { return filepath.Join(r.Root, rel) }

// IsFile reports whether rel exists and is a regular file.
func (r *Repo) IsFile(rel string) bool {
	info, err := os.Stat(r.Path(rel))

	return err == nil && info.Mode().IsRegular()
}

// IsDir reports whether rel exists and is a directory.
func (r *Repo) IsDir(rel string) bool {
	info, err := os.Stat(r.Path(rel))

	return err == nil && info.IsDir()
}

// ReadFile reads rel relative to the repo root.
func (r *Repo) ReadFile(rel string) ([]byte, error) {
	data, err := os.ReadFile(r.Path(rel))
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", rel, err)
	}

	return data, nil
}
