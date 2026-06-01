package repo

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"regexp"
	"strings"
)

// Justfile is the parsed view of the repo's justfile. It is built from the
// authoritative `just --dump --dump-format json` AST rather than a line scan,
// so recipe ordering, body presence, and recipe names are exact.
type Justfile struct {
	Present     bool
	First       string // name of the first recipe (default target)
	Recipes     map[string]Recipe
	ToolMissing bool  // the `just` binary is not on PATH
	ParseErr    error // justfile exists but `just` could not parse it
}

// Recipe is the subset of a just recipe conformist's rules need.
type Recipe struct {
	Name    string
	HasBody bool // the recipe has a body (is not a pure aggregate)
}

// Justfile parses the justfile once and caches the result.
func (r *Repo) Justfile() *Justfile {
	if r.justfile != nil {
		return r.justfile
	}

	jf := &Justfile{Recipes: map[string]Recipe{}}
	r.justfile = jf

	if !r.IsFile("justfile") {
		return jf
	}

	jf.Present = true

	if _, err := exec.LookPath("just"); err != nil {
		jf.ToolMissing = true
		r.fillFirstRecipeFromSource(jf)

		return jf
	}

	// --unstable is harmless on modern just (JSON dump is stable) and required
	// on older versions that gate --dump-format json behind it.
	out, err := exec.Command("just", "--justfile", r.Path("justfile"),
		"--unstable", "--dump", "--dump-format", "json").Output()
	if err != nil {
		jf.ParseErr = fmt.Errorf("`just --dump` failed (justfile may be invalid): %w", justStderr(err))

		return jf
	}

	var raw struct {
		First   string `json:"first"`
		Recipes map[string]struct {
			Body json.RawMessage `json:"body"`
		} `json:"recipes"`
	}

	if err := json.Unmarshal(out, &raw); err != nil {
		jf.ParseErr = fmt.Errorf("parsing `just --dump` json: %w", err)

		return jf
	}

	jf.First = raw.First

	for name, rr := range raw.Recipes {
		jf.Recipes[name] = Recipe{Name: name, HasBody: nonEmptyJSONArray(rr.Body)}
	}

	if jf.First == "" {
		r.fillFirstRecipeFromSource(jf)
	}

	return jf
}

func (r *Repo) fillFirstRecipeFromSource(jf *Justfile) {
	if data, err := r.ReadFile("justfile"); err == nil {
		jf.First = firstRecipeName(data)
	}
}

// nonEmptyJSONArray reports whether raw is a JSON array with at least one
// element. just encodes a recipe body as an array of lines; an aggregate
// recipe has an empty (or null) body.
func nonEmptyJSONArray(raw json.RawMessage) bool {
	trimmed := bytes.TrimSpace(raw)
	if len(trimmed) == 0 || string(trimmed) == "null" {
		return false
	}

	var arr []json.RawMessage
	if err := json.Unmarshal(trimmed, &arr); err != nil {
		return false
	}

	return len(arr) > 0
}

// justStderr unwraps an exec error to its captured stderr when available.
func justStderr(err error) error {
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && len(exitErr.Stderr) > 0 {
		return errors.New(strings.TrimSpace(string(exitErr.Stderr)))
	}

	return err
}

var (
	jfAssignmentRE = regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*\s*:?=`)
	jfRecipeRE     = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_-]*)`)
)

// firstRecipeName is a source-level fallback for the first recipe name, used
// only when `just` is unavailable or omits the "first" key. It skips comments,
// blank/indented lines, settings, exports, attributes, and assignments — the
// same exclusions the bash predecessor used.
func firstRecipeName(data []byte) string {
	sc := bufio.NewScanner(bytes.NewReader(data))
	for sc.Scan() {
		line := sc.Text()

		switch {
		case line == "",
			strings.HasPrefix(line, "#"),
			strings.HasPrefix(line, " "),
			strings.HasPrefix(line, "\t"):
			continue
		case line == "set", strings.HasPrefix(line, "set "), strings.HasPrefix(line, "export "):
			continue
		case strings.HasPrefix(line, "["):
			continue
		case jfAssignmentRE.MatchString(line):
			continue
		}

		if m := jfRecipeRE.FindStringSubmatch(line); m != nil {
			return m[1]
		}
	}

	return ""
}
