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
        # ==================== NEW: PRODUCTION EXECUTABLE WRAPPER DERIVATION ====================
        # Compiles your application source tracks into a single optimized native binary wrapper!
        packages.default = pkgs.writers.writePython3Bin "mango-calendar" {
          # Hard-wires PyQt6 inside the package sandbox context so it runs flawlessly out-of-the-box
          libraries = [ pkgs.python3Packages.pyqt6 ];
        } ''
          # Injects your theme module and core application code strings inline cleanly
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

