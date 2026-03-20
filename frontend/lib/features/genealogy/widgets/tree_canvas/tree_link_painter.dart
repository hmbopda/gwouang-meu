import 'package:flutter/material.dart';

import 'package:gwangmeu/features/genealogy/state/tree_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Paints Bézier-curve links between tree nodes.
class TreeLinkPainter extends CustomPainter {
  final List<LayoutLink> links;
  final String? selectedPersonId;

  TreeLinkPainter({required this.links, this.selectedPersonId});

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      switch (link.type) {
        case LinkType.filiation:
          _drawFiliation(canvas, link);
        case LinkType.union:
          _drawUnion(canvas, link);
        case LinkType.siblings:
          _drawSiblings(canvas, link);
        case LinkType.aiSuggestion:
          _drawAiSuggestion(canvas, link);
      }
    }
  }

  void _drawFiliation(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = link.highlight ? T.gold : T.txt3
      ..strokeWidth = link.highlight ? 2.5 : 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (link.highlight) {
      // Glow effect
      final glow = Paint()
        ..color = T.goldGlow
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      _drawBezier(canvas, glow, link.from, link.to);
    }

    _drawBezier(canvas, paint, link.from, link.to);
  }

  void _drawUnion(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = T.orange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dashed horizontal line for unions
    final path = Path();
    final dx = link.to.dx - link.from.dx;
    final dy = link.to.dy - link.from.dy;
    final dist = (link.to - link.from).distance;
    const dashLen = 6.0;
    const gapLen = 4.0;
    double d = 0;
    bool drawing = true;
    while (d < dist) {
      final seg = drawing ? dashLen : gapLen;
      final end = (d + seg).clamp(0.0, dist);
      final p1 = Offset(
        link.from.dx + dx * (d / dist),
        link.from.dy + dy * (d / dist),
      );
      final p2 = Offset(
        link.from.dx + dx * (end / dist),
        link.from.dy + dy * (end / dist),
      );
      if (drawing) {
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
      }
      d = end;
      drawing = !drawing;
    }
    canvas.drawPath(path, paint);

    // Heart icon at midpoint
    final mid = Offset(
      (link.from.dx + link.to.dx) / 2,
      (link.from.dy + link.to.dy) / 2,
    );
    _drawHeart(canvas, mid);
  }

  void _drawSiblings(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = T.txt3.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(link.from, link.to, paint);
  }

  void _drawAiSuggestion(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = T.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Dotted line
    final path = _dottedPath(link.from, link.to, 3, 5);
    canvas.drawPath(path, paint);
  }

  void _drawBezier(Canvas canvas, Paint paint, Offset from, Offset to) {
    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  Path _dottedPath(Offset from, Offset to, double dotLen, double gapLen) {
    final path = Path();
    final dist = (to - from).distance;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    double d = 0;
    bool drawing = true;
    while (d < dist) {
      final seg = drawing ? dotLen : gapLen;
      final end = (d + seg).clamp(0.0, dist);
      if (drawing) {
        path.moveTo(
          from.dx + dx * (d / dist),
          from.dy + dy * (d / dist),
        );
        path.lineTo(
          from.dx + dx * (end / dist),
          from.dy + dy * (end / dist),
        );
      }
      d = end;
      drawing = !drawing;
    }
    return path;
  }

  void _drawHeart(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = T.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, paint);

    // Orange ring
    final ring = Paint()
      ..color = T.orange.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 7, ring);
  }

  @override
  bool shouldRepaint(covariant TreeLinkPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.selectedPersonId != selectedPersonId;
  }
}
