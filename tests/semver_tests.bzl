""" Unit tests for semver """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "@user_space_package_manager//def:semver.bzl",
    "filter_semvers_by_range",
    "parse_range",
    "parse_version",
    "range",
    "semver",
    "sort_semvers",
)

def _parse_test(ctx):
    env = unittest.begin(ctx)
    data = {
        "1.2.3": semver(1, 2, 3),
        "0": semver(0, 0, 0),
        "0.1": semver(0, 1, 0),
    }
    for k in data:
        asserts.equals(env, data[k], parse_version(k))

    return unittest.end(env)

def _parse_range_test(ctx):
    env = unittest.begin(ctx)
    data = {
        "1.2.3": range(semver(1, 2, 3), semver(1, 2, 3)),
        "*": range(semver(0, 0, 0), semver(100000, 0, 0)),
        "0.1-2": range(semver(0, 1, 0), semver(2)),
    }
    for k in data:
        asserts.equals(env, data[k], parse_range(k))

    return unittest.end(env)

def _sort_semvers_test(ctx):
    env = unittest.begin(ctx)
    semvers = [semver(1, 2, 3), semver(0, 1), semver(5, 2, 3), semver(2, 2, 3)]
    expected = [semver(0, 1), semver(1, 2, 3), semver(2, 2, 3), semver(5, 2, 3)]

    asserts.equals(env, expected, sort_semvers(semvers))

    return unittest.end(env)

def _filter_by_range_test(ctx):
    env = unittest.begin(ctx)
    versions = ["0.1", "1.2.3", "4.117.4", "5.5.15", "5.17", "122.3.5"]
    semver_versions = [parse_version(v) for v in versions]
    data = [
        [range(semver(1, 2, 3), semver(5, 6, 7)), ["1.2.3", "4.117.4", "5.5.15"]],
        [parse_range("*"), versions],
    ]
    for p in data:
        expected = [parse_version(v) for v in p[1]]
        asserts.equals(env, expected, filter_semvers_by_range(semver_versions, p[0]))

    return unittest.end(env)

parse_test = unittest.make(_parse_test)
parse_range_test = unittest.make(_parse_range_test)
filter_by_range_test = unittest.make(_filter_by_range_test)
sort_semvers_test = unittest.make(_sort_semvers_test)

def semver_test_suite():
    unittest.suite(
        "semver_test_suite",
        parse_test,
        parse_range_test,
        filter_by_range_test,
        sort_semvers_test,
    )
