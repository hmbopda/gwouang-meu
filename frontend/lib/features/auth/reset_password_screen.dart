import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/router/route_names.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/auth/auth_notifier.dart';

/// Écran « Nouveau mot de passe » — style « Tissage ».
///
/// Atteint après le clic sur le lien de réinitialisation reçu par email :
/// le deep link ré-ouvre l'app sur /auth-callback avec `type=recovery`, ce qui
/// route ici (session temporaire de récupération active côté Supabase).
///
/// Deux champs (nouveau mot de passe + confirmation), validation longueur et
/// égalité, puis `updatePassword` → succès → redirige vers /feed (ou /auth si
/// la session est perdue) avec un SnackBar.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (prev, next) {
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
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: t.goldBg,
                              borderRadius:
                                  BorderRadius.circular(GwTokens.rCardLg),
                              border: Border.all(color: t.goldLine, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Symbols.lock_reset,
                                size: 32, color: t.goldText),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'SÉCURITÉ · MOT DE PASSE',
                            style: GwType.mono(
                                fontSize: 10,
                                color: t.goldText,
                                letterSpacing: 2.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nouveau mot de passe',
                            style: GwType.display(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: t.stone,
                                height: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choisissez un mot de passe solide pour protéger '
                            'votre mémoire et celle des vôtres.',
                            style: GwType.ui(
                                fontSize: 14.5, color: t.stoneMid, height: 1.5),
                          ),
                          const SizedBox(height: 24),

                          _field(
                            t,
                            controller: _passwordCtrl,
                            label: 'Nouveau mot de passe',
                            hint: 'Minimum 6 caractères',
                            obscure: _obscure,
                            onToggle: () =>
                                setState(() => _obscure = !_obscure),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimum 6 caractères'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            t,
                            controller: _confirmCtrl,
                            label: 'Confirmer le mot de passe',
                            hint: 'Retapez le mot de passe',
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: (v) => (v != _passwordCtrl.text)
                                ? 'Les mots de passe ne correspondent pas'
                                : null,
                          ),

                          const SizedBox(height: 24),
                          _goldCta(
                            label: 'Enregistrer',
                            icon: Symbols.check_circle,
                            loading: authState is AsyncLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
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

    await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(_passwordCtrl.text);

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state is AsyncError) return; // le SnackBar d'erreur est déjà géré

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe mis à jour avec succès.'),
        backgroundColor: GwTokens.sage,
      ),
    );

    final hasSession =
        state is AsyncData && (state as AsyncData).value != null;
    context.go(hasSession ? Routes.feed : Routes.auth);
  }

  Widget _field(
    GwTokens t, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GwType.ui(fontSize: 14.5, color: t.stone),
      cursorColor: GwTokens.gold,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GwType.ui(fontSize: 14, color: t.stoneMid),
        floatingLabelStyle: GwType.ui(fontSize: 12, color: t.goldText),
        hintText: hint,
        hintStyle: GwType.ui(fontSize: 14, color: t.stoneDim),
        filled: true,
        fillColor: t.inkLift,
        prefixIcon: Icon(Symbols.lock, size: 20, color: t.stoneDim),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Symbols.visibility_off : Symbols.visibility,
            size: 20,
            color: t.stoneDim,
          ),
          onPressed: onToggle,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        enabledBorder: border(t.line),
        focusedBorder: border(GwTokens.gold, 1.5),
        errorBorder: border(t.emberText),
        focusedErrorBorder: border(t.emberText, 1.5),
        errorStyle: GwType.ui(fontSize: 12, color: t.emberText),
      ),
    );
  }

  Widget _goldCta({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
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

  String _friendlyError(String raw) {
    if (raw.contains('New password should be different')) {
      return 'Le nouveau mot de passe doit être différent de l\'ancien.';
    }
    if (raw.contains('session') || raw.contains('expired')) {
      return 'Lien expiré. Recommencez la réinitialisation.';
    }
    return 'Impossible de mettre à jour le mot de passe. Réessayez.';
  }
}
