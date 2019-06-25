def filter_semvers_by_range(possible_versions, range_):
    filtered = []
    for version in possible_versions:
        if (in_range(version, range_)):
            filtered.append(version)
    return filtered

def parse_range(text):
    if text == "*":
        return range(semver(), semver(100000))

    parts = text.split("-")
    if len(parts) < 2:
        exact = parse_version(text)
        return range(exact, exact)
    else:
        return range(parse_version(parts[0]), parse_version(parts[1]))

def range(s, e):
    return struct(start = s, end = e)

def semver(ma = 0, mi = 0, pa = 0):
    return struct(major = ma, minor = mi, patch = pa)

def parse_version(semver_):
    parts = semver_.split(".")

    major = 0
    minor = 0
    patch = 0

    if len(parts) > 3 or len(parts) == 0:
        fail("Error parsing smever: " + semver_)
    major = int(parts[0])

    if len(parts) > 1:
        minor = int(parts[1])

    if len(parts) > 2:
        patch = int(parts[2])

    return semver(major, minor, patch)

def compare_semver(version1, version2):
    madiff = version1.major - version2.major
    if madiff != 0:
        return madiff
    midiff = version1.minor - version2.minor
    if midiff != 0:
        return midiff
    return version1.patch - version2.patch

def in_range(version, range_):
    return compare_semver(range_.start, version) <= 0 and compare_semver(range_.end, version) >= 0

def sort_semvers(semvers):
    map = {}
    for semver in semvers:
        str_ = ".".join([num_to_xxxxx_str(v) for v in [semver.major, semver.minor, semver.patch]])
        map[str_] = semver
    sorted_ = sorted(map.keys())
    return [map[v] for v in sorted_]

def str_semver(semver_):
    return ".".join([str(v) for v in [semver_.major, semver_.minor, semver_.patch]])

def num_to_xxxxx_str(num, len_ = 5):
    result = str(num)
    for i in (1, len_):
        if len(result) == len_:
            break
        result = "0" + result
    return result
