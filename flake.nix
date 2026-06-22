{
  description = "Copy files and terminal output for debugging";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {self, nixpkgs, nixpkgs-unstable, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
        haskellEnv = pkgs.haskellPackages.ghcWithPackages (p: [
          p.streamly-core
          p.streamly-process
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs-unstable.bazel_9
          ];
          shellHook = ''
            exec fish
          '';
        };
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "debug-files";
            version = "0.1.0";
            src = ./.;
            buildInputs = [ haskellEnv ];
            buildPhase = ''
              ghc -O2 -o debug-files Main.hs
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp debug-files $out/bin/
            '';
          };
          ghc-env = haskellEnv;
        };
      }
    );
}
