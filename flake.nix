{
  description = "Shaun's Library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
      in {
        lib = import ./lib { inherit pkgs lib; };
      };
    );
}
