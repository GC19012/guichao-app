// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:collection';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GchEdge – weighted directed edge
// ─────────────────────────────────────────────────────────────────────────────
class GchEdge {
  final String from;
  final String to;
  final double weight;

  const GchEdge(this.from, this.to, {this.weight = 1.0});

  @override
  String toString() => 'Edge($from->$to, w=$weight)';

  @override
  bool operator ==(Object other) =>
      other is GchEdge && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// ─────────────────────────────────────────────────────────────────────────────
// GchGraph – directed weighted graph (adjacency list)
// ─────────────────────────────────────────────────────────────────────────────
class GchGraph {
  final Map<String, List<GchEdge>> _adj = {};

  Set<String> get vertices => Set.unmodifiable(_adj.keys);

  List<GchEdge> get edges {
    final result = <GchEdge>[];
    for (final list in _adj.values) {
      result.addAll(list);
    }
    return result;
  }

  void addVertex(String v) {
    _adj.putIfAbsent(v, () => []);
  }

  void removeVertex(String v) {
    _adj.remove(v);
    for (final list in _adj.values) {
      list.removeWhere((e) => e.to == v);
    }
  }

  void addEdge(String from, String to, {double weight = 1.0}) {
    addVertex(from);
    addVertex(to);
    // avoid duplicate edge
    _adj[from]!.removeWhere((e) => e.to == to);
    _adj[from]!.add(GchEdge(from, to, weight: weight));
  }

  void removeEdge(String from, String to) {
    _adj[from]?.removeWhere((e) => e.to == to);
  }

  bool hasVertex(String v) => _adj.containsKey(v);

  bool hasEdge(String from, String to) {
    return _adj[from]?.any((e) => e.to == to) ?? false;
  }

  List<GchEdge> edgesFrom(String v) => List.unmodifiable(_adj[v] ?? <GchEdge>[]);

  List<String> neighbors(String v) =>
      (_adj[v] ?? <GchEdge>[]).map((e) => e.to).toList();

  // BFS from start vertex
  List<String> bfs(String start) {
    if (!hasVertex(start)) return [];
    final visited = <String>{};
    final queue = Queue<String>();
    final result = <String>[];
    queue.add(start);
    visited.add(start);
    while (queue.isNotEmpty) {
      final v = queue.removeFirst();
      result.add(v);
      for (final e in _adj[v] ?? <GchEdge>[]) {
        if (!visited.contains(e.to)) {
          visited.add(e.to);
          queue.add(e.to);
        }
      }
    }
    return result;
  }

  // DFS from start vertex
  List<String> dfs(String start) {
    if (!hasVertex(start)) return [];
    final visited = <String>{};
    final result = <String>[];
    _dfsHelper(start, visited, result);
    return result;
  }

  void _dfsHelper(String v, Set<String> visited, List<String> result) {
    visited.add(v);
    result.add(v);
    for (final e in _adj[v] ?? <GchEdge>[]) {
      if (!visited.contains(e.to)) {
        _dfsHelper(e.to, visited, result);
      }
    }
  }

  // Topological sort using Kahn's algorithm (returns empty list if cycle)
  List<String> topologicalSort() {
    final inDegree = <String, int>{};
    for (final v in _adj.keys) {
      inDegree.putIfAbsent(v, () => 0);
      for (final e in _adj[v]!) {
        inDegree[e.to] = (inDegree[e.to] ?? 0) + 1;
      }
    }
    final queue = Queue<String>();
    for (final entry in inDegree.entries) {
      if (entry.value == 0) queue.add(entry.key);
    }
    final result = <String>[];
    while (queue.isNotEmpty) {
      final v = queue.removeFirst();
      result.add(v);
      for (final e in _adj[v] ?? <GchEdge>[]) {
        inDegree[e.to] = (inDegree[e.to] ?? 1) - 1;
        if (inDegree[e.to] == 0) queue.add(e.to);
      }
    }
    // if result doesn't contain all vertices, cycle exists
    if (result.length != _adj.length) return [];
    return result;
  }

  // hasCycle – detect cycle using DFS coloring
  bool hasCycle() {
    final color = <String, int>{}; // 0=white, 1=gray, 2=black
    for (final v in _adj.keys) {
      color[v] = 0;
    }
    for (final v in _adj.keys) {
      if (color[v] == 0) {
        if (_dfsCycle(v, color)) return true;
      }
    }
    return false;
  }

  bool _dfsCycle(String v, Map<String, int> color) {
    color[v] = 1;
    for (final e in _adj[v] ?? <GchEdge>[]) {
      if (color[e.to] == 1) return true;
      if (color[e.to] == 0 && _dfsCycle(e.to, color)) return true;
    }
    color[v] = 2;
    return false;
  }

  // shortestPath – Dijkstra, returns (distance, path)
  ({double distance, List<String> path}) shortestPath(String start, String end) {
    if (!hasVertex(start) || !hasVertex(end)) {
      return (distance: double.infinity, path: []);
    }
    final dist = <String, double>{};
    final prev = <String, String?>{};
    final visited = <String>{};
    for (final v in _adj.keys) {
      dist[v] = double.infinity;
    }
    dist[start] = 0.0;

    // simple priority queue using sorted list
    final pq = _MinPQ();
    pq.insert(start, 0.0);

    while (!pq.isEmpty) {
      final u = pq.extractMin();
      if (visited.contains(u)) continue;
      visited.add(u);
      if (u == end) break;
      for (final e in _adj[u] ?? <GchEdge>[]) {
        final newDist = dist[u]! + e.weight;
        if (newDist < (dist[e.to] ?? double.infinity)) {
          dist[e.to] = newDist;
          prev[e.to] = u;
          pq.insert(e.to, newDist);
        }
      }
    }

    if (dist[end] == double.infinity) {
      return (distance: double.infinity, path: []);
    }

    // reconstruct path
    final path = <String>[];
    String? current = end;
    while (current != null) {
      path.insert(0, current);
      current = prev[current];
    }
    return (distance: dist[end]!, path: path);
  }

  // allShortestPaths – Dijkstra from start to all reachable vertices
  Map<String, double> allShortestPaths(String start) {
    final dist = <String, double>{};
    final visited = <String>{};
    for (final v in _adj.keys) {
      dist[v] = double.infinity;
    }
    dist[start] = 0.0;
    final pq = _MinPQ();
    pq.insert(start, 0.0);

    while (!pq.isEmpty) {
      final u = pq.extractMin();
      if (visited.contains(u)) continue;
      visited.add(u);
      for (final e in _adj[u] ?? <GchEdge>[]) {
        final newDist = dist[u]! + e.weight;
        if (newDist < (dist[e.to] ?? double.infinity)) {
          dist[e.to] = newDist;
          pq.insert(e.to, newDist);
        }
      }
    }
    return dist;
  }

  // isFullyReachable – checks if all vertices are reachable from first vertex
  bool get isFullyReachable {
    if (_adj.isEmpty) return true;
    final start = _adj.keys.first;
    final reached = bfs(start);
    return reached.length == _adj.length;
  }

  // isStronglyConnected – SCC check via two DFS passes (Kosaraju)
  bool get isStronglyConnected {
    if (_adj.isEmpty) return true;
    final start = _adj.keys.first;
    final visited = <String>{};
    _dfsHelper(start, visited, []);
    if (visited.length != _adj.length) return false;
    // build reversed graph
    final rev = GchGraph();
    for (final e in edges) {
      rev.addEdge(e.to, e.from, weight: e.weight);
    }
    final visited2 = <String>{};
    rev._dfsHelper(start, visited2, []);
    return visited2.length == _adj.length;
  }

  int get vertexCount => _adj.length;
  int get edgeCount => edges.length;

  void clear() => _adj.clear();

  @override
  String toString() =>
      'GchGraph(vertices=$vertexCount, edges=$edgeCount)';
}

// ─────────────────────────────────────────────────────────────────────────────
// _MinPQ – internal simple min-priority queue for Dijkstra
// ─────────────────────────────────────────────────────────────────────────────
class _MinPQ {
  final List<(String, double)> _data = [];

  bool get isEmpty => _data.isEmpty;

  void insert(String v, double d) {
    _data.add((v, d));
    _bubbleUp(_data.length - 1);
  }

  String extractMin() {
    final min = _data[0].$1;
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _bubbleDown(0);
    }
    return min;
  }

  void _bubbleUp(int i) {
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_data[i].$2 < _data[p].$2) {
        final tmp = _data[i];
        _data[i] = _data[p];
        _data[p] = tmp;
        i = p;
      } else break;
    }
  }

  void _bubbleDown(int i) {
    final n = _data.length;
    while (true) {
      int best = i;
      final l = 2 * i + 1, r = 2 * i + 2;
      if (l < n && _data[l].$2 < _data[best].$2) best = l;
      if (r < n && _data[r].$2 < _data[best].$2) best = r;
      if (best == i) break;
      final tmp = _data[i];
      _data[i] = _data[best];
      _data[best] = tmp;
      i = best;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchUnionFind – disjoint set union
// ─────────────────────────────────────────────────────────────────────────────
class GchUnionFind {
  final Map<String, String> _parent = {};
  final Map<String, int> _rank = {};
  int _componentCount = 0;

  int get componentCount => _componentCount;

  void addElement(String x) {
    if (!_parent.containsKey(x)) {
      _parent[x] = x;
      _rank[x] = 0;
      _componentCount++;
    }
  }

  String find(String x) {
    if (!_parent.containsKey(x)) addElement(x);
    if (_parent[x] != x) {
      _parent[x] = find(_parent[x]!);
    }
    return _parent[x]!;
  }

  bool union(String x, String y) {
    final rx = find(x), ry = find(y);
    if (rx == ry) return false;
    final rankX = _rank[rx] ?? 0;
    final rankY = _rank[ry] ?? 0;
    if (rankX > rankY) {
      _parent[ry] = rx;
    } else if (rankX < rankY) {
      _parent[rx] = ry;
    } else {
      _parent[ry] = rx;
      _rank[rx] = rankX + 1;
    }
    _componentCount--;
    return true;
  }

  bool connected(String x, String y) => find(x) == find(y);

  void reset() {
    _parent.clear();
    _rank.clear();
    _componentCount = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchUndirectedGraph – undirected weighted graph
// ─────────────────────────────────────────────────────────────────────────────
class GchUndirectedGraph {
  final GchGraph _directed = GchGraph();

  Set<String> get vertices => _directed.vertices;

  void addVertex(String v) => _directed.addVertex(v);

  void addEdge(String u, String v, {double weight = 1.0}) {
    _directed.addEdge(u, v, weight: weight);
    _directed.addEdge(v, u, weight: weight);
  }

  void removeEdge(String u, String v) {
    _directed.removeEdge(u, v);
    _directed.removeEdge(v, u);
  }

  void removeVertex(String v) => _directed.removeVertex(v);

  bool hasVertex(String v) => _directed.hasVertex(v);
  bool hasEdge(String u, String v) => _directed.hasEdge(u, v);

  List<String> neighbors(String v) => _directed.neighbors(v);

  List<String> bfs(String start) => _directed.bfs(start);
  List<String> dfs(String start) => _directed.dfs(start);

  // Kruskal's minimum spanning tree
  GchGraph minSpanningTree() {
    final uf = GchUnionFind();
    for (final v in _directed.vertices) {
      uf.addElement(v);
    }

    // collect unique edges (avoid double-counting undirected)
    final seen = <String>{};
    final allEdges = <GchEdge>[];
    for (final e in _directed.edges) {
      final key = [e.from, e.to]..sort();
      final k = '${key[0]}-${key[1]}';
      if (!seen.contains(k)) {
        seen.add(k);
        allEdges.add(e);
      }
    }
    allEdges.sort((a, b) => a.weight.compareTo(b.weight));

    final mst = GchGraph();
    for (final v in _directed.vertices) {
      mst.addVertex(v);
    }
    for (final e in allEdges) {
      if (!uf.connected(e.from, e.to)) {
        uf.union(e.from, e.to);
        mst.addEdge(e.from, e.to, weight: e.weight);
        mst.addEdge(e.to, e.from, weight: e.weight);
      }
    }
    return mst;
  }

  // connectedComponents – returns list of vertex groups
  List<List<String>> connectedComponents() {
    final visited = <String>{};
    final components = <List<String>>[];
    for (final v in _directed.vertices) {
      if (!visited.contains(v)) {
        final component = _directed.bfs(v);
        // only visit from this component
        final filtered = component.where((u) => !visited.contains(u)).toList();
        if (filtered.isNotEmpty) {
          components.add(filtered);
          visited.addAll(filtered);
        }
      }
    }
    return components;
  }

  bool get isFullyReachable => _directed.isFullyReachable;

  int get vertexCount => _directed.vertexCount;
  int get edgeCount => _directed.edgeCount ~/ 2;

  @override
  String toString() =>
      'GchUndirectedGraph(vertices=$vertexCount, edges=$edgeCount)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Preset graph test data (30+ node graph)
// ─────────────────────────────────────────────────────────────────────────────
const List<(String, String, double)> kSampleGraphEdges = [
  ('A', 'B', 4.0), ('A', 'C', 2.0), ('B', 'C', 5.0), ('B', 'D', 10.0),
  ('C', 'E', 3.0), ('D', 'F', 11.0), ('E', 'D', 4.0), ('E', 'F', 2.0),
  ('F', 'G', 6.0), ('G', 'H', 1.0), ('H', 'I', 3.0), ('I', 'J', 2.0),
  ('J', 'K', 5.0), ('K', 'L', 4.0), ('L', 'M', 7.0), ('M', 'N', 2.0),
  ('N', 'O', 3.0), ('O', 'P', 6.0), ('P', 'Q', 1.0), ('Q', 'R', 4.0),
  ('R', 'S', 2.0), ('S', 'T', 5.0), ('T', 'U', 3.0), ('U', 'V', 8.0),
  ('V', 'W', 2.0), ('W', 'X', 4.0), ('X', 'Y', 6.0), ('Y', 'Z', 3.0),
  ('B', 'E', 7.0), ('D', 'G', 2.0), ('F', 'I', 4.0), ('H', 'K', 5.0),
];

const List<String> kGraphVertices = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
  'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
  'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'BB', 'CC', 'DD',
];

// Build a test graph from constants
GchGraph buildSampleGraph() {
  final g = GchGraph();
  for (final edge in kSampleGraphEdges) {
    g.addEdge(edge.$1, edge.$2, weight: edge.$3);
  }
  return g;
}

GchUndirectedGraph buildSampleUndirectedGraph() {
  final g = GchUndirectedGraph();
  for (final edge in kSampleGraphEdges) {
    g.addEdge(edge.$1, edge.$2, weight: edge.$3);
  }
  return g;
}

// ─────────────────────────────────────────────────────────────────────────────
// GchBellmanFord – single-source shortest paths with negative edge support
// ─────────────────────────────────────────────────────────────────────────────
class GchBellmanFord {
  GchBellmanFord._();

  /// Returns a map of shortest distances from [source] to all other vertices.
  /// Returns null if a negative-weight cycle is detected.
  static Map<String, double>? compute(GchGraph graph, String source) {
    final dist = <String, double>{};
    for (final v in graph.vertices) {
      dist[v] = double.infinity;
    }
    dist[source] = 0.0;

    final edgeList = graph.edges;
    final n = graph.vertexCount;

    // Relax all edges (n-1) times
    for (int i = 0; i < n - 1; i++) {
      bool updated = false;
      for (final e in edgeList) {
        final du = dist[e.from] ?? double.infinity;
        if (du != double.infinity) {
          final newDist = du + e.weight;
          if (newDist < (dist[e.to] ?? double.infinity)) {
            dist[e.to] = newDist;
            updated = true;
          }
        }
      }
      if (!updated) break;
    }

    // Check for negative-weight cycles
    for (final e in edgeList) {
      final du = dist[e.from] ?? double.infinity;
      if (du != double.infinity &&
          du + e.weight < (dist[e.to] ?? double.infinity)) {
        return null; // negative cycle detected
      }
    }
    return dist;
  }

  /// Floyd-Warshall: all-pairs shortest paths.
  /// Returns a 2D map or null if a negative cycle exists.
  static Map<String, Map<String, double>>? floydWarshall(GchGraph graph) {
    final vertices = graph.vertices.toList();
    final n = vertices.length;
    final dist = <String, Map<String, double>>{};
    for (final u in vertices) {
      dist[u] = {};
      for (final v in vertices) {
        dist[u]![v] = u == v ? 0.0 : double.infinity;
      }
    }
    for (final e in graph.edges) {
      if (e.weight < (dist[e.from]![e.to] ?? double.infinity)) {
        dist[e.from]![e.to] = e.weight;
      }
    }
    for (final k in vertices) {
      for (final u in vertices) {
        for (final v in vertices) {
          final duk = dist[u]![k] ?? double.infinity;
          final dkv = dist[k]![v] ?? double.infinity;
          if (duk != double.infinity && dkv != double.infinity) {
            final through = duk + dkv;
            if (through < (dist[u]![v] ?? double.infinity)) {
              dist[u]![v] = through;
            }
          }
        }
      }
    }
    // Detect negative cycles
    for (final v in vertices) {
      if ((dist[v]![v] ?? 0.0) < 0) return null;
    }
    return dist;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GchGraphUtil – miscellaneous graph utilities
// ─────────────────────────────────────────────────────────────────────────────
class GchGraphUtil {
  GchGraphUtil._();

  /// Returns all strongly connected components (Kosaraju's algorithm).
  static List<List<String>> stronglyConnectedComponents(GchGraph graph) {
    final visited = <String>{};
    final finishOrder = <String>[];

    // First DFS pass – record finish order
    void dfs1(String v) {
      visited.add(v);
      for (final e in graph.edgesFrom(v)) {
        if (!visited.contains(e.to)) dfs1(e.to);
      }
      finishOrder.add(v);
    }

    for (final v in graph.vertices) {
      if (!visited.contains(v)) dfs1(v);
    }

    // Build reversed graph
    final rev = GchGraph();
    for (final e in graph.edges) {
      rev.addEdge(e.to, e.from, weight: e.weight);
    }

    // Second DFS pass on reversed graph in reverse finish order
    final visited2 = <String>{};
    final sccs = <List<String>>[];

    void dfs2(String v, List<String> scc) {
      visited2.add(v);
      scc.add(v);
      for (final e in rev.edgesFrom(v)) {
        if (!visited2.contains(e.to)) dfs2(e.to, scc);
      }
    }

    for (final v in finishOrder.reversed) {
      if (!visited2.contains(v)) {
        final scc = <String>[];
        dfs2(v, scc);
        sccs.add(scc);
      }
    }
    return sccs;
  }

  /// Articulation points (cut vertices) in an undirected graph.
  static Set<String> articulationPoints(GchUndirectedGraph graph) {
    final visited = <String, bool>{};
    final disc = <String, int>{};
    final low = <String, int>{};
    final parent = <String, String?>{};
    final aps = <String>{};
    int timer = 0;

    void dfs(String u) {
      visited[u] = true;
      disc[u] = low[u] = timer++;
      int childCount = 0;
      for (final v in graph.neighbors(u)) {
        if (!(visited[v] ?? false)) {
          childCount++;
          parent[v] = u;
          dfs(v);
          low[u] = (low[u]! < low[v]!) ? low[u]! : low[v]!;
          final isRoot = parent[u] == null;
          if (isRoot && childCount > 1) aps.add(u);
          if (!isRoot && low[v]! >= disc[u]!) aps.add(u);
        } else if (v != parent[u]) {
          low[u] = (low[u]! < disc[v]!) ? low[u]! : disc[v]!;
        }
      }
    }

    for (final v in graph.vertices) {
      if (!(visited[v] ?? false)) {
        parent[v] = null;
        dfs(v);
      }
    }
    return aps;
  }

  /// Check if an undirected graph is bipartite (2-colorable).
  static bool isBipartite(GchUndirectedGraph graph) {
    final color = <String, int>{};
    for (final start in graph.vertices) {
      if (color.containsKey(start)) continue;
      final queue = Queue<String>();
      queue.add(start);
      color[start] = 0;
      while (queue.isNotEmpty) {
        final u = queue.removeFirst();
        for (final v in graph.neighbors(u)) {
          if (!color.containsKey(v)) {
            color[v] = 1 - color[u]!;
            queue.add(v);
          } else if (color[v] == color[u]) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Euler path/circuit check: all vertices must have even degree (for circuit)
  /// or exactly two vertices with odd degree (for path).
  static ({bool hasCircuit, bool hasPath}) eulerProperties(
      GchUndirectedGraph graph) {
    int oddDegreeCount = 0;
    for (final v in graph.vertices) {
      if (graph.neighbors(v).length % 2 != 0) oddDegreeCount++;
    }
    return (
      hasCircuit: oddDegreeCount == 0,
      hasPath: oddDegreeCount == 2,
    );
  }
}
