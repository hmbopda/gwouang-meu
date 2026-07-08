import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/auth/auth_notifier.dart';
import 'package:gwangmeu/features/geo/geo_notifier.dart';
import 'package:gwangmeu/shared/models/country_model.dart';
import 'package:gwangmeu/shared/models/village_model.dart';

/// Écran d'authentification « Tissage » — connexion + inscription en 3 étapes.
///
/// Refonte selon la maquette #3d « P4 Onboarding Origines » :
/// bande tissée signature, progression 3 segments, titres Fraunces 28,
/// recherche village, cartes sélectionnables or + preuve sociale mono sage,
/// chips clan, note de confidentialité, CTA or 54 px.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;

  // ── État de l'assistant d'inscription ──
  int _regStep = 0; // 0=profil, 1=origines, 2=récapitulatif
  final _regFormKeys = [GlobalKey<FormState>(), GlobalKey<FormState>()];
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regBioCtrl = TextEditingController();
  final _regLanguageCtrl = TextEditingController();
  bool _regObscure = true;
  String? _regSelectedGender;
  CountryModel? _regSelectedCountry;
  List<VillageModel> _regSelectedVillages = [];
  final _regClanCtrl = TextEditingController();

  // Recherche village + saisie libre du clan (étape Origines).
  final _villageSearchCtrl = TextEditingController();
  String _villageSearchQuery = '';
  bool _clanOtherSelected = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regBioCtrl.dispose();
    _regLanguageCtrl.dispose();
    _regClanCtrl.dispose();
    _villageSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        context.go(Routes.feed);
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(next.error.toString())),
            backgroundColor: GwTokens.ember,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: t.ink,
      body: SafeArea(
        child: Column(
          children: [
            const GwWeaveBand(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _mode == AuthMode.register
                      ? _buildRegistrationWizard(authState)
                      : _buildLoginForm(authState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONNEXION / MOT DE PASSE OUBLIÉ
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginForm(AsyncValue authState) {
    final t = GwTokens.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildLogo(),
          const SizedBox(height: 28),

          Text(
            'MBƐ́Ɛ — BIENVENUE',
            style: GwType.mono(
                fontSize: 10, color: t.goldText, letterSpacing: 2.5),
          ),
          const SizedBox(height: 10),
          Text(
            _mode == AuthMode.login ? 'Connexion' : 'Mot de passe oublié',
            style: GwType.display(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: t.stone,
                height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == AuthMode.login
                ? 'Retrouvez votre communauté'
                : 'Recevez un lien de réinitialisation',
            style: GwType.ui(fontSize: 14.5, color: t.stoneMid, height: 1.5),
          ),
          const SizedBox(height: 24),

          Form(
            key: _loginFormKey,
            child: Column(
              children: [
                _tissageField(
                  controller: _emailCtrl,
                  label: 'Adresse email',
                  hint: 'nom@exemple.com',
                  icon: Symbols.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                if (_mode != AuthMode.forgotPassword) ...[
                  const SizedBox(height: 14),
                  _tissageField(
                    controller: _passwordCtrl,
                    label: 'Mot de passe',
                    hint: 'Minimum 6 caractères',
                    icon: Symbols.lock,
                    obscure: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: _validatePassword,
                  ),
                ],
              ],
            ),
          ),

          if (_mode == AuthMode.login)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() => _mode = AuthMode.forgotPassword),
                child: Text(
                  'Mot de passe oublié ?',
                  style: GwType.ui(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: t.goldText),
                ),
              ),
            )
          else
            const SizedBox(height: 20),

          _goldCta(
            label: _mode == AuthMode.login ? 'Se connecter' : 'Envoyer le lien',
            loading: authState is AsyncLoading,
            onPressed: _submitLogin,
          ),
          const SizedBox(height: 14),

          if (_mode == AuthMode.login)
            _outlineCta(
              label: 'Créer un compte',
              icon: Symbols.person_add,
              onPressed: () => setState(() {
                _mode = AuthMode.register;
                _regStep = 0;
              }),
            )
          else
            _ghostCta(
              label: 'Retour à la connexion',
              onPressed: () => setState(() => _mode = AuthMode.login),
            ),

          if (_mode != AuthMode.forgotPassword) ...[
            const SizedBox(height: 28),
            _buildDividerOr(),
            const SizedBox(height: 20),
            _SocialGrid(
              onTap: (provider) => ref
                  .read(authNotifierProvider.notifier)
                  .signInWithSocial(provider),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ASSISTANT D'INSCRIPTION (3 étapes)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRegistrationWizard(AsyncValue authState) {
    final t = GwTokens.of(context);
    return Column(
      children: [
        // ── En-tête : retour + progression 3 segments + compteur mono ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              _backSquare(onTap: () {
                if (_regStep > 0) {
                  setState(() => _regStep--);
                } else {
                  setState(() => _mode = AuthMode.login);
                }
              }),
              const SizedBox(width: 14),
              Expanded(child: _buildStepSegments(t)),
              const SizedBox(width: 14),
              Text(
                '${_regStep + 1}/3',
                style: GwType.mono(fontSize: 11, color: t.stoneFaint),
              ),
            ],
          ),
        ),

        // ── Contenu de l'étape ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: [
                _buildStep0Personal,
                _buildStep1Origins,
                _buildStep2Recap,
              ][_regStep](authState),
            ),
          ),
        ),
      ],
    );
  }

  /// Barre de progression : segment actif or plein, inactifs inkHigh,
  /// hauteur 4 px, rayon pilule, gap 6 px.
  Widget _buildStepSegments(GwTokens t) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rPill),
              color: i <= _regStep ? GwTokens.gold : t.inkHigh,
            ),
          ),
        );
      }),
    );
  }

  /// En-tête d'étape : label mono « ÉTAPE X SUR 3 », titre Fraunces 28,
  /// sous-titre Syne stoneMid.
  Widget _stepHeading({
    required String kicker,
    required String title,
    required String subtitle,
  }) {
    final t = GwTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style:
              GwType.mono(fontSize: 10, color: t.goldText, letterSpacing: 2.5),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GwType.display(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: t.stone,
              height: 1.2),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GwType.ui(fontSize: 14.5, color: t.stoneMid, height: 1.6),
        ),
      ],
    );
  }

  // ── ÉTAPE 0 : profil ──

  Widget _buildStep0Personal(AsyncValue authState) {
    final t = GwTokens.of(context);
    return Form(
      key: _regFormKeys[0],
      child: Column(
        key: const ValueKey('step0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeading(
            kicker: 'ÉTAPE 1 SUR 3 · VOTRE PROFIL',
            title: 'Qui êtes-vous ?',
            subtitle:
                'Votre nom relie votre mémoire à celle des vôtres. Créez votre accès en quelques instants.',
          ),
          const SizedBox(height: 24),

          _sectionMono('IDENTITÉ'),
          const SizedBox(height: 12),

          _tissageField(
            controller: _regNameCtrl,
            label: 'Nom complet',
            hint: 'Ex : Amara Kouassi',
            icon: Symbols.person,
            validator: (v) =>
                (v == null || v.length < 2) ? 'Minimum 2 caractères' : null,
          ),
          const SizedBox(height: 14),

          _tissageField(
            controller: _regEmailCtrl,
            label: 'Adresse email',
            hint: 'nom@exemple.com',
            icon: Symbols.mail,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),

          _tissageField(
            controller: _regPasswordCtrl,
            label: 'Mot de passe',
            hint: 'Minimum 6 caractères',
            icon: Symbols.lock,
            obscure: _regObscure,
            onToggleObscure: () => setState(() => _regObscure = !_regObscure),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: _regSelectedGender,
            decoration: _fieldDecoration(
              label: 'Genre',
              hint: 'Sélectionnez votre genre',
              icon: Symbols.wc,
            ),
            style: GwType.ui(fontSize: 14.5, color: t.stone),
            dropdownColor: t.inkLift,
            iconEnabledColor: t.stoneDim,
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Homme')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Femme')),
              DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _regSelectedGender = v),
            validator: (v) => v == null ? 'Le genre est obligatoire' : null,
          ),

          const SizedBox(height: 28),

          _goldCta(
            label: 'Continuer',
            icon: Symbols.arrow_forward,
            onPressed: () {
              if (_regFormKeys[0].currentState!.validate()) {
                setState(() => _regStep = 1);
              }
            },
          ),

          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _mode = AuthMode.login),
              child: RichText(
                text: TextSpan(
                  text: 'Déjà un compte ? ',
                  style: GwType.ui(fontSize: 13.5, color: t.stoneMid),
                  children: [
                    TextSpan(
                      text: 'Se connecter',
                      style: GwType.ui(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: t.goldText),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── ÉTAPE 1 : origines (maquette #3d) ──

  Widget _buildStep1Origins(AsyncValue authState) {
    final t = GwTokens.of(context);
    return Form(
      key: _regFormKeys[1],
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeading(
            kicker: 'ÉTAPE 2 SUR 3 · VOS ORIGINES',
            title: 'D\'où vient votre famille ?',
            subtitle:
                'Votre village relie votre profil à votre lignée. Vous pourrez en ajouter d\'autres ensuite.',
          ),
          const SizedBox(height: 24),

          _sectionMono('PAYS D\'ORIGINE'),
          const SizedBox(height: 12),
          _countryDropdown(t),

          const SizedBox(height: 20),
          _sectionMono('VILLAGE(S) D\'ORIGINE'),
          const SizedBox(height: 12),
          _villageSection(t),

          // ── Clan (facultatif) ──
          if (_regSelectedVillages.isNotEmpty) ...[
            const SizedBox(height: 20),
            _clanCard(t),
          ],

          const SizedBox(height: 20),
          _sectionMono('LANGUE MATERNELLE'),
          const SizedBox(height: 12),
          _tissageField(
            controller: _regLanguageCtrl,
            label: 'Langue native',
            hint: 'Ex : Bassa, Ewondo, Wolof…',
            icon: Symbols.record_voice_over,
          ),

          const SizedBox(height: 20),
          _sectionMono('À PROPOS DE VOUS (FACULTATIF)'),
          const SizedBox(height: 8),
          Text(
            'Parlez de vous, de votre lien avec votre village.',
            style: GwType.ui(fontSize: 12.5, color: t.stoneDim, height: 1.5),
          ),
          const SizedBox(height: 12),
          _tissageField(
            controller: _regBioCtrl,
            label: 'Bio',
            hint: 'Diaspora Paris, passionné de culture Bassa…',
            icon: Symbols.notes,
            maxLines: 3,
            maxLength: 200,
          ),

          const SizedBox(height: 24),

          _goldCta(
            label: 'Continuer',
            icon: Symbols.arrow_forward,
            onPressed: () {
              if (_regFormKeys[1].currentState?.validate() ?? true) {
                setState(() => _regStep = 2);
              }
            },
          ),

          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _regStep = 2),
              child: Text(
                'Je préfère répondre plus tard',
                style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Sélecteur de pays stylé Tissage (les villages en dépendent).
  Widget _countryDropdown(GwTokens t) {
    final countriesAsync = ref.watch(countriesNotifierProvider);
    return countriesAsync.when(
      loading: () => LinearProgressIndicator(
        minHeight: 2,
        color: GwTokens.gold,
        backgroundColor: t.inkLift,
      ),
      error: (_, __) => _infoCard(
        t,
        icon: Symbols.error,
        text: 'Impossible de charger les pays. Réessayez plus tard.',
      ),
      data: (countries) => DropdownButtonFormField<CountryModel>(
        initialValue: _regSelectedCountry,
        decoration: _fieldDecoration(
          label: 'Pays',
          hint: 'Sélectionnez votre pays',
          icon: Symbols.public,
        ),
        style: GwType.ui(fontSize: 14.5, color: t.stone),
        dropdownColor: t.inkLift,
        iconEnabledColor: t.stoneDim,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        isExpanded: true,
        items: countries
            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
            .toList(),
        onChanged: (c) => setState(() {
          _regSelectedCountry = c;
          _regSelectedVillages = [];
          _regClanCtrl.clear();
          _clanOtherSelected = false;
          _villageSearchCtrl.clear();
          _villageSearchQuery = '';
        }),
      ),
    );
  }

  /// Recherche + cartes de sélection village (maquette #3d).
  Widget _villageSection(GwTokens t) {
    if (_regSelectedCountry == null) {
      return _infoCard(
        t,
        icon: Symbols.travel_explore,
        text: 'Choisissez d\'abord un pays pour découvrir ses villages.',
      );
    }

    final villagesAsync = ref.watch(
      villagesByCountryNotifierProvider(_regSelectedCountry?.isoCode),
    );

    return villagesAsync.when(
      loading: () => LinearProgressIndicator(
        minHeight: 2,
        color: GwTokens.gold,
        backgroundColor: t.inkLift,
      ),
      error: (_, __) => _infoCard(
        t,
        icon: Symbols.error,
        text: 'Impossible de charger les villages. Réessayez plus tard.',
      ),
      data: (villages) {
        if (villages.isEmpty) {
          return _infoCard(
            t,
            icon: Symbols.location_off,
            text: 'Aucun village enregistré pour ce pays pour le moment.',
          );
        }

        final query = _villageSearchQuery.trim().toLowerCase();
        final selectedIds = _regSelectedVillages.map((v) => v.id).toSet();
        final matches = villages
            .where((v) => !selectedIds.contains(v.id))
            .where((v) =>
                query.isEmpty ||
                v.name.toLowerCase().contains(query) ||
                (v.region?.toLowerCase().contains(query) ?? false) ||
                (v.primaryDialect?.toLowerCase().contains(query) ?? false))
            .toList();
        const maxShown = 8;
        final shown = matches.take(maxShown).toList();
        final hidden = matches.length - shown.length;
        final selCount = _regSelectedVillages.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _villageSearchField(t),
            const SizedBox(height: 8),
            Text(
              '${villages.length} VILLAGES'
              '${selCount > 0 ? ' · $selCount SÉLECTIONNÉ${selCount > 1 ? 'S' : ''}' : ''}',
              style: GwType.mono(
                  fontSize: 10, color: t.stoneFaint, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),

            // Villages sélectionnés d'abord, puis les correspondances.
            for (final v in _regSelectedVillages)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _villageCard(t, v, selected: true, tintIndex: 0),
              ),
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _villageCard(t, shown[i], selected: false, tintIndex: i),
              ),

            if (shown.isEmpty && _regSelectedVillages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun village ne correspond à « $_villageSearchQuery ».',
                  style: GwType.ui(fontSize: 13.5, color: t.stoneDim),
                ),
              )
            else if (hidden > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+$hidden autres villages — affinez votre recherche',
                    style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Champ recherche village : ≥ 50 px, fond inkLift, rayon 14, icône search.
  Widget _villageSearchField(GwTokens t) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: _villageSearchCtrl,
      onChanged: (v) => setState(() => _villageSearchQuery = v),
      style: GwType.ui(fontSize: 14.5, color: t.stone),
      cursorColor: GwTokens.gold,
      decoration: InputDecoration(
        hintText: 'Rechercher un village…',
        hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
        filled: true,
        fillColor: t.inkLift,
        prefixIcon: Icon(Symbols.search, size: 20, color: t.stoneDim),
        suffixIcon: _villageSearchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Symbols.close, size: 18, color: t.stoneDim),
                onPressed: () {
                  _villageSearchCtrl.clear();
                  setState(() => _villageSearchQuery = '');
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: border(t.line),
        focusedBorder: border(GwTokens.gold, 1.5),
      ),
    );
  }

  /// Carte village sélectionnable : tuile initiale Fraunces teintée,
  /// nom 15 w600, méta 12.5 stoneDim ; sélectionnée = fond/bordure or +
  /// check_circle rempli + preuve sociale mono sage.
  Widget _villageCard(
    GwTokens t,
    VillageModel v, {
    required bool selected,
    required int tintIndex,
  }) {
    const tints = [
      Color(0xFF70C090), // sage clair
      Color(0xFF7AA8E0), // azure clair
      GwTokens.rose,
      GwTokens.goldLight,
    ];
    final tint = selected ? GwTokens.gold : tints[tintIndex % tints.length];

    final metaParts = <String>[
      v.region ?? v.country,
      if (v.primaryDialect != null) 'dialecte ${v.primaryDialect}',
      if (v.memberCount > 0) '${v.memberCount} membres',
    ];

    return Material(
      color: selected ? GwTokens.gold.withValues(alpha: 0.12) : t.inkCard,
      borderRadius: BorderRadius.circular(GwTokens.rCard),
      child: InkWell(
        onTap: () => _toggleVillage(v),
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rCard),
            border: Border.all(
              color: selected ? GwTokens.gold.withValues(alpha: 0.55) : t.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  v.name.isNotEmpty ? v.name[0].toUpperCase() : '?',
                  style: GwType.display(
                      fontSize: 20, color: GwTokens.inkOnGold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.stone),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 5),
                      Text(
                        _socialProof(v),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GwType.mono(
                            fontSize: 11,
                            color: t.sageText,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (selected)
                Icon(Symbols.check_circle,
                    fill: 1, size: 24, color: t.goldText)
              else
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.lineMid, width: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Preuve sociale mono sage sous la carte sélectionnée.
  String _socialProof(VillageModel v) {
    if (v.memberCount > 0) {
      return '${v.memberCount} MEMBRE${v.memberCount > 1 ? 'S' : ''} '
          'Y ${v.memberCount > 1 ? 'SONT' : 'EST'} DÉJÀ';
    }
    return 'VOTRE FAMILLE Y SERA LA PREMIÈRE';
  }

  void _toggleVillage(VillageModel v) {
    setState(() {
      final exists = _regSelectedVillages.any((sv) => sv.id == v.id);
      if (exists) {
        _regSelectedVillages =
            _regSelectedVillages.where((sv) => sv.id != v.id).toList();
      } else {
        _regSelectedVillages = [..._regSelectedVillages, v];
      }
      // Le clan dépend du premier village sélectionné.
      _regClanCtrl.clear();
      _clanOtherSelected = false;
    });
  }

  /// Carte clan : chips pilules or + saisie libre + note de confidentialité.
  Widget _clanCard(GwTokens t) {
    final firstVillageId =
        _regSelectedVillages.isNotEmpty ? _regSelectedVillages.first.id : null;
    final clansAsync = ref.watch(clansByVillageNotifierProvider(firstVillageId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOTRE CLAN (FACULTATIF)',
            style: GwType.mono(
                fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          clansAsync.when(
            loading: () => LinearProgressIndicator(
              minHeight: 2,
              color: GwTokens.gold,
              backgroundColor: t.inkLift,
            ),
            error: (_, __) => _clanFreeField(),
            data: (clans) {
              if (clans.isEmpty) return _clanFreeField();
              final shown = clans.take(6).toList();
              final currentClan = _regClanCtrl.text.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...shown.map(
                        (c) => _clanChip(
                          t,
                          label: c,
                          selected: !_clanOtherSelected && currentClan == c,
                          onTap: () => setState(() {
                            if (!_clanOtherSelected && currentClan == c) {
                              _regClanCtrl.clear();
                            } else {
                              _regClanCtrl.text = c;
                            }
                            _clanOtherSelected = false;
                          }),
                        ),
                      ),
                      _clanChip(
                        t,
                        label: 'Autre…',
                        selected: _clanOtherSelected,
                        onTap: () => setState(() {
                          _clanOtherSelected = !_clanOtherSelected;
                          _regClanCtrl.clear();
                        }),
                      ),
                    ],
                  ),
                  if (_clanOtherSelected) ...[
                    const SizedBox(height: 12),
                    _clanFreeField(),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.lock, size: 16, color: t.stoneDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le clan aide l\'IA à retrouver vos lignées — il reste privé par défaut.',
                  style:
                      GwType.ui(fontSize: 12.5, color: t.stoneDim, height: 1.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clanFreeField() {
    return _tissageField(
      controller: _regClanCtrl,
      label: 'Clan',
      hint: 'Ex : Basaa, Beti…',
      icon: Symbols.shield,
    );
  }

  Widget _clanChip(
    GwTokens t, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? t.goldBg : t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border: Border.all(
              color: selected ? t.goldLine : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GwType.ui(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? t.goldText : t.stoneMid,
            ),
          ),
        ),
      ),
    );
  }

  // ── ÉTAPE 2 : récapitulatif ──

  Widget _buildStep2Recap(AsyncValue authState) {
    final t = GwTokens.of(context);
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeading(
          kicker: 'ÉTAPE 3 SUR 3 · RÉCAPITULATIF',
          title: 'Tout est prêt ?',
          subtitle: 'Vérifiez vos informations avant de créer votre compte.',
        ),
        const SizedBox(height: 24),

        // Carte récapitulative
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.inkCard,
            borderRadius: BorderRadius.circular(GwTokens.rCardLg),
            border: Border.all(color: t.goldLine),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.goldBg,
                  border: Border.all(color: t.goldLine, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _regNameCtrl.text.isNotEmpty
                      ? _regNameCtrl.text[0].toUpperCase()
                      : '?',
                  style: GwType.display(fontSize: 28, color: t.goldText),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                _regNameCtrl.text,
                style: GwType.display(fontSize: 22, color: t.stone),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: t.goldBg,
                  borderRadius: BorderRadius.circular(GwTokens.rPill),
                  border: Border.all(color: t.goldLine),
                ),
                child: Text(
                  'MEMBRE',
                  style: GwType.mono(
                      fontSize: 10, color: t.goldText, letterSpacing: 2),
                ),
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: t.line),
              const SizedBox(height: 12),

              _recapRow(Symbols.mail, 'Email', _regEmailCtrl.text),
              if (_regSelectedGender != null)
                _recapRow(
                    Symbols.person,
                    'Genre',
                    _regSelectedGender == 'MALE'
                        ? 'Homme'
                        : _regSelectedGender == 'FEMALE'
                            ? 'Femme'
                            : 'Autre'),
              if (_regSelectedCountry != null)
                _recapRow(Symbols.public, 'Pays', _regSelectedCountry!.name),
              if (_regSelectedVillages.isNotEmpty)
                _recapRow(Symbols.location_on, 'Village(s)',
                    _regSelectedVillages.map((v) => v.name).join(', ')),
              if (_regClanCtrl.text.isNotEmpty)
                _recapRow(Symbols.shield, 'Clan', _regClanCtrl.text),
              if (_regLanguageCtrl.text.isNotEmpty)
                _recapRow(Symbols.record_voice_over, 'Langue native',
                    _regLanguageCtrl.text),
              if (_regBioCtrl.text.isNotEmpty)
                _recapRow(Symbols.notes, 'Bio', _regBioCtrl.text),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Boutons d'édition
        Row(
          children: [
            Expanded(child: _editStepButton('Modifier le profil', 0)),
            const SizedBox(width: 10),
            Expanded(child: _editStepButton('Modifier les origines', 1)),
          ],
        ),

        const SizedBox(height: 24),

        _goldCta(
          label: 'Créer mon compte',
          icon: Symbols.check_circle,
          loading: authState is AsyncLoading,
          onPressed: _submitRegistration,
        ),

        const SizedBox(height: 12),
        Center(
          child: Text(
            'En créant un compte, vous acceptez les conditions d\'utilisation',
            style: GwType.ui(fontSize: 12, color: t.stoneDim, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _editStepButton(String label, int step) {
    final t = GwTokens.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: () => setState(() => _regStep = step),
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          height: GwTokens.tapTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(color: t.lineMid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.edit, size: 16, color: t.stoneMid),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: t.stoneMid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value) {
    final t = GwTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: t.stoneDim),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GwType.ui(fontSize: 12.5, color: t.stoneMid),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GwType.ui(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: t.stone),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  WIDGETS PARTAGÉS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bouton retour carré 44 px, fond inkLift, rayon 14.
  Widget _backSquare({required VoidCallback onTap}) {
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
          child: Icon(Symbols.arrow_back, size: 20, color: t.stoneMid),
        ),
      ),
    );
  }

  /// CTA principal or plein : hauteur 54 px, rayon 14, texte 15 w700.
  Widget _goldCta({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Material(
        color: GwTokens.gold,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: GwTokens.inkOnGold,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GwType.ui(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: GwTokens.inkOnGold,
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 18, color: GwTokens.inkOnGold),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Bouton secondaire : contour or, rayon 14, hauteur 50 px.
  Widget _outlineCta({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final t = GwTokens.of(context);
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
              border: Border.all(color: t.goldLine, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: t.goldText),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GwType.ui(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: t.goldText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton discret (texte seul), cible 44 px.
  Widget _ghostCta({required String label, required VoidCallback onPressed}) {
    final t = GwTokens.of(context);
    return SizedBox(
      height: GwTokens.tapTarget,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: GwType.ui(
              fontSize: 14, fontWeight: FontWeight.w500, color: t.stoneMid),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final t = GwTokens.of(context);
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 160,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: t.goldBg,
                borderRadius: BorderRadius.circular(GwTokens.rCardLg),
                border: Border.all(color: GwTokens.gold, width: 1.5),
              ),
              child: Icon(Symbols.language, color: t.goldText, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'GWANG MEU',
              style: GwType.display(
                  fontSize: 24, color: t.goldText, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Text(
              'LANGUES · CULTURE · FUTUR',
              style: GwType.mono(
                  fontSize: 10, color: t.stoneDim, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Label de section mono (10 px, MAJUSCULES, letter-spacing 2).
  Widget _sectionMono(String text) {
    final t = GwTokens.of(context);
    return Text(
      text,
      style: GwType.mono(fontSize: 10, color: t.stoneFaint, letterSpacing: 2),
    );
  }

  /// Encart d'information neutre (états vides / erreurs).
  Widget _infoCard(GwTokens t, {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCard),
        border: Border.all(color: t.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: t.stoneDim),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GwType.ui(fontSize: 13.5, color: t.stoneDim, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Champ de saisie Tissage : fond inkLift, rayon 14, focus or.
  Widget _tissageField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    final t = GwTokens.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GwType.ui(fontSize: 14.5, color: t.stone),
      cursorColor: GwTokens.gold,
      decoration: _fieldDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffix: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Symbols.visibility_off : Symbols.visibility,
                  size: 20,
                  color: t.stoneDim,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    final t = GwTokens.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: GwType.ui(fontSize: 14, color: t.stoneMid),
      floatingLabelStyle: GwType.ui(fontSize: 12, color: t.goldText),
      hintText: hint,
      hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
      filled: true,
      fillColor: t.inkLift,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: t.stoneDim) : null,
      suffixIcon: suffix,
      counterStyle:
          GwType.mono(fontSize: 10, color: t.stoneFaint, letterSpacing: 1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(t.line),
      focusedBorder: border(GwTokens.gold, 1.5),
      errorBorder: border(t.emberText),
      focusedErrorBorder: border(t.emberText, 1.5),
      errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
    );
  }

  Widget _buildDividerOr() {
    final t = GwTokens.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: t.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou continuer avec',
            style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
          ),
        ),
        Expanded(child: Container(height: 1, color: t.line)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SOUMISSION
  // ═══════════════════════════════════════════════════════════════════════════

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);
    switch (_mode) {
      case AuthMode.login:
        notifier.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      case AuthMode.forgotPassword:
        notifier.resetPassword(_emailCtrl.text.trim());
      case AuthMode.register:
        break;
    }
  }

  void _submitRegistration() {
    ref.read(authNotifierProvider.notifier).signUp(
          email: _regEmailCtrl.text.trim(),
          password: _regPasswordCtrl.text,
          displayName: _regNameCtrl.text.trim(),
          country: _regSelectedCountry?.name,
          nativeLanguage: _regLanguageCtrl.text.trim().isEmpty
              ? null
              : _regLanguageCtrl.text.trim(),
          bio: _regBioCtrl.text.trim().isEmpty ? null : _regBioCtrl.text.trim(),
          villageIds: _regSelectedVillages.isNotEmpty
              ? _regSelectedVillages.map((v) => v.id).toList()
              : null,
          clan: _regClanCtrl.text.trim().isEmpty
              ? null
              : _regClanCtrl.text.trim(),
          gender: _regSelectedGender!,
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VALIDATEURS
  // ═══════════════════════════════════════════════════════════════════════════

  String? _validateEmail(String? v) =>
      (v == null || !v.contains('@')) ? 'Email invalide' : null;

  String? _validatePassword(String? v) =>
      (v == null || v.length < 6) ? 'Minimum 6 caractères' : null;

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Email ou mot de passe incorrect';
    if (raw.contains('Email not confirmed')) {
      return 'Confirmez votre email d\'abord';
    }
    if (raw.contains('already registered')) return 'Cet email est déjà utilisé';
    if (raw.contains('rate limit')) {
      return 'Trop de tentatives. Attendez quelques minutes.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GRILLE SOCIALE
// ═══════════════════════════════════════════════════════════════════════════════

class _SocialGrid extends StatelessWidget {
  final void Function(OAuthProvider) onTap;
  const _SocialGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                initial: 'G',
                brandColor: const Color(0xFFDB4437),
                onTap: () => onTap(OAuthProvider.google),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                initial: 'f',
                brandColor: const Color(0xFF1877F2),
                onTap: () => onTap(OAuthProvider.facebook),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                initial: 'A',
                brandColor: t.stone,
                onTap: () => onTap(OAuthProvider.apple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'GitHub',
                initial: 'G',
                brandColor: const Color(0xFF6E40C9),
                onTap: () => onTap(OAuthProvider.github),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Twitter / X',
                initial: 'X',
                brandColor: t.stone,
                onTap: () => onTap(OAuthProvider.twitter),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'LinkedIn',
                initial: 'in',
                brandColor: const Color(0xFF0A66C2),
                onTap: () => onTap(OAuthProvider.linkedin),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bouton social sans dépendance d'icônes de marque : pastille ronde
/// portant l'initiale du fournisseur (Fraunces, couleur de marque) + libellé.
class _SocialButton extends StatelessWidget {
  final String label;
  final String initial;
  final Color brandColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.initial,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: brandColor.withValues(alpha: 0.07),
        side: BorderSide(color: brandColor.withValues(alpha: 0.28)),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.16),
              border: Border.all(color: brandColor.withValues(alpha: 0.45)),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GwType.display(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: brandColor,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GwType.ui(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.stone,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
