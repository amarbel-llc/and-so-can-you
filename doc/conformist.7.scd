conformist(7)

# NAME

conformist - whole-repo cross-format linter and bootstrapper for eng conventions

# SYNOPSIS

*conformist check* [_dir_]++
*conformist bootstrap* [_options_] [_dir_]++
*conformist rules*++
*conformist version*++
*conformist help*

# DESCRIPTION

*conformist* makes a repository conform to the amarbel-llc engineering
conventions documented in the *eng-*(7) family of manpages, and scaffolds
new repositories that already do.

It treats a repo's heterogeneous "meta" files — _justfile_, _README.md_,
_flake.nix_, _VERSION_, _identity.toml_, and _doc/*.7.scd_ — as
first-class lintable artifacts under a single ruleset. Each rule encodes
a mechanically-checkable clause from an *eng-*(7) page; *conformist rules*
prints the full rule-to-clause map.

Formatting is delegated to *treefmt*(1). conformist owns the structural
and semantic rules that formatters do not cover (e.g. "the justfile has a
_default recipe", "a manpage has a NAME section").

# COMMANDS

*check* [_dir_]
	Lint _dir_ (default: the current directory) against the eng-*(7)
	rules. Prints each violation grouped with its spec citation and a
	summary. Exits non-zero if any *error*-severity violation is found;
	*warn*-severity findings are reported but do not fail the run.

*bootstrap* [_options_] [_dir_]
	Scaffold an eng-conformant repository into _dir_ (default: the
	current directory), then run the check rules against the result so
	the scaffold proves its own conformance.

*rules*
	List every rule id and the *eng-*(7) clause it enforces.

*version*
	Print conformist's version (read from _VERSION_).

*help*
	Print usage.

# BOOTSTRAP OPTIONS

*--name* _NAME_
	Canonical repo name. Default: the target directory's basename.
	Must be lowercase letters, digits, and hyphens.

*--owner* _OWNER_
	GitHub org or user. Default: *amarbel-llc*.

*--contact* _ADDR_
	Role contact address. Default: *eng@amarbel.example*.

*--force*
	Scaffold into a non-empty directory.

# RULES

Rules are grouped by concern. A shape rule fires only when its subject
file exists; layout rules from *eng*(7) fire unconditionally.

*layout* (*eng*(7))
	_justfile_, _README.md_, _VERSION_, and _identity.toml_ exist at the
	repo root; _doc/_ exists for manpages.

*versioning* (*eng-versioning*(7))
	_VERSION_ is a single line containing a bare *MAJOR.MINOR.PATCH*
	semver with no leading *v*.

*identity* (*eng-identity*(7))
	_identity.toml_ declares *name*, *owner*, and *contact*; the contact
	is a role address.

*justfile* (*eng-design_patterns-justfile*(7))
	The first recipe is *_default* running *just --list*; public recipes
	carry a doc comment; recipe names are verb-noun and hyphenated.

*manpages* (*eng-manpages*(7))
	Sources are named _<topic>.<section>.scd_ and carry a header,
	a *NAME* section of the form _topic - description_, and a
	*DESCRIPTION* section; rendered roff is not committed.

*nix* (*eng-nix*(7))
	A repo with _flake.nix_ commits _flake.lock_, exposes
	*devShells.default*, and wires *formatter* to treefmt.

*direnv* (*eng-direnv*(7))
	A repo with a flake has an _.envrc_ that runs *use flake* and
	contains no secrets.

*bats* (amarbel-llc/eng#123)
	bats tests use the shfmt-compatible *function NAME { # @test* form
	rather than the bats-native *@test "..."* form.

# SEVERITY

*error*
	A violation of a mandatory clause. Fails the run (non-zero exit).

*warn*
	A violation of a recommended convention. Reported; does not fail.

# ENVIRONMENT

*CONFORMIST_LIB*
	Override the path to conformist's _lib/conformist_ directory.
	Normally resolved relative to the executable.

*NO_COLOR*
	Disable colored output.

# EXIT STATUS

*0*
	No error-severity violations.

*1*
	One or more error-severity violations.

*2*
	Usage error or internal error.

# FILES

_identity.toml_
	Canonical repository identity. See *eng-identity*(7).

_VERSION_
	Version source of truth. See *eng-versioning*(7).

# SEE ALSO

*eng*(7), *eng-design_patterns-justfile*(7), *eng-direnv*(7),
*eng-identity*(7), *eng-manpages*(7), *eng-nix*(7), *eng-versioning*(7),
*treefmt*(1), *just*(1), *scdoc*(1)
