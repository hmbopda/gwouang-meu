import 'package:flutter/material.dart';

/// Widget helper pour le chargement différé (deferred imports).
/// Sur le web, réduit la taille du bundle initial de ~30-40%.
/// Sur mobile/desktop, loadLibrary() retourne immédiatement.
class DeferredWidget extends StatefulWidget {
  const DeferredWidget({
    super.key,
    required this.loader,
    required this.builder,
  });

  final Future<dynamic> Function() loader;
  final Widget Function() builder;

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  late Future<void> _future;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _future = widget.loader().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded) return widget.builder();

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.builder();
        }
        // Placeholder ultra-léger — pas de spinner pour éviter le flash
        return const SizedBox.shrink();
      },
    );
  }
}
