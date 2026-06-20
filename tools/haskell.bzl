def _haskell_binary_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    src_depset = depset(ctx.files.srcs)
    args = ctx.actions.args()
    args.add("-O2")
    args.add("-o", executable.path)
    args.add_all(src_depset)
    ctx.actions.run(
        inputs = src_depset,
        outputs = [executable],
        executable = ctx.executable._ghc,
        arguments = [args],
        mnemonic = "GhcCompile",
        progress_message = "Compiling Haskell binary: %s" % ctx.label.name,
    )
    return [DefaultInfo(executable = executable, files = depset([executable]))]

haskell_binary = rule(
    implementation = _haskell_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [".hs"]),
        "_ghc": attr.label(
            default = Label("@nix_ghc//:compiler"),
            executable = True,
            cfg = "exec",
        ),
    },
)
