{
  description = "A reproducible Lua calendar widget";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        # --- 1. Package compilation derivation output ---
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "mango-calendar";
          version = "1.0.0";
          src = ./.; # Automatically packages your main.lua and conf.lua files

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            # Create isolated target destination storage trees inside the Nix store
            mkdir -p $out/share/mango-calendar $out/bin
            
            # Copy all files cleanly into the store directory path
            cp -r ./* $out/share/mango-calendar/

            # Generates a wrapper script binary that hooks love directly to the assets!
            makeWrapper ${pkgs.love}/bin/love $out/bin/mango-calendar \
              --add-flags "$out/share/mango-calendar"
          '';
        };

        # --- 2. Your existing local development environment ---
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            lua        
            love       
            lua-language-server 
          ];

          shellHook = ''
            echo "  Lua Environment Loaded!  "
            lua -v
          '';
        };
      });
}

