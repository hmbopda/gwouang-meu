import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Eager imports (pages initiales / toujours visibles) ──
import '../../features/auth/auth_screen.dart';
import '../../features/feed/feed_screen.dart';
import '../../features/home/home_screen.dart';
import '../../shared/models/village_model.dart';
import '../../shared/widgets/deferred_widget.dart';

// ── Deferred imports (chargés à la demande — réduit ~30-40% bundle web) ──
import '../../features/genealogy/genealogy_screen.dart' deferred as genealogy;
import '../../features/genealogy/invitation_screen.dart'
    deferred as invitation;
import '../../features/profile/profile_screen.dart' deferred as profile;
import '../../features/search/search_screen.dart' deferred as search;
import '../../features/villages/create_village_screen.dart'
    deferred as create_village;
import '../../features/villages/edit_village_screen.dart'
    deferred as edit_village;
import '../../features/villages/my_villages_screen.dart'
    deferred as my_villages;
import '../../features/villages/village_detail_screen.dart'
    deferred as village_detail;
import '../../features/villages/villages_screen.dart' deferred as villages;

import 'route_names.dart';

/// ChangeNotifier qui écoute un Stream et notifie GoRouter à chaque event.
/// Permet au router de ré-évaluer les redirections lors des changements d'auth
/// (connexion OAuth, déconnexion, token refresh...).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );

  return GoRouter(
    initialLocation: Routes.feed,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,

    // Guard : redirige vers /auth si pas de session Supabase active
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isGoingToAuth = state.matchedLocation.startsWith('/auth');
      final isGoingToInvite = state.matchedLocation.startsWith('/invite');

      if (session == null && !isGoingToAuth && !isGoingToInvite) {
        return Routes.auth;
      }
      if (session != null && isGoingToAuth) return Routes.feed;
      return null;
    },

    routes: [
      // Auth (eager — potentiellement premier écran)
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => const AuthScreen(),
      ),

      // Shell — navigation fixe (IconRail + TopBar desktop, BottomNav mobile)
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          // ── Onglets principaux ──

          // Feed (eager — page initiale, doit s'afficher immédiatement)
          GoRoute(
            path: Routes.feed,
            builder: (context, state) => const FeedScreen(),
          ),

          // Villages (deferred)
          GoRoute(
            path: Routes.villages,
            builder: (context, state) => DeferredWidget(
              loader: villages.loadLibrary,
              builder: () => villages.VillagesScreen(),
            ),
          ),

          // Search (deferred)
          GoRoute(
            path: Routes.search,
            builder: (context, state) => DeferredWidget(
              loader: search.loadLibrary,
              builder: () => search.SearchScreen(),
            ),
          ),

          // Profile (deferred)
          GoRoute(
            path: Routes.profile,
            builder: (context, state) => DeferredWidget(
              loader: profile.loadLibrary,
              builder: () => profile.ProfileScreen(),
            ),
          ),

          // Genealogy (deferred)
          GoRoute(
            path: Routes.genealogy,
            builder: (context, state) => DeferredWidget(
              loader: genealogy.loadLibrary,
              builder: () => genealogy.GenealogyScreen(),
            ),
          ),

          // ── Routes internes (navigation fixe conservée) ──

          // Mes villages (deferred)
          GoRoute(
            path: Routes.myVillages,
            builder: (context, state) => DeferredWidget(
              loader: my_villages.loadLibrary,
              builder: () => my_villages.MyVillagesScreen(),
            ),
          ),

          // Création village (AVANT /:id pour éviter collision)
          GoRoute(
            path: Routes.createVillage,
            builder: (context, state) => DeferredWidget(
              loader: create_village.loadLibrary,
              builder: () => create_village.CreateVillageScreen(),
            ),
          ),

          // Édition village (AVANT /:id pour éviter collision)
          GoRoute(
            path: Routes.editVillage,
            builder: (context, state) => DeferredWidget(
              loader: edit_village.loadLibrary,
              builder: () => edit_village.EditVillageScreen(
                village: state.extra! as VillageModel,
              ),
            ),
          ),

          // Détail village (deferred)
          GoRoute(
            path: Routes.village,
            builder: (context, state) => DeferredWidget(
              loader: village_detail.loadLibrary,
              builder: () => village_detail.VillageDetailScreen(
                villageId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),

      // Invitation (hors shell, accessible sans auth, deferred)
      GoRoute(
        path: Routes.invite,
        builder: (context, state) => DeferredWidget(
          loader: invitation.loadLibrary,
          builder: () => invitation.InvitationScreen(
            token: state.uri.queryParameters['token']!,
          ),
        ),
      ),
    ],
  );
});
