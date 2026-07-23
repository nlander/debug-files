{
  description = "Copy files and terminal output for debugging";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    streamly-env.url = "github:nlander/streamly-env";
  };
  outputs = {self, nixpkgs, streamly-env, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellEnv = streamly-env.packages.${system}.default;
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
