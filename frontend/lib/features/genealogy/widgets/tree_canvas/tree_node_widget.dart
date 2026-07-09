import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

// ── Géométrie des cartes (contrat avec tree_layout_provider) ──
// Carte standard 230×84 (centres), mini-carte enfant de foyer 200×48
// (empilée dans une rangée de 56 px à l'intérieur de la boîte pointillée).

/// Largeur d'un nœud-carte standard (maquettes 1a/2a : ~230×84).
const double kTreeNodeWidth = 230;

/// Hauteur d'un nœud-carte standard.
const double kTreeNodeHeight = 84;

/// Largeur du nœud SUJET (même carte que le standard dans la maquette).
const double kTreeSubjectWidth = 230;

/// Mini-carte enfant EMPILÉE dans une boîte foyer (maquette 2a : ~200×48).
const double kTreeMiniNodeWidth = 200;

/// Hauteur d'une mini-carte enfant de foyer.
const double kTreeMiniNodeHeight = 48;

/// Brun charte — pilules « ♛ CHEF DE FAMILLE », « VOUS », « SUCCESSEUR ».
const Color _kBrown = Color(0xFF3B2A16);

/// Texte crème posé sur le brun charte.
const Color _kCream = Color(0xFFFAF6EE);

/// Nœud-carte « Tissage » (maquettes 1a/2a) : carte blanche horizontale,
/// coins 12 px, liseré fin ; badge circulaire à initiales serif à gauche
/// (anneau or lignée sujet / rose lignée alliée / couleur de foyer) ;
/// à droite nom gras serif, ligne dates·lieu grise, pilules mono.
///
/// Variantes :
/// - sujet (« VOUS ») : fond or très pâle, bordure or 1.5 px, badge plein or ;
/// - chef de famille (maquette 2a) : même fond or pâle + pilule brune ♛ ;
/// - épouse d'un foyer : bordure + anneau de la couleur du foyer, pilule
///   « ÉPOUSE N » teintée ;
/// - enfant de foyer : mini-carte compacte 200×48.
///
/// Performance : seul le nœud SUJET instancie un AnimationController
/// (pulse d'opacité du halo). Tous les autres nœuds sont Stateless.
class TreeNodeWidget extends StatelessWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    if (node.inFoyerBox) {
      return _MiniChildNode(
        node: node,
        isSelected: isSelected,
        isHovered: isHovered,
        onTap: onTap,
        onHover: onHover,
      );
    }
    if (node.isSubject) {
      return _SubjectNode(
        node: node,
        isSelected: isSelected,
        isHovered: isHovered,
        onTap: onTap,
        onHover: onHover,
      );
    }
    return _StandardNode(
      node: node,
      isSelected: isSelected,
      isHovered: isHovered,
      onTap: onTap,
      onHover: onHover,
    );
  }
}

/// Enveloppe commune hover/tap : léger scale au survol, curseur main.
class _NodeShell extends StatelessWidget {
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final Widget child;

  const _NodeShell({
    required this.isHovered,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) {
        // Defer to next frame to avoid mouse_tracker assertion on Flutter Web
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onHover(false);
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }
}

// ── Nœud sujet (« VOUS ») : fond or pâle, halo à opacité pulsée ──

class _SubjectNode extends StatefulWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _SubjectNode({
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_SubjectNode> createState() => _SubjectNodeState();
}

class _SubjectNodeState extends State<_SubjectNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _haloOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _haloOpacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final node = widget.node;
    final p = node.person;

    return _NodeShell(
      isHovered: widget.isHovered,
      onTap: widget.onTap,
      onHover: widget.onHover,
      child: Stack(
        children: [
          // Halo FIXE : seule l'opacité pulse (FadeTransition), jamais
          // de Transform.scale — le repaint reste local au RepaintBoundary.
          Positioned.fill(
            child: FadeTransition(
              opacity: _haloOpacity,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x24C9A84C), // gold 14 %
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: kTreeSubjectWidth,
            height: kTreeNodeHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              // Fond OR très pâle : goldBg (translucide) aplati sur la carte.
              color: Color.alphaBlend(t.goldBg, t.inkCard),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GwTokens.gold
                    .withValues(alpha: widget.isSelected ? 1.0 : 0.75),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Badge initiales PLEIN OR.
                _avatar(t, p,
                    size: 40, ringColor: GwTokens.gold, solid: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${p.firstName} ${p.lastName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GwType.display(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: t.stone),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Pilule sombre « VOUS » à droite du nom.
                          _brownPill('VOUS'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lifeline(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                            fontSize: 11.5, height: 1.15, color: t.stoneDim),
                      ),
                      const SizedBox(height: 4),
                      _pillRow([
                        if (node.isChief)
                          _brownPill('CHEF DE FAMILLE', icon: Symbols.crown)
                        else if (p.clan != null && p.clan!.isNotEmpty)
                          _tintPill('CLAN ${p.clan!.toUpperCase()}',
                              GwTokens.gold),
                        if (p.isAlive) _alivePill(p),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nœud standard (Stateless) : carte blanche maquette 1a/2a ──

class _StandardNode extends StatelessWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _StandardNode({
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  /// Épouse d'un foyer polygame (maquette 2a) : bordure + anneau + pilule
  /// « ÉPOUSE N » de la couleur du foyer.
  bool get _isWife => node.foyerColor != null && !node.inFoyerBox;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final p = node.person;
    final isAi = node.type == NodeType.aiSuggestion;
    final ringColor = _lineageColor(node);

    // Liseré : fin t.line par défaut ; couleur de foyer pour une épouse ;
    // or à la sélection ; sage pour la suggestion IA.
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      borderColor = GwTokens.gold;
      borderWidth = 1.5;
    } else if (node.isChief) {
      borderColor = GwTokens.gold.withValues(alpha: isHovered ? 1.0 : 0.75);
      borderWidth = 1.5;
    } else if (_isWife) {
      borderColor =
          node.foyerColor!.withValues(alpha: isHovered ? 1.0 : 0.7);
      borderWidth = 1.2;
    } else if (isAi) {
      borderColor = GwTokens.sage.withValues(alpha: isHovered ? 0.9 : 0.55);
      borderWidth = 1.2;
    } else {
      borderColor = isHovered ? t.lineMid : t.line;
      borderWidth = 1;
    }

    return _NodeShell(
      isHovered: isHovered,
      onTap: onTap,
      onHover: onHover,
      child: Container(
        width: kTreeNodeWidth,
        height: kTreeNodeHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          // Chef de famille : même fond or pâle que le sujet ; sinon BLANC.
          color: node.isChief
              ? Color.alphaBlend(t.goldBg, t.inkCard)
              : t.inkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (isSelected || isHovered)
              BoxShadow(
                color: (isSelected ? GwTokens.gold : ringColor)
                    .withValues(alpha: 0.18),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            if (isAi)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GwTokens.sageBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: GwTokens.sage, width: 2),
                ),
                child:
                    Icon(Symbols.auto_awesome, size: 17, color: t.sageText),
              )
            else
              _avatar(t, p,
                  size: 40,
                  ringColor: ringColor,
                  solid: node.isChief),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.firstName} ${p.lastName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: t.stone),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metaLine(node),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 11.5, height: 1.15, color: t.stoneDim),
                  ),
                  const SizedBox(height: 4),
                  _pillRow(_pills(t)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pilules mono (maquette) : chef ♛ / épouse N / clan-lignée, VIVANT·E,
  /// rang d'union, TERMINÉE, conformité douce, DOT.
  List<Widget> _pills(GwTokens t) {
    final p = node.person;
    final info = node.unionInfo;
    final pills = <Widget>[];

    if (node.isChief) {
      pills.add(_brownPill('CHEF DE FAMILLE', icon: Symbols.crown));
    } else if (_isWife) {
      final rank = info?.rank ?? 1;
      pills.add(_tintPill('ÉPOUSE $rank', node.foyerColor!));
    } else {
      final badge = _badgeText(node);
      if (badge != null) pills.add(_tintPill(badge, _badgeColor(node)));
    }

    // Personne vivante : petite pilule verte + point vert.
    if (p.isAlive && node.type != NodeType.aiSuggestion) {
      pills.add(_alivePill(p));
    }

    // Rang d'union (mode monogame 1a — les foyers 2a portent déjà ÉPOUSE N).
    if (!_isWife && info != null && (info.isPolygamous || info.rank >= 2)) {
      pills.add(_tintPill(_rankLabel(info.rank), GwTokens.gold));
    }
    if (info != null && !info.isActive) {
      pills.add(_tintPill('TERMINÉE', t.stoneFaint));
    }
    // Conformité au droit civil — ton ember doux, jamais de rouge dur,
    // jamais de « légitimité ».
    if (info != null &&
        (info.compliance == UnionCompliance.warning ||
            info.compliance == UnionCompliance.nonCompliant)) {
      pills.add(_tintPill('À VÉRIFIER', GwTokens.ember));
    }

    if (node.hasDotPaid) pills.add(_tintPill('DOT', GwTokens.gold));

    return pills;
  }
}

// ── Mini-carte enfant de foyer (maquette 2a, ~200×48) ─────────

class _MiniChildNode extends StatelessWidget {
  final LayoutNode node;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _MiniChildNode({
    required this.node,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final p = node.person;
    final color = node.foyerColor ?? GwTokens.gold;

    final Color borderColor = isSelected
        ? GwTokens.gold
        : isHovered
            ? color.withValues(alpha: 0.7)
            : t.line;

    return _NodeShell(
      isHovered: isHovered,
      onTap: onTap,
      onHover: onHover,
      child: Container(
        width: kTreeMiniNodeWidth,
        height: kTreeMiniNodeHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: t.inkCard, // mini-carte BLANCHE
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: [
            if (isSelected || isHovered)
              BoxShadow(
                color: color.withValues(alpha: 0.16),
                blurRadius: 10,
              ),
          ],
        ),
        child: Row(
          children: [
            _avatar(t, p, size: 28, ringColor: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.firstName} ${p.lastName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: t.stone),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    // « 1969 · Yaoundé » — le rang dans le foyer (« aîné·e du
                    // foyer ») n'est pas encore exposé par LayoutNode : hook
                    // prêt le jour où le layout portera cette méta.
                    _miniLifeline(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 11, height: 1.1, color: t.stoneDim),
                  ),
                ],
              ),
            ),
            // Hook « SUCCESSEUR » : le modèle n'expose pas encore d'héritier
            // désigné — dès qu'un flag existera, rendre ici :
            // _brownPill('SUCCESSEUR').
          ],
        ),
      ),
    );
  }
}

// ── Éléments partagés ────────────────────────────────────────

/// Badge circulaire à initiales serif : fond ivoire clair + anneau 2 px de
/// la couleur de lignée/foyer, ou PLEIN OR (sujet, chef).
Widget _avatar(
  GwTokens t,
  PersonGenealogy p, {
  required double size,
  required Color ringColor,
  bool solid = false,
}) {
  final first = p.firstName.isNotEmpty ? p.firstName[0] : '';
  final last = p.lastName.isNotEmpty ? p.lastName[0] : '';
  final initials = '$first$last'.toUpperCase();

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: solid ? GwTokens.gold : t.inkLift,
      border: solid ? null : Border.all(color: ringColor, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: p.photoUrl != null
        ? CachedNetworkImage(
            imageUrl: p.photoUrl!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorWidget: (_, __, ___) => Text(
              initials,
              style: GwType.display(
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w600,
                  color: solid ? GwTokens.inkOnGold : t.stone),
            ),
          )
        : Text(
            initials,
            style: GwType.display(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w600,
                color: solid ? GwTokens.inkOnGold : t.stone),
          ),
  );
}

/// Rangée de pilules sur UNE ligne : FittedBox scaleDown pour que la carte
/// garde sa hauteur fixe de 84 px quel que soit le nombre de pilules.
Widget _pillRow(List<Widget> pills) {
  if (pills.isEmpty) return const SizedBox(height: 15);
  return SizedBox(
    height: 15,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            pills[i],
          ],
        ],
      ),
    ),
  );
}

/// Pilule mono teintée : fond couleur 10 %, texte couleur (maquette).
Widget _tintPill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(GwTokens.rPill),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: GwType.mono(fontSize: 9, color: color, letterSpacing: 1.5),
    ),
  );
}

/// Pilule brune charte (« ♛ CHEF DE FAMILLE », « VOUS », « SUCCESSEUR »).
Widget _brownPill(String text, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _kBrown,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: _kCream),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          maxLines: 1,
          style:
              GwType.mono(fontSize: 9, color: _kCream, letterSpacing: 1.5),
        ),
      ],
    ),
  );
}

/// Pilule verte « VIVANT·E » avec point vert (maquette 1a).
Widget _alivePill(PersonGenealogy p) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: GwTokens.sage.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(GwTokens.rPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: GwTokens.sage,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          p.gender == 'FEMALE' ? 'VIVANTE' : 'VIVANT',
          maxLines: 1,
          style: GwType.mono(
              fontSize: 9, color: GwTokens.sage, letterSpacing: 1.5),
        ),
      ],
    ),
  );
}

/// Couleur de lignée de l'anneau du badge : or lignée sujet / rose lignée
/// alliée / sage IA — une épouse de foyer prend la couleur de SON foyer.
Color _lineageColor(LayoutNode node) {
  if (node.foyerColor != null) return node.foyerColor!;
  switch (node.type) {
    case NodeType.subject:
    case NodeType.primaryLineage:
    case NodeType.founder:
    case NodeType.ancestor:
      return GwTokens.gold;
    case NodeType.secondaryLineage:
    case NodeType.spouse:
      return GwTokens.rose;
    case NodeType.aiSuggestion:
      return GwTokens.sage;
  }
}

Color _badgeColor(LayoutNode node) {
  switch (node.type) {
    case NodeType.aiSuggestion:
      return GwTokens.sage;
    case NodeType.secondaryLineage:
    case NodeType.spouse:
      return GwTokens.rose;
    default:
      return GwTokens.gold;
  }
}

String? _badgeText(LayoutNode n) {
  final p = n.person;
  if (n.type == NodeType.aiSuggestion) return 'AFFLUENT PROBABLE';
  if (n.type == NodeType.secondaryLineage || n.type == NodeType.spouse) {
    return 'LIGNÉE ${p.lastName.toUpperCase()}';
  }
  if (p.clan != null && p.clan!.isNotEmpty) {
    return 'CLAN ${p.clan!.toUpperCase()}';
  }
  return null;
}

/// Ligne méta d'un nœud standard : « ✦ » discret pour les ancêtres dont le
/// décès n'est pas renseigné — jamais de noir « décédé ».
String _metaLine(LayoutNode node) {
  final base = _lifeline(node.person);
  if (node.type == NodeType.ancestor &&
      node.person.isAlive &&
      !base.contains('✦')) {
    return '$base ✦';
  }
  return base;
}

/// Dates · lieu (maquette) :
/// - vivant·e : « né·e en 1944 · Yaoundé » ;
/// - décédé·e : « 1912 – ✦ · Bafoussam » — tiret demi-cadratin, le « ✦ »
///   tient lieu d'année de décès (non portée par le modèle), jamais de noir.
String _lifeline(PersonGenealogy p) {
  final birth = p.birthDate?.year;
  final place = p.birthPlace;
  final parts = <String>[];
  if (!p.isAlive) {
    if (birth != null) parts.add('$birth – ✦');
    if (place != null && place.isNotEmpty) parts.add(place);
    return parts.isEmpty ? '✦' : parts.join(' · ');
  }
  if (birth != null) {
    parts.add(p.gender == 'FEMALE' ? 'née en $birth' : 'né en $birth');
  }
  if (place != null && place.isNotEmpty) parts.add(place);
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// Sous-ligne d'une mini-carte enfant : « 1969 · Yaoundé ».
String _miniLifeline(PersonGenealogy p) {
  final parts = <String>[
    if (p.birthDate != null) '${p.birthDate!.year}',
    if (p.birthPlace != null && p.birthPlace!.isNotEmpty) p.birthPlace!,
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _rankLabel(int rank) {
  switch (rank) {
    case 1:
      return '1RE UNION';
    case 2:
      return '2E UNION';
    case 3:
      return '3E UNION';
    default:
      return '${rank}E UNION';
  }
}
