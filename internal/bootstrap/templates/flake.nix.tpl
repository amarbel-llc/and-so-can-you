{
  description = "@@NAME@@ — eng-conformant repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in {
        formatter = treefmtEval.config.build.wrapper;

        # Read-only formatting gate consumed by `just lint-fmt`.
        checks.formatting = treefmtEval.config.build.check self;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
            scdoc
            shfmt
            shellcheck
            ripgrep
            bats
            alejandra
          ];
        };
      }
    );
}
