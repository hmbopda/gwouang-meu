import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/breadcrumb_provider.dart';
import '../../core/router/route_names.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/gwang_button.dart';
import '../genealogy/genealogy_notifier.dart';
import '../villages/villages_notifier.dart';
import 'profile_edit_sheet.dart';
import 'profile_notifier.dart';

import '../../core/theme/gw_colors.dart';

const _serif = 'Georgia';
const _mono = 'monospace';

// ═══════════════════════════════════════════════════════
// PROFILE SCREEN
// ═══════════════════════════════════════════════════════

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final profileState = ref.watch(profileNotifierProvider);

    return profileState.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: c.gold),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.stoneDim),
            const SizedBox(height: 12),
            Text('Impossible de charger le profil',
                style: TextStyle(color: c.stoneMid)),
            const SizedBox(height: 16),
            GwangButton(
              label: 'Réessayer',
              onPressed: () => ref.invalidate(profileNotifierProvider),
              fullWidth: false,
            ),
          ],
        ),
      ),
      data: (user) => user == null
          ? _notLoggedIn(context)
          : _ResponsiveShell(user: user),
    );
  }

  Widget _notLoggedIn(BuildContext context) {
    final c = GwColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: c.stoneDim),
          const SizedBox(height: 16),
          Text('Non connecté', style: TextStyle(color: c.stoneMid)),
          const SizedBox(height: 24),
          GwangButton(
            label: 'Se connecter',
            onPressed: () => context.go(Routes.auth),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RESPONSIVE SHELL — 3 colonnes desktop, 1 colonne mobile
// ═══════════════════════════════════════════════════════

class _ResponsiveShell extends ConsumerWidget {
  const _ResponsiveShell({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Desktop (>= 1100) : Left Rail + Center + Right Panel
        if (w >= 1100) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: _LeftRail(user: user),
              ),
              Container(width: 1, color: c.line),
              Expanded(
                child: _CenterPanel(user: user),
              ),
              Container(width: 1, color: c.line),
              SizedBox(
                width: 272,
                child: _RightPanel(user: user),
              ),
            ],
          );
        }

        // Tablet (>= 800) : Left Rail + Center
        if (w >= 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: _LeftRail(user: user),
              ),
              Container(width: 1, color: c.line),
              Expanded(
                child: _CenterPanel(user: user),
              ),
            ],
          );
        }

        // Mobile : Center only
        return _CenterPanel(user: user);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// LEFT RAIL — Identité + Complétion + Nav + Villages
// ═══════════════════════════════════════════════════════

class _LeftRail extends ConsumerWidget {
  const _LeftRail({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider);
    final completion = _calcCompletion(user);

    return Container(
      color: c.ink,
      child: Column(
        children: [
          // Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Text('MON PROFIL',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: c.stoneDim,
                    )),
                const Spacer(),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Identity card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + Name
                      Row(
                        children: [
                          _MiniAvatar(
                              letter: _initial(user), size: 38, color: c.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Membre',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: c.stone,
                                  ),
                                ),
                                Text(
                                  '@${(user.displayName ?? user.email).toLowerCase().replaceAll(' ', '')}',
                                  style: TextStyle(
                                    fontFamily: _mono,
                                    fontSize: 9,
                                    color: c.stoneFaint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Completion bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PROFIL COMPLÉTÉ',
                              style: TextStyle(
                                fontFamily: _mono,
                                fontSize: 8,
                                letterSpacing: 1,
                                color: c.stoneFaint,
                              )),
                          Text('$completion %',
                              style: TextStyle(
                                fontFamily: _mono,
                                fontSize: 10,
                                color: c.gold,
                              )),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 2,
                          backgroundColor: c.inkRaise,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(c.gold),
                        ),
                      ),
                    ],
                  ),
                ),

                const _RailDivider(),
                const _RailSection(label: 'MES CLANS'),

                // Clans actifs
                ..._activeClanNames(user).map((name) => _RailClanItem(
                      name: name,
                      pending: false,
                      c: c,
                    )),

                // Clans en attente de validation (placeholder — sera alimenté par l'API)
                // ignore: dead_code
                ...(_pendingClanNames(user)).map((name) => _RailClanItem(
                      name: name,
                      pending: true,
                      c: c,
                    )),

                if (_activeClanNames(user).isEmpty && _pendingClanNames(user).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Aucun clan associé',
                      style: TextStyle(fontSize: 12, color: c.stoneFaint),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ProfileEditSheet(user: user),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 14, color: c.goldDim),
                        const SizedBox(width: 6),
                        Text(
                          'Gérer mes clans',
                          style: TextStyle(fontSize: 12, color: c.goldDim),
                        ),
                      ],
                    ),
                  ),
                ),

                const _RailDivider(),
                const _RailSection(label: 'MES VILLAGES'),

                // Villages list
                myVillages.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                        child:
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.gold))),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (villages) => Column(
                    children: [
                      for (final v in villages)
                        _RailNavItem(
                          icon: Icons.holiday_village_outlined,
                          label: v.name,
                          onTap: () {
                            ref
                                .read(breadcrumbProvider.notifier)
                                .reset(const BreadcrumbEntry(
                                    label: 'Profil', route: Routes.profile));
                            ref.read(breadcrumbProvider.notifier).push(
                                BreadcrumbEntry(
                                    label: v.name,
                                    route: Routes.villageDetail(v.id)));
                            context.push(Routes.villageDetail(v.id));
                          },
                        ),
                      if (villages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Text('Aucun village',
                              style:
                                  TextStyle(fontSize: 12, color: c.stoneFaint)),
                        ),
                    ],
                  ),
                ),

                const _RailDivider(),
                const _RailSection(label: 'PARAMÈTRES'),
                _RailNavItem(icon: Icons.settings_outlined, label: 'Paramètres'),
                _RailNavItem(
                    icon: Icons.lock_outline, label: 'Confidentialité'),

                const SizedBox(height: 16),

                // Sign out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final c = GwColors.of(context);
                      return GestureDetector(
                      onTap: () async {
                        await ref
                            .read(profileNotifierProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go(Routes.auth);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.emberLine),
                          borderRadius: BorderRadius.circular(6),
                          color: c.emberBg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 14, color: c.ember),
                            const SizedBox(width: 6),
                            Text('Déconnexion',
                                style:
                                    TextStyle(fontSize: 12, color: c.ember)),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _activeClanNames(UserModel u) {
    if (u.clan == null || u.clan!.trim().isEmpty) return [];
    return u.clan!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Placeholder — à connecter à un futur endpoint /api/v1/clans/pending
  List<String> _pendingClanNames(UserModel u) => [];

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
}

// ═══════════════════════════════════════════════════════
// CENTER PANEL — Hero + Tabs + Content
// ═══════════════════════════════════════════════════════

class _CenterPanel extends ConsumerStatefulWidget {
  const _CenterPanel({required this.user});
  final UserModel user;

  @override
  ConsumerState<_CenterPanel> createState() => _CenterPanelState();
}

class _CenterPanelState extends ConsumerState<_CenterPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = ['Aperçu', 'Publications', 'Généalogie', 'Langues', 'Formations'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final myVillages = ref.watch(myVillagesNotifierProvider);
    final villageCount = myVillages.valueOrNull?.length ?? 0;

    // Ancestor count from genealogy
    final genealogyState = ref.watch(genealogyNotifierProvider);
    final hasGenealogy = genealogyState.valueOrNull != null;

    final c = GwColors.of(context);
    return Container(
      color: c.inkDeep,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Hero
          SliverToBoxAdapter(child: _HeroSection(user: user)),

          // Tabs (sticky)
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: c.stone,
                unselectedLabelColor: c.stoneDim,
                labelStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
                indicatorColor: c.gold,
                indicatorWeight: 1.5,
                dividerColor: c.line,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Aperçu ──
            _ApercuPane(
              user: user,
              villageCount: villageCount,
              hasGenealogy: hasGenealogy,
            ),
            // ── Publications ──
            _ComingSoonPane(title: 'Publications', icon: Icons.article_outlined),
            // ── Généalogie ──
            _ComingSoonPane(
                title: 'Généalogie', icon: Icons.account_tree_outlined),
            // ── Langues ──
            _ComingSoonPane(
                title: 'Langues', icon: Icons.record_voice_over_outlined),
            // ── Formations ──
            _ComingSoonPane(title: 'Formations', icon: Icons.school_outlined),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// HERO SECTION — Cover canvas + Avatar overlap + Identity
// ═══════════════════════════════════════════════════════

class _HeroSection extends ConsumerWidget {
  const _HeroSection({required this.user});
  final UserModel user;

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, String folder, String profileField) async {
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
        const SnackBar(content: Text('Upload en cours...'), duration: Duration(seconds: 2)),
      );
      final bytes = await picked.readAsBytes();
      await ref.read(profileNotifierProvider.notifier).uploadImage(
        bytes: bytes,
        filename: picked.name,
        folder: folder,
        profileField: profileField,
      );
      if (!context.mounted) return;
      final c = GwColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Photo mise a jour'), backgroundColor: c.sage),
      );
    } catch (e) {
      debugPrint('[UPLOAD] Error: $e');
      if (!context.mounted) return;
      final c = GwColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: c.ember),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    final hPad = isMobile ? 20.0 : 36.0;
    final coverHeight = isMobile ? 180.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover canvas ──
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image or fallback canvas
            Container(
              height: coverHeight,
              decoration: user.coverUrl == null
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.inkDeep.withValues(alpha: 0.95), c.inkDeep.withValues(alpha: 0.97), c.inkDeep],
                      ),
                    )
                  : null,
              child: Stack(
                children: [
                  if (user.coverUrl != null)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: user.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => RepaintBoundary(
                          child: CustomPaint(painter: _HeroCanvasPainter()),
                        ),
                      ),
                    )
                  else
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(painter: _HeroCanvasPainter()),
                      ),
                    ),
                  // Bottom gradient fade
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [c.inkDeep.withValues(alpha: 0.0), c.inkDeep.withValues(alpha: 0.69), c.inkDeep],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "Modifier la couverture" button
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => _pickAndUpload(context, ref, 'covers', 'coverUrl'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.inkDeep.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.lineMid),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 14, color: c.stoneMid),
                      const SizedBox(width: 6),
                      Text('Modifier la couverture',
                          style: TextStyle(fontSize: 12, color: c.stoneMid)),
                    ],
                  ),
                ),
              ),
            ),

            // Avatar overlapping hero bottom — tap to change
            Positioned(
              bottom: -46,
              left: hPad,
              child: GestureDetector(
                onTap: () => _pickAndUpload(context, ref, 'avatars', 'avatarUrl'),
                child: Stack(
                  children: [
                    _LargeAvatar(user: user),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: c.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, size: 14, color: c.inkDeep),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Identity row: avatar space left + info + actions right ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Space reserved for avatar overflow
              const SizedBox(width: 110),
              // Gold separator line
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 8),
                  color: c.goldLine,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 44),

        // ── Name + Actions row ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildName(context, user),
                    const SizedBox(height: 10),
                    _HeroActions(user: user),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildName(context, user)),
                    _HeroActions(user: user),
                  ],
                ),
        ),

        const SizedBox(height: 10),

        // ── Badges row ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.goldFaint,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: c.gold),
                    const SizedBox(width: 4),
                    Text(
                      (user.role).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: c.gold,
                      ),
                    ),
                  ],
                ),
              ),
              // Online badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: c.sageLine),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: c.sage),
                    const SizedBox(width: 5),
                    Text('EN LIGNE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: c.sage,
                        )),
                  ],
                ),
              ),
              // Verified badge
              if (user.verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.goldFaint,
                    border: Border.all(color: c.goldLine),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: c.gold),
                      const SizedBox(width: 4),
                      Text('VERIFIE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: c.gold,
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Bio text ──
        if (user.bio != null && user.bio!.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
            child: Text(
              user.bio!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: c.stoneMid,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        if (user.bio != null && user.bio!.isNotEmpty)
          const SizedBox(height: 6),

        // ── Subtitle: Diaspora — Pays ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: _buildSubtitle(context, user),
        ),

        const SizedBox(height: 8),

        // ── Meta row with icons ──
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
          child: _buildMetaRow(context, user),
        ),
      ],
    );
  }

  Widget _buildName(BuildContext context, UserModel user) {
    final c = GwColors.of(context);
    final parts = (user.displayName ?? 'Membre').split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: firstName,
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: c.stone,
              height: 1.1,
            ),
          ),
          if (lastName.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(
              text: lastName,
              style: TextStyle(
                fontFamily: _serif,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: c.stone,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, UserModel user) {
    final c = GwColors.of(context);
    final parts = <String>[];
    if (user.residenceCountry != null || user.country != null) {
      parts.add('Diaspora');
    }
    if (user.residenceCountry != null) {
      parts.add(user.residenceCountry!);
    }
    if (user.country != null && user.country != user.residenceCountry) {
      parts.add(user.country!);
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' \u2014 '),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: c.stoneDim,
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, UserModel user) {
    final c = GwColors.of(context);
    final items = <Widget>[];

    if (user.residenceCity != null) {
      items.add(_MetaItem(
        icon: Icons.location_on_outlined,
        text: user.residenceCity!,
        iconColor: c.emberLight,
      ));
    }

    if (user.clan != null) {
      items.add(_MetaItem(
        icon: Icons.fort_outlined,
        text: 'Clan ${user.clan}',
        iconColor: c.goldDim,
      ));
    }

    if (user.createdAt != null) {
      final months = [
        'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Aout', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      items.add(_MetaItem(
        icon: Icons.calendar_today_outlined,
        text: 'Membre depuis ${months[user.createdAt!.month - 1]}. ${user.createdAt!.year}',
        iconColor: c.stoneDim,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items,
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.text,
    required this.iconColor,
  });
  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: c.stoneDim,
            )),
      ],
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Modifier le profil
        GestureDetector(
          onTap: () => showProfileEditSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: c.gold,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x4DC9A84C), blurRadius: 20),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 14, color: c.inkDeep),
                const SizedBox(width: 6),
                Text('Modifier le profil',
                    style: TextStyle(
                      color: c.inkDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Settings
        GestureDetector(
          onTap: () {
            // TODO: settings
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.inkRaise,
              border: Border.all(color: c.lineMid),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.settings_outlined, size: 18, color: c.stoneMid),
          ),
        ),
        const SizedBox(width: 8),
        // Partager
        GestureDetector(
          onTap: () {
            // TODO: share profile
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.inkRaise,
              border: Border.all(color: c.lineMid),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.share_outlined, size: 18, color: c.stoneMid),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// APERÇU PANE
// ═══════════════════════════════════════════════════════

class _ApercuPane extends StatelessWidget {
  const _ApercuPane({
    required this.user,
    required this.villageCount,
    required this.hasGenealogy,
  });
  final UserModel user;
  final int villageCount;
  final bool hasGenealogy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Stats band
        _StatsBar(villageCount: villageCount),

        // Bio section
        _BioSection(user: user),

        // Langues aperçu
        _LanguesApercu(user: user),

        // Placeholder formations
        _FormationsApercu(),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// STATS BAR
// ═══════════════════════════════════════════════════════

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.villageCount});
  final int villageCount;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          _StatCell(value: '—', label: 'CONNEXIONS', highlight: true),
          _StatCell(value: '$villageCount', label: 'VILLAGES'),
          _StatCell(value: '—', label: 'ANCÊTRES'),
          _StatCell(value: '—', label: 'FORMATIONS'),
          _StatCell(value: '—', label: 'PUBLICATIONS', isLast: true),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.highlight = false,
    this.isLast = false,
  });
  final String value;
  final String label;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(right: BorderSide(color: c.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                  fontFamily: _serif,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  color: highlight ? c.goldLight : c.stone,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 8,
                  letterSpacing: 1,
                  color: c.stoneFaint,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// BIO SECTION
// ═══════════════════════════════════════════════════════

class _BioSection extends StatelessWidget {
  const _BioSection({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
            child: Row(
              children: [
                Text('À propos',
                    style: TextStyle(
                      fontFamily: _serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: c.stone,
                      letterSpacing: -0.4,
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: () => showProfileEditSheet(context),
                  child: Text('Modifier →',
                      style: TextStyle(
                        fontFamily: _mono,
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        color: c.goldDim,
                      )),
                ),
              ],
            ),
          ),

          // Bio text
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.bio ?? 'Aucune biographie renseignée.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w300,
                    color: c.stoneMid,
                    height: 2,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Chips
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (user.residenceCity != null || user.residenceCountry != null)
                      _BioChip(
                          text:
                              '${user.residenceCity ?? ''}${user.residenceCity != null && user.residenceCountry != null ? ', ' : ''}${user.residenceCountry ?? ''}'),
                    if (user.country != null) _BioChip(text: user.country!),
                    if (user.profession != null)
                      _BioChip(text: user.profession!),
                    if (user.clan != null)
                      _BioChip(text: 'Clan ${user.clan}'),
                    if (user.nativeLanguage != null)
                      _BioChip(text: user.nativeLanguage!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BioChip extends StatelessWidget {
  const _BioChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.inkRaise,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, color: c.stoneDim, fontWeight: FontWeight.w300)),
    );
  }
}

// ═══════════════════════════════════════════════════════
// LANGUES APERÇU
// ═══════════════════════════════════════════════════════

class _LanguesApercu extends StatelessWidget {
  const _LanguesApercu({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
            child: Row(
              children: [
                Text('Langues',
                    style: TextStyle(
                      fontFamily: _serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: c.stone,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('Aperçu',
                      style: TextStyle(
                        fontFamily: _mono,
                        fontSize: 8,
                        letterSpacing: 1,
                        color: c.stoneFaint,
                      )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
            child: Column(
              children: [
                if (user.nativeLanguage != null)
                  _LangueRow(
                    name: user.nativeLanguage!,
                    level: 'Langue native',
                    pct: 1.0,
                    color: c.gold,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangueRow extends StatelessWidget {
  const _LangueRow({
    required this.name,
    required this.level,
    required this.pct,
    required this.color,
  });
  final String name;
  final String level;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w400, color: c.stone)),
                    Text(level,
                        style: TextStyle(
                          fontFamily: _mono,
                          fontSize: 9,
                          letterSpacing: 0.6,
                          color: color,
                        )),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 2,
                    backgroundColor: c.inkRaise,
                    valueColor: AlwaysStoppedAnimation(color),
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

// ═══════════════════════════════════════════════════════
// FORMATIONS APERÇU (placeholder)
// ═══════════════════════════════════════════════════════

class _FormationsApercu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
            child: Row(
              children: [
                Text('Formations',
                    style: TextStyle(
                      fontFamily: _serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: c.stone,
                      letterSpacing: -0.4,
                    )),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('Bientôt',
                      style: TextStyle(
                        fontFamily: _mono,
                        fontSize: 8,
                        letterSpacing: 1,
                        color: c.stoneFaint,
                      )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.inkRaise,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, color: c.stoneFaint, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les formations culturelles seront bientôt disponibles.',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w300,
                          color: c.stoneDim),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RIGHT PANEL — Lignée + Villages + Complétion
// ═══════════════════════════════════════════════════════

class _RightPanel extends ConsumerWidget {
  const _RightPanel({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GwColors.of(context);
    final myVillages = ref.watch(myVillagesNotifierProvider);

    return Container(
      color: c.ink,
      child: Column(
        children: [
          // Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Text('CONNEXIONS',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: c.stoneDim,
                    )),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Lignée directe
                _RightBlock(
                  label: 'LIGNÉE DIRECTE',
                  child: _FiliationTree(user: user),
                ),

                // Mes villages
                _RightBlock(
                  label: 'MES VILLAGES',
                  child: myVillages.when(
                    loading: () => SizedBox(
                        height: 40,
                        child: Center(
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: c.gold)))),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (villages) => Column(
                      children: [
                        for (final v in villages)
                          _VillageChip(
                            name: v.name,
                            memberCount: v.memberCount,
                            onTap: () =>
                                context.push(Routes.villageDetail(v.id)),
                          ),
                        if (villages.isEmpty)
                          Text('Aucun village',
                              style: TextStyle(
                                  fontSize: 12, color: c.stoneFaint)),
                      ],
                    ),
                  ),
                ),

                // Complétion profil
                _RightBlock(
                  label: 'COMPLÉTER LE PROFIL',
                  child: _CompletionChecklist(user: user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// FILIATION TREE (Right Panel)
// ═══════════════════════════════════════════════════════

class _FiliationTree extends StatelessWidget {
  const _FiliationTree({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Column(
      children: [
        // Vous
        _FiliationRow(
          initials: _initial(user),
          name: user.displayName ?? 'Vous',
          relation: 'Vous',
          bgColor: c.goldFaint,
          borderColor: c.goldLine,
          textColor: c.gold,
          isMe: true,
        ),

        // Père
        if (user.fatherName != null)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _FiliationRow(
              initials: user.fatherName!
                  .split(' ')
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase(),
              name: user.fatherName!,
              relation: 'Père',
              bgColor: c.azureBg,
              borderColor: c.azureLine,
              textColor: c.azureLight,
            ),
          ),

        // Mère
        if (user.motherName != null)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _FiliationRow(
              initials: user.motherName!
                  .split(' ')
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase(),
              name: user.motherName!,
              relation: 'Mère',
              bgColor: c.emberBg,
              borderColor: c.emberLine,
              textColor: c.emberLight,
            ),
          ),

        if (user.fatherName != null || user.motherName != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.sageBg,
                border: Border.all(color: c.sageLine),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 12, color: c.sage),
                  const SizedBox(width: 8),
                  Text(
                    '${(user.fatherName != null ? 1 : 0) + (user.motherName != null ? 1 : 0)} liens directs',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w300,
                        color: c.sage),
                  ),
                ],
              ),
            ),
          ),

        if (user.fatherName == null && user.motherName == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.inkRaise,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ajoutez vos parents pour débloquer la lignée.',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w300, color: c.stoneDim),
            ),
          ),
      ],
    );
  }
}

class _FiliationRow extends StatelessWidget {
  const _FiliationRow({
    required this.initials,
    required this.name,
    required this.relation,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.isMe = false,
  });
  final String initials;
  final String name;
  final String relation;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: TextStyle(
                  fontFamily: _serif,
                  fontSize: 9,
                  color: textColor,
                )),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? c.stone : c.stoneMid,
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                    )),
                Text(relation,
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 9,
                      color: c.stoneFaint,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// VILLAGE CHIP (Right Panel)
// ═══════════════════════════════════════════════════════

class _VillageChip extends StatelessWidget {
  const _VillageChip({
    required this.name,
    this.memberCount,
    this.onTap,
  });
  final String name;
  final int? memberCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: c.inkRaise,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: TextStyle(fontSize: 12, color: c.stone)),
              ),
              if (memberCount != null)
                Text('$memberCount',
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 9,
                      color: c.stoneFaint,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// COMPLETION CHECKLIST (Right Panel)
// ═══════════════════════════════════════════════════════

class _CompletionChecklist extends StatelessWidget {
  const _CompletionChecklist({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    final items = <_CheckItem>[
      _CheckItem('Identité renseignée', user.displayName != null),
      _CheckItem('Biographie ajoutée', user.bio != null && user.bio!.isNotEmpty),
      _CheckItem('Photo de profil', user.avatarUrl != null, bonus: 8),
      _CheckItem('Village rejoint', true), // s'il voit le profil, il est inscrit
      _CheckItem('Parents ajoutés', user.fatherName != null || user.motherName != null, bonus: 12),
      _CheckItem('Date de naissance', false, bonus: 8),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: item.done ? c.sageBg : c.inkRaise,
                border: Border.all(
                    color: item.done ? c.sageLine : c.line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    item.done
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: item.done ? c.sage : c.stoneDim,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: item.done ? c.sage : c.stoneDim,
                        )),
                  ),
                  if (!item.done && item.bonus != null)
                    Text('+${item.bonus} %',
                        style: TextStyle(
                          fontFamily: _mono,
                          fontSize: 8.5,
                          color: c.goldDim,
                        )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.done, {this.bonus});
  final String label;
  final bool done;
  final int? bonus;
}

// ═══════════════════════════════════════════════════════
// COMING SOON PANE (tabs secondaires)
// ═══════════════════════════════════════════════════════

class _ComingSoonPane extends StatelessWidget {
  const _ComingSoonPane({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: c.stoneFaint),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  fontFamily: _serif,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: c.stone,
                )),
            const SizedBox(height: 8),
            Text('Cette section sera bientôt disponible.',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: c.stoneDim)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.letter,
    required this.size,
    required this.color,
  });
  final String letter;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c.goldDim, color, c.goldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.goldLine, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: TextStyle(
            fontFamily: _serif,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w500,
            color: c.inkDeep,
          )),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    const size = 92.0;
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.inkDeep, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x38C9A84C), blurRadius: 32),
            ],
          ),
          child: ClipOval(
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _MiniAvatar(letter: _initial(user), size: size, color: c.gold),
                  )
                : _MiniAvatar(letter: _initial(user), size: size, color: c.gold),
          ),
        ),
        // Online status dot
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: c.sage,
              shape: BoxShape.circle,
              border: Border.all(color: c.inkDeep, width: 2.5),
            ),
            child: const Icon(Icons.check, size: 9, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: c.line,
    );
  }
}

class _RailSection extends StatelessWidget {
  const _RailSection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(label,
          style: TextStyle(
            fontFamily: _mono,
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: c.stoneFaint,
          )),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  _RailNavItem({
    required this.icon,
    required this.label,
    this.count,
    this.active = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.goldFaint : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? c.gold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active ? c.goldFaint : c.inkRaise,
                border: Border.all(color: active ? c.goldLine : c.line),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon,
                  size: 13,
                  color: active ? c.gold : c.stoneDim),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: active ? c.stone : c.stoneDim,
                  )),
            ),
            if (count != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? c.goldFaint : c.inkRaise,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(count!,
                    style: TextStyle(
                      fontFamily: _mono,
                      fontSize: 9,
                      color: active ? c.goldDim : c.stoneFaint,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Item clan dans le rail gauche ────────────────────────────
class _RailClanItem extends StatelessWidget {
  const _RailClanItem({
    required this.name,
    required this.pending,
    required this.c,
  });
  final String name;
  final bool pending;
  final GwColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          // Icône clan / en attente
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: pending ? c.inkRaise : c.goldFaint,
              border: Border.all(color: pending ? c.line : c.goldLine),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              pending ? Icons.hourglass_top_outlined : Icons.fort_outlined,
              size: 13,
              color: pending ? c.stoneFaint : c.goldDim,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: pending ? c.stoneFaint : c.stoneDim,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: c.inkRaise,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'EN ATTENTE',
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 7.5,
                  letterSpacing: 0.6,
                  color: c.stoneFaint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RightBlock extends StatelessWidget {
  const _RightBlock({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GwColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: _mono,
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: c.stoneFaint,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabBar});
  final TabBar tabBar;

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = GwColors.of(context);
    return Container(
      color: c.ink,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
// HERO CANVAS PAINTER
// ═══════════════════════════════════════════════════════

class _HeroCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gold centre-right glow
    final goldPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.2),
        radius: 0.8,
        colors: [
          const Color(0x22B48A32),
          const Color(0x0D785A1E),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), goldPaint);

    // Sage left breath
    final sagePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.84, 0.4),
        radius: 0.5,
        colors: [
          const Color(0x122A7A5C),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sagePaint);

    // Kente texture lines
    final linePaint = Paint()
      ..color = const Color(0x07B48C32)
      ..strokeWidth = 0.6;
    for (double y = 0; y < h; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
    }

    // Diagonal pattern
    final diagPaint = Paint()
      ..color = const Color(0x06C9A84C)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double i = -h; i < w + h; i += 32) {
      canvas.drawLine(Offset(i, 0), Offset(i + h, h), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════
// UTILS
// ═══════════════════════════════════════════════════════

String _initial(UserModel user) {
  return (user.displayName ?? user.email).substring(0, 1).toUpperCase();
}
