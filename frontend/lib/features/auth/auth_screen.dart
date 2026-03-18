import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/country_model.dart';
import '../../shared/models/village_model.dart';
import '../../shared/widgets/country_village_selector.dart';
import '../../shared/widgets/gwang_button.dart';
import '../geo/geo_notifier.dart';
import 'auth_notifier.dart';

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

  // ── Registration wizard state ──
  int _regStep = 0; // 0=personal, 1=origins, 2=recap
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        context.go(Routes.feed);
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(next.error.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _mode == AuthMode.register
                ? _buildRegistrationWizard(authState)
                : _buildLoginForm(authState),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOGIN / FORGOT PASSWORD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginForm(AsyncValue authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          _buildLogo(),
          const SizedBox(height: 40),

          Text(
            _mode == AuthMode.login ? 'Connexion' : 'Mot de passe oublie',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _mode == AuthMode.login
                ? 'Retrouvez votre communaute'
                : 'Recevez un lien de reinitialisation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          Form(
            key: _loginFormKey,
            child: Column(
              children: [
                _styledField(
                  controller: _emailCtrl,
                  label: 'Adresse email',
                  hint: 'nom@exemple.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                if (_mode != AuthMode.forgotPassword) ...[
                  const SizedBox(height: 14),
                  _styledField(
                    controller: _passwordCtrl,
                    label: 'Mot de passe',
                    hint: 'Minimum 6 caracteres',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
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
                onPressed: () => setState(() => _mode = AuthMode.forgotPassword),
                child: const Text('Mot de passe oublie ?'),
              ),
            )
          else
            const SizedBox(height: 20),

          GwangButton(
            label: _mode == AuthMode.login ? 'Se connecter' : 'Envoyer le lien',
            loading: authState is AsyncLoading,
            onPressed: _submitLogin,
          ),
          const SizedBox(height: 14),

          if (_mode == AuthMode.login)
            GwangButton(
              label: 'Creer un compte',
              variant: GwangButtonVariant.outline,
              icon: Icons.person_add_outlined,
              onPressed: () => setState(() {
                _mode = AuthMode.register;
                _regStep = 0;
              }),
            )
          else
            GwangButton(
              label: 'Retour a la connexion',
              variant: GwangButtonVariant.ghost,
              onPressed: () => setState(() => _mode = AuthMode.login),
            ),

          if (_mode != AuthMode.forgotPassword) ...[
            const SizedBox(height: 28),
            _buildDividerOr(),
            const SizedBox(height: 20),
            _SocialGrid(
              onTap: (provider) =>
                  ref.read(authNotifierProvider.notifier).signInWithSocial(provider),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REGISTRATION WIZARD (3 steps)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRegistrationWizard(AsyncValue authState) {
    return Column(
      children: [
        // ── Header with back + step info ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_regStep > 0) {
                    setState(() => _regStep--);
                  } else {
                    setState(() => _mode = AuthMode.login);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etape ${_regStep + 1} sur 3',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['Informations personnelles', 'Origines & Langue', 'Recapitulatif'][_regStep],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Step indicators ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _buildStepIndicator(),
        ),

        const SizedBox(height: 24),

        // ── Step content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
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

  // ── Step indicator bar ──

  Widget _buildStepIndicator() {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= _regStep;
        final isCurrent = i == _regStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive ? accent : AppColors.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? accent : AppColors.surfaceAlt,
                      ),
                      alignment: Alignment.center,
                      child: i < _regStep
                          ? const Icon(Icons.check, size: 12, color: Colors.black)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.black : AppColors.textHint,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ['Profil', 'Origines', 'Confirmer'][i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? accent : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── STEP 0: Personal info ──

  Widget _buildStep0Personal(AsyncValue authState) {
    final accent = Theme.of(context).colorScheme.primary;
    return Form(
      key: _regFormKeys[0],
      child: Column(
        key: const ValueKey('step0'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Identite'),
          const SizedBox(height: 12),

          _styledField(
            controller: _regNameCtrl,
            label: 'Nom complet',
            hint: 'Ex: Amara Kouassi',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.length < 2) ? 'Minimum 2 caracteres' : null,
          ),
          const SizedBox(height: 14),

          _styledField(
            controller: _regEmailCtrl,
            label: 'Adresse email',
            hint: 'nom@exemple.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),

          _styledField(
            controller: _regPasswordCtrl,
            label: 'Mot de passe',
            hint: 'Minimum 6 caracteres',
            icon: Icons.lock_outline,
            obscure: _regObscure,
            onToggleObscure: () => setState(() => _regObscure = !_regObscure),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _regSelectedGender,
            decoration: const InputDecoration(
              labelText: 'Genre',
              hintText: 'Selectionnez votre genre',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Homme')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Femme')),
              DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _regSelectedGender = v),
            validator: (v) => v == null ? 'Le genre est obligatoire' : null,
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),

          const SizedBox(height: 28),

          GwangButton(
            label: 'Suivant',
            icon: Icons.arrow_forward,
            onPressed: () {
              if (_regFormKeys[0].currentState!.validate()) {
                setState(() => _regStep = 1);
              }
            },
          ),

          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _mode = AuthMode.login),
              child: RichText(
                text: TextSpan(
                  text: 'Deja un compte ? ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: 'Se connecter',
                      style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── STEP 1: Origins / Language ──

  Widget _buildStep1Origins(AsyncValue authState) {
    final firstVillageId = _regSelectedVillages.isNotEmpty
        ? _regSelectedVillages.first.id
        : null;
    final clansAsync = ref.watch(
      clansByVillageNotifierProvider(firstVillageId),
    );

    return Form(
      key: _regFormKeys[1],
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Pays & Village d\'origine'),
          const SizedBox(height: 12),

          CountryVillageSelector(
            selectedCountry: _regSelectedCountry,
            selectedVillages: _regSelectedVillages,
            multiSelect: true,
            countryLabel: 'Pays',
            villageLabel: 'Village(s) d\'origine',
            onCountryChanged: (c) => setState(() {
              _regSelectedCountry = c;
              _regSelectedVillages = [];
              _regClanCtrl.clear();
            }),
            onVillagesChanged: (v) => setState(() {
              _regSelectedVillages = v;
              _regClanCtrl.clear();
            }),
          ),

          // ── Clan / Famille ──
          if (_regSelectedVillages.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionLabel('Clan / Famille'),
            const SizedBox(height: 4),
            Text(
              'Selectionnez un clan existant ou saisissez le votre',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 12),

            clansAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => _styledField(
                controller: _regClanCtrl,
                label: 'Clan',
                hint: 'Ex: Basaa, Beti...',
                icon: Icons.shield_outlined,
              ),
              data: (clans) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return clans;
                  return clans.where((c) =>
                    c.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                  );
                },
                onSelected: (selection) => _regClanCtrl.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  // Sync avec notre controller
                  controller.text = _regClanCtrl.text;
                  controller.addListener(() => _regClanCtrl.text = controller.text);
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Clan',
                      hintText: clans.isEmpty
                          ? 'Saisissez votre clan'
                          : 'Tapez ou selectionnez un clan',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                      prefixIcon: const Icon(Icons.shield_outlined),
                      suffixIcon: clans.isNotEmpty
                          ? const Icon(Icons.arrow_drop_down, color: AppColors.textHint)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 20),
          _sectionLabel('Langue maternelle'),
          const SizedBox(height: 12),

          _styledField(
            controller: _regLanguageCtrl,
            label: 'Langue native',
            hint: 'Ex: Bassa, Ewondo, Wolof...',
            icon: Icons.record_voice_over_outlined,
          ),

          const SizedBox(height: 20),
          _sectionLabel('A propos de vous'),
          const SizedBox(height: 4),
          Text(
            'Optionnel — Parlez de vous, de votre lien avec votre village',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _regBioCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Diaspora Paris, passionne de culture Bassa...',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.short_text_outlined),
              ),
              counterStyle: const TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ),

          const SizedBox(height: 28),

          GwangButton(
            label: 'Suivant',
            icon: Icons.arrow_forward,
            onPressed: () {
              setState(() => _regStep = 2);
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── STEP 2: Recap ──

  Widget _buildStep2Recap(AsyncValue authState) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Recap card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withAlpha(40)),
          ),
          child: Column(
            children: [
              // Avatar preview
              CircleAvatar(
                radius: 36,
                backgroundColor: accent.withAlpha(30),
                child: Text(
                  _regNameCtrl.text.isNotEmpty ? _regNameCtrl.text[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                _regNameCtrl.text,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withAlpha(50)),
                ),
                child: Text(
                  'MEMBRE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: Theme.of(context).colorScheme.outline.withAlpha(30)),
              const SizedBox(height: 12),

              _recapRow(Icons.email_outlined, 'Email', _regEmailCtrl.text),
              if (_regSelectedGender != null)
                _recapRow(Icons.person_outline, 'Genre',
                    _regSelectedGender == 'MALE' ? 'Homme' : _regSelectedGender == 'FEMALE' ? 'Femme' : 'Autre'),
              if (_regSelectedCountry != null)
                _recapRow(Icons.public_outlined, 'Pays', _regSelectedCountry!.name),
              if (_regSelectedVillages.isNotEmpty)
                _recapRow(Icons.location_on_outlined, 'Village(s)',
                    _regSelectedVillages.map((v) => v.name).join(', ')),
              if (_regClanCtrl.text.isNotEmpty)
                _recapRow(Icons.shield_outlined, 'Clan', _regClanCtrl.text),
              if (_regLanguageCtrl.text.isNotEmpty)
                _recapRow(Icons.record_voice_over_outlined, 'Langue native', _regLanguageCtrl.text),
              if (_regBioCtrl.text.isNotEmpty)
                _recapRow(Icons.short_text_outlined, 'Bio', _regBioCtrl.text),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Edit buttons
        Row(
          children: [
            Expanded(child: _editStepButton('Modifier le profil', 0)),
            const SizedBox(width: 10),
            Expanded(child: _editStepButton('Modifier les origines', 1)),
          ],
        ),

        const SizedBox(height: 24),

        GwangButton(
          label: 'Creer mon compte',
          icon: Icons.check_circle_outline,
          loading: authState is AsyncLoading,
          onPressed: _submitRegistration,
        ),

        const SizedBox(height: 10),
        Center(
          child: Text(
            'En creant un compte, vous acceptez les conditions d\'utilisation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _editStepButton(String label, int step) {
    return GestureDetector(
      onTap: () => setState(() => _regStep = step),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(40)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLogo() {
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent, width: 1.5),
              ),
              child: Icon(Icons.language, color: accent, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'GWANG MEU',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: accent,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Langues  ·  Culture  ·  Futur',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: Icon(icon),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: onToggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }

  Widget _buildDividerOr() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou continuer avec',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUBMIT
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
      nativeLanguage: _regLanguageCtrl.text.trim().isEmpty ? null : _regLanguageCtrl.text.trim(),
      bio: _regBioCtrl.text.trim().isEmpty ? null : _regBioCtrl.text.trim(),
      villageIds: _regSelectedVillages.isNotEmpty
          ? _regSelectedVillages.map((v) => v.id).toList()
          : null,
      clan: _regClanCtrl.text.trim().isEmpty ? null : _regClanCtrl.text.trim(),
      gender: _regSelectedGender!,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  String? _validateEmail(String? v) =>
      (v == null || !v.contains('@')) ? 'Email invalide' : null;

  String? _validatePassword(String? v) =>
      (v == null || v.length < 6) ? 'Minimum 6 caracteres' : null;

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Email ou mot de passe incorrect';
    if (raw.contains('Email not confirmed')) return 'Confirmez votre email d\'abord';
    if (raw.contains('already registered')) return 'Cet email est deja utilise';
    if (raw.contains('rate limit')) return 'Trop de tentatives. Attendez quelques minutes.';
    return 'Une erreur est survenue. Reessayez.';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SOCIAL GRID
// ═══════════════════════════════════════════════════════════════════════════════

class _SocialGrid extends StatelessWidget {
  final void Function(OAuthProvider) onTap;
  const _SocialGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: FontAwesomeIcons.google,
                brandColor: const Color(0xFFDB4437),
                onTap: () => onTap(OAuthProvider.google),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                icon: FontAwesomeIcons.facebookF,
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
                icon: FontAwesomeIcons.apple,
                brandColor: Colors.white,
                onTap: () => onTap(OAuthProvider.apple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'GitHub',
                icon: FontAwesomeIcons.github,
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
                icon: FontAwesomeIcons.xTwitter,
                brandColor: Colors.white,
                onTap: () => onTap(OAuthProvider.twitter),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'LinkedIn',
                icon: FontAwesomeIcons.linkedinIn,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color brandColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: brandColor.withAlpha(18),
        side: BorderSide(color: brandColor.withAlpha(70), width: 1),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 15, color: brandColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
