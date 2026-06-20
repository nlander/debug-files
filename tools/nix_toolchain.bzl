def _nix_ghc_repo_impl(ctx):
    workspace_root = ctx.path(Label("//:BUILD.bazel")).dirname
    ctx.watch(ctx.path(Label("//:flake.nix")))
    ctx.watch(ctx.path(Label("//:flake.lock")))
    res = ctx.execute(
        ["nix", "build", ".#ghc-env", "--no-link", "--print-out-paths"],
        working_directory = str(workspace_root),
    )
    if res.return_code != 0:
        fail("failed to fex GHC via nix build: %s" % res.stderr)
    ghc_store_path = res.stdout.strip()
    ctx.symlink(ghc_store_path + "/bin", "bin")
    ctx.symlink(ghc_store_path + "/lib", "lib")
    ctx.file("BUILD.bazel", """
filegroup(
      name = "compiler",
      srcs = ["bin/ghc"],
      visibility = ["//visibility:public"],
)
""")

nix_ghc_repo = repository_rule(
    implementation = _nix_ghc_repo_impl,
    local = True,
)

def _nix_toolchain_extension_impl(ctx):
    nix_ghc_repo(name = "nix_ghc")

nix_toolchain_extension = module_extension(
    implementation = _nix_toolchain_extension_impl,
)
