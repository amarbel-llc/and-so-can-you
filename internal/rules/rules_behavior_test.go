package rules

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/amarbel-llc/and-so-can-you/internal/repo"
	"github.com/amarbel-llc/and-so-can-you/internal/rule"
)

// runRepo writes files into a temp dir (relative paths, nested dirs created as
// needed) and runs the full registry against it.
func runRepo(t *testing.T, files map[string]string) rule.Result {
	t.Helper()

	dir := t.TempDir()

	for name, content := range files {
		p := filepath.Join(dir, name)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}

		if err := os.WriteFile(p, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	r, err := repo.New(dir)
	if err != nil {
		t.Fatal(err)
	}

	return Registry().Run(r)
}

func findingIDs(res rule.Result) map[string]rule.Severity {
	m := map[string]rule.Severity{}
	for _, f := range res.Findings {
		m[f.RuleID] = f.Severity
	}

	return m
}

func TestVersioningSemver(t *testing.T) {
	cases := []struct {
		name        string
		content     string
		wantFinding bool
	}{
		{"valid", "export FOO_VERSION=1.2.3\n", false},
		{"prerelease", "export FOO_VERSION=1.2.3-rc.1\n", false},
		{"two-part", "export FOO_VERSION=1.2\n", true},
		{"leading-v", "export FOO_VERSION=v1.2.3\n", true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			res := runRepo(t, map[string]string{"version.env": tc.content})

			_, got := findingIDs(res)["eng-versioning/semver"]
			if got != tc.wantFinding {
				t.Errorf("semver finding = %v, want %v", got, tc.wantFinding)
			}
		})
	}
}

func TestVersioningSourceOfTruth(t *testing.T) {
	res := runRepo(t, map[string]string{"version.env": "FOO=bar\n"})

	if _, ok := findingIDs(res)["eng-versioning/source-of-truth"]; !ok {
		t.Error("expected eng-versioning/source-of-truth on version.env without <REPO>_VERSION")
	}
}

func TestLayoutMissingFilesAreErrors(t *testing.T) {
	ids := findingIDs(runRepo(t, map[string]string{}))

	for _, id := range []string{"eng/layout-justfile", "eng/layout-agents", "eng/layout-version"} {
		if ids[id] != rule.SeverityError {
			t.Errorf("expected error-severity %q on an empty repo", id)
		}
	}
}

func TestBatsNativeFormRejected(t *testing.T) {
	res := runRepo(t, map[string]string{
		"zz-tests_bats/bad.bats": "@test \"x\" {\n  true\n}\n",
	})

	if findingIDs(res)["conformist/bats-shfmt-compat"] != rule.SeverityError {
		t.Error("expected conformist/bats-shfmt-compat error for bats-native form")
	}
}

func TestBatsFunctionFormAccepted(t *testing.T) {
	res := runRepo(t, map[string]string{
		"zz-tests_bats/ok.bats": "function x { # @test\n  true\n}\n",
	})

	if _, ok := findingIDs(res)["conformist/bats-shfmt-compat"]; ok {
		t.Error("did not expect a bats finding for the shfmt-compatible form")
	}
}
