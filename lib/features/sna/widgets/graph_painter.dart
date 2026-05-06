import 'dart:math';
import 'package:flutter/material.dart';

import '../models/sna_graph_model.dart';

enum GraphViewType { undirected, directed, weighted, directedWeighted }

enum GraphLayoutType { forceDirected, circular, radial, grid, random }

enum NodeSizeMetric { degree, inDegree, outDegree, weightedDegree }

extension GraphViewTypeLabel on GraphViewType {
  String get label {
    switch (this) {
      case GraphViewType.undirected:
        return 'Undirected Graph';
      case GraphViewType.directed:
        return 'Directed Graph';
      case GraphViewType.weighted:
        return 'Weighted Graph';
      case GraphViewType.directedWeighted:
        return 'Directed Weighted Graph';
    }
  }

  bool get isDirected {
    return this == GraphViewType.directed ||
        this == GraphViewType.directedWeighted;
  }

  bool get isWeighted {
    return this == GraphViewType.weighted ||
        this == GraphViewType.directedWeighted;
  }
}

extension GraphLayoutTypeLabel on GraphLayoutType {
  String get label {
    switch (this) {
      case GraphLayoutType.forceDirected:
        return 'Force-Directed Layout';
      case GraphLayoutType.circular:
        return 'Circular Layout';
      case GraphLayoutType.radial:
        return 'Radial Layout';
      case GraphLayoutType.grid:
        return 'Grid Layout';
      case GraphLayoutType.random:
        return 'Random Layout';
    }
  }
}

extension NodeSizeMetricLabel on NodeSizeMetric {
  String get label {
    switch (this) {
      case NodeSizeMetric.degree:
        return 'Degree';
      case NodeSizeMetric.inDegree:
        return 'In-Degree';
      case NodeSizeMetric.outDegree:
        return 'Out-Degree';
      case NodeSizeMetric.weightedDegree:
        return 'Weighted Degree';
    }
  }
}

const double graphWorldSize = 10000;
const double graphWorldCenter = graphWorldSize / 2;

const List<Color> graphPalette = [
  Color(0xFF2563EB),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFE11D48),
  Color(0xFF06B6D4),
  Color(0xFFEA580C),
  Color(0xFF16A34A),
  Color(0xFF7C3AED),
  Color(0xFF0F766E),
];

class GraphPainter extends CustomPainter {
  final List<SnaNode> nodes;
  final List<SnaEdge> edges;
  final Map<String, SnaNode> nodeMap;
  final String? selectedId;
  final Set<String> neighborIds;
  final double scale;
  final GraphViewType graphViewType;
  final NodeSizeMetric nodeSizeMetric;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    required this.selectedId,
    required this.neighborIds,
    required this.scale,
    required this.graphViewType,
    required this.nodeSizeMetric,
  });

  Color _communityColor(int community) {
    return graphPalette[community % graphPalette.length];
  }

  double _metricValue(SnaNode node) {
    switch (nodeSizeMetric) {
      case NodeSizeMetric.degree:
        return node.metrics.degree;
      case NodeSizeMetric.inDegree:
        return node.metrics.inDegree;
      case NodeSizeMetric.outDegree:
        return node.metrics.outDegree;
      case NodeSizeMetric.weightedDegree:
        return node.metrics.weightedDegree;
    }
  }

  double _nodeRadius(SnaNode node) {
    final metric = _metricValue(node).clamp(0.0, 1.0);

    double radius = 8 + metric * 20;

    if (node.type.toLowerCase().contains('post')) {
      radius *= 1.2;
    }

    if (node.type.toLowerCase().contains('comment')) {
      radius *= 0.9;
    }

    return radius.clamp(7, 32);
  }

  double _edgeWidth(SnaEdge edge, bool active) {
    if (active) return 4.2;

    if (!graphViewType.isWeighted) {
      return scale < 0.4 ? 0.9 : 1.4;
    }

    final normalized = edge.weight.clamp(1, 12);
    return 1.0 + log(normalized + 1) * 0.9;
  }

  Color _edgeColor(SnaEdge edge, bool active) {
    if (active) {
      return const Color(0xFF111827).withValues(alpha: 0.95);
    }

    if (!graphViewType.isWeighted) {
      return const Color(0xFF64748B).withValues(alpha: 0.42);
    }

    if (edge.weight >= 5) {
      return const Color(0xFF111827).withValues(alpha: 0.80);
    }

    if (edge.weight >= 3) {
      return const Color(0xFF334155).withValues(alpha: 0.65);
    }

    return const Color(0xFF64748B).withValues(alpha: 0.45);
  }

  bool _shouldDrawEdge(SnaEdge edge) {
    if (selectedId != null) {
      return edge.source == selectedId || edge.target == selectedId;
    }

    if (scale < 0.25) {
      return edge.weight >= 3;
    }

    return true;
  }

  bool _shouldDrawLabel(SnaNode node) {
    if (selectedId == node.id) return true;
    if (neighborIds.contains(node.id)) return true;

    final metric = _metricValue(node);

    if (scale < 0.45) return false;
    if (scale < 0.9) return metric >= 0.4;

    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in edges) {
      if (!_shouldDrawEdge(edge)) continue;

      final source = nodeMap[edge.source];
      final target = nodeMap[edge.target];

      if (source == null || target == null) continue;

      final isActive =
          selectedId != null &&
          (edge.source == selectedId || edge.target == selectedId);

      final start = Offset(source.x, source.y);
      final end = Offset(target.x, target.y);

      final paint = Paint()
        ..color = _edgeColor(edge, isActive)
        ..strokeWidth = _edgeWidth(edge, isActive)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);

      if (graphViewType.isDirected) {
        _drawArrow(canvas, start, end, paint);
      }

      if (graphViewType.isWeighted && scale > 0.75 && edge.weight > 1) {
        _drawEdgeWeight(canvas, start, end, edge.weight);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowLength = 18.0;
    final arrowAngle = pi / 7;

    final target = Offset(end.dx - cos(angle) * 18, end.dy - sin(angle) * 18);

    final path = Path()
      ..moveTo(target.dx, target.dy)
      ..lineTo(
        target.dx - arrowLength * cos(angle - arrowAngle),
        target.dy - arrowLength * sin(angle - arrowAngle),
      )
      ..lineTo(
        target.dx - arrowLength * cos(angle + arrowAngle),
        target.dy - arrowLength * sin(angle + arrowAngle),
      )
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawEdgeWeight(Canvas canvas, Offset start, Offset end, double weight) {
    final middle = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    final textPainter = TextPainter(
      text: TextSpan(
        text: weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final rect = Rect.fromLTWH(
      middle.dx - textPainter.width / 2 - 4,
      middle.dy - textPainter.height / 2 - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    textPainter.paint(
      canvas,
      Offset(
        middle.dx - textPainter.width / 2,
        middle.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawNodes(Canvas canvas) {
    for (final node in nodes) {
      final isSelected = selectedId == node.id;
      final isNeighbor = neighborIds.contains(node.id);

      if (selectedId != null && !isSelected && !isNeighbor) {
        _drawNode(canvas, node, faded: true);
      } else {
        _drawNode(canvas, node, selected: isSelected);
      }
    }
  }

  void _drawNode(
    Canvas canvas,
    SnaNode node, {
    bool selected = false,
    bool faded = false,
  }) {
    final position = Offset(node.x, node.y);
    final radius = _nodeRadius(node);

    final baseColor = _communityColor(node.community);
    final nodeColor = faded
        ? baseColor.withValues(alpha: 0.18)
        : baseColor.withValues(alpha: 0.95);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.20 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(position.translate(0, 3), radius + 2, shadowPaint);

    final fillPaint = Paint()..color = nodeColor;
    final borderPaint = Paint()
      ..color = selected ? const Color(0xFF111827) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 4 : 2.5;

    if (node.type.toLowerCase().contains('post')) {
      final rect = Rect.fromCircle(center: position, radius: radius);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.35)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.35)),
        borderPaint,
      );
    } else {
      canvas.drawCircle(position, radius, fillPaint);
      canvas.drawCircle(position, radius, borderPaint);
    }

    if (_shouldDrawLabel(node)) {
      _drawNodeLabel(canvas, node, radius);
    }
  }

  void _drawNodeLabel(Canvas canvas, SnaNode node, double radius) {
    final text = node.label.length > 24
        ? '${node.label.substring(0, 24)}...'
        : node.label;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: 180);

    final offset = Offset(node.x - textPainter.width / 2, node.y + radius + 5);

    final bgRect = Rect.fromLTWH(
      offset.dx - 5,
      offset.dy - 2,
      textPainter.width + 10,
      textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.86),
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.round;

    const spacing = 28.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) => false;
}
