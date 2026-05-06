import 'dart:math';

class SnaNodeMetrics {
  final double degree;
  final double inDegree;
  final double outDegree;
  final double weightedDegree;

  const SnaNodeMetrics({
    this.degree = 0,
    this.inDegree = 0,
    this.outDegree = 0,
    this.weightedDegree = 0,
  });
}

class SnaNode {
  final String id;
  final String label;
  final String type;
  final String group;

  double x;
  double y;
  double dx;
  double dy;

  int community;
  SnaNodeMetrics metrics;

  SnaNode({
    required this.id,
    required this.label,
    required this.type,
    required this.group,
    this.x = 0,
    this.y = 0,
    this.dx = 0,
    this.dy = 0,
    this.community = 0,
    this.metrics = const SnaNodeMetrics(),
  });

  factory SnaNode.fromJson(Map<String, dynamic> json) {
    return SnaNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
    );
  }
}

class SnaEdge {
  final String source;
  final String target;
  final double weight;
  final String type;

  SnaEdge({
    required this.source,
    required this.target,
    required this.weight,
    required this.type,
  });

  factory SnaEdge.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['weight'];

    return SnaEdge(
      source: json['source']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      weight: rawWeight is num ? rawWeight.toDouble() : 1,
      type: json['type']?.toString() ?? '',
    );
  }
}

class SnaGraphModel {
  final List<SnaNode> nodes;
  final List<SnaEdge> edges;
  final int totalNodes;
  final int totalEdges;

  SnaGraphModel({
    required this.nodes,
    required this.edges,
    required this.totalNodes,
    required this.totalEdges,
  });

  factory SnaGraphModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final summary = data['summary'] ?? {};

    final List nodeList = data['nodes'] ?? [];
    final List edgeList = data['edges'] ?? [];

    final nodes = nodeList.map((item) => SnaNode.fromJson(item)).toList();
    final edges = edgeList.map((item) => SnaEdge.fromJson(item)).toList();

    _assignFrontendCommunities(nodes, edges);
    _assignFrontendMetrics(nodes, edges);

    return SnaGraphModel(
      nodes: nodes,
      edges: edges,
      totalNodes: summary['total_nodes'] ?? nodes.length,
      totalEdges: summary['total_edges'] ?? edges.length,
    );
  }

  static void _assignFrontendCommunities(
    List<SnaNode> nodes,
    List<SnaEdge> edges,
  ) {
    final nodeMap = {for (final node in nodes) node.id: node};
    final visited = <String>{};
    int communityIndex = 0;

    final adjacency = <String, List<String>>{};

    for (final node in nodes) {
      adjacency[node.id] = [];
    }

    for (final edge in edges) {
      adjacency.putIfAbsent(edge.source, () => []).add(edge.target);
      adjacency.putIfAbsent(edge.target, () => []).add(edge.source);
    }

    for (final node in nodes) {
      if (visited.contains(node.id)) continue;

      final queue = <String>[node.id];
      visited.add(node.id);

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final currentNode = nodeMap[current];

        if (currentNode != null) {
          currentNode.community = communityIndex;
        }

        for (final neighbor in adjacency[current] ?? []) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }

      communityIndex++;
    }
  }

  static void _assignFrontendMetrics(List<SnaNode> nodes, List<SnaEdge> edges) {
    final inDegree = <String, double>{};
    final outDegree = <String, double>{};
    final degree = <String, double>{};
    final weightedDegree = <String, double>{};

    for (final node in nodes) {
      inDegree[node.id] = 0;
      outDegree[node.id] = 0;
      degree[node.id] = 0;
      weightedDegree[node.id] = 0;
    }

    for (final edge in edges) {
      outDegree[edge.source] = (outDegree[edge.source] ?? 0) + 1;
      inDegree[edge.target] = (inDegree[edge.target] ?? 0) + 1;

      degree[edge.source] = (degree[edge.source] ?? 0) + 1;
      degree[edge.target] = (degree[edge.target] ?? 0) + 1;

      weightedDegree[edge.source] =
          (weightedDegree[edge.source] ?? 0) + max(1, edge.weight);
      weightedDegree[edge.target] =
          (weightedDegree[edge.target] ?? 0) + max(1, edge.weight);
    }

    final maxDegree = degree.values.isEmpty ? 1.0 : degree.values.reduce(max);
    final maxInDegree = inDegree.values.isEmpty
        ? 1.0
        : inDegree.values.reduce(max);
    final maxOutDegree = outDegree.values.isEmpty
        ? 1.0
        : outDegree.values.reduce(max);
    final maxWeightedDegree = weightedDegree.values.isEmpty
        ? 1.0
        : weightedDegree.values.reduce(max);

    for (final node in nodes) {
      node.metrics = SnaNodeMetrics(
        degree: maxDegree == 0 ? 0 : (degree[node.id] ?? 0) / maxDegree,
        inDegree: maxInDegree == 0 ? 0 : (inDegree[node.id] ?? 0) / maxInDegree,
        outDegree: maxOutDegree == 0
            ? 0
            : (outDegree[node.id] ?? 0) / maxOutDegree,
        weightedDegree: maxWeightedDegree == 0
            ? 0
            : (weightedDegree[node.id] ?? 0) / maxWeightedDegree,
      );
    }
  }
}
