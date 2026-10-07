{
  description = "Copy files and terminal output for debugging";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bazel-rules.url = "github:nlander/elodie_bazel_rules";
  };
  outputs = {self, nixpkgs, flake-utils, bazel-rules}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellEnv = bazel-rules.packages.${system}.ghc-env;
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
