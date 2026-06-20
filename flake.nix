{
  description = "Building with bazel from first principles";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellEnv = pkgs.haskellPackages.ghcWithPackages (p: [
          p.streamly-core
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.bazel_9
          ];
          shellHook = ''
            exec fish
          '';
        };
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "bazel-first-principles";
            version = "0.1.0";
            src = ./.;
            buildInputs = [ haskellEnv ];
            buildPhase = ''
              ghc -O2 -o bazel-first-principles Main.hs
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp bazel-first-principles $out/bin/
            '';
          };
          ghc-env = haskellEnv;
        };
      }
    );
}
