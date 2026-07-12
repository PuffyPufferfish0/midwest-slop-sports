{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (
          import (inputs.nixpkgs) {
            inherit system;
            config = {
              allowUnfree = true;
            };
          }
        );
		
		#this is AI, just for me to run with nixGL
        nixglPkgs = inputs.nixgl.packages.${system} or {};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            godot
          ] ++ lib.optionals stdenv.isLinux [
		  
            nixglPkgs.nixGLDefault
          ];

          shellHook = ''
            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              alias godot="nixGL godot"
            ''}
          '';
        };
      }
    );
}
