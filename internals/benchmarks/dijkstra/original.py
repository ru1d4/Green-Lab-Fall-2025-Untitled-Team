import heapq
import time


def dijkstra(graph, start, end, _cache={}):
    """Return the cost of the shortest path between vertices start and end.

    Cached version: the graph’s adjacency lists are converted to tuples once,
    just to make the structure a little leaner for repeated calls.
    """
    key = id(graph)
    if key not in _cache:
        # Convert inner lists to tuples (immutable & slightly faster to iterate)
        cached_graph = {k: tuple((v, c) for v, c in vs) for k, vs in graph.items()}
        _cache[key] = cached_graph
    else:
        cached_graph = _cache[key]

    heap = [(0, start)]
    visited = set()

    while heap:
        cost, u = heapq.heappop(heap)
        if u in visited:
            continue
        visited.add(u)
        if u == end:
            return cost
        for v, c in cached_graph[u]:
            if v not in visited:
                heapq.heappush(heap, (cost + c, v))
    return -1


# --- Graphs ---
G = {
    "A": [["B", 2], ["C", 5]],
    "B": [["A", 2], ["D", 3], ["E", 1], ["F", 1]],
    "C": [["A", 5], ["F", 3]],
    "D": [["B", 3]],
    "E": [["B", 4], ["F", 3]],
    "F": [["C", 3], ["E", 3]],
}

G2 = {
    "B": [["C", 1]],
    "C": [["D", 1]],
    "D": [["F", 1]],
    "E": [["B", 1], ["F", 3]],
    "F": [],
}

G3 = {
    "B": [["C", 1]],
    "C": [["D", 1]],
    "D": [["F", 1]],
    "E": [["B", 1], ["G", 2]],
    "F": [],
    "G": [["F", 1]],
}


# --- Benchmark (exactly as you had it) ---
for _ in range(200000):
    dijkstra(G, "E", "C")
    dijkstra(G2, "E", "F")
    dijkstra(G3, "E", "F")

print(time.time())

for _ in range(200000):
    dijkstra(G, "E", "C")
    dijkstra(G2, "E", "F")
    dijkstra(G3, "E", "F")
