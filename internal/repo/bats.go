package repo

// BatsFiles returns the repo-relative paths of every *.bats file in the tree.
func (r *Repo) BatsFiles() []string { return r.findByExt("", ".bats") }
