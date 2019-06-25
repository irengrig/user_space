""" Unit tests for queue.bzl """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@user_space_package_manager//def:solver.bzl", "matrix", "traverse_transitive")
load("@user_space_package_manager//def:semver.bzl", "semver")

def _matrix_test(ctx):
    env = unittest.begin(ctx)

    modules = _create_longer_modules()
    matrix_ = matrix(modules)

    # todo assertions
    print("MATRIX: " + str(matrix_))

    return unittest.end(env)

def _traverse_transitive_test(ctx):
    env = unittest.begin(ctx)

    modules = _create_modules()
    successful = traverse_transitive(modules)

    asserts.equals(env, 2, len(successful))

    print("successful: " + str(successful))
    expected = {}
    expected[semver(2)] = False
    expected[semver(5)] = False
    for item in successful:
        asserts.equals(env, semver(1, 2, 4), item["mod1"])
        expected[item["dep1"]] = True
    for exp in expected:
        asserts.equals(env, True, expected[exp])

    return unittest.end(env)

def _create_modules():
    return {
        "mod1": {
            semver(1, 2, 3): {
                "dep1": "1",
            },
            semver(1, 2, 4): {
                "dep1": "*",
            },
        },
        "dep1": {
            semver(2): {},
            semver(5): {},
        },
    }

def _traverse_longer_transitive_test(ctx):
    env = unittest.begin(ctx)

    modules = _create_longer_modules()
    successful = traverse_transitive(modules)

    asserts.equals(env, 3, len(successful))

    print("successful: " + str(successful))
    for item in successful:
        asserts.equals(env, semver(1, 2, 4), item["mod1"])
        asserts.equals(env, semver(1, 0, 0), item["dep1"])

    return unittest.end(env)

def _traverse_example_transitive_test(ctx):
    env = unittest.begin(ctx)

    modules = {"framework": {
            struct(major = 1, minor = 2, patch = 3):
                {"utility": struct(end = struct(major = 5, minor = 0, patch = 0), start = struct(major = 5, minor = 0, patch = 0))}},
              "utility": {
              struct(major = 5, minor = 1, patch = 0):
                    {"framework": struct(end = struct(major = 1, minor = 2, patch = 3), start = struct(major = 1, minor = 2, patch = 0))},
              struct(major = 5, minor = 0, patch = 0):
                {"framework": struct(end = struct(major = 0, minor = 0, patch = 1), start = struct(major = 0, minor = 0, patch = 1))}}
            }
    successful = traverse_transitive(modules)

    asserts.equals(env, 1, len(successful))

    print("successful: " + str(successful))

    return unittest.end(env)


def _create_longer_modules():
    return {
        "mod1": {
            semver(1, 2, 3): {
                "dep1": "1",
                "dep2": "2-5",
            },
            semver(1, 2, 4): {
                "dep1": "*",
                "dep2": "1-1.5",
                "dep3": "1.5.3",
            },
        },
        "dep1": {
            semver(1): {},
            semver(2): {},
            semver(5): {},
        },
        "dep2": {
            semver(1): {},
            semver(1, 2): {},
            semver(1, 5): {},
        },
        "dep3": {
            semver(1, 5, 3): {"dep1": "1"},
            semver(2): {},
        },
    }

matrix_test = unittest.make(_matrix_test)
traverse_transitive_test = unittest.make(_traverse_transitive_test)
traverse_longer_transitive_test = unittest.make(_traverse_longer_transitive_test)
traverse_example_transitive_test = unittest.make(_traverse_example_transitive_test)

def solver_test_suite():
    unittest.suite(
        "solver_test_suite",
        matrix_test,
        traverse_transitive_test,
        traverse_longer_transitive_test,
        traverse_example_transitive_test
        #        queue_no_eternal_cycle_test,
    )
