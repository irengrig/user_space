load(":semver.bzl", "compare_semver", "filter_semvers_by_range", "parse_range", "sort_semvers")
load(":queue.bzl", "iterate")

# name: {semver1: { name1: "range", name2: ... }, semver2: ...}
def _possible_ordered_semvers(modules):
    possible_versions = {}
    for name in modules:
        module = modules[name]
        possible_versions[name] = sort_semvers(module.keys())
    return possible_versions

def matrix(modules):
    mod_2_ordered_semvers = _possible_ordered_semvers(modules)
    matrix = _all_mods(mod_2_ordered_semvers.keys())

    for mod1 in mod_2_ordered_semvers:
        mod1_semvers = mod_2_ordered_semvers[mod1]
        for semver1 in mod1_semvers:
            column = _all_mods(mod_2_ordered_semvers.keys())
            matrix[mod1][semver1] = column
            for mod2 in mod_2_ordered_semvers:
                mod2_semvers = mod_2_ordered_semvers[mod2]
                if mod1 == mod2:
                    continue

                mod1_at_semver1 = modules[mod1][semver1]
                if mod1_at_semver1 == None:
                    fail(mod1 + "@" + str(semver1))
                mod2_range = mod1_at_semver1.get(mod2) or "*"
                filtered_ = filter_semvers_by_range(mod2_semvers, parse_range(mod2_range) if type(mod2_range) == "string" else mod2_range)

                for semver2 in mod2_semvers:
                    column[mod2][semver2] = False
                for semver2 in filtered_:
                    column[mod2][semver2] = True
    return matrix

def _all_mods(keys):
    result = {}
    for key in keys:
        result[key] = {}
    return result

def traverse_transitive(modules):
    matrix_ = matrix(modules)
    data_ctx = struct(
        matrix = matrix_,
        modules = sorted(matrix_.keys()),
        successful = [],
    )

    iterate([_traverse_item({}, {}, True)], data_ctx, traverse_transitive_callback)

    return data_ctx.successful

def traverse_transitive_callback(data_ctx, traverse_item_):
    selected_map = traverse_item_.selected_map
    constraints_map = traverse_item_.constraints_map
    ignore_constraints = traverse_item_.ignore_constraints

    idx_next = len(selected_map)

    if idx_next == len(data_ctx.modules):
        data_ctx.successful.append(selected_map)
        return []

    next_module = data_ctx.modules[idx_next]

    possible_next_versions = data_ctx.matrix[next_module].keys() if ignore_constraints else constraints_map.get(next_module)
    if not possible_next_versions:
        return []

    items_to_queue = []
    for possible_version in possible_next_versions:
        selected_by_next_module = data_ctx.matrix[next_module][possible_version]
        new_constraints = {}
        version_selected = True

        # check selected constraints
        for sel_mod in selected_map.keys():
            sel_mod_ver = selected_map[sel_mod]
            if not selected_by_next_module[sel_mod][sel_mod_ver]:
                version_selected = False
                break
        if not version_selected:
            continue

        for idx_module in range(idx_next + 1, len(data_ctx.modules)):
            module = data_ctx.modules[idx_module]
            possible_module_versions = []
            if not ignore_constraints:
                possible_module_versions = constraints_map.get(module)
            else:
                for key in data_ctx.matrix[module].keys():
                    if data_ctx.matrix[module][key][next_module].get(possible_version):
                        possible_module_versions.append(key)
            if not possible_module_versions:
                version_selected = False
                break
            newly_selected = intersect_lists(possible_module_versions, selected_by_next_module[module])
            if not newly_selected:
                version_selected = False
                break
            new_constraints[module] = newly_selected
        if version_selected:
            new_selected_map = _copy(selected_map)
            new_selected_map[next_module] = possible_version
            items_to_queue.append(_traverse_item(new_selected_map, new_constraints))

    return items_to_queue

def intersect_lists(l1, l2):
    res = []
    for i1 in l1:
        if i1 in l2:
            res.append(i1)
    return res

# module -> semver list
def intersect_constraints(map1, map2):
    result = {}
    for k1 in map1:
        semvers1 = map1[k1]
        intersection = []
        for semver2 in map2[k1]:
            for semver1 in semvers1:
                if compare_semver(semver1, semver2) == 0:
                    intersection.append(semver1)
        if not intersection:
            return {}
        result[k1] = intersection
    return result

def _traverse_item(selected_map, constraints_map, ignore_constraints = False):
    return struct(
        selected_map = selected_map,
        constraints_map = constraints_map,
        ignore_constraints = ignore_constraints,
    )

def _copy(map_):
    result = {}
    for k in map_:
        result[k] = map_[k]
    return result
