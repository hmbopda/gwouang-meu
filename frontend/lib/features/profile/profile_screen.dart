import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/breadcrumb_provider.dart';
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
import 'package:gwangmeu/shared/models/village_model.dart';

/// Profil « Tissage » (#3c) — carte d'identité culturelle.
///
/// Bande tissée, avatar 96 px à anneau dégradé or→ember→sage, chips
/// identité (clan or / diaspora azure / langues sage), carte lignée,
/// grille « Mes villages », stats « contribution à la mémoire » et
/// CTA « Enregistrer mon récit ». Toute la logique existante est
/// conservée (profileNotifierProvider, édition, uploads, déconnexion).
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
            _GoldPillButton(
              label: 'Réessayer',
              onTap: () => ref.invalidate(profileNotifierProvider),
            ),
          ],
        ),
      ),
      data: (user) => user == null
          ? _notLoggedIn(context)
          : _ProfileView(user: user),
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
          _GoldPillButton(
            label: 'Se connecter',
            onTap: () => context.go(Routes.auth),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Vue principale — colonne unique scrollable (mobile & desktop)
// ─────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final desktop = isDesktopLayout(context);
    final completion = _calcCompletion(user);

    final content = RefreshIndicator(
      color: t.goldText,
      onRefresh: () => ref.read(profileNotifierProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _IdentityHeader(user: user),
          const SizedBox(height: 10),
          _LineageCard(user: user),
          const SizedBox(height: 16),
          const _SectionLabel('MES VILLAGES'),
          const SizedBox(height: 8),
          const _VillagesGrid(),
          const SizedBox(height: 18),
          const _SectionLabel('MA CONTRIBUTION À LA MÉMOIRE'),
          const SizedBox(height: 8),
          const _ContributionCard(),
          const SizedBox(height: 12),
          const _RecordCta(),
          const SizedBox(height: 24),
          _SectionLabel('PROFIL COMPLÉTÉ · $completion %'),
          const SizedBox(height: 8),
          _CompletionCard(user: user, completion: completion),
          const SizedBox(height: 24),
          const _SectionLabel('RÉGLAGES'),
          const SizedBox(height: 8),
          const _SettingsCard(),
          const SizedBox(height: 12),
          const _SignOutButton(),
        ],
      ),
    );

    // Desktop : colonne centrée dans le shell (rail + topbar déjà fournis).
    if (desktop) {
      return Container(
        color: t.ink,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: content,
        ),
      );
    }

    // Mobile : bande tissée signature en haut de l'écran.
    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Bandeau identité — avatar 96 px anneau tissé, nom Fraunces,
//  chip rôle mono, chips identité (clan / diaspora / langues)
// ─────────────────────────────────────────────────────────────────

class _IdentityHeader extends ConsumerWidget {
  const _IdentityHeader({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final subline = _subline(user);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GwTokens.gold.withValues(alpha: 0.09),
            GwTokens.gold.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        children: [
          // Action réglages (cible 44 px) — ouvre la feuille d'édition
          // (profil, mode d'affichage, accent…).
          Align(
            alignment: Alignment.centerRight,
            child: _HeaderAction(
              icon: Symbols.settings,
              onTap: () => showProfileEditSheet(context),
            ),
          ),
          const SizedBox(height: 2),
          _WovenAvatar(
            user: user,
            onTap: () => _pickAndUpload(
              context,
              ref,
              folder: 'avatars',
              profileField: 'avatarUrl',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName ?? 'Membre',
            textAlign: TextAlign.center,
            style: GwType.display(fontSize: 23, color: t.stone),
          ),
          if (subline != null) ...[
            const SizedBox(height: 3),
            Text(
              subline,
              textAlign: TextAlign.center,
              style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
            ),
          ],
          const SizedBox(height: 10),
          // Chip rôle (mono) + vérifié
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _MonoChip(label: user.role.toUpperCase(), color: t.goldText),
              if (user.verified)
                _MonoChip(label: 'VÉRIFIÉ', color: t.sageText),
            ],
          ),
          const SizedBox(height: 10),
          // Chips identité culturelle
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final clan in _clanNames(user))
                _IdentityChip(
                  label: 'Clan $clan',
                  bg: t.goldBg,
                  line: t.goldLine,
                  text: t.goldText,
                ),
              if (user.residenceCountry != null || user.country != null)
                _IdentityChip(
                  label: user.residenceCountry != null
                      ? 'Diaspora · ${user.residenceCountry}'
                      : 'Diaspora',
                  bg: GwTokens.azureBg,
                  line: GwTokens.azureLine,
                  text: t.azureText,
                ),
              if (user.nativeLanguage != null)
                _IdentityChip(
                  label: 'Parle ${user.nativeLanguage}',
                  bg: GwTokens.sageBg,
                  line: GwTokens.sageLine,
                  text: t.sageText,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _subline(UserModel u) {
    final places = <String>[];
    if (u.country != null) places.add(u.country!);
    final residence = u.residenceCity ?? u.residenceCountry;
    if (residence != null && residence != u.country) places.add(residence);

    final parts = <String>[];
    if (places.isNotEmpty) parts.add(places.join(' → '));
    if (u.createdAt != null) parts.add('membre depuis ${u.createdAt!.year}');
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

/// Avatar 96 px — anneau dégradé tissé or→ember→sage (padding 3 px),
/// initiale Fraunces si pas de photo, badge photo pour changer l'image.
class _WovenAvatar extends StatelessWidget {
  const _WovenAvatar({required this.user, required this.onTap});
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
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GwTokens.gold, GwTokens.ember, GwTokens.sage],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: t.inkLift,
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: t.ink, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: user.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initialBox(t),
                      )
                    : _initialBox(t),
              ),
            ),
            // Badge appareil photo (affordance upload)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: t.goldText,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.ink, width: 2),
                ),
                alignment: Alignment.center,
                child: Icon(Symbols.photo_camera, size: 14, color: t.inkCard),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialBox(GwTokens t) => Center(
        child: Text(
          _initial(user),
          style: GwType.display(fontSize: 36, color: t.goldText),
        ),
      );
}

/// Action d'en-tête 44×44 (a11y) — surface inkLift, rayon 14.
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

/// Chip mono (rôle, badges) — pilule or/sage translucide, MAJUSCULES.
class _MonoChip extends StatelessWidget {
  const _MonoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Text(
        label,
        style: GwType.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }
}

/// Chip identité (clan / diaspora / langues) — pilule 99, 12 px w600.
class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.label,
    required this.bg,
    required this.line,
    required this.text,
  });
  final String label;
  final Color bg;
  final Color line;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(GwTokens.rPill),
      ),
      child: Text(
        label,
        style: GwType.ui(fontSize: 12, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Carte lignée — « Génération N » + « X récits », lien vers l'arbre
// ─────────────────────────────────────────────────────────────────

class _LineageCard extends ConsumerWidget {
  const _LineageCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    final myPerson = ref.watch(genealogyNotifierProvider).valueOrNull;
    final tree = myPerson == null
        ? null
        : ref.watch(familyTreeProvider(myPerson.id)).valueOrNull;

    final generations = tree != null
        ? _countGenerations(tree)
        : 1 + ((user.fatherName != null || user.motherName != null) ? 1 : 0);
    final members = tree != null ? _treeMemberCount(tree) : null;

    final lineageName = user.clan ?? _familyName(user);
    final title = lineageName != null
        ? 'Lignée $lineageName — génération $generations'
        : 'Ma lignée — génération $generations';
    final subtitle = members != null
        ? '$members membres · — récits audio collectés'
        : 'Explorer mon arbre familial';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        child: InkWell(
          onTap: () => context.go(Routes.genealogy),
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.goldBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child:
                      Icon(Symbols.family_history, size: 24, color: t.goldText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: t.stone,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.chevron_right, size: 20, color: t.stoneFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _familyName(UserModel u) {
    final parts = (u.displayName ?? '').trim().split(' ');
    if (parts.length < 2) return null;
    return parts.last;
  }
}

// ─────────────────────────────────────────────────────────────────
//  Grille « Mes villages » — tuiles initiale Fraunces teintées
// ─────────────────────────────────────────────────────────────────

class _VillagesGrid extends ConsumerWidget {
  const _VillagesGrid();

  // Teintes des tuiles (cycle) : or, azur, sauge, rose cuivré.
  static const _accents = <Color>[
    GwTokens.gold,
    GwTokens.azure,
    GwTokens.sage,
    GwTokens.rose,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: myVillages.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: t.goldText),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (villages) {
          if (villages.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.inkCard,
                borderRadius: BorderRadius.circular(GwTokens.rCard),
              ),
              child: Text(
                'Aucun village rejoint pour le moment.',
                style: GwType.ui(fontSize: 14, color: t.stoneDim),
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 118,
            ),
            itemCount: villages.length,
            itemBuilder: (context, i) => _VillageTile(
              village: villages[i],
              accent: _accents[i % _accents.length],
              highlighted: i == 0,
              onTap: () {
                ref.read(breadcrumbProvider.notifier).reset(
                    const BreadcrumbEntry(
                        label: 'Profil', route: Routes.profile));
                ref.read(breadcrumbProvider.notifier).push(BreadcrumbEntry(
                    label: villages[i].name,
                    route: Routes.villageDetail(villages[i].id)));
                context.push(Routes.villageDetail(villages[i].id));
              },
            ),
          );
        },
      ),
    );
  }
}

class _VillageTile extends StatelessWidget {
  const _VillageTile({
    required this.village,
    required this.accent,
    required this.highlighted,
    required this.onTap,
  });
  final VillageModel village;
  final Color accent;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.inkCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: highlighted ? t.goldLine : t.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  village.name.isNotEmpty
                      ? village.name[0].toUpperCase()
                      : '?',
                  style: GwType.display(
                      fontSize: 16, color: GwTokens.inkOnGold),
                ),
              ),
              const Spacer(),
              Text(
                village.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: t.stone,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${village.memberCount} membres',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GwType.ui(fontSize: 12, color: t.stoneDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Stats « contribution à la mémoire » — Fraunces + labels mono
// ─────────────────────────────────────────────────────────────────

class _ContributionCard extends ConsumerWidget {
  const _ContributionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = GwTokens.of(context);

    final myPerson = ref.watch(genealogyNotifierProvider).valueOrNull;
    final tree = myPerson == null
        ? null
        : ref.watch(familyTreeProvider(myPerson.id)).valueOrNull;
    final added = tree != null ? '${_treeMemberCount(tree) - 1}' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _StatCell(value: '—', label: 'RÉCITS AUDIO', color: t.sageText),
              Container(width: 1, color: t.line),
              _StatCell(
                  value: added, label: 'PERSONNES AJOUTÉES', color: t.goldText),
              Container(width: 1, color: t.line),
              _StatCell(value: '—', label: 'PHOTOS', color: t.goldText),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GwType.display(
                fontSize: 22, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GwType.mono(
                fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CTA « Enregistrer mon récit » — bouton primaire or, ≥ 50 px
// ─────────────────────────────────────────────────────────────────

class _RecordCta extends StatelessWidget {
  const _RecordCta();

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: t.goldText,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('L\'enregistrement de récits arrive bientôt'),
                backgroundColor: t.inkHigh,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.mic, size: 20, color: t.inkCard),
                const SizedBox(width: 8),
                Text(
                  'Enregistrer mon récit',
                  style: GwType.ui(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.inkCard,
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
//  Complétion du profil — barre + checklist (logique conservée)
// ─────────────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.user, required this.completion});
  final UserModel user;
  final int completion;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final items = <_CheckItem>[
      _CheckItem('Identité renseignée', user.displayName != null),
      _CheckItem(
          'Biographie ajoutée', user.bio != null && user.bio!.isNotEmpty),
      _CheckItem('Photo de profil', user.avatarUrl != null, bonus: 8),
      const _CheckItem('Village rejoint', true),
      _CheckItem('Parents ajoutés',
          user.fatherName != null || user.motherName != null,
          bonus: 12),
      const _CheckItem('Date de naissance', false, bonus: 8),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              child: LinearProgressIndicator(
                value: completion / 100,
                minHeight: 4,
                backgroundColor: t.inkHigh,
                valueColor: AlwaysStoppedAnimation<Color>(t.goldText),
              ),
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      item.done
                          ? Symbols.check_circle
                          : Symbols.radio_button_unchecked,
                      size: 16,
                      color: item.done ? t.sageText : t.stoneDim,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GwType.ui(
                          fontSize: 13,
                          color: item.done ? t.sageText : t.stoneDim,
                        ),
                      ),
                    ),
                    if (!item.done && item.bonus != null)
                      Text(
                        '+${item.bonus} %',
                        style: GwType.mono(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: t.goldText),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.done, {this.bonus});
  final String label;
  final bool done;
  final int? bonus;
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

/// Bouton pilule or (états vides / erreurs).
class _GoldPillButton extends StatelessWidget {
  const _GoldPillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Material(
      color: t.goldText,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          height: GwTokens.tapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GwType.ui(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: t.inkCard,
            ),
          ),
        ),
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

/// Score de complétion du profil (sur 10 critères) — logique conservée.
int _calcCompletion(UserModel u) {
  int score = 0;
  const total = 10;
  if (u.displayName != null && u.displayName!.isNotEmpty) score++;
  if (u.bio != null && u.bio!.isNotEmpty) score++;
  if (u.avatarUrl != null && u.avatarUrl!.isNotEmpty) score++;
  if (u.country != null) score++;
  if (u.profession != null) score++;
  if (u.nativeLanguage != null) score++;
  if (u.clan != null) score++;
  if (u.tribe != null) score++;
  if (u.fatherName != null) score++;
  if (u.motherName != null) score++;
  return ((score / total) * 100).round();
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
