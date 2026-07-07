/// Constantes de routes — GoRouter
abstract class Routes {
  static const splash = '/';
  static const auth = '/auth';

  // Shell (bottom nav — 5 destinations : Fil, Villages, Lignées, Messages, Profil)
  static const home = '/home';
  static const feed = '/home/feed';
  static const villages = '/home/villages';
  static const search = '/home/search';
  static const profile = '/home/profile';
  static const genealogy = '/home/genealogy';

  /// Messages — destination de premier niveau.
  static const messages = '/messages';
  static const messagesConversation = '/messages/:groupId';

  // Routes détail (hors shell)
  static const village = '/villages/:id';
  static const createVillage = '/villages/create';
  static const editVillage = '/villages/:id/edit';
  static const myVillages = '/my-villages';
  static const invite = '/invite';

  /// Vérification d'une suggestion IA (parcours « Suggestion IA vers Arbre »).
  static const verifySuggestion = '/genealogy/verify/:suggestionId';

  static String villageDetail(String id) => '/villages/$id';
  static String villageEdit(String id) => '/villages/$id/edit';
  static String conversation(String groupId) => '/messages/$groupId';
  static String verify(String suggestionId) => '/genealogy/verify/$suggestionId';
}
