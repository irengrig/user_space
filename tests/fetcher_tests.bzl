""" Unit tests for queue.bzl """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@user_space_package_manager//def:fetcher.bzl", "get_transitive_modules")

def _fetcher_test(ctx):
    env = unittest.begin(ctx)

    mock_rctx = struct(
        data = {
            "framework": """
{
    "name": "framework",
    "head": "1.2.3",
    "versions": {
        "1.2.3": {
            "url": "framework-url-1.2.3",
            "sha256": "",
            "bazel": "0.26-",
            "deps": {
                "utility": {
                    "version": "5.0",
                    "manifest_url": "utility-url"
                }
            }
        },
        "1.2.0": {
            "url": "framework-url-1.2.0",
            "sha256": "",
            "bazel": "0.24-0.25",
            "deps": {
                "utility": {
                    "version": "4.1",
                    "manifest_url": "utility-url"
                }
            }
        }
    }
}
""",
            "utility": """
{
    "name": "utility",
    "head": "5.0",
    "versions": {
        "5.0": {
            "url": "utility-url-5.0",
            "sha256": "",
            "bazel": "0.26-",
            "deps": {}
        },
        "4.1": {
            "url": "utility-url-4.1",
            "sha256": "",
            "bazel": "0.26-",
            "deps": {}
        }
    }
}
""",
        },
        download_trace = {},
    )

    modules_info = get_transitive_modules(mock_rctx, _test_reader, _test_downloader, "framework", "framework")
    modules = modules_info.modules

    asserts.equals(env, 1, len(mock_rctx.download_trace))
    asserts.equals(env, True, mock_rctx.download_trace["utility-url"])

    # todo more assertions
    asserts.equals(env, 2, len(modules["framework"]))
    asserts.equals(env, 2, len(modules["utility"]))

    # Have it for debug
    print("MODULES: " + str(modules))

    return unittest.end(env)

def _test_reader(mock_rctx, path):
    if (path.startswith("utility")):
        return mock_rctx.data["utility"]
    if (path.startswith("framework")):
        return mock_rctx.data["framework"]
    fail()

def _test_downloader(mock_rctx, url, path_str):
    mock_rctx.download_trace[url] = True
    return path_str

fetcher_test = unittest.make(_fetcher_test)

def fetcher_test_suite():
    unittest.suite(
        "fetcher_test_suite",
        fetcher_test,
    )
