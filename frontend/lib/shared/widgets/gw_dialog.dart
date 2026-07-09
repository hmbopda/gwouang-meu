import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';

/// Mode de présentation d'un [GwDialog].
enum GwDialogMode { dialog, sheet }

/// Scope interne : indique à [GwDialog] s'il est présenté en dialog centré
/// (desktop / tablette) ou en bottom-sheet (mobile).
class GwDialogScope extends InheritedWidget {
  const GwDialogScope({super.key, required this.mode, required super.child});

  final GwDialogMode mode;

  static GwDialogMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GwDialogScope>()?.mode ??
      GwDialogMode.dialog;

  @override
  bool updateShouldNotify(GwDialogScope oldWidget) => mode != oldWidget.mode;
}

/// Ouvre un [GwDialog] de façon adaptative : dialog centré sur écran
/// large (≥ 600 px), bottom-sheet plein-largeur sur mobile.
Future<T?> showGwDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final isCompact = MediaQuery.of(context).size.width < 600;
  if (isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GwDialogScope(
        mode: GwDialogMode.sheet,
        child: Builder(builder: builder),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => GwDialogScope(
      mode: GwDialogMode.dialog,
      child: Builder(builder: builder),
    ),
  );
}

/// Action affichée dans la rangée du bas d'un [GwDialog].
///
/// Une action `primary` est rendue en bouton or plein (hauteur 50, rayon 14) ;
/// les autres en boutons texte discrets (cible ≥ 44 px).
class GwDialogAction {
  const GwDialogAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.primary = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool loading;
}

/// Conteneur de dialog « Tissage » réutilisable.
///
/// Fond [GwTokens.inkCard], rayon 20, bande tissée optionnelle en haut,
/// titre Fraunces, bouton fermer 44 px, zone de contenu scrollable et
/// rangée d'actions (primaire or plein 50 px + secondaires discrets).
///
/// Présenté via [showGwDialog], il devient bottom-sheet sur mobile.
class GwDialog extends StatelessWidget {
  const GwDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.actions = const [],
    this.maxWidth = 480,
    this.showWeave = true,
    this.contentPadding = const EdgeInsets.all(20),
    this.onClose,
  });

  /// Titre (Fraunces 18–20).
  final String title;

  /// Sous-titre optionnel (méta, ≥ 12 px).
  final String? subtitle;

  /// Icône optionnelle affichée dans une pastille or à gauche du titre.
  final IconData? icon;

  /// Contenu principal, enveloppé dans un scroll.
  final Widget child;

  /// Actions du bas. Vide → pas de rangée d'actions.
  final List<GwDialogAction> actions;

  /// Largeur maximale en mode dialog centré.
  final double maxWidth;

  /// Affiche la bande tissée signature en haut.
  final bool showWeave;

  final EdgeInsetsGeometry contentPadding;

  /// Callback du bouton fermer (défaut : `Navigator.maybePop`).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final mode = GwDialogScope.of(context);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showWeave) const GwWeaveBand(),
        if (mode == GwDialogMode.sheet)
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: t.lineMid,
              borderRadius: BorderRadius.circular(GwTokens.rPill),
            ),
          ),
        _header(context, t),
        Container(height: 1, color: t.line),
        Flexible(
          child: SingleChildScrollView(
            padding: contentPadding,
            child: child,
          ),
        ),
        if (actions.isNotEmpty) _actionsRow(context, t),
      ],
    );

    if (mode == GwDialogMode.sheet) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(GwTokens.rCardLg)),
            border: Border.all(color: t.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(top: false, child: body),
        ),
      );
    }

    return Dialog(
      backgroundColor: t.inkCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: body,
      ),
    );
  }

  Widget _header(BuildContext context, GwTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: t.goldLine),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: t.goldText),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.display(fontSize: 19, color: t.stone),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(fontSize: 12, color: t.stoneMid),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: GwTokens.tapTarget,
            height: GwTokens.tapTarget,
            child: IconButton(
              tooltip: 'Fermer',
              onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Symbols.close, size: 22, color: t.stoneMid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow(BuildContext context, GwTokens t) {
    final primaries = actions.where((a) => a.primary).toList();
    final secondaries = actions.where((a) => !a.primary).toList();

    final Widget row;
    if (primaries.isEmpty) {
      row = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < secondaries.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _secondaryButton(t, secondaries[i]),
          ],
        ],
      );
    } else {
      row = Row(
        children: [
          for (final a in secondaries) ...[
            _secondaryButton(t, a),
            const SizedBox(width: 4),
          ],
          if (secondaries.isNotEmpty) const SizedBox(width: 4),
          Expanded(child: _primaryButton(t, primaries.first)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: row,
    );
  }

  Widget _primaryButton(GwTokens t, GwDialogAction a) {
    const inkOnGold = Color(0xFF0C0B0F);
    final enabled = a.onPressed != null && !a.loading;
    return SizedBox(
      height: 50,
      child: Material(
        color: enabled || a.loading ? GwTokens.gold : t.inkLift,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: enabled ? a.onPressed : null,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Center(
            child: a.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: inkOnGold,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a.icon != null) ...[
                        Icon(a.icon, size: 18,
                            color: enabled ? inkOnGold : t.stoneDim),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GwType.ui(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: enabled ? inkOnGold : t.stoneDim,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton(GwTokens t, GwDialogAction a) {
    return TextButton(
      onPressed: a.loading ? null : a.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: t.stoneMid,
        minimumSize: const Size(GwTokens.tapTarget, GwTokens.tapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (a.icon != null) ...[
            Icon(a.icon, size: 18, color: t.stoneMid),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              a.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GwType.ui(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.stoneMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Décoration d'input « Tissage » : fond [GwTokens.inkLift], rayon 14,
/// focus or, erreurs ember. À utiliser sur tous les champs des dialogs.
InputDecoration gwInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  bool dense = false,
  bool alignLabelWithHint = false,
}) {
  final t = GwTokens.of(context);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    labelStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
    floatingLabelStyle: GwType.ui(fontSize: 13, color: t.goldText),
    hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 20, color: t.stoneDim)
        : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: t.inkLift,
    isDense: dense,
    contentPadding:
        EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 12 : 14),
    border: border(t.line),
    enabledBorder: border(t.line),
    focusedBorder: border(t.goldLine, 1.4),
    errorBorder: border(GwTokens.emberLine),
    focusedErrorBorder: border(GwTokens.ember, 1.4),
    errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
  );
}

/// Label de section : JetBrains Mono majuscules, ≥ 12 px.
class GwSectionLabel extends StatelessWidget {
  const GwSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Text(
      text.toUpperCase(),
      style: GwType.mono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: t.stoneDim,
      ),
    );
  }
}

/// Tonalités sémantiques des encarts d'information.
enum GwBannerTone { gold, sage, ember, azure }

/// Encart d'information coloré (fond translucide + bordure + icône).
class GwInfoBanner extends StatelessWidget {
  const GwInfoBanner({
    super.key,
    required this.text,
    this.tone = GwBannerTone.azure,
    this.icon,
  });

  final String text;
  final GwBannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final (Color bg, Color line, Color fg, IconData defaultIcon) =
        switch (tone) {
      GwBannerTone.gold =>
        (t.goldBg, t.goldLine, t.goldText, Symbols.info),
      GwBannerTone.sage =>
        (GwTokens.sageBg, GwTokens.sageLine, t.sageText, Symbols.check_circle),
      GwBannerTone.ember =>
        (GwTokens.emberBg, GwTokens.emberLine, t.emberText, Symbols.warning),
      GwBannerTone.azure =>
        (GwTokens.azureBg, GwTokens.azureLine, t.azureText, Symbols.info),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GwType.ui(fontSize: 12, height: 1.4, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilule de choix or (sélecteurs des dialogs) — cible ≥ 44 px, rayon 99.
class GwChoicePill extends StatelessWidget {
  const GwChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Si vrai, centre le contenu et occupe toute la largeur disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final fg = selected ? t.goldText : t.stoneMid;
    return Material(
      color: selected ? t.goldBg : t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(color: selected ? t.goldLine : t.line),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg, fill: selected ? 1 : 0),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  // Les libellés de pilules (ex. « Dans l'arbre », « Religieuse
                  // (Église) ») peuvent passer sur 2 lignes plutôt que d'être
                  // tronqués quand la colonne est étroite (sheet mobile 3 pilules).
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GwType.ui(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? t.goldText : t.stone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
