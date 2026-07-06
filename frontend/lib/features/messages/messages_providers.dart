import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre de messages non lus toutes conversations confondues.
/// Alimente le badge ember de la bottom nav (destination Messages).
final unreadMessagesCountProvider = Provider<int>((ref) {
  // TODO(messages): brancher sur l'API chat quand le backend expose le compteur.
  return 3;
});
