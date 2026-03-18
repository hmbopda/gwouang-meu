import 'package:flutter/material.dart';

/// Design tokens Gwang Meu — calqués sur la maquette HTML.
abstract final class T {
  // ── Gold ─────────────────────────────────────────
  static const gold     = Color(0xFFC8A020);
  static const goldLt   = Color(0xFFF0C848);
  static const goldDk   = Color(0xFF8A6C10);
  static const goldGlow = Color(0x4CC8A020); // 30%
  static const goldBg   = Color(0x14C8A020); // 8%

  // ── Ink (backgrounds) ────────────────────────────
  static const ink  = Color(0xFF08080A);
  static const ink2 = Color(0xFF0E0E12);
  static const ink3 = Color(0xFF141418);
  static const ink4 = Color(0xFF1C1C22);
  static const ink5 = Color(0xFF242430);

  // ── Text ─────────────────────────────────────────
  static const txt1 = Color(0xFFF2EDE4);
  static const txt2 = Color(0xFFA09880);
  static const txt3 = Color(0xFF605848);

  // ── Borders ──────────────────────────────────────
  static const border  = Color(0x0FFFFFFF); // 6%
  static const border2 = Color(0x26C8A020); // 15%

  // ── Semantic ─────────────────────────────────────
  static const green   = Color(0xFF2EAA6E);
  static const greenBg = Color(0x192EAA6E); // 10%
  static const red     = Color(0xFFE85040);
  static const blue    = Color(0xFF4890E8);
  static const orange  = Color(0xFFE87828);
  static const purple  = Color(0xFF9858C8);
  static const sacred  = Color(0xFFC83860);
  static const sacredBg = Color(0x1FC83860); // 12%

  // ── Node colors by gender ────────────────────────
  static const maleNode   = Color(0xFF1C3A5A);
  static const maleBorder = Color(0xFF4890E8);
  static const femaleNode   = Color(0xFF3A1C3A);
  static const femaleBorder = Color(0xFFC850A0);
  static const deadNode = Color(0xFF1C1C1C);
  static const deadBorder = Color(0xFF404040);
  static const aiNode = Color(0xFF0D2A0D);
  static const aiBorder = Color(0xFF2EAA6E);
  static const wifeNode = Color(0xFF2A1800);
  static const wifeBorder = Color(0xFFE87828);
  static const founderBorder = Color(0xFFC83860);

  // ── Generation colors ────────────────────────────
  static const List<Color> genColors = [
    Color(0xFF8A5A00), // G0 placeholder
    Color(0xFF5A3A00), // G1
    Color(0xFF7A4A00), // G2
    Color(0xFF9A6010), // G3
    Color(0xFFC8A020), // G4 (subject)
    Color(0xFF4890E8), // G5
    Color(0xFF2EAA6E), // G6
  ];

  // ── Sizes ────────────────────────────────────────
  static const double leftPanelW  = 280;
  static const double rightPanelW = 360;
  static const double nodeRadius  = 26;
  static const double subjectRadius = 30;

  // ── Fonts (famille) ──────────────────────────────
  static const fontDisplay = 'Fraunces';
  static const fontUi      = 'Syne';
  static const fontMono    = 'JetBrains Mono';

  // ── Borders radius ───────────────────────────────
  static const r   = 14.0;
  static const rSm = 8.0;
  static const rLg = 20.0;
}
