""" Unit tests for queue.bzl """

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("@user_space_package_manager//def:queue.bzl", "iterate")

def _queue_test(ctx):
    env = unittest.begin(ctx)

    data_ctx = struct(
        cnt = [0],
    )
    iterate([0], data_ctx, _normal_callback)
    asserts.equals(env, 10, data_ctx.cnt[0])

    return unittest.end(env)

#def _queue_no_eternal_cycle_test(ctx):
#    env = unittest.begin(ctx)
#
#    # this ineeded fails
#    iterate([0], {}, _bad_callback)
#
#    return unittest.end(env)

def _normal_callback(data_ctx, item_):
    if item_ < 10:
        data_ctx.cnt[0] = data_ctx.cnt[0] + 1
        return [item_ + 1]
    return []

#def _bad_callback(data_ctx, item_):
#    return [0]

queue_test = unittest.make(_queue_test)
#queue_no_eternal_cycle_test = unittest.make(_queue_no_eternal_cycle_test)

def queue_test_suite():
    unittest.suite(
        "queue_test_suite",
        queue_test,
        #        queue_no_eternal_cycle_test,
    )
