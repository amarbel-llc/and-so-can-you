{
  description = "andsocanyou — conformist: eng-conformance linter and bootstrapper";

  inputs = {
    # amarbel-llc/nixpkgs fork. Its overlay carries buildGoApplication, which
    # auto-injects `-X main.version` (read from version.env) and `-X main.commit`
    # (from src.rev) — no per-repo ldflags wiring. See eng-versioning(7) and
    # amarbel-llc/nixpkgs#31.
    igloo.url = "github:amarbel-llc/igloo";

    # Pinned plain nixpkgs as the source of go_1_26 (matches go.mod's toolchain),
    # mirroring treelint/moxy.
    nixpkgs-master.url = "github:NixOS/nixpkgs/d233902339c02a9c334e7e593de68855ad26c4cb";

    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "igloo";
    };

    # gomod2nix CLI for the devShell. Kept as an explicit input (rather than via
    # mkGoEnv) so `nix develop` evaluates before gomod2nix.toml exists — that
    # breaks the chicken-and-egg of generating the lock from inside the shell.
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs-master";
      inputs.flake-utils.follows = "utils";
    };
  };

  outputs =
    {
      self,
      igloo,
      nixpkgs-master,
      utils,
      treefmt-nix,
      gomod2nix,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import igloo { inherit system; };
        pkgs-master = import nixpkgs-master { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        conformist = pkgs.buildGoApplication {
          pname = "conformist";
          # `src = self` lets buildGoApplication read version.env for
          # `-X main.version` and src.rev for `-X main.commit`.
          src = self;
          pwd = ./.;
          modules = ./gomod2nix.toml;
          subPackages = [ "./cmd/conformist" ];
          go = pkgs-master.go_1_26;
          GOTOOLCHAIN = "local";
          doCheck = false;
        };

        # Man pages built by Nix, never committed (eng-manpages(7) PRINCIPLE 4):
        # section 7 is hand-written scdoc; section 1 is generated from the cobra
        # command tree via `conformist gen-man` (PRINCIPLE 3).
        manpages =
          pkgs.runCommand "conformist-manpages"
            {
              nativeBuildInputs = [
                pkgs.scdoc
                conformist
              ];
            }
            ''
              mkdir -p $out/share/man/man1 $out/share/man/man7
              for f in ${self}/doc/*.scd; do
                scdoc < "$f" > "$out/share/man/man7/$(basename "''${f%.scd}")"
              done
              conformist gen-man "$out/share/man/man1"
            '';
      in
      {
        packages = {
          default = conformist;
          inherit conformist manpages;
        };

        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check self;

          # Self-consumption: conformist must lint its own tree clean. `just` is
          # needed because the justfile rules parse it via `just --dump`.
          conformance =
            pkgs.runCommand "conformist-self-check"
              {
                nativeBuildInputs = [
                  conformist
                  pkgs.just
                ];
              }
              ''
                cp -r ${self} repo && chmod -R u+w repo && cd repo
                conformist check . && touch $out
              '';
        };

        devShells.default = pkgs-master.mkShell {
          # Deliberately NOT including the `conformist` package here: it would
          # force buildGoApplication (which reads ./gomod2nix.toml) to evaluate,
          # and the devShell must come up before gomod2nix.toml exists so it can
          # be used to generate it. bats falls back to ./build/conformist.
          packages = [
            pkgs-master.go_1_26
            pkgs-master.gofumpt
            pkgs-master.golangci-lint
            pkgs-master.gopls
            gomod2nix.packages.${system}.default
            pkgs.just
            pkgs.scdoc
            pkgs.bats
          ];
        };
      }
    );
}
