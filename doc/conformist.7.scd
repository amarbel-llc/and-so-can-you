conformist(7)

# NAME

conformist - whole-repo linter and bootstrapper for the eng-\*(7) conventions

# SYNOPSIS

*conformist* [_dir_]++
*conformist check* [_dir_]++
*conformist bootstrap* [_options_] [_dir_]++
*conformist rules*++
*conformist version*

# DESCRIPTION

*conformist* checks whether a repository follows the amarbel-llc engineering
conventions documented in the eng-\*(7) family of manpages, and scaffolds new
repositories that already do.

It treats a repo's heterogeneous "meta" files — _justfile_, _version.env_,
_flake.nix_, _.envrc_, _doc/\*.scd_, and _\*.bats_ — as first-class lintable
artifacts under a single ruleset. Each rule encodes one mechanically-checkable
clause from an eng-\*(7) page and carries that citation with it; *conformist
rules* prints the full rule-to-clause map. The eng-\*(7) manpages remain the
source of truth — this tool checks the subset that can be checked mechanically.

Parsing goes through real parsers rather than text scraping: the justfile is
read from the *just*(1) JSON AST (`just --dump`), version.env and scdoc sources
through dedicated parsers. Formatting is delegated to *treefmt*(1); conformist
owns the structural and semantic rules formatters do not cover.

With no arguments, *conformist* checks the current directory.

# COMMANDS

*check* [_dir_]
	Lint _dir_ (default: the current directory). Each violation is printed
	grouped with its spec citation, followed by a summary. Exits non-zero if
	any *error*-severity violation is found; *warn*-severity findings are
	reported but do not fail the run.

*bootstrap* [_options_] [_dir_]
	Scaffold an eng-conformant repository into _dir_ (default: the current
	directory), then run the check rules against the result so the scaffold
	proves its own conformance.

*rules*
	List every rule id and the eng-\*(7) clause it enforces.

*version*
	Print conformist's version as _conformist <version>+<commit>_.

# BOOTSTRAP OPTIONS

*--name* _NAME_
	Canonical repo name. Default: the target directory's basename. Must be
	lowercase letters, digits, and hyphens.

*--force*
	Scaffold into a non-empty directory.

# RULES

Rules are grouped by concern. A shape rule fires only when its subject exists;
layout rules fire unconditionally.

*layout*
	_eng/layout-justfile_ (error), _eng/layout-agents_ (error),
	_eng/layout-readme_ (warn), _eng/layout-version_ (error), and
	_eng/layout-doc-dir_ (warn): the justfile, AGENTS.md, README.md,
	version.env, and doc/ at the repo root.

*versioning* (*eng-versioning*(7))
	_eng-versioning/deprecated-file_ (warn): no VERSION/version.txt.
	_eng-versioning/source-of-truth_ (error): version.env declares
	_export <REPO>_VERSION=_. _eng-versioning/semver_ (error): the value is a
	bare MAJOR.MINOR.PATCH.

*justfile* (*eng-design_patterns-justfile*(7))
	_eng-justfile/parse_ (error): the justfile parses. _eng-justfile/default-recipe_
	(error): the first recipe is _default_. _eng-justfile/default-aggregate_
	(warn): _default_ has no body. _eng-justfile/generic-name_ (warn): no
	generic recipe names (all/dev/check/compile).

*manpages* (*eng-manpages*(7))
	_eng-manpages/no-rendered_ (warn): no committed rendered roff under doc/.
	_eng-manpages/source-naming_ (error): sources are _name.SECTION.scd_.
	_eng-manpages/header-name_ (error): a _name(N)_ header and a NAME section
	of the form _topic - description_. _eng-manpages/description_ (error): a
	DESCRIPTION section.

*flake*
	_flake/lock_ (warn): flake.lock is committed alongside flake.nix.
	_flake/devshell_ (warn): the flake exposes _devShells.default_
	(*eng-design_patterns-justfile*(7) VALIDATE-DEVSHELL). _flake/formatter_
	(warn): the formatter is wired to treefmt (*eng-design_patterns-justfile*(7)
	LINT-FMT).

*direnv* (*eng-direnv*(7))
	_eng-direnv/use-flake_ (warn): _.envrc_ runs _use flake_.
	_eng-direnv/secrets_ (warn): no secret assignments in _.envrc_/_.env_.

*bats* (amarbel-llc/eng#123)
	_conformist/bats-shfmt-compat_ (error): bats tests use the
	_function NAME { # @test_ form rather than the bats-native _@test "..."_
	form.

# SEVERITY

*error*
	A violation of a mandatory clause. Fails the run (non-zero exit).

*warn*
	A violation of a recommended convention. Reported; does not fail.

# EXIT STATUS

*0*
	No error-severity violations.

*1*
	One or more error-severity violations.

*2*
	Usage error, or an operational failure (for example, _just_ is not on
	PATH but the repo has a justfile).

# ENVIRONMENT

*NO_COLOR*
	Disable colored output. Color is also disabled for non-terminal output.

# SEE ALSO

*eng*(7), *eng-design_patterns-justfile*(7), *eng-direnv*(7),
*eng-manpages*(7), *eng-versioning*(7), *eng-nix*(7), *just*(1), *treefmt*(1),
*scdoc*(1)
