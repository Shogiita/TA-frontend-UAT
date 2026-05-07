import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../bloc/sna_bloc.dart';
import '../bloc/sna_event.dart';
import '../bloc/sna_state.dart';
import '../models/sna_graph_model.dart';
import '../widgets/graph_painter.dart';

const _kBg = Color(0xFFF0F4FB);
const _kCard = Colors.white;
const _kBorder = Color(0xFFDDE3EF);
const _kAccent = Color(0xFF2563EB);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);

class SnaVisualizationPage extends StatefulWidget {
  final String source;
  final int mode;
  final int limit;

  const SnaVisualizationPage({
    super.key,
    this.source = 'app',
    this.mode = 1,
    this.limit = 300,
  });

  @override
  State<SnaVisualizationPage> createState() => _SnaVisualizationPageState();
}

class _SnaVisualizationPageState extends State<SnaVisualizationPage> {
  late String selectedSource;
  late int selectedMode;
  late int selectedLimit;

  GraphViewType graphViewType = GraphViewType.directedWeighted;
  GraphLayoutType layoutType = GraphLayoutType.forceDirected;
  NodeSizeMetric nodeSizeMetric = NodeSizeMetric.degree;

  bool showControls = true;

  @override
  void initState() {
    super.initState();

    selectedSource = widget.source;
    selectedMode = widget.mode;
    selectedLimit = widget.limit;

    _loadGraph();
  }

  void _loadGraph() {
    context.read<SnaBloc>().add(
      LoadSnaVisualization(
        source: selectedSource,
        mode: selectedMode,
        limit: selectedLimit,
      ),
    );
  }

  String _modeLabel(int mode) {
    if (mode == 1) return '1-Mode User to User';
    if (mode == 2) return '2-Mode User to Post';
    return 'Post to Post';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Network Analysis',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Source: ${selectedSource.toUpperCase()} • ${_modeLabel(selectedMode)} • Limit: $selectedLimit',
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: _kText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Controls',
            onPressed: () {
              setState(() => showControls = !showControls);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _loadGraph,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<SnaBloc, SnaState>(
        builder: (context, state) {
          if (state is SnaLoading || state is SnaInitial) {
            return const LoadingWidget(message: 'Building network graph...');
          }

          if (state is SnaError) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (state is SnaLoaded) {
            return _GraphCanvas(
              graph: state.graph,
              source: selectedSource,
              mode: selectedMode,
              limit: selectedLimit,
              graphViewType: graphViewType,
              layoutType: layoutType,
              nodeSizeMetric: nodeSizeMetric,
              showControls: showControls,
              onGraphViewTypeChanged: (value) {
                setState(() => graphViewType = value);
              },
              onLayoutChanged: (value) {
                setState(() => layoutType = value);
              },
              onNodeSizeMetricChanged: (value) {
                setState(() => nodeSizeMetric = value);
              },
              onSourceChanged: (value) {
                setState(() => selectedSource = value);
                _loadGraph();
              },
              onModeChanged: (value) {
                setState(() => selectedMode = value);
                _loadGraph();
              },
              onLimitChanged: (value) {
                setState(() => selectedLimit = value);
                _loadGraph();
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _GraphCanvas extends StatefulWidget {
  final SnaGraphModel graph;
  final String source;
  final int mode;
  final int limit;

  final GraphViewType graphViewType;
  final GraphLayoutType layoutType;
  final NodeSizeMetric nodeSizeMetric;
  final bool showControls;

  final ValueChanged<GraphViewType> onGraphViewTypeChanged;
  final ValueChanged<GraphLayoutType> onLayoutChanged;
  final ValueChanged<NodeSizeMetric> onNodeSizeMetricChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<int> onLimitChanged;

  const _GraphCanvas({
    required this.graph,
    required this.source,
    required this.mode,
    required this.limit,
    required this.graphViewType,
    required this.layoutType,
    required this.nodeSizeMetric,
    required this.showControls,
    required this.onGraphViewTypeChanged,
    required this.onLayoutChanged,
    required this.onNodeSizeMetricChanged,
    required this.onSourceChanged,
    required this.onModeChanged,
    required this.onLimitChanged,
  });

  @override
  State<_GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<_GraphCanvas> {
  late List<SnaNode> nodes;
  late List<SnaEdge> edges;
  late Map<String, SnaNode> nodeMap;

  final TransformationController transformController =
      TransformationController();

  double currentScale = 0.12;

  String? selectedId;
  SnaNode? draggedNode;
  Set<String> neighborIds = {};

  @override
  void initState() {
    super.initState();
    _setupGraph();

    transformController.addListener(() {
      final scale = transformController.value.getMaxScaleOnAxis();
      if ((scale - currentScale).abs() > 0.02 && mounted) {
        setState(() => currentScale = scale);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerGraph();
    });
  }

  @override
  void didUpdateWidget(covariant _GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.graph != widget.graph ||
        oldWidget.layoutType != widget.layoutType) {
      _setupGraph();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerGraph();
      });
    }
  }

  @override
  void dispose() {
    transformController.dispose();
    super.dispose();
  }

  void _setupGraph() {
    nodes = widget.graph.nodes;
    edges = widget.graph.edges;
    nodeMap = {for (final node in nodes) node.id: node};

    _applyLayout(widget.layoutType);
  }

  void _centerGraph() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    const scale = 0.12;

    transformController.value = Matrix4.translationValues(
      (size.width / 2) - (graphWorldCenter * scale),
      (size.height / 2) - (graphWorldCenter * scale) - 80,
      0,
    )..multiply(Matrix4.diagonal3Values(scale, scale, scale));

    setState(() => currentScale = scale);
  }

  void _applyLayout(GraphLayoutType layout) {
    if (nodes.isEmpty) return;

    switch (layout) {
      case GraphLayoutType.forceDirected:
        _applyForceDirectedLayout();
        break;
      case GraphLayoutType.circular:
        _applyCircularLayout();
        break;
      case GraphLayoutType.radial:
        _applyRadialLayout();
        break;
      case GraphLayoutType.grid:
        _applyGridLayout();
        break;
      case GraphLayoutType.random:
        _applyRandomLayout();
        break;
    }
  }

  void _applyCircularLayout() {
    final radius = min(3200.0, 900 + nodes.length * 8);

    for (int i = 0; i < nodes.length; i++) {
      final angle = (2 * pi * i) / max(1, nodes.length);

      nodes[i].x = graphWorldCenter + cos(angle) * radius;
      nodes[i].y = graphWorldCenter + sin(angle) * radius;
    }
  }

  void _applyRadialLayout() {
    final groups = <int, List<SnaNode>>{};

    for (final node in nodes) {
      groups.putIfAbsent(node.community, () => []).add(node);
    }

    final groupEntries = groups.entries.toList();
    final groupCount = max(1, groupEntries.length);

    for (int g = 0; g < groupEntries.length; g++) {
      final group = groupEntries[g].value;
      final groupAngle = (2 * pi * g) / groupCount;

      final center = Offset(
        graphWorldCenter + cos(groupAngle) * 2200,
        graphWorldCenter + sin(groupAngle) * 2200,
      );

      final radius = max(260.0, sqrt(group.length) * 90);

      for (int i = 0; i < group.length; i++) {
        final angle = (2 * pi * i) / max(1, group.length);

        group[i].x = center.dx + cos(angle) * radius;
        group[i].y = center.dy + sin(angle) * radius;
      }
    }
  }

  void _applyGridLayout() {
    final columns = sqrt(nodes.length).ceil();
    const gap = 190.0;

    final startX = graphWorldCenter - (columns * gap / 2);
    final startY = graphWorldCenter - (columns * gap / 2);

    for (int i = 0; i < nodes.length; i++) {
      final row = i ~/ columns;
      final column = i % columns;

      nodes[i].x = startX + column * gap;
      nodes[i].y = startY + row * gap;
    }
  }

  void _applyRandomLayout() {
    final rng = Random(42);

    for (final node in nodes) {
      node.x = 1200 + rng.nextDouble() * 7600;
      node.y = 1200 + rng.nextDouble() * 7600;
    }
  }

  void _applyForceDirectedLayout() {
    _applyRadialLayout();

    final validIds = nodes.map((node) => node.id).toSet();
    final layoutEdges = edges
        .where(
          (edge) =>
              validIds.contains(edge.source) && validIds.contains(edge.target),
        )
        .toList();

    final area = graphWorldSize * graphWorldSize;
    final k = sqrt(area / max(1, nodes.length)) * 0.08;
    double temperature = graphWorldSize * 0.018;

    for (int iteration = 0; iteration < 100; iteration++) {
      for (final node in nodes) {
        node.dx = 0;
        node.dy = 0;
      }

      for (int i = 0; i < nodes.length; i++) {
        final a = nodes[i];

        for (int j = i + 1; j < nodes.length; j++) {
          final b = nodes[j];

          double dx = a.x - b.x;
          double dy = a.y - b.y;

          double distance = sqrt(dx * dx + dy * dy);
          if (distance < 0.01) distance = 0.01;

          final force = (k * k) / distance;

          final fx = (dx / distance) * force;
          final fy = (dy / distance) * force;

          a.dx += fx;
          a.dy += fy;
          b.dx -= fx;
          b.dy -= fy;
        }
      }

      for (final edge in layoutEdges) {
        final source = nodeMap[edge.source];
        final target = nodeMap[edge.target];

        if (source == null || target == null) continue;

        double dx = source.x - target.x;
        double dy = source.y - target.y;

        double distance = sqrt(dx * dx + dy * dy);
        if (distance < 0.01) distance = 0.01;

        final weightFactor = edge.weight.clamp(1, 8);
        final force = ((distance * distance) / k) * 0.018 * weightFactor;

        final fx = (dx / distance) * force;
        final fy = (dy / distance) * force;

        source.dx -= fx;
        source.dy -= fy;
        target.dx += fx;
        target.dy += fy;
      }

      for (final node in nodes) {
        final displacement = sqrt(node.dx * node.dx + node.dy * node.dy);

        if (displacement > 0) {
          final limited = min(displacement, temperature);

          node.x += (node.dx / displacement) * limited;
          node.y += (node.dy / displacement) * limited;
        }

        node.x = node.x.clamp(350, graphWorldSize - 350);
        node.y = node.y.clamp(350, graphWorldSize - 350);
      }

      temperature *= 0.94;
    }
  }

  Offset _toCanvas(Offset local) {
    final matrix = transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    return Offset(
      (local.dx - translation.x) / scale,
      (local.dy - translation.y) / scale,
    );
  }

  double _nodeRadius(SnaNode node) {
    final metric = switch (widget.nodeSizeMetric) {
      NodeSizeMetric.degree => node.metrics.degree,
      NodeSizeMetric.inDegree => node.metrics.inDegree,
      NodeSizeMetric.outDegree => node.metrics.outDegree,
      NodeSizeMetric.weightedDegree => node.metrics.weightedDegree,
    };

    double radius = 8 + metric * 22;

    if (node.type.toLowerCase().contains('post')) {
      radius *= 1.2;
    }

    return radius.clamp(8, 38);
  }

  SnaNode? _hitTest(Offset position) {
    for (final node in nodes.reversed) {
      final dx = position.dx - node.x;
      final dy = position.dy - node.y;
      final radius = _nodeRadius(node) + 14;

      if ((dx * dx + dy * dy) <= radius * radius) {
        return node;
      }
    }

    return null;
  }

  void _onPointerDown(PointerDownEvent event) {
    final node = _hitTest(_toCanvas(event.localPosition));

    if (node != null) {
      setState(() => draggedNode = node);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (draggedNode == null) return;

    final position = _toCanvas(event.localPosition);

    setState(() {
      draggedNode!.x = position.dx;
      draggedNode!.y = position.dy;
    });
  }

  void _onPointerUp(PointerEvent event) {
    if (draggedNode != null) {
      setState(() => draggedNode = null);
    }
  }

  void _onTapUp(TapUpDetails details) {
    final node = _hitTest(_toCanvas(details.localPosition));

    setState(() {
      if (node == null || node.id == selectedId) {
        selectedId = null;
        neighborIds = {};
      } else {
        selectedId = node.id;

        neighborIds = edges
            .where((edge) => edge.source == node.id || edge.target == node.id)
            .expand((edge) => [edge.source, edge.target])
            .toSet();

        _showNodeDetail(node);
      }
    });
  }

  void _showNodeDetail(SnaNode node) {
    final relatedEdges = edges
        .where((edge) => edge.source == node.id || edge.target == node.id)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        graphPalette[node.community % graphPalette.length],
                    child: Text(
                      node.label.isNotEmpty ? node.label[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${node.type} • ${node.group}',
                          style: const TextStyle(color: _kMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailMetric('Degree', node.metrics.degree),
                      _detailMetric('In', node.metrics.inDegree),
                      _detailMetric('Out', node.metrics.outDegree),
                      _detailMetric('Weight', node.metrics.weightedDegree),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connected edges: ${relatedEdges.length}',
                  style: const TextStyle(
                    color: _kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        selectedId = null;
        neighborIds = {};
      });
    });
  }

  Widget _detailMetric(String label, double value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 160),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
        ],
      ),
    );
  }

  int get communityCount {
    if (nodes.isEmpty) return 0;
    return nodes.map((node) => node.community).toSet().length;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 768;
    final isMobile = screenWidth < 600;

    return Stack(
      children: [
        Container(color: _kCard),
        CustomPaint(size: Size.infinite, painter: DotGridPainter()),
        Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: InteractiveViewer(
            transformationController: transformController,
            panEnabled: draggedNode == null,
            scaleEnabled: draggedNode == null,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.04,
            maxScale: 4.5,
            child: GestureDetector(
              onTapUp: _onTapUp,
              child: SizedBox(
                width: graphWorldSize,
                height: graphWorldSize,
                child: CustomPaint(
                  painter: GraphPainter(
                    nodes: nodes,
                    edges: edges,
                    nodeMap: nodeMap,
                    selectedId: selectedId,
                    neighborIds: neighborIds,
                    scale: currentScale,
                    graphViewType: widget.graphViewType,
                    nodeSizeMetric: widget.nodeSizeMetric,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: isMobile ? 10 : 14,
          left: isMobile ? 10 : 14,
          right: isMobile ? 10 : null,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _InfoChip(
              nodeCount: nodes.length,
              edgeCount: edges.length,
              communityCount: communityCount,
              graphViewType: widget.graphViewType,
              layoutType: widget.layoutType,
              isCompact: isCompact,
            ),
          ),
        ),
        if (widget.showControls)
          Positioned(
            right: isMobile ? 10 : 14,
            bottom: isMobile ? 10 : 18,
            left: isCompact && isMobile ? 10 : null,
            child: SingleChildScrollView(
              child: _VisualControlPanel(
                source: widget.source,
                mode: widget.mode,
                limit: widget.limit,
                graphViewType: widget.graphViewType,
                layoutType: widget.layoutType,
                nodeSizeMetric: widget.nodeSizeMetric,
                onGraphViewTypeChanged: widget.onGraphViewTypeChanged,
                onLayoutChanged: widget.onLayoutChanged,
                onNodeSizeMetricChanged: widget.onNodeSizeMetricChanged,
                onSourceChanged: widget.onSourceChanged,
                onModeChanged: widget.onModeChanged,
                onLimitChanged: widget.onLimitChanged,
                isCompact: isCompact,
              ),
            ),
          ),
        if (!isMobile)
          Positioned(
            left: 14,
            bottom: 18,
            child: _EdgeLegend(
              isWeighted: widget.graphViewType.isWeighted,
              isDirected: widget.graphViewType.isDirected,
            ),
          ),
        if (isMobile)
          Positioned(
            left: 10,
            bottom: 10,
            right: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _EdgeLegend(
                isWeighted: widget.graphViewType.isWeighted,
                isDirected: widget.graphViewType.isDirected,
                isCompact: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final int nodeCount;
  final int edgeCount;
  final int communityCount;
  final GraphViewType graphViewType;
  final GraphLayoutType layoutType;
  final bool isCompact;

  const _InfoChip({
    required this.nodeCount,
    required this.edgeCount,
    required this.communityCount,
    required this.graphViewType,
    required this.layoutType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? 290 : (isCompact ? 280 : 330),
      ),
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: isMobile ? 6 : 8,
        runSpacing: isMobile ? 6 : 8,
        children: [
          _pill(Icons.circle_outlined, '$nodeCount Nodes', isMobile),
          _pill(Icons.timeline, '$edgeCount Edges', isMobile),
          _pill(Icons.hub, '$communityCount Clusters', isMobile),
          _pill(Icons.account_tree, graphViewType.label, isMobile),
          _pill(Icons.scatter_plot, layoutType.label, isMobile),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 7 : 9,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 11 : 13, color: _kAccent),
          SizedBox(width: isMobile ? 3 : 5),
          Text(
            label,
            style: TextStyle(
              color: _kText,
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VisualControlPanel extends StatefulWidget {
  final String source;
  final int mode;
  final int limit;

  final GraphViewType graphViewType;
  final GraphLayoutType layoutType;
  final NodeSizeMetric nodeSizeMetric;

  final ValueChanged<GraphViewType> onGraphViewTypeChanged;
  final ValueChanged<GraphLayoutType> onLayoutChanged;
  final ValueChanged<NodeSizeMetric> onNodeSizeMetricChanged;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<int> onModeChanged;
  final ValueChanged<int> onLimitChanged;
  final bool isCompact;

  const _VisualControlPanel({
    required this.source,
    required this.mode,
    required this.limit,
    required this.graphViewType,
    required this.layoutType,
    required this.nodeSizeMetric,
    required this.onGraphViewTypeChanged,
    required this.onLayoutChanged,
    required this.onNodeSizeMetricChanged,
    required this.onSourceChanged,
    required this.onModeChanged,
    required this.onLimitChanged,
    this.isCompact = false,
  });

  @override
  State<_VisualControlPanel> createState() => _VisualControlPanelState();
}

class _VisualControlPanelState extends State<_VisualControlPanel> {
  late final TextEditingController limitController;

  @override
  void initState() {
    super.initState();
    limitController = TextEditingController(text: widget.limit.toString());
  }

  @override
  void dispose() {
    limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final width = isMobile ? (MediaQuery.of(context).size.width - 20) : 330.0;

    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: _kAccent,
                size: isMobile ? 16 : 18,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Controls',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _kText,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          _dropdown<String>(
            label: 'Source',
            value: widget.source,
            items: const ['app', 'instagram'],
            itemLabel: (item) => item.toUpperCase(),
            onChanged: widget.onSourceChanged,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _dropdown<int>(
            label: 'Mode',
            value: widget.mode,
            items: const [1, 2, 3],
            itemLabel: (item) {
              if (item == 1) return '1-Mode';
              if (item == 2) return '2-Mode';
              return '3-Mode';
            },
            onChanged: widget.onModeChanged,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _dropdown<GraphViewType>(
            label: 'Type',
            value: widget.graphViewType,
            items: GraphViewType.values,
            itemLabel: (item) => item.label.substring(0, 10),
            onChanged: widget.onGraphViewTypeChanged,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _dropdown<GraphLayoutType>(
            label: 'Layout',
            value: widget.layoutType,
            items: GraphLayoutType.values,
            itemLabel: (item) => item.label,
            onChanged: widget.onLayoutChanged,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _dropdown<NodeSizeMetric>(
            label: 'Size',
            value: widget.nodeSizeMetric,
            items: NodeSizeMetric.values,
            itemLabel: (item) => item.label,
            onChanged: widget.onNodeSizeMetricChanged,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          TextField(
            controller: limitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Limit',
              isDense: true,
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 8 : 10,
              ),
            ),
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                widget.onLimitChanged(parsed.clamp(50, 3000));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T> onChanged,
    required bool isMobile,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 8 : 10,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: isMobile ? 12 : 13),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _EdgeLegend extends StatelessWidget {
  final bool isWeighted;
  final bool isDirected;
  final bool isCompact;

  const _EdgeLegend({
    required this.isWeighted,
    required this.isDirected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isCompact ? (isMobile ? 220 : 250) : 250,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _line(width: 1.5, label: 'Normal', isMobile: isMobile),
          SizedBox(height: isMobile ? 6 : 8),
          _line(
            width: 5,
            label: isWeighted ? 'Weighted' : 'Off',
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDirected ? Icons.arrow_forward : Icons.remove,
                size: isMobile ? 14 : 16,
                color: _kAccent,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                isDirected ? 'Directed' : 'Undirected',
                style: TextStyle(fontSize: isMobile ? 9 : 11, color: _kMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line({
    required double width,
    required String label,
    bool isMobile = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMobile ? 36 : 44,
          height: width,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: isMobile ? 9 : 11, color: _kMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
