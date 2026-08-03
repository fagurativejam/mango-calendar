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
        
        # Enforce a localized python environment containing PyQt6 runtime boundaries
        pythonEnv = pkgs.python3.withPackages (ps: [ ps.pyqt6 ]);
      in {
        # ==================== LINT-FREE SHELL SCRIPT BINARY ====================
        packages.default = pkgs.writeShellScriptBin "mango-calendar" ''
          exec ${pythonEnv}/bin/python3 << 'EOF'
          ${builtins.readFile ./theme.py}
          ${builtins.readFile ./main.py}
          EOF
        '';

        # Local development environment environment shell matrix
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.python3Packages.python-lsp-server
          ];
          shellHook = ''
            echo " 🐍 Python & PyQt6 Development Matrix Loaded! 🐍 "
          '';
        };
      });
}

