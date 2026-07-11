import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Eager imports (pages initiales / toujours visibles) ──
import 'package:gwangmeu/features/auth/auth_screen.dart';
import 'package:gwangmeu/features/feed/feed_screen.dart';
import 'package:gwangmeu/features/home/home_screen.dart';
import 'package:gwangmeu/shared/models/village_model.dart';
import 'package:gwangmeu/shared/widgets/deferred_widget.dart';

// ── Deferred imports (chargés à la demande — réduit ~30-40% bundle web) ──
import 'package:gwangmeu/features/genealogy/genealogy_screen.dart' deferred as genealogy;
import 'package:gwangmeu/features/genealogy/verification/verification_screen.dart'
    deferred as verification;
import 'package:gwangmeu/features/messages/conversation_screen.dart'
    deferred as conversation;
import 'package:gwangmeu/features/messages/messages_screen.dart'
    deferred as messages;
import 'package:gwangmeu/shared/models/chat_group_model.dart';
import 'package:gwangmeu/features/genealogy/invitation_screen.dart'
    deferred as invitation;
import 'package:gwangmeu/features/profile/profile_screen.dart' deferred as profile;
import 'package:gwangmeu/features/search/search_screen.dart' deferred as search;
import 'package:gwangmeu/features/villages/add_village_screen.dart'
    deferred as add_village;
import 'package:gwangmeu/features/villages/create_village_screen.dart'
    deferred as create_village;
import 'package:gwangmeu/features/villages/edit_village_screen.dart'
    deferred as edit_village;
import 'package:gwangmeu/features/villages/my_villages_screen.dart'
    deferred as my_villages;
import 'package:gwangmeu/features/villages/village_detail_screen.dart'
    deferred as village_detail;
import 'package:gwangmeu/features/villages/villages_hub_screen.dart'
    deferred as villages_hub;

import 'package:gwangmeu/core/router/route_names.dart';

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

          // Villages — l'onglet ouvre le NOUVEL écran village (hub) sur le
          // premier village de l'utilisateur, pas la liste d'exploration.
          GoRoute(
            path: Routes.villages,
            builder: (context, state) => DeferredWidget(
              loader: villages_hub.loadLibrary,
              builder: () => villages_hub.VillagesHubScreen(),
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

          // Messages — destination de premier niveau (deferred)
          GoRoute(
            path: Routes.messages,
            builder: (context, state) => DeferredWidget(
              loader: messages.loadLibrary,
              builder: () => messages.MessagesScreen(),
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

          // Ajouter un village — villages hérités + invitations
          // (AVANT /:id pour éviter collision)
          GoRoute(
            path: Routes.addVillage,
            builder: (context, state) => DeferredWidget(
              loader: add_village.loadLibrary,
              builder: () => add_village.AddVillageScreen(),
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

      // Vérification suggestion IA (hors shell — transition fade + translateY
      // 14px, 300ms ease, deferred)
      GoRoute(
        path: Routes.verifySuggestion,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          child: DeferredWidget(
            loader: verification.loadLibrary,
            builder: () => verification.VerificationScreen(
              suggestionId: state.pathParameters['suggestionId']!,
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.ease);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.018), // ≈ 14px sur 844px
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),

      // Conversation (hors shell — plein écran avec retour, deferred)
      GoRoute(
        path: Routes.messagesConversation,
        builder: (context, state) {
          final extra = state.extra as Map<String, Object>?;
          return DeferredWidget(
            loader: conversation.loadLibrary,
            builder: () => conversation.ConversationScreen(
              groupId: state.pathParameters['groupId']!,
              group: extra?['group'] as ChatGroupModel?,
              villageName: extra?['villageName'] as String?,
            ),
          );
        },
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
