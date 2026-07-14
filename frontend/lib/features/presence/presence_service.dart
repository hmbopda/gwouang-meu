import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gwangmeu/features/profile/profile_notifier.dart';

/// Présence temps réel — SOURCE UNIQUE de « qui est en ligne » pour toute l'app
/// (membres de village, contacts, chat…). Basée sur Supabase Realtime Presence :
/// chaque client connecté s'annonce sur un canal partagé et on récupère
/// l'ensemble des `users.id` présents.
///
/// Best-effort : si le canal échoue, l'ensemble reste vide (personne « en ligne »)
/// — jamais de crash. Garder ce provider watché au niveau du shell de l'app pour
/// que l'utilisateur reste présent tant que l'appli est ouverte.
final onlineUsersProvider =
    StateNotifierProvider<PresenceNotifier, Set<String>>((ref) {
  return PresenceNotifier(ref);
});

class PresenceNotifier extends StateNotifier<Set<String>> {
  PresenceNotifier(this._ref) : super(const <String>{}) {
    // (Re)joint le canal dès que l'id de l'utilisateur courant est connu.
    _ref.listen<AsyncValue<dynamic>>(profileNotifierProvider, (_, next) {
      final id = next.valueOrNull?.id;
      if (id is String && id.isNotEmpty && id != _myId) {
        _join(id);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  RealtimeChannel? _channel;
  String? _myId;

  Future<void> _join(String myId) async {
    _myId = myId;
    await _leave();
    try {
      final client = Supabase.instance.client;
      final channel = client.channel(
        'gw-presence',
        opts: const RealtimeChannelConfig(self: true),
      );
      _channel = channel;
      channel
          .onPresenceSync((_) => _recompute(channel))
          .onPresenceJoin((_) => _recompute(channel))
          .onPresenceLeave((_) => _recompute(channel))
          .subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await channel.track({'user_id': myId});
        }
      });
    } catch (_) {
      // Présence best-effort : en cas d'échec, personne n'est marqué en ligne.
    }
  }

  void _recompute(RealtimeChannel channel) {
    try {
      final ids = <String>{};
      for (final s in channel.presenceState()) {
        for (final p in s.presences) {
          final uid = p.payload['user_id'];
          if (uid is String && uid.isNotEmpty) ids.add(uid);
        }
      }
      if (mounted) state = ids;
    } catch (_) {
      // ignore : on garde l'état précédent
    }
  }

  Future<void> _leave() async {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await ch.untrack();
      } catch (_) {}
      try {
        await Supabase.instance.client.removeChannel(ch);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }
}
