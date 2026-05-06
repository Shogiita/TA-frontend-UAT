class CentralityItem {
  final int rank;
  final String id;
  final String label;
  final double score;

  CentralityItem({
    required this.rank,
    required this.id,
    required this.label,
    required this.score,
  });

  factory CentralityItem.fromJson(Map<String, dynamic> json) {
    return CentralityItem(
      rank: json['rank'] ?? 0,
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      score: json['score'] is num ? json['score'].toDouble() : 0.0,
    );
  }
}

class LeidenCommunityMember {
  final String id;
  final String label;

  LeidenCommunityMember({required this.id, required this.label});

  factory LeidenCommunityMember.fromJson(Map<String, dynamic> json) {
    return LeidenCommunityMember(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class LeidenCommunity {
  final int rank;
  final int communityId;
  final int size;
  final List<LeidenCommunityMember> members;

  LeidenCommunity({
    required this.rank,
    required this.communityId,
    required this.size,
    required this.members,
  });

  factory LeidenCommunity.fromJson(Map<String, dynamic> json) {
    final List rawMembers = json['members'] ?? [];

    return LeidenCommunity(
      rank: json['rank'] ?? 0,
      communityId: json['community_id'] ?? 0,
      size: json['size'] ?? 0,
      members: rawMembers
          .map((item) => LeidenCommunityMember.fromJson(item))
          .toList(),
    );
  }
}

class GeodesicNode {
  final String id;
  final String label;

  GeodesicNode({required this.id, required this.label});

  factory GeodesicNode.fromJson(Map<String, dynamic> json) {
    return GeodesicNode(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class GeodesicEdge {
  final String source;
  final String target;
  final String sourceLabel;
  final String targetLabel;
  final double weight;

  GeodesicEdge({
    required this.source,
    required this.target,
    required this.sourceLabel,
    required this.targetLabel,
    required this.weight,
  });

  factory GeodesicEdge.fromJson(Map<String, dynamic> json) {
    return GeodesicEdge(
      source: json['source']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      sourceLabel: json['source_label']?.toString() ?? '',
      targetLabel: json['target_label']?.toString() ?? '',
      weight: json['weight'] is num ? json['weight'].toDouble() : 1.0,
    );
  }
}

class GeodesicPath {
  final int rank;
  final String source;
  final String sourceLabel;
  final String target;
  final String targetLabel;
  final int hops;
  final double totalWeight;
  final double totalDistance;
  final String pathDetails;
  final List<GeodesicNode> path;
  final List<GeodesicEdge> edges;

  GeodesicPath({
    required this.rank,
    required this.source,
    required this.sourceLabel,
    required this.target,
    required this.targetLabel,
    required this.hops,
    required this.totalWeight,
    required this.totalDistance,
    required this.pathDetails,
    required this.path,
    required this.edges,
  });

  factory GeodesicPath.fromJson(Map<String, dynamic> json) {
    final List rawPath = json['path'] ?? [];
    final List rawEdges = json['edges'] ?? [];

    return GeodesicPath(
      rank: json['rank'] ?? 0,
      source: json['source']?.toString() ?? '',
      sourceLabel: json['source_label']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      targetLabel: json['target_label']?.toString() ?? '',
      hops: json['hops'] ?? 0,
      totalWeight: json['total_weight'] is num
          ? json['total_weight'].toDouble()
          : 0.0,
      totalDistance: json['total_distance'] is num
          ? json['total_distance'].toDouble()
          : 0.0,
      pathDetails: json['path_details']?.toString() ?? '',
      path: rawPath.map((item) => GeodesicNode.fromJson(item)).toList(),
      edges: rawEdges.map((item) => GeodesicEdge.fromJson(item)).toList(),
    );
  }
}

class NetworkAnalysisModel {
  final int totalNodes;
  final int totalEdges;

  final List<CentralityItem> degree;
  final List<CentralityItem> eigenvector;
  final List<CentralityItem> closeness;
  final List<CentralityItem> betweenness;

  final int totalCommunities;
  final List<LeidenCommunity> communities;

  final List<GeodesicPath> geodesicPaths;

  NetworkAnalysisModel({
    required this.totalNodes,
    required this.totalEdges,
    required this.degree,
    required this.eigenvector,
    required this.closeness,
    required this.betweenness,
    required this.totalCommunities,
    required this.communities,
    required this.geodesicPaths,
  });

  factory NetworkAnalysisModel.empty() {
    return NetworkAnalysisModel(
      totalNodes: 0,
      totalEdges: 0,
      degree: [],
      eigenvector: [],
      closeness: [],
      betweenness: [],
      totalCommunities: 0,
      communities: [],
      geodesicPaths: [],
    );
  }

  factory NetworkAnalysisModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final summary = data['summary'] ?? {};
    final centrality = data['centrality'] ?? {};
    final leiden = data['leiden'] ?? {};

    final List rawDegree = centrality['degree'] ?? [];
    final List rawEigenvector = centrality['eigenvector'] ?? [];
    final List rawCloseness = centrality['closeness'] ?? [];
    final List rawBetweenness = centrality['betweenness'] ?? [];

    final List rawCommunities = leiden['communities'] ?? [];
    final List rawGeodesicPaths = data['geodesic_paths'] ?? [];

    return NetworkAnalysisModel(
      totalNodes: summary['total_nodes'] ?? 0,
      totalEdges: summary['total_edges'] ?? 0,
      degree: rawDegree.map((item) => CentralityItem.fromJson(item)).toList(),
      eigenvector: rawEigenvector
          .map((item) => CentralityItem.fromJson(item))
          .toList(),
      closeness: rawCloseness
          .map((item) => CentralityItem.fromJson(item))
          .toList(),
      betweenness: rawBetweenness
          .map((item) => CentralityItem.fromJson(item))
          .toList(),
      totalCommunities: leiden['total_communities'] ?? 0,
      communities: rawCommunities
          .map((item) => LeidenCommunity.fromJson(item))
          .toList(),
      geodesicPaths: rawGeodesicPaths
          .map((item) => GeodesicPath.fromJson(item))
          .toList(),
    );
  }
}
