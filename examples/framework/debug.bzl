def _impl(ctx):
    out = ctx.actions.declare_file("out.txt")
    ctx.actions.write(out, ctx.attr.text)
    return [DefaultInfo(files = depset(direct = [out]))]

debug = rule(
    implementation = _impl,
    attrs = {
        "text": attr.string(),
    },
)
