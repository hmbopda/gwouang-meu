import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/genealogy_notifier.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/features/profile/profile_edit_sheet.dart';
import 'package:gwangmeu/features/profile/profile_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/models/user_model.dart';

/// Profil « Héritage clair » — conçu dans le même langage patrimonial que
/// la fiche de vie de Lignée : gros badge à initiales (anneau or, point vert
/// « vivant·e »), nom serif, méta mono en petites capitales, carte
/// « FICHE DE VIE » (puces colorées + titre + sous-ligne) et actions
/// or plein / brun plein / contour bien alignées.
///
/// Toute la logique existante est conservée : `profileNotifierProvider`
/// (chargement, refresh, upload, déconnexion), `showProfileEditSheet`
/// (édition), navigation vers la lignée et les réglages.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final profileState = ref.watch(profileNotifierProvider);

    return profileState.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: t.goldText),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.error, size: 48, color: t.stoneDim),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger le profil',
              style: GwType.ui(fontSize: 15, color: t.stoneMid),
            ),
            const SizedBox(height: 16),
            _GoldButton(
              icon: Symbols.refresh,
              label: 'Réessayer',
              onTap: () => ref.invalidate(profileNotifierProvider),
            ),
          ],
        ),
      ),
      data: (user) =>
          user == null ? _notLoggedIn(context) : _ProfileView(user: user),
    );
  }

  Widget _notLoggedIn(BuildContext context) {
    final t = GwTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.person_off, size: 64, color: t.stoneDim),
          const SizedBox(height: 16),
          Text(
            'Non connecté',
            style: GwType.ui(fontSize: 15, color: t.stoneMid),
          ),
          const SizedBox(height: 24),
          _GoldButton(
            icon: Symbols.login,
            label: 'Se connecter',
            onTap: () => context.go(Routes.auth),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Vue principale — colonne unique centrée & bornée (mobile & desktop)
// ─────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final desktop = isDesktopLayout(context);

    final content = RefreshIndicator(
      color: t.goldText,
      onRefresh: () => ref.read(profileNotifierProvider.notifier).refresh(),
      child: ListView(
        padding: EdgeInsets.only(top: desktop ? 24 : 8, bottom: 40),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 12),
          _StatsRow(user: user),
          const SizedBox(height: 20),
          const _SectionLabel('FICHE DE VIE'),
          const SizedBox(height: 8),
          _LifeSheetCard(user: user),
          const SizedBox(height: 20),
          const _SectionLabel('MA LIGNÉE'),
          const SizedBox(height: 8),
          _ActionsBlock(user: user),
          const SizedBox(height: 24),
          const _SectionLabel('RÉGLAGES'),
          const SizedBox(height: 8),
          const _SettingsCard(),
          const SizedBox(height: 12),
          const _SignOutButton(),
        ],
      ),
    );

    // Contenu centré et borné en largeur de lecture — évite l'étirement
    // « bande » sur les moniteurs larges ; le shell fournit rail + topbar.
    final bounded = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: content,
      ),
    );

    if (desktop) {
      return Container(
        color: t.ink,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: bounded,
      );
    }

    // Mobile : bande tissée signature en haut de l'écran.
    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Expanded(child: bounded),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  1) En-tête profil — gros badge à initiales (anneau or, point vert),
//     nom serif, email en gris, pilules mono (clan · génération · statut)
// ─────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    final myPerson = ref.watch(genealogyNotifierProvider).valueOrNull;
    final tree = myPerson == null
        ? null
        : ref.watch(familyTreeProvider(myPerson.id)).valueOrNull;
    final generation = tree != null
        ? _countGenerations(tree)
        : 1 + ((user.fatherName != null || user.motherName != null) ? 1 : 0);

    final clans = _clanNames(user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Réglages rapides (cible ≥ 44 px) aligné à droite.
          Align(
            alignment: Alignment.centerRight,
            child: _HeaderAction(
              icon: Symbols.settings,
              onTap: () => showProfileEditSheet(context),
            ),
          ),
          _InitialsBadge(
            user: user,
            onTap: () => _pickAndUpload(
              context,
              ref,
              folder: 'avatars',
              profileField: 'avatarUrl',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName ?? 'Membre',
            textAlign: TextAlign.center,
            style: GwType.display(fontSize: 26, color: t.stone),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
          ),
          const SizedBox(height: 12),
          // Pilules mono — clan(s) (or), génération · VOUS (or), statut (vert).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final clan in clans)
                _MonoPill(label: 'CLAN $clan', color: t.goldText),
              _MonoPill(
                label: 'GÉNÉRATION $generation · VOUS',
                color: t.goldText,
              ),
              _MonoPill(
                label: 'VIVANT·E',
                color: t.sageText,
                dot: GwTokens.sage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gros badge circulaire à initiales — anneau or (2 px), point vert
/// « vivant·e » en bas à droite, badge appareil photo pour changer l'image.
class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({required this.user, required this.onTap});
  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Semantics(
      button: true,
      label: 'Changer la photo de profil',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.goldBg,
                border: Border.all(color: GwTokens.gold, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: user.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 104,
                      height: 104,
                      errorWidget: (_, __, ___) => _initialText(t),
                    )
                  : _initialText(t),
            ),
            // Point vert « vivant·e ».
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GwTokens.sage,
                  border: Border.all(color: t.ink, width: 3),
                ),
              ),
            ),
            // Badge appareil photo (affordance upload).
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: t.goldText,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(Symbols.photo_camera,
                    size: 15, color: GwTokens.inkOnGold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialText(GwTokens t) => Text(
        _initial(user),
        style: GwType.display(fontSize: 42, color: t.goldText),
      );
}

/// Action d'en-tête 44×44 (a11y) — surface inkLift, rayon rBtn.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: SizedBox(
          width: GwTokens.tapTarget,
          height: GwTokens.tapTarget,
          child: Icon(icon, size: 20, color: t.stoneMid),
        ),
      ),
    );
  }
}

/// Pilule mono en petites capitales — anneau/fond translucide, point
/// coloré optionnel (statut « vivant·e »).
class _MonoPill extends StatelessWidget {
  const _MonoPill({required this.label, required this.color, this.dot});
  final String label;
  final Color color;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GwType.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  2) Rangée de stats « X membres · Y générations · Z clans »
// ─────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    final myPerson = ref.watch(genealogyNotifierProvider).valueOrNull;
    final tree = myPerson == null
        ? null
        : ref.watch(familyTreeProvider(myPerson.id)).valueOrNull;
    final members = tree != null ? '${_treeMemberCount(tree)}' : '—';
    final generations = tree != null
        ? '${_countGenerations(tree)}'
        : '${1 + ((user.fatherName != null || user.motherName != null) ? 1 : 0)}';

    final villageCount = ref
        .watch(myVillagesNotifierProvider)
        .maybeWhen(data: (v) => v.length, orElse: () => null);
    final clanCount = _clanNames(user).length;
    // Rattachement culturel : clans si présents, sinon villages rejoints.
    final (thirdValue, thirdLabel) = clanCount > 0
        ? ('$clanCount', clanCount > 1 ? 'clans' : 'clan')
        : (
            villageCount != null ? '$villageCount' : '—',
            (villageCount ?? 0) > 1 ? 'villages' : 'village'
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DefaultTextStyle(
        style: GwType.mono(
          fontSize: 12,
          letterSpacing: 1,
          color: t.stoneMid,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stat(t, members, 'membres'),
            _dot(t),
            _stat(t, generations, generations == '1' ? 'génération' : 'générations'),
            _dot(t),
            _stat(t, thirdValue, thirdLabel),
          ],
        ),
      ),
    );
  }

  Widget _stat(GwTokens t, String value, String label) {
    return Flexible(
      child: RichText(
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: GwType.mono(fontSize: 12, letterSpacing: 1, color: t.stoneMid),
          children: [
            TextSpan(
              text: value,
              style: GwType.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: t.goldText,
              ),
            ),
            TextSpan(text: ' $label'),
          ],
        ),
      ),
    );
  }

  Widget _dot(GwTokens t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('·', style: GwType.mono(fontSize: 14, color: t.stoneFaint)),
      );
}

// ─────────────────────────────────────────────────────────────────
//  3) Carte « FICHE DE VIE » — même style que le panneau Lignée :
//     puces colorées + titre + sous-ligne (naissance, résidence,
//     langue, profession, clan…), selon les champs disponibles.
// ─────────────────────────────────────────────────────────────────

class _LifeSheetCard extends StatelessWidget {
  const _LifeSheetCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);

    final residence = [
      if (user.residenceCity != null) user.residenceCity!,
      if (user.residenceCountry != null) user.residenceCountry!,
    ].join(', ');

    final origin = user.country;
    final memberSince =
        user.createdAt != null ? 'Membre depuis ${user.createdAt!.year}' : null;

    final rows = <Widget>[
      _LifeRow(
        icon: Symbols.cake,
        accent: GwTokens.rose,
        label: 'Origine',
        value: origin,
      ),
      _LifeRow(
        icon: Symbols.home,
        accent: GwTokens.sage,
        label: 'Résidence',
        value: residence.isNotEmpty ? residence : null,
      ),
      _LifeRow(
        icon: Symbols.language,
        accent: GwTokens.azure,
        label: 'Langue',
        value: user.nativeLanguage,
      ),
      _LifeRow(
        icon: Symbols.work,
        accent: GwTokens.gold,
        label: 'Profession',
        value: user.profession,
        sub: user.employer,
      ),
      _LifeRow(
        icon: Symbols.groups,
        accent: GwTokens.gold,
        label: 'Clan',
        value: _clanNames(user).isEmpty ? null : _clanNames(user).join(' · '),
        sub: user.tribe,
      ),
      _LifeRow(
        icon: Symbols.diversity_3,
        accent: GwTokens.rose,
        label: 'Situation',
        value: user.maritalStatus,
        sub: user.childrenCount != null && user.childrenCount! > 0
            ? '${user.childrenCount} enfant${user.childrenCount! > 1 ? 's' : ''}'
            : null,
      ),
      if (memberSince != null)
        _LifeRow(
          icon: Symbols.event,
          accent: GwTokens.azure,
          label: 'Ancienneté',
          value: memberSince,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          border: Border.all(color: t.line),
        ),
        child: Column(children: rows),
      ),
    );
  }
}

/// Rangée « fiche de vie » — puce colorée carrée arrondie + icône, titre
/// (label) + valeur, sous-ligne facultative. Reprend le langage du panneau
/// Lignée (puces colorées, méta discrète).
class _LifeRow extends StatelessWidget {
  const _LifeRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.sub,
  });
  final IconData icon;
  final Color accent;
  final String label;
  final String? value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puce colorée (comme les pastilles du panneau Lignée).
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GwType.mono(
                    fontSize: 9.5,
                    letterSpacing: 1.5,
                    color: t.stoneFaint,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasValue ? value! : 'Non renseigné',
                  style: GwType.ui(
                    fontSize: 14.5,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? t.stone : t.stoneDim,
                  ),
                ),
                if (sub != null && sub!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  4) Actions — « Modifier mon profil » (or plein),
//     « Voir ma lignée » (brun plein), icônes alignées au label.
// ─────────────────────────────────────────────────────────────────

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _GoldButton(
            icon: Symbols.edit,
            label: 'Modifier mon profil',
            onTap: () => showProfileEditSheet(context),
            fullWidth: true,
          ),
          const SizedBox(height: 10),
          _InkButton(
            icon: Symbols.account_tree,
            label: 'Voir ma lignée',
            onTap: () => context.go(Routes.genealogy),
          ),
        ],
      ),
    );
  }
}

/// Bouton primaire — or plein, icône (18) + gap 8 centrés sur le label.
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final button = Material(
      color: t.goldText,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: GwTokens.inkOnGold),
              const SizedBox(width: 8),
              Text(
                label,
                style: GwType.ui(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: GwTokens.inkOnGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Bouton secondaire fort — brun plein (encre/stone), pleine largeur.
class _InkButton extends StatelessWidget {
  const _InkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    // Fond brun patrimonial (stone) sur clair ; sur sombre, surface élevée.
    final bg = t.brightness == Brightness.light ? t.stone : t.inkHigh;
    final fg = t.brightness == Brightness.light ? t.ink : t.stone;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Réglages — édition profil, photos, partage (actions conservées)
// ─────────────────────────────────────────────────────────────────

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rCardLg),
            border: Border.all(color: t.line),
          ),
          child: Column(
            children: [
              _SettingsRow(
                icon: Symbols.edit,
                label: 'Modifier le profil',
                onTap: () => showProfileEditSheet(context),
              ),
              Divider(height: 1, color: t.line),
              _SettingsRow(
                icon: Symbols.photo_camera,
                label: 'Photo de profil',
                onTap: () => _pickAndUpload(
                  context,
                  ref,
                  folder: 'avatars',
                  profileField: 'avatarUrl',
                ),
              ),
              Divider(height: 1, color: t.line),
              _SettingsRow(
                icon: Symbols.wallpaper,
                label: 'Photo de couverture',
                onTap: () => _pickAndUpload(
                  context,
                  ref,
                  folder: 'covers',
                  profileField: 'coverUrl',
                ),
              ),
              Divider(height: 1, color: t.line),
              _SettingsRow(
                icon: Symbols.share,
                label: 'Partager mon profil',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Partage de profil bientôt disponible'),
                      backgroundColor: t.inkHigh,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GwTokens.rBtn)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52, // cible tactile ≥ 44 px
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: t.stoneMid),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GwType.ui(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: t.stone,
                  ),
                ),
              ),
              Icon(Symbols.chevron_right, size: 18, color: t.stoneFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: GwTokens.emberBg,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: () async {
            await ref.read(profileNotifierProvider.notifier).signOut();
            if (context.mounted) context.go(Routes.auth);
          },
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: GwTokens.emberLine),
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.logout, size: 18, color: t.emberText),
                const SizedBox(width: 8),
                Text(
                  'Déconnexion',
                  style: GwType.ui(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: t.emberText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Widgets partagés
// ─────────────────────────────────────────────────────────────────

/// Label de section — JetBrains Mono MAJUSCULES, letter-spacing 2.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style:
            GwType.mono(fontSize: 10, letterSpacing: 2, color: t.stoneFaint),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Logique conservée — upload d'images, complétion, généalogie
// ─────────────────────────────────────────────────────────────────

/// Sélectionne une image et l'upload (avatar ou couverture),
/// puis met à jour le profil. Logique identique à l'existant.
Future<void> _pickAndUpload(
  BuildContext context,
  WidgetRef ref, {
  required String folder,
  required String profileField,
}) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: folder == 'avatars' ? 512 : 1920,
      maxHeight: folder == 'avatars' ? 512 : 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Upload en cours...'),
          duration: Duration(seconds: 2)),
    );
    final bytes = await picked.readAsBytes();
    await ref.read(profileNotifierProvider.notifier).uploadImage(
          bytes: bytes,
          filename: picked.name,
          folder: folder,
          profileField: profileField,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Photo mise a jour'),
          backgroundColor: GwTokens.sage),
    );
  } catch (e) {
    debugPrint('[UPLOAD] Error: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e'), backgroundColor: GwTokens.ember),
    );
  }
}

/// Noms de clans (champ `clan` séparé par des virgules) — logique conservée.
List<String> _clanNames(UserModel u) {
  if (u.clan == null || u.clan!.trim().isEmpty) return [];
  return u.clan!
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Nombre de générations visibles dans l'arbre (sujet, parents,
/// grands-parents, enfants).
int _countGenerations(FamilyTree tree) {
  int g = 1;
  if (tree.father.isNotEmpty || tree.mother.isNotEmpty) g++;
  if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) g++;
  if (tree.children.isNotEmpty) g++;
  return g;
}

/// Nombre total de membres connus de l'arbre.
int _treeMemberCount(FamilyTree tree) {
  return 1 +
      tree.father.length +
      tree.mother.length +
      tree.paternalGP.length +
      tree.maternalGP.length +
      tree.siblings.length +
      tree.children.length +
      tree.cousins.length +
      tree.uncles.length;
}

String _initial(UserModel user) {
  return (user.displayName ?? user.email).substring(0, 1).toUpperCase();
}
