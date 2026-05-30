{
  description = "andsocanyou — conformist: eng-conformance linter and bootstrapper";

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

        # conformist is a pure bash + coreutils tool. Wrap it so the runtime
        # tools it prefers (ripgrep) are on PATH, and ship its lib/ alongside.
        conformist = pkgs.stdenv.mkDerivation {
          pname = "conformist";
          version = builtins.readFile ./VERSION;
          src = ./.;

          nativeBuildInputs = [pkgs.makeWrapper];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/lib
            cp -r lib/conformist $out/lib/conformist
            install -Dm755 bin/conformist $out/bin/conformist
            install -Dm644 VERSION $out/VERSION
            wrapProgram $out/bin/conformist \
              --set CONFORMIST_LIB $out/lib/conformist \
              --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ripgrep pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.findutils]}
            runHook postInstall
          '';

          meta = {
            description = "Whole-repo cross-format linter and bootstrapper for eng-*(7) conventions";
            mainProgram = "conformist";
          };
        };
      in {
        formatter = treefmtEval.config.build.wrapper;

        packages = {
          inherit conformist;
          default = conformist;

          # the conformist manpage, built from scdoc (never committed rendered)
          manpages = pkgs.stdenv.mkDerivation {
            pname = "andsocanyou-manpages";
            version = builtins.readFile ./VERSION;
            src = ./doc;
            nativeBuildInputs = [pkgs.scdoc];
            buildPhase = ''
              for f in *.scd; do
                scdoc < "$f" > "''${f%.scd}"
              done
            '';
            installPhase = ''
              mkdir -p $out/share/man/man7
              install -Dm644 *.7 -t $out/share/man/man7
            '';
          };
        };

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
