{
  description = "A portable, zero-dependency Python and PyQt6 calendar widget for MangoWM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # ==================== PRODUCTION EXECUTABLE WRAPPER DERIVATION ====================
        packages.default = pkgs.writers.writePython3Bin "mango-calendar" {
          libraries = [ pkgs.python3Packages.pyqt6 ];
          # FIXED LINTER CHECKER: Instructs Nix to bypass stylistic layout warnings completely!
          flake8 = false;
        } ''
          # Nix combines your theme setup and main execution logic into one file block!
          ${builtins.readFile ./theme.py}
          ${builtins.readFile ./main.py}
        '';

        # Local development environment environment shell matrix
        devShells.default = pkgs.mkShell {
          buildInputs = [
            (pkgs.python3.withPackages (ps: [ ps.pyqt6 ]))
            pkgs.python3Packages.python-lsp-server
          ];
          shellHook = ''
            echo " 🐍 Python & PyQt6 Development Matrix Loaded! 🐍 "
          '';
        };
      });
}

