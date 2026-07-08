import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Écran public d'acceptation d'invitation — style « Tissage ».
/// Accessible via le lien /invite?token=xxx
/// Le parent invité peut :
/// 1. Voir ses infos pré-remplies
/// 2. Corriger ses informations
/// 3. Indiquer s'il connaît la personne qui l'a invité
/// 4. Créer son compte (email + mot de passe) ou se connecter
/// 5. Confirmer
class InvitationScreen extends ConsumerStatefulWidget {
  final String token;
  const InvitationScreen({super.key, required this.token});

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

/// Nature de l'erreur de chargement, pour un état dédié.
enum _InviteErrorKind { expired, alreadyAccepted, generic }

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _maidenNameCtrl = TextEditingController();
  final _clanCtrl = TextEditingController();
  final _totemCtrl = TextEditingController();
  final _nativeLanguageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  bool? _knowsInviter;
  bool _knowsInviterMissing = false;
  String? _inviterName;
  String? _error;
  String? _submitError;
  bool _obscurePassword = true;
  bool _isLoggedIn = false;
  bool _needsSignUp = true;
  String _invitationType = 'PARENT';

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    try {
      final api = ref.read(genealogyApiServiceProvider);
      final data = await api.getInvitationByToken(widget.token);
      final person = data['person'] as Map<String, dynamic>?;

      setState(() {
        _inviterName = data['inviterName'] as String?;
        if (person != null) {
          _firstNameCtrl.text = person['firstName'] ?? '';
          _lastNameCtrl.text = person['lastName'] ?? '';
          _maidenNameCtrl.text = person['maidenName'] ?? '';
          _clanCtrl.text = person['clan'] ?? '';
          _totemCtrl.text = person['totem'] ?? '';
          _nativeLanguageCtrl.text = person['nativeLanguage'] ?? '';
        }
        _emailCtrl.text = data['email'] ?? '';
        _invitationType = data['invitationType'] as String? ?? 'PARENT';
        _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
        _needsSignUp = !_isLoggedIn;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _maidenNameCtrl.dispose();
    _clanCtrl.dispose();
    _totemCtrl.dispose();
    _nativeLanguageCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Scaffold(
      backgroundColor: t.inkDeep,
      body: Column(
        children: [
          const GwWeaveBand(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildContent(t),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GwTokens t) {
    if (_loading) return _buildLoading(t);
    if (_error != null) return _buildErrorState(t);
    return _buildForm(t);
  }

  // ── État : chargement ──────────────────────────────────────────

  Widget _buildLoading(GwTokens t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            color: t.goldText,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'OUVERTURE DE L\'INVITATION',
          style: GwType.mono(
            fontSize: 11,
            letterSpacing: 2,
            color: t.stoneDim,
          ),
        ),
      ],
    );
  }

  // ── États : erreur / expirée / déjà acceptée ───────────────────

  _InviteErrorKind _classifyError(String message) {
    final m = message.toLowerCase();
    if (m.contains('expir')) return _InviteErrorKind.expired;
    if (m.contains('accept')) return _InviteErrorKind.alreadyAccepted;
    return _InviteErrorKind.generic;
  }

  String _cleanErrorMessage(String raw) {
    var m = raw.trim();
    if (m.startsWith('Exception:')) m = m.substring(10).trim();
    return m.isEmpty ? 'Une erreur inattendue est survenue.' : m;
  }

  Widget _buildErrorState(GwTokens t) {
    final kind = _classifyError(_error!);
    switch (kind) {
      case _InviteErrorKind.expired:
        return _statusCard(
          t,
          icon: Symbols.hourglass_bottom,
          iconColor: t.goldText,
          iconBg: t.goldBg,
          iconBorder: t.goldLine,
          title: 'Invitation expirée',
          body:
              'Ce lien n\'est plus valide : les invitations expirent au bout de 30 jours. '
              'Demandez à votre proche de vous envoyer une nouvelle invitation depuis son arbre.',
        );
      case _InviteErrorKind.alreadyAccepted:
        return _statusCard(
          t,
          icon: Symbols.check_circle,
          iconColor: t.sageText,
          iconBg: GwTokens.sageBg,
          iconBorder: GwTokens.sageLine,
          title: 'Invitation déjà acceptée',
          body:
              'Cette invitation a déjà été utilisée. Si c\'était vous, connectez-vous '
              'pour retrouver votre place dans la lignée.',
          actionLabel: 'Se connecter',
          onAction: () => context.go(Routes.auth),
        );
      case _InviteErrorKind.generic:
        return _statusCard(
          t,
          icon: Symbols.error,
          iconColor: t.emberText,
          iconBg: GwTokens.emberBg,
          iconBorder: GwTokens.emberLine,
          title: 'Une erreur est survenue',
          body: _cleanErrorMessage(_error!),
          bodyColor: t.emberText,
          actionLabel: 'Réessayer',
          onAction: () {
            setState(() {
              _error = null;
              _loading = true;
            });
            _loadInvitation();
          },
        );
    }
  }

  Widget _statusCard(
    GwTokens t, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color iconBorder,
    required String title,
    required String body,
    Color? bodyColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      decoration: BoxDecoration(
        color: t.inkCard,
        borderRadius: BorderRadius.circular(GwTokens.rCardLg),
        border: Border.all(color: t.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: iconBorder),
            ),
            child: Icon(icon, size: 34, color: iconColor, fill: 1),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GwType.display(fontSize: 24, color: t.stone),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GwType.ui(
              fontSize: 14.5,
              color: bodyColor ?? t.stoneMid,
              height: 1.55,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: GwTokens.gold,
                  foregroundColor: const Color(0xFF0C0B0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GwTokens.rBtn),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GwType.ui(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0C0B0F),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── État : formulaire ──────────────────────────────────────────

  String get _inviteSentence {
    if (_invitationType == 'SPOUSE') {
      return _inviterName != null
          ? '$_inviterName vous a enregistré·e comme conjoint·e dans son arbre généalogique.'
          : 'Vous avez été enregistré·e comme conjoint·e dans un arbre généalogique.';
    }
    return _inviterName != null
        ? '$_inviterName vous a ajouté·e à son arbre généalogique.'
        : 'Un membre de votre famille vous a ajouté·e à son arbre généalogique.';
  }

  Widget _buildForm(GwTokens t) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête ──
          Center(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.goldBg,
                shape: BoxShape.circle,
                border: Border.all(color: t.goldLine),
              ),
              child: Icon(
                Symbols.family_history,
                size: 34,
                color: t.goldText,
                fill: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'INVITATION · GWANG MEU',
              style: GwType.mono(
                fontSize: 11,
                letterSpacing: 2.5,
                color: t.goldText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vous êtes invité·e à rejoindre la lignée',
            textAlign: TextAlign.center,
            style: GwType.display(fontSize: 27, color: t.stone, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            _inviteSentence,
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 14.5, color: t.stoneMid, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Vérifiez et corrigez vos informations ci-dessous.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
          ),
          const SizedBox(height: 28),

          // ── Carte : détails de l'invitation ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.inkCard,
              borderRadius: BorderRadius.circular(GwTokens.rCardLg),
              border: Border.all(color: t.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'VOS INFORMATIONS',
                        style: GwType.mono(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: t.goldText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: t.goldBg,
                        borderRadius: BorderRadius.circular(GwTokens.rPill),
                        border: Border.all(color: t.goldLine),
                      ),
                      child: Text(
                        _invitationType == 'SPOUSE' ? 'CONJOINT·E' : 'LIGNÉE',
                        style: GwType.mono(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: t.goldText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _field(
                  t,
                  controller: _firstNameCtrl,
                  label: 'Prénom *',
                  icon: Symbols.person,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                _field(
                  t,
                  controller: _lastNameCtrl,
                  label: 'Nom *',
                  icon: Symbols.badge,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                _field(
                  t,
                  controller: _maidenNameCtrl,
                  label: 'Nom de jeune fille',
                  icon: Symbols.history_edu,
                ),
                const SizedBox(height: 12),
                _field(
                  t,
                  controller: _clanCtrl,
                  label: 'Clan / grande famille',
                  icon: Symbols.shield,
                ),
                const SizedBox(height: 12),
                _field(
                  t,
                  controller: _totemCtrl,
                  label: 'Totem',
                  icon: Symbols.pets,
                ),
                const SizedBox(height: 12),
                _field(
                  t,
                  controller: _nativeLanguageCtrl,
                  label: 'Langue maternelle',
                  icon: Symbols.translate,
                ),

                // ── Question : connaît l'inviteur ? ──
                const SizedBox(height: 22),
                Container(height: 1, color: t.line),
                const SizedBox(height: 20),
                Text(
                  _inviterName != null
                      ? 'Connaissez-vous $_inviterName ?'
                      : 'Connaissez-vous la personne à l\'origine de cette invitation ?',
                  style: GwType.ui(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: t.stone,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette information nous aide à vérifier l\'authenticité des liens familiaux.',
                  style: GwType.ui(
                      fontSize: 12.5, color: t.stoneDim, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _choiceButton(
                        t,
                        label: 'Oui, je le·la connais',
                        icon: Symbols.check_circle,
                        selected: _knowsInviter == true,
                        onTap: () => setState(() {
                          _knowsInviter = true;
                          _knowsInviterMissing = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _choiceButton(
                        t,
                        label: 'Non',
                        icon: Symbols.help,
                        selected: _knowsInviter == false,
                        onTap: () => setState(() {
                          _knowsInviter = false;
                          _knowsInviterMissing = false;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_knowsInviterMissing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Symbols.error, size: 16, color: t.emberText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Veuillez répondre à cette question avant de continuer.',
                          style: GwType.ui(fontSize: 12.5, color: t.emberText),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Compte (si pas connecté) ──
                if (_needsSignUp) ...[
                  const SizedBox(height: 22),
                  Container(height: 1, color: t.line),
                  const SizedBox(height: 20),
                  Text(
                    'VOTRE COMPTE',
                    style: GwType.mono(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: t.goldText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Créez votre accès pour rejoindre l\'arbre familial.',
                    style: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    t,
                    controller: _emailCtrl,
                    label: 'Email *',
                    icon: Symbols.mail,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (!_needsSignUp) return null;
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    t,
                    controller: _passwordCtrl,
                    label: 'Mot de passe *',
                    icon: Symbols.lock,
                    obscure: _obscurePassword,
                    onToggleObscure: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (!_needsSignUp) return null;
                      if (v == null || v.length < 6) {
                        return '6 caractères minimum';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Erreur de soumission ──
          if (_submitError != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GwTokens.emberBg,
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                border: Border.all(color: GwTokens.emberLine),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.error, size: 20, color: t.emberText, fill: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: GwType.ui(
                        fontSize: 13.5,
                        color: t.emberText,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── CTA confirmer ──
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: GwTokens.gold,
                foregroundColor: const Color(0xFF0C0B0F),
                disabledBackgroundColor: GwTokens.gold.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GwTokens.rBtn),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0C0B0F),
                      ),
                    )
                  : Text(
                      'Confirmer et rejoindre la lignée',
                      style: GwType.ui(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0C0B0F),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'En confirmant, vos informations seront reliées à cet arbre familial.',
            textAlign: TextAlign.center,
            style: GwType.ui(fontSize: 12, color: t.stoneFaint),
          ),
        ],
      ),
    );
  }

  // ── Champ de saisie Tissage : fond inkLift, rayon 14, focus or ──

  Widget _field(
    GwTokens t, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GwType.ui(fontSize: 14.5, color: t.stone),
      cursorColor: GwTokens.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GwType.ui(fontSize: 14, color: t.stoneMid),
        floatingLabelStyle: GwType.ui(fontSize: 12, color: t.goldText),
        filled: true,
        fillColor: t.inkLift,
        prefixIcon: Icon(icon, size: 20, color: t.stoneDim),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                onPressed: onToggleObscure,
                tooltip: obscure
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                icon: Icon(
                  obscure ? Symbols.visibility : Symbols.visibility_off,
                  size: 20,
                  color: t.stoneDim,
                ),
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(t.line),
        focusedBorder: border(GwTokens.gold, 1.5),
        errorBorder: border(t.emberText),
        focusedErrorBorder: border(t.emberText, 1.5),
        errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
      ),
      validator: validator,
    );
  }

  // ── Bouton de choix oui / non ──────────────────────────────────

  Widget _choiceButton(
    GwTokens t, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? t.goldBg : t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rBtn),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rBtn),
        child: Container(
          constraints: const BoxConstraints(minHeight: GwTokens.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rBtn),
            border: Border.all(
              color: selected ? t.goldLine : t.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? t.goldText : t.stoneMid,
                fill: selected ? 1 : 0,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? t.goldText : t.stoneMid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SOUMISSION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_knowsInviter == null) {
      setState(() => _knowsInviterMissing = true);
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Créer le compte ou se connecter
      if (_needsSignUp) {
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text;

        bool needsSignIn = false;
        try {
          final signUpRes = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
          );
          // Supabase peut retourner un user sans session si l'email existe déjà
          if (signUpRes.session == null) {
            needsSignIn = true;
          }
        } on AuthException catch (e) {
          // 422 = email déjà enregistré → fallback signIn
          if (e.statusCode == '422' ||
              e.message.toLowerCase().contains('already registered')) {
            needsSignIn = true;
          } else {
            rethrow;
          }
        }

        if (needsSignIn) {
          try {
            await Supabase.instance.client.auth.signInWithPassword(
              email: email,
              password: password,
            );
          } on AuthException {
            throw Exception(
              'Ce compte existe déjà. Veuillez saisir le mot de passe correct '
              'ou utiliser une autre adresse email.',
            );
          }
        }
      }

      // 2. Accepter l'invitation
      final api = ref.read(genealogyApiServiceProvider);
      await api.acceptInvitation(widget.token, {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'maidenName': _maidenNameCtrl.text.trim().isNotEmpty
            ? _maidenNameCtrl.text.trim()
            : null,
        'clan': _clanCtrl.text.trim().isNotEmpty ? _clanCtrl.text.trim() : null,
        'totem':
            _totemCtrl.text.trim().isNotEmpty ? _totemCtrl.text.trim() : null,
        'nativeLanguage': _nativeLanguageCtrl.text.trim().isNotEmpty
            ? _nativeLanguageCtrl.text.trim()
            : null,
        'knowsInviter': _knowsInviter,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: GwTokens.sage,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GwTokens.rBtn),
            ),
            content: Text(
              'Bienvenue ! Votre compte a été créé et relié à votre fiche généalogique.',
              style: GwType.ui(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
        // Rediriger vers l'accueil
        context.go(Routes.feed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitError = _cleanErrorMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
