def iterate(items, data_ctx, callback):
    queue = []
    for item in items:
        queue.append(item)

    for i in range(1, 1000000):
        if len(queue) == 0:
            return
        new_items = callback(data_ctx, queue.pop(0))
        for new_item in new_items:
            queue.append(new_item)
    fail("Too many iterations, queue state: " + str(queue))
