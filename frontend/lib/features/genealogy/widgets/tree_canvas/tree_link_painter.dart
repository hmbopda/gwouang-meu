import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Liens « Tissage » (#2c) — rendu ORGANIGRAMME professionnel.
///
/// - Filiation (parent→enfant) : connecteur ORTHOGONAL en équerre (« elbow »),
///   traits droits pleins, coins très légèrement arrondis, routés par une ligne
///   horizontale à mi-chemin entre les deux paliers.
/// - Union (conjoint↔conjoint) : trait horizontal INTERROMPU (tirets) ancré aux
///   côtés des cartes, petit point rose d'alliance au centre.
/// - Fratrie : barre horizontale + descentes verticales (déjà orthogonal côté
///   layout ; on ancre au bord haut des cartes enfants).
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

  // Demi-dimensions des cartes-nœud : les liens d'UNION sont ancrés au CÔTÉ des
  // cartes (et non au centre) pour rester visibles ENTRE les deux conjoints.
  //
  // La filiation, elle, route jusqu'au CENTRE de la carte cible : les nœuds sont
  // peints PAR-DESSUS les liens (ordre du Stack : liens puis nœuds), donc le
  // moignon carte-centre → bord est masqué par la carte et le trait paraît
  // s'arrêter net au bord haut de l'enfant. Cela résout aussi proprement le cas
  // du lien couple→barre-de-fratrie (cible = jonction, pas une carte) : on
  // atteint exactement le point, sans laisser de vide avant la barre.
  static const double _halfWidth = 115; // kTreeNodeWidth (230) / 2

  // Rayon des coins de l'équerre (jonctions vertical↔horizontal). Nets, très
  // légèrement adoucis pour un rendu propre, jamais « courbe ».
  static const double _elbowRadius = 6;

  /// Ancre horizontale : ramène `from`/`to` aux CÔTÉS des cartes (union).
  static (Offset, Offset) _hEndpoints(Offset from, Offset to, double half) {
    final sign = to.dx >= from.dx ? 1.0 : -1.0;
    final d = math.min(half, (to.dx - from.dx).abs() * 0.45);
    return (
      Offset(from.dx + sign * d, from.dy),
      Offset(to.dx - sign * d, to.dy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Compteur de tressage : chaque union colorée de MÊME RANGÉE descend un
    // cran plus bas que la précédente (maquette 6a).
    var braid = 0;
    for (final link in links) {
      switch (link.type) {
        case LinkType.filiation:
          _drawFiliation(canvas, link);
        case LinkType.union:
          braid = _drawUnion(canvas, link, braid);
        case LinkType.siblings:
          _drawSiblings(canvas, link);
        case LinkType.aiSuggestion:
          _drawAiSuggestion(canvas, link);
        case LinkType.foyerDrop:
          _drawFoyerDrop(canvas, link);
      }
    }
  }

  /// Filiation : connecteur orthogonal en équerre.
  ///
  /// Depuis le bas-centre du parent → segment VERTICAL vers le bas jusqu'à une
  /// ligne de routage horizontale (mi-hauteur entre les paliers) → segment
  /// HORIZONTAL jusqu'à l'abscisse de l'enfant → segment VERTICAL vers le
  /// haut-centre de l'enfant. Coins nets, très légèrement arrondis (≤ 6 px).
  /// On route de centre à centre : les cartes (peintes par-dessus) masquent les
  /// moignons et le trait paraît naître/mourir au bord des nœuds.
  void _drawFiliation(Canvas canvas, LayoutLink link) {
    final base = link.color ?? neutralColor;
    // Union terminée : filiation atténuée (opacité et trait réduits), jamais
    // effacée — le fait généalogique reste toujours visible.
    final baseAlpha = link.highlight ? 0.75 : (link.ended ? 0.22 : 0.42);
    final strokeWidth = link.highlight ? 2.0 : (link.ended ? 1.5 : 1.7);

    final paint = Paint()
      ..color = base.withValues(alpha: baseAlpha)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _elbowPath(link.from, link.to);

    // Glow du lien sélectionné : même tracé orthogonal, flouté dessous.
    if (link.highlight) {
      final glow = Paint()
        ..color = base.withValues(alpha: 0.20)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glow);
    }

    canvas.drawPath(path, paint);
  }

  /// Construit l'équerre orthogonale de `a` (émetteur) vers `b` (récepteur).
  ///
  /// Cas vertical (paliers différents) : V descendant → H de routage → V. Le
  /// palier horizontal est placé à mi-hauteur entre `a.dy` et `b.dy`. Si les
  /// deux abscisses coïncident (± 1 px), on trace un simple trait droit.
  /// Cas dégénéré (même palier) : simple ligne droite.
  Path _elbowPath(Offset a, Offset b) {
    final path = Path()..moveTo(a.dx, a.dy);

    final dx = (b.dx - a.dx).abs();
    final dy = (b.dy - a.dy).abs();

    // Colinéaires (verticalement ou horizontalement alignés) : trait droit.
    if (dx < 1.0 || dy < 1.0) {
      path.lineTo(b.dx, b.dy);
      return path;
    }

    // Ligne de routage horizontale, au milieu vertical entre les paliers.
    final routeY = (a.dy + b.dy) / 2;

    // Rayon des coins borné pour ne jamais dépasser les demi-segments
    // disponibles (évite les arcs qui se chevauchent quand les cartes sont
    // proches ou l'écart horizontal très faible).
    final vHalf = (routeY - a.dy).abs();
    final r = math.min(_elbowRadius, math.min(dx / 2, vHalf));

    final xSign = b.dx >= a.dx ? 1.0 : -1.0; // sens horizontal du palier
    final ySignDown = b.dy >= a.dy ? 1.0 : -1.0; // descente/montée émetteur

    if (r <= 0.5) {
      // Trop peu de place pour arrondir : équerre à angles vifs.
      path
        ..lineTo(a.dx, routeY)
        ..lineTo(b.dx, routeY)
        ..lineTo(b.dx, b.dy);
      return path;
    }

    // 1) Segment vertical émetteur → juste avant la ligne de routage.
    path.lineTo(a.dx, routeY - ySignDown * r);
    // Coin arrondi vertical→horizontal (côté émetteur).
    path.quadraticBezierTo(a.dx, routeY, a.dx + xSign * r, routeY);
    // 2) Segment horizontal de routage → juste avant l'abscisse enfant.
    path.lineTo(b.dx - xSign * r, routeY);
    // Coin arrondi horizontal→vertical (côté récepteur).
    path.quadraticBezierTo(b.dx, routeY, b.dx, routeY + ySignDown * r);
    // 3) Segment vertical → haut-centre de l'enfant.
    path.lineTo(b.dx, b.dy);

    return path;
  }

  /// Union : trait horizontal INTERROMPU entre conjoints, ancré aux côtés des
  /// cartes. Active = tirets discrets ; terminée = tirets plus espacés et
  /// atténués (le lien reste visible, jamais barré). Point rose = alliance.
  ///
  /// Mode FOYERS (maquette 2a) : `link.color` est fournie (couleur du foyer,
  /// or / rose / vert) → connecteur ORTHOGONAL PLEIN chef→épouse dans cette
  /// couleur ; la pilule « 1RE UNION · 1968 » (widget) en couvre le milieu.
  int _drawUnion(Canvas canvas, LayoutLink link, int braidIndex) {
    final foyer = link.color;
    if (foyer != null) {
      final paint = Paint()
        ..color = foyer.withValues(alpha: link.ended ? 0.35 : 0.85)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // MÊME RANGÉE (sujet + conjoints côte à côte) : TRESSAGE sous la
      // rangée (maquette 6a) — descente sous le sujet, course horizontale
      // colorée, remontée sous la carte du conjoint. Chaque union a son
      // propre cran de profondeur.
      final sameRow = (link.from.dy - link.to.dy).abs() < 1;
      if (sameRow) {
        const cardHalfH = 42.0; // demi-hauteur de carte standard (84 px)
        final startX = link.from.dx - 24 + braidIndex * 16.0;
        final fromBottom = link.from.dy + cardHalfH;
        final routeY = fromBottom + 14 + braidIndex * 10.0;
        final toBottom = link.to.dy + cardHalfH;
        final path = Path()
          ..moveTo(startX, fromBottom)
          ..lineTo(startX, routeY)
          ..lineTo(link.to.dx, routeY)
          ..lineTo(link.to.dx, toBottom);
        canvas.drawPath(path, paint);
        return braidIndex + 1;
      }

      canvas.drawPath(_elbowPath(link.from, link.to), paint);
      return braidIndex;
    }

    final paint = Paint()
      ..color = link.ended
          ? unionColor.withValues(alpha: unionColor.a * 0.55)
          : unionColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ancrage aux côtés des cartes (union ≈ horizontale) → plus de trait qui
    // traverse les nœuds conjoints.
    final (a, b) = _hEndpoints(link.from, link.to, _halfWidth);

    // Trait bien « interrompu » : tirets nets (segments plus longs que les
    // trous) — plus lisible qu'un pointillé fin comme une liaison suspendue.
    final path = _dashedPath(a, b, link.ended ? 5 : 7, link.ended ? 5 : 4);
    canvas.drawPath(path, paint);

    // Petit point rose au milieu (alliance) — plus doux si l'union est terminée.
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    canvas.drawCircle(
      mid,
      3,
      Paint()..color = GwTokens.rose.withValues(alpha: link.ended ? 0.3 : 0.6),
    );
    return braidIndex;
  }

  /// Descente pointillée épouse → boîte foyer (maquette 2a) : petit trait
  /// vertical en pointillé fin, dans la couleur du foyer (or / rose / vert).
  void _drawFoyerDrop(Canvas canvas, LayoutLink link) {
    final base = link.color ?? neutralColor;
    final paint = Paint()
      ..color = base.withValues(alpha: link.ended ? 0.35 : 0.60)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _dashedPath(link.from, link.to, 3, 4);
    canvas.drawPath(path, paint);
  }

  /// Barre de fratrie (une par union) : trait horizontal plein reliant les
  /// enfants d'un même couple. Le layout fournit déjà les descentes verticales
  /// (liens filiation couple→enfant) ; ici on rend juste la barre nette.
  /// Union terminée : plus atténuée.
  void _drawSiblings(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = neutralColor.withValues(alpha: link.ended ? 0.20 : 0.34)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // La barre de fratrie est horizontale (même Y) : trait droit.
    canvas.drawLine(link.from, link.to, paint);
  }

  /// Affluent IA : équerre orthogonale en tirets sage (cohérent filiation).
  void _drawAiSuggestion(Canvas canvas, LayoutLink link) {
    final paint = Paint()
      ..color = GwTokens.sage.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Même routage orthogonal que la filiation, mais rendu en tirets pour
    // marquer la suggestion (non confirmée).
    final elbow = _elbowPath(link.from, link.to);
    final dashed = _dashPathMetric(elbow, 5, 5);
    canvas.drawPath(dashed, paint);
  }

  /// Découpe un `Path` quelconque (ex. équerre) en tirets, en suivant sa
  /// longueur d'arc réelle (PathMetric) — les coins arrondis restent nets.
  Path _dashPathMetric(Path source, double dashLen, double gapLen) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < metric.length) {
        final seg = draw ? dashLen : gapLen;
        final end = math.min(d + seg, metric.length);
        if (draw) {
          result.addPath(metric.extractPath(d, end), Offset.zero);
        }
        d = end;
        draw = !draw;
      }
    }
    return result;
  }

  /// Tirets sur un segment droit `from`→`to` (union). `dashLen`/`gapLen` en px.
  Path _dashedPath(Offset from, Offset to, double dashLen, double gapLen) {
    final path = Path();
    final dist = (to - from).distance;
    if (dist == 0) return path;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    double d = 0;
    bool drawing = true;
    while (d < dist) {
      final seg = drawing ? dashLen : gapLen;
      final end = math.min(d + seg, dist);
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
