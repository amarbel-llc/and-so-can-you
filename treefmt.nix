# `nix fmt` configuration (treefmt-nix). Drives `just codemod-fmt` (write mode)
# and `just lint-fmt` / `nix build .#checks.<sys>.formatting` (read-only gate).
{ ... }:
{
  projectRootFile = "flake.nix";

  programs.gofmt.enable = true;
  programs.nixfmt.enable = true;
  programs.taplo.enable = true;

  settings.global.excludes = [
    # Generated / locked — not hand-formatted.
    "gomod2nix.toml"
    "flake.lock"
    "go.sum"
    # scdoc sources and scaffold templates are not Go/Nix/TOML.
    "*.scd"
    "internal/bootstrap/templates/**"
    # Prose.
    "*.md"
    "LICENSE"
  ];
}
