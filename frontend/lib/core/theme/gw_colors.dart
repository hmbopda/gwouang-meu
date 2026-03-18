import 'package:flutter/material.dart';

/// Palette de design tokens GWANG MEU — adaptative dark/light.
///
/// Usage : `final c = GwColors.of(context);` puis `c.ink`, `c.gold`, etc.
/// Les couleurs sémantiques (sage, ember, azure) restent identiques
/// sur les deux thèmes ; seuls les fonds, textes et lignes s'inversent.
class GwColors {
  const GwColors._({
    // Backgrounds
    required this.ink,
    required this.inkDeep,
    required this.inkLift,
    required this.inkRaise,
    required this.inkHigh,
    // Gold accent
    required this.gold,
    required this.goldLight,
    required this.goldDim,
    required this.goldFaint,
    required this.goldLine,
    required this.goldGlow,
    // Text
    required this.stone,
    required this.stoneMid,
    required this.stoneDim,
    required this.stoneFaint,
    // Lines
    required this.line,
    required this.lineMid,
    // Semantic
    required this.sage,
    required this.sageBg,
    required this.sageLine,
    required this.ember,
    required this.emberBg,
    required this.emberLine,
    required this.azure,
    required this.azureBg,
    required this.azureLine,
    // Light accent text variants
    required this.sageLight,
    required this.emberLight,
    required this.azureLight,
  });

  // ── Backgrounds ──
  final Color ink;
  final Color inkDeep;
  final Color inkLift;
  final Color inkRaise;
  final Color inkHigh;

  // ── Gold accent ──
  final Color gold;
  final Color goldLight;
  final Color goldDim;
  final Color goldFaint;
  final Color goldLine;
  final Color goldGlow;

  // ── Text ──
  final Color stone;
  final Color stoneMid;
  final Color stoneDim;
  final Color stoneFaint;

  // ── Lines / borders ──
  final Color line;
  final Color lineMid;

  // ── Semantic ──
  final Color sage;
  final Color sageBg;
  final Color sageLine;
  final Color ember;
  final Color emberBg;
  final Color emberLine;
  final Color azure;
  final Color azureBg;
  final Color azureLine;

  // ── Light accent text ──
  final Color sageLight;
  final Color emberLight;
  final Color azureLight;

  /// Résout la palette en fonction du thème actif.
  static GwColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // ════════════════════════════════════════════
  //  DARK
  // ════════════════════════════════════════════
  static const dark = GwColors._(
    ink: Color(0xFF0C0B0F),
    inkDeep: Color(0xFF080709),
    inkLift: Color(0xFF1C1A22),
    inkRaise: Color(0xFF242230),
    inkHigh: Color(0xFF2E2B3C),
    gold: Color(0xFFC9A84C),
    goldLight: Color(0xFFE8C96A),
    goldDim: Color(0xFF7A6028),
    goldFaint: Color(0x1EC9A84C),
    goldLine: Color(0x2EC9A84C),
    goldGlow: Color(0x1FC9A84C),
    stone: Color(0xFFF0EBE1),
    stoneMid: Color(0xFFB8AD9E),
    stoneDim: Color(0xFF7A7268),
    stoneFaint: Color(0xFF3C3830),
    line: Color(0x0FFFFFFF),
    lineMid: Color(0x1AFFFFFF),
    sage: Color(0xFF2A7A5C),
    sageBg: Color(0x1A2A7A5C),
    sageLine: Color(0x382A7A5C),
    ember: Color(0xFFC4583A),
    emberBg: Color(0x1AC4583A),
    emberLine: Color(0x38C4583A),
    azure: Color(0xFF3A6CB4),
    azureBg: Color(0x1A3A6CB4),
    azureLine: Color(0x383A6CB4),
    sageLight: Color(0xFF70C090),
    emberLight: Color(0xFFE09080),
    azureLight: Color(0xFF7AA8E0),
  );

  // ════════════════════════════════════════════
  //  LIGHT
  // ════════════════════════════════════════════
  static const light = GwColors._(
    ink: Color(0xFFFAFAF8),
    inkDeep: Color(0xFFF5F2EE),
    inkLift: Color(0xFFEDE8E0),
    inkRaise: Color(0xFFE5E0D8),
    inkHigh: Color(0xFFDDD8D0),
    gold: Color(0xFFC9A84C),
    goldLight: Color(0xFF9A7810),
    goldDim: Color(0xFF8A6828),
    goldFaint: Color(0x18C9A84C),
    goldLine: Color(0x30C9A84C),
    goldGlow: Color(0x18C9A84C),
    stone: Color(0xFF1A1A1A),
    stoneMid: Color(0xFF555555),
    stoneDim: Color(0xFF888888),
    stoneFaint: Color(0xFFBBB8B0),
    line: Color(0x12000000),
    lineMid: Color(0x1A000000),
    sage: Color(0xFF1E6B4A),
    sageBg: Color(0x1A2A7A5C),
    sageLine: Color(0x382A7A5C),
    ember: Color(0xFFB04830),
    emberBg: Color(0x1AC4583A),
    emberLine: Color(0x38C4583A),
    azure: Color(0xFF2E5A9A),
    azureBg: Color(0x1A3A6CB4),
    azureLine: Color(0x383A6CB4),
    sageLight: Color(0xFF1E6B4A),
    emberLight: Color(0xFFB04830),
    azureLight: Color(0xFF2E5A9A),
  );
}
