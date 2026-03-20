import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Ecran d'acceptation d'invitation.
/// Accessible via le lien /invite?token=xxx
/// Le parent invite peut :
/// 1. Voir ses infos pre-remplies
/// 2. Corriger ses informations
/// 3. Indiquer s'il connait la personne qui l'a invite
/// 4. Creer son compte (email + mot de passe) ou se connecter
/// 5. Confirmer
class InvitationScreen extends ConsumerStatefulWidget {
  final String token;
  const InvitationScreen({super.key, required this.token});

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

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
  String? _inviterName;
  String? _error;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildForm();
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _error = null;
              _loading = true;
            });
            _loadInvitation();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
          child: const Text('Reessayer'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final accent = Theme.of(context).colorScheme.primary;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.account_tree, color: accent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Invitation Gwang Meu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _invitationType == 'SPOUSE'
                      ? (_inviterName != null
                          ? '$_inviterName vous a enregistre(e) comme conjoint(e) dans son arbre genealogique.'
                          : 'Vous avez ete enregistre(e) comme conjoint(e) dans un arbre genealogique.')
                      : (_inviterName != null
                          ? '$_inviterName vous a ajoute a son arbre genealogique.'
                          : 'Quelqu\'un vous a ajoute a son arbre genealogique.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Verifiez et corrigez vos informations ci-dessous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Infos pre-remplies (modifiables) ──
          const Text(
            'Vos informations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Prenom *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _maidenNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de jeune fille',
              prefixIcon: Icon(Icons.history_edu_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clanCtrl,
            decoration: const InputDecoration(
              labelText: 'Clan',
              prefixIcon: Icon(Icons.shield_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _totemCtrl,
            decoration: const InputDecoration(
              labelText: 'Totem',
              prefixIcon: Icon(Icons.pets_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nativeLanguageCtrl,
            decoration: const InputDecoration(
              labelText: 'Langue maternelle',
              prefixIcon: Icon(Icons.translate_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // ── Question : connait l'inviteur ? ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _inviterName != null
                      ? 'Connaissez-vous $_inviterName ?'
                      : 'Connaissez-vous la personne qui a initie votre creation ?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cette information nous aide a verifier l\'authenticite des liens familiaux.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _choiceButton(
                        label: 'Oui, je le/la connais',
                        icon: Icons.check_circle_outline,
                        selected: _knowsInviter == true,
                        onTap: () => setState(() => _knowsInviter = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choiceButton(
                        label: 'Non',
                        icon: Icons.help_outline,
                        selected: _knowsInviter == false,
                        onTap: () => setState(() => _knowsInviter = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Compte (si pas connecte) ──
          if (_needsSignUp) ...[
            const Text(
              'Creer votre compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (!_needsSignUp) return null;
                if (v == null || v.isEmpty) return 'Requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Mot de passe *',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
              validator: (v) {
                if (!_needsSignUp) return null;
                if (v == null || v.length < 6) return '6 caracteres minimum';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],

          // ── Bouton confirmer ──
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmer et rejoindre',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? accent : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_knowsInviter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer si vous connaissez la personne qui vous a invite'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Creer le compte ou se connecter
      if (_needsSignUp) {
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text;

        bool needsSignIn = false;
        try {
          final signUpRes = await Supabase.instance.client.auth.signUp(
            email: email,
            password: password,
          );
          // Supabase peut retourner un user sans session si l'email existe deja
          if (signUpRes.session == null) {
            needsSignIn = true;
          }
        } on AuthException catch (e) {
          // 422 = email deja enregistre → fallback signIn
          if (e.statusCode == '422' || e.message.toLowerCase().contains('already registered')) {
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
              'Ce compte existe deja. Veuillez entrer le mot de passe correct '
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
        'totem': _totemCtrl.text.trim().isNotEmpty ? _totemCtrl.text.trim() : null,
        'nativeLanguage': _nativeLanguageCtrl.text.trim().isNotEmpty
            ? _nativeLanguageCtrl.text.trim()
            : null,
        'knowsInviter': _knowsInviter,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bienvenue ! Votre compte a ete cree et lie a votre fiche genealogique.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Rediriger vers l'accueil
        context.go(Routes.feed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
