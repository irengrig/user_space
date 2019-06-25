load("@bazel_json//lib:json_parser.bzl", "json_parse")
load(":semver.bzl", "parse_range", "parse_version")
load(":queue.bzl", "iterate")

def get_transitive_modules_rctx(rctx, root_name, root):
    return get_transitive_modules(rctx, _reader, _downloader, root_name, root)

def _reader(rctx, path):
    if type(path) == "Label":
        copied_path = copy_file(rctx, path)
        return rctx.read(copied_path)
    return rctx.read(path)

def copy_file(rctx, src):
    src_path = rctx.path(src)
    copy_path = src_path.basename
    rctx.template(copy_path, src_path)
    return copy_path

def _downloader(rctx, url, path_str):
    if url.startswith("@"):
        return copy_file(rctx, Label(url))

    output = rctx.path(path_str)
    rctx.download(url = url, output = output)
    return output

def get_transitive_modules(rctx, reader, downloader, root_name, root):
    data_ctx = struct(
        rctx = rctx,
        reader = reader,
        downloader = downloader,
        # name: {version1: { name1: "range", name2: ... }, version2: ...}
        modules = {},
        full_modules_map = {},
        cnt = [0],
    )
    iterate([_item(root_name, root)], data_ctx, process_module_callback)

    return struct(modules = data_ctx.modules, full_modules_map = data_ctx.full_modules_map)

def process_module_callback(data_ctx, item_):
    rctx = data_ctx.rctx
    modules = data_ctx.modules
    full_modules_map = data_ctx.full_modules_map

    obj = json_parse(data_ctx.reader(rctx, item_.path))
    obj_name = obj["name"]
    if (obj_name != item_.name):
        fail("Expected to parse for '%s', but got '%s'" % (item_.name, obj_name))

    full_modules_map[obj_name] = obj

    new_items = []
    module_map = {}
    modules[obj_name] = module_map
    for version in obj["versions"]:
        version_metadata = obj["versions"][version]

        # assume that if a module was loaded, all the the metadata is known
        module_version_deps = {}
        module_map[parse_version(version)] = module_version_deps

        # download & queue
        for dep_name in version_metadata["deps"]:
            dep_data = version_metadata["deps"][dep_name]
            module_version_deps[dep_name] = parse_range(dep_data["version"])

            # Maybe it was already loaded.
            if not modules.get(dep_name):
                cnt = data_ctx.cnt[0]
                data_ctx.cnt[0] = cnt + 1
                output = data_ctx.downloader(rctx, dep_data["manifest_url"], dep_name + str(cnt))
                new_items.append(_item(dep_name, output))
    return new_items

def _item(name, path_):
    return struct(name = name, path = path_)
