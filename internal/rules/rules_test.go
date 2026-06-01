package rules

import (
	"os"
	"strings"
	"testing"
)

func TestRuleInvariants(t *testing.T) {
	seen := map[string]bool{}

	for _, rl := range Registry().Rules() {
		if rl.ID == "" {
			t.Error("rule with empty ID")
		}

		if rl.Spec == "" {
			t.Errorf("rule %q has an empty Spec citation", rl.ID)
		}

		if rl.Check == nil {
			t.Errorf("rule %q has a nil Check", rl.ID)
		}

		if seen[rl.ID] {
			t.Errorf("duplicate rule ID %q", rl.ID)
		}

		seen[rl.ID] = true
	}
}

// TestEveryRuleDocumented guards against the doc/code drift that motivated the
// rewrite: every registered rule id must appear in the section-7 manpage.
func TestEveryRuleDocumented(t *testing.T) {
	data, err := os.ReadFile("../../doc/conformist.7.scd")
	if err != nil {
		t.Fatalf("reading manpage: %v", err)
	}

	page := string(data)

	for _, rl := range Registry().Rules() {
		if !strings.Contains(page, rl.ID) {
			t.Errorf("rule %q is not documented in doc/conformist.7.scd", rl.ID)
		}
	}
}
