{
  description = "A modern Python and PyQt6 desktop calendar widget environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Formulate Python 3 environment bundled with true PyQt6 bindings
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pyqt6
        ]);
      in {
        # 1. Local development environment shell matrix
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.python3Packages.python-lsp-server # Provides autocomplete for your IDE
          ];

          shellHook = ''
            echo " 🐍 Python & PyQt6 Development Matrix Loaded! 🐍 "
            python --version
          '';
        };
      });
}

