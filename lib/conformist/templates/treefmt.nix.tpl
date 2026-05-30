# treefmt.nix — formatter configuration for @@NAME@@ (see eng-nix(7))
{...}: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;

    shfmt = {
      enable = true;
      indent_size = 2;
    };

    prettier = {
      enable = true;
      includes = [
        "*.md"
        "*.yaml"
        "*.yml"
        "*.json"
      ];
    };
  };

  settings.global.excludes = [
    "*.lock"
    "flake.lock"
    "result"
    "result-*"
    ".direnv"
  ];
}
