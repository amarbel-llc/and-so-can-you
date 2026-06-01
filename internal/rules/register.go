// Package rules holds conformist's eng-*(7) conformance rules, one Go value per
// mechanically-checkable clause. Each rule carries its own normative citation
// (see internal/rule). The eng-*(7) manpages remain the source of truth; this
// package is the subset conformist can check.
package rules

import "github.com/amarbel-llc/and-so-can-you/internal/rule"

// Registry returns the full, ordered rule registry. Order follows the eng(7)
// concern grouping: layout, versioning, justfile, manpages, flake, direnv, bats.
func Registry() *rule.Registry {
	reg := rule.NewRegistry()

	reg.Add(layoutRules()...)
	reg.Add(versioningRules()...)
	reg.Add(justfileRules()...)
	reg.Add(manpageRules()...)
	reg.Add(flakeRules()...)
	reg.Add(direnvRules()...)
	reg.Add(batsRules()...)

	return reg
}
