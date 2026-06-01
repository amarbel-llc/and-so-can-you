package repo

import (
	"io/fs"
	"path/filepath"
	"sort"
	"strings"
)

// skipDirs are directory names never walked when scanning a repo for files of
// interest: VCS metadata, build outputs, dependency caches, and nested
// worktrees (which may contain other repos).
var skipDirs = map[string]bool{
	".git":         true,
	".direnv":      true,
	".worktrees":   true,
	".tmp":         true,
	"node_modules": true,
	"vendor":       true,
	"build":        true,
}

func skipDir(name string) bool {
	return skipDirs[name] || strings.HasPrefix(name, "result")
}

// findByExt walks dir (relative to the repo root) and returns the repo-relative
// paths of every regular file whose name ends with suffix, skipping noise
// directories. Results are sorted for stable output.
func (r *Repo) findByExt(dir, suffix string) []string {
	var out []string

	root := r.Path(dir)

	_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil //nolint:nilerr // unreadable entries are simply skipped
		}

		if d.IsDir() {
			if path != root && skipDir(d.Name()) {
				return filepath.SkipDir
			}

			return nil
		}

		if strings.HasSuffix(d.Name(), suffix) {
			if rel, relErr := filepath.Rel(r.Root, path); relErr == nil {
				out = append(out, rel)
			}
		}

		return nil
	})

	sort.Strings(out)

	return out
}
