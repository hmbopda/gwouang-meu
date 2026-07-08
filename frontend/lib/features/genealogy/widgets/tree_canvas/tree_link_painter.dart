import 'package:flutter/material.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Liens « Tissage » (#2c) : courbes bézier douces 2 px, opacité 30–45 %,
/// colorées par lignée (or Mbopda, rose Ngo Bassa). Unions en pointillé
/// discret, suggestions IA en tirets sage.
///
/// Les couleurs dépendantes du thème sont injectées par le widget appelant
/// (jamais de `GwTokens.of`/`GwTokens.dark` dans le painter).
class TreeLinkPainter extends CustomPainter {
  final List<LayoutLink> links;
  final String? selectedPersonId;

  /// Couleur neutre (filiation sans lignée, fratrie) — `stoneFaint` du thème.
  final Color neutralColor;

  /// Couleur du pointillé d'union — `stone` translucide du thème.
  final Color unionColor;

  TreeLinkPainter({
    required this.links,
    this.selectedPersonId,
    required this.neutralColor,
    required this.unionColor,
  });

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
    final base = link.color ?? neutralColor;
    // Union terminée : filiation atténuée (opacité et trait réduits), jamais
    // effacée — le fait généalogique reste toujours visible.
    final baseAlpha = link.highlight ? 0.65 : (link.ended ? 0.20 : 0.38);
    final paint = Paint()
      ..color = base.withValues(alpha: baseAlpha)
      ..strokeWidth = link.highlight ? 2.5 : (link.ended ? 1.5 : 2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (link.highlight) {
      final glow = Paint()
        ..color = base.withValues(alpha: 0.18)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      _drawBezier(canvas, glow, link.from, link.to);
    }

    _drawBezier(canvas, paint, link.from, link.to);
  }

  /// Union : trait entre conjoints. Active = plein discret ; terminée = pointillé
  /// atténué (le lien reste visible, jamais barré). Point rose = alliance.
  void _drawUnion(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = link.ended
          ? unionColor.withValues(alpha: unionColor.a * 0.55)
          : unionColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (link.ended) {
      final path = _dottedPath(link.from, link.to, 1.5, 6);
      canvas.drawPath(path, paint);
    } else {
      final path = _dottedPath(link.from, link.to, 1.5, 5);
      canvas.drawPath(path, paint);
    }

    // Petit point rose au milieu (alliance) — plus doux si l'union est terminée.
    final mid = Offset(
      (link.from.dx + link.to.dx) / 2,
      (link.from.dy + link.to.dy) / 2,
    );
    canvas.drawCircle(
      mid,
      3,
      Paint()..color = GwTokens.rose.withValues(alpha: link.ended ? 0.3 : 0.6),
    );
  }

  /// Barre de fratrie (une par union). Union terminée : plus atténuée.
  void _drawSiblings(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = neutralColor.withValues(alpha: link.ended ? 0.18 : 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(link.from, link.to, paint);
  }

  /// Affluent IA : tirets sage arrondis (4 / 6).
  void _drawAiSuggestion(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = GwTokens.sage.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _dottedPath(link.from, link.to, 4, 6);
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
    if (dist == 0) return path;
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

  @override
  bool shouldRepaint(covariant TreeLinkPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.selectedPersonId != selectedPersonId ||
        oldDelegate.neutralColor != neutralColor ||
        oldDelegate.unionColor != unionColor;
  }
}
