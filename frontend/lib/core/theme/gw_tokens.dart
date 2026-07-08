import 'package:flutter/material.dart';

/// GwTokens — source unique des design tokens « Tissage » GWANG MEU.
///
/// Remplace les trois systèmes historiques :
/// `AppColors` (app_theme.dart), `GwColors` (gw_colors.dart) et
/// `T` (tree_tokens.dart).
///
/// Usage adaptatif (recommandé) :
/// ```dart
/// final t = GwTokens.of(context);
/// Container(color: t.inkCard, child: Text('…', style: TextStyle(color: t.stone)));
/// ```
/// Les palettes `GwTokens.dark` et `GwTokens.light` sont aussi accessibles
/// directement pour les rares contextes sans BuildContext.
class GwTokens {
  const GwTokens._({
    required this.brightness,
    // Fonds
    required this.inkDeep,
    required this.ink,
    required this.inkCard,
    required this.inkLift,
    required this.inkHigh,
    // Or
    required this.goldText,
    required this.goldBg,
    required this.goldLine,
    required this.goldGlow,
    // Texte
    required this.stone,
    required this.stoneMid,
    required this.stoneDim,
    required this.stoneFaint,
    // Lignes
    required this.line,
    required this.lineMid,
    // Sémantiques (texte adapté au thème)
    required this.sageText,
    required this.emberText,
    required this.azureText,
  });

  final Brightness brightness;

  // ── Fonds ─────────────────────────────────────────────────────
  /// Fond le plus profond (splash, zones immersives). Dark: #080709 · Light: paperWarm.
  final Color inkDeep;

  /// Fond d'écran principal. Dark: ink #0C0B0F · Light: paper #FAF6EE.
  final Color ink;

  /// Fond des cartes. Dark: #16141B · Light: blanc pur.
  final Color inkCard;

  /// Surfaces interactives (pilules d'action, inputs). Dark: #1C1A22 · Light: paperRaise.
  final Color inkLift;

  /// Surface la plus élevée (badges de code, tooltips). Dark: #2E2B3C.
  final Color inkHigh;

  // ── Or (accent) ───────────────────────────────────────────────
  /// Texte/icônes or garantissant le contraste AA sur le fond du thème.
  /// Dark: gold #C9A84C · Light: goldDeep #9A7810.
  final Color goldText;

  /// Fond or translucide (~14-16 %) pour pilules actives et encarts.
  final Color goldBg;

  /// Bordure or translucide (~30-45 %).
  final Color goldLine;

  /// Halo or (glow du sujet dans l'arbre, cartes mises en avant).
  final Color goldGlow;

  // ── Texte ─────────────────────────────────────────────────────
  /// Texte principal. Dark: stone #F0EBE1 · Light: #231F18.
  final Color stone;

  /// Texte secondaire. Dark: #B8AD9E · Light: #6B6255.
  final Color stoneMid;

  /// Hint / placeholder (AA). Dark: #8A8172 · Light: #857B6B.
  final Color stoneDim;

  /// Méta uniquement, jamais sous 12 px. Dark: #7A7268.
  final Color stoneFaint;

  // ── Lignes / bordures ─────────────────────────────────────────
  final Color line;
  final Color lineMid;

  // ── Sémantiques : variantes texte lisibles sur le thème ──────
  /// Texte sage (IA / succès). Dark: #70C090 · Light: #1E6B4A.
  final Color sageText;

  /// Texte ember (live / alerte / non-lus). Dark: #E09080 · Light: #B04830.
  final Color emberText;

  /// Texte azure (diaspora / info). Dark: #7AA8E0 · Light: #2E5A9A.
  final Color azureText;

  /// Résout la palette selon le thème actif.
  static GwTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ══════════════════════════════════════════════════════════════
  //  CONSTANTES PARTAGÉES (identiques sur les deux thèmes)
  // ══════════════════════════════════════════════════════════════

  // ── Or — un seul (l'ancien #C8A020 disparaît) ────────────────
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);

  /// Texte/actions or sur thème clair (contraste AA).
  static const goldDeep = Color(0xFF9A7810);

  /// Texte/icône posé sur un fond or (ou tuile teintée) — identique
  /// sur les deux thèmes.
  static const inkOnGold = Color(0xFF0C0B0F);

  // ── Sémantiques ──────────────────────────────────────────────
  /// IA / succès.
  static const sage = Color(0xFF2A7A5C);
  static const sageBg = Color(0x242A7A5C); // ~14 %
  static const sageLine = Color(0x592A7A5C); // ~35 %

  /// Live / alerte / non-lus.
  static const ember = Color(0xFFC4583A);
  static const emberBg = Color(0x24C4583A);
  static const emberLine = Color(0x59C4583A);

  /// Diaspora / info.
  static const azure = Color(0xFF3A6CB4);
  static const azureBg = Color(0x243A6CB4);
  static const azureLine = Color(0x593A6CB4);

  /// Lignée secondaire de l'arbre (rose cuivré).
  static const rose = Color(0xFFC878A0);
  static const roseBg = Color(0x24C878A0);
  static const roseLine = Color(0x59C878A0);

  // ── Rayons ───────────────────────────────────────────────────
  /// Cartes : 18–20 px.
  static const double rCard = 18;
  static const double rCardLg = 20;

  /// Boutons / inputs : 14 px.
  static const double rBtn = 14;

  /// Pilules : 99 px.
  static const double rPill = 99;

  // ── Cibles tactiles ──────────────────────────────────────────
  /// Cible tactile minimale (a11y bloquante).
  static const double tapTarget = 44;

  // ── Bande tissée signature ───────────────────────────────────
  /// Hauteur de la bande tissée en haut de chaque écran.
  static const double weaveHeight = 4;

  /// Segments du motif tissé : gold 0→28, sage 28→40, gold 40→68, ember 68→80.
  static const List<Color> weaveColors = [gold, sage, gold, ember];
  static const List<double> weaveStops = [28, 12, 28, 12];

  // ══════════════════════════════════════════════════════════════
  //  PALETTES
  // ══════════════════════════════════════════════════════════════

  static const dark = GwTokens._(
    brightness: Brightness.dark,
    inkDeep: Color(0xFF080709),
    ink: Color(0xFF0C0B0F),
    inkCard: Color(0xFF16141B),
    inkLift: Color(0xFF1C1A22),
    inkHigh: Color(0xFF2E2B3C),
    goldText: gold,
    goldBg: Color(0x29C9A84C), // 16 %
    goldLine: Color(0x73C9A84C), // 45 %
    goldGlow: Color(0x33C9A84C), // 20 %
    stone: Color(0xFFF0EBE1),
    stoneMid: Color(0xFFB8AD9E),
    stoneDim: Color(0xFF8A8172),
    stoneFaint: Color(0xFF7A7268),
    line: Color(0x1AFFFFFF), // 10 %
    lineMid: Color(0x2EFFFFFF), // 18 %
    sageText: Color(0xFF70C090),
    emberText: Color(0xFFE09080),
    azureText: Color(0xFF7AA8E0),
  );

  static const light = GwTokens._(
    brightness: Brightness.light,
    inkDeep: Color(0xFFF5EDDD), // paperWarm
    ink: Color(0xFFFAF6EE), // paper
    inkCard: Color(0xFFFFFFFF),
    inkLift: Color(0xFFF0E8D8), // paperRaise
    inkHigh: Color(0xFFE8DEC8),
    goldText: goldDeep,
    goldBg: Color(0x26C9A84C), // 15 %
    goldLine: Color(0x809A7810), // 50 %
    goldGlow: Color(0x2EC9A84C),
    stone: Color(0xFF231F18),
    stoneMid: Color(0xFF6B6255),
    stoneDim: Color(0xFF857B6B),
    stoneFaint: Color(0xFF968C7A),
    line: Color(0x14000000), // 8 %
    lineMid: Color(0x24000000), // 14 %
    sageText: Color(0xFF1E6B4A),
    emberText: Color(0xFFB04830),
    azureText: Color(0xFF2E5A9A),
  );
}

/// GwType — les 3 familles typographiques « Tissage », bundlées dans
/// `assets/fonts/` (subset latin, variantes statiques — aucun accès réseau).
///
/// - **Fraunces** (serif) : titres, citations, récits, initiales d'avatars.
/// - **Syne** (sans) : interface. Corps 15 px, secondaire 14 px, minimum 12 px.
/// - **JetBrains Mono** : méta, badges, labels de section (10–12 px,
///   letter-spacing 1.5–2.5, MAJUSCULES).
abstract final class GwType {
  static const String _fraunces = 'Fraunces';
  static const String _syne = 'Syne';
  static const String _jetBrainsMono = 'JetBrainsMono';

  /// Fraunces — titres & récits.
  static TextStyle display({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _fraunces,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Fraunces italique — citations & récits (17–19 px).
  static TextStyle quote({
    double fontSize = 17,
    Color? color,
    double? height,
    FontWeight fontWeight = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: _fraunces,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: FontStyle.italic,
        color: color,
        height: height ?? 1.5,
      );

  /// Syne — interface & corps de texte.
  static TextStyle ui({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: _syne,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  /// JetBrains Mono — méta, badges, labels de section. Jamais sous 10 px,
  /// texte porteur d'information ≥ 12 px.
  static TextStyle mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double letterSpacing = 1.5,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _jetBrainsMono,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}

/// Bande tissée signature — 4 px en haut de chaque écran.
///
/// Équivalent du CSS
/// `repeating-linear-gradient(90deg, gold 0 28px, sage 28px 40px,
/// gold 40px 68px, ember 68px 80px)`.
class GwWeaveBand extends StatelessWidget {
  const GwWeaveBand({super.key, this.height = GwTokens.weaveHeight});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const CustomPaint(painter: _WeavePainter()),
    );
  }
}

class _WeavePainter extends CustomPainter {
  const _WeavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    double x = 0;
    int i = 0;
    while (x < size.width) {
      final w = GwTokens.weaveStops[i % GwTokens.weaveStops.length];
      paint.color = GwTokens.weaveColors[i % GwTokens.weaveColors.length];
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _WeavePainter oldDelegate) => false;
}

/// Barre tissée verticale (gabarit de post « citation », 4–5 px de large).
class GwWeaveBarVertical extends StatelessWidget {
  const GwWeaveBarVertical({super.key, this.width = 5});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: const CustomPaint(painter: _WeaveVerticalPainter()),
    );
  }
}

class _WeaveVerticalPainter extends CustomPainter {
  const _WeaveVerticalPainter();

  // Motif vertical : gold 0→14, sage 14→20, gold 20→34, ember 34→40.
  static const _stops = [14.0, 6.0, 14.0, 6.0];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    double y = 0;
    int i = 0;
    while (y < size.height) {
      final h = _stops[i % _stops.length];
      paint.color = GwTokens.weaveColors[i % GwTokens.weaveColors.length];
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
      y += h;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _WeaveVerticalPainter oldDelegate) => false;
}
