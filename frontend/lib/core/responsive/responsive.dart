import 'package:flutter/widgets.dart';

/// Système responsive « Tissage » — un seul jeu de points de rupture partagé
/// par toute l'application (chrome de navigation + contenu des écrans).
///
/// Usage :
/// ```dart
/// if (context.isDesktop) { … }
/// switch (context.formFactor) { … }
/// ```
enum FormFactor { mobile, tablet, desktop }

/// Points de rupture (largeur logique en dp).
abstract final class Breakpoints {
  /// En dessous : téléphone (une colonne, bottom nav).
  static const double tablet = 600;

  /// À partir de : desktop (rail étendu, multi-colonnes).
  static const double desktop = 1024;

  /// Largeur maximale du contenu centré sur grand écran (évite l'étirement
  /// « bande mobile » ou « ligne infinie » sur les moniteurs larges).
  static const double contentMax = 1180;

  /// Largeur maximale d'une colonne de lecture unique (fil, formulaire).
  static const double readingMax = 680;
}

extension ResponsiveContext on BuildContext {
  /// Largeur logique courante.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final w = screenWidth;
    if (w >= Breakpoints.desktop) return FormFactor.desktop;
    if (w >= Breakpoints.tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }

  bool get isMobile => formFactor == FormFactor.mobile;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isDesktop => formFactor == FormFactor.desktop;

  /// Vrai dès la tablette (rail de navigation au lieu du bottom nav).
  bool get isWide => screenWidth >= Breakpoints.tablet;

  /// Sélection responsive d'une valeur selon le device.
  /// `tablet` retombe sur `mobile` s'il n'est pas fourni ;
  /// `desktop` retombe sur `tablet`/`mobile`.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (formFactor) {
      case FormFactor.desktop:
        return desktop ?? tablet ?? mobile;
      case FormFactor.tablet:
        return tablet ?? mobile;
      case FormFactor.mobile:
        return mobile;
    }
  }
}

/// Centre le contenu et lui applique une largeur maximale sur grand écran,
/// via un simple **padding horizontal symétrique** (LayoutBuilder).
///
/// Contrairement à un `Center`/`Align` + `ConstrainedBox`, cette approche
/// conserve des contraintes **serrées** (hauteur pleine, largeur = cible) :
/// tout écran qui s'affichait correctement en pleine largeur (colonnes avec
/// `Expanded`, canvas plein-hauteur…) reste valide, simplement plus étroit
/// et centré — évite l'étirement edge-to-edge sur les moniteurs larges.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMax,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (!w.isFinite || w <= maxWidth) return child;
        final pad = (w - maxWidth) / 2;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        );
      },
    );
  }
}
