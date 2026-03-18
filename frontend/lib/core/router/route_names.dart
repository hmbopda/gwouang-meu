/// Constantes de routes — GoRouter Phase 1
abstract class Routes {
  static const splash = '/';
  static const auth = '/auth';

  // Shell (bottom nav)
  static const home = '/home';
  static const feed = '/home/feed';
  static const villages = '/home/villages';
  static const search = '/home/search';
  static const profile = '/home/profile';
  static const genealogy = '/home/genealogy';

  // Routes détail (hors shell)
  static const village = '/villages/:id';
  static const createVillage = '/villages/create';
  static const editVillage = '/villages/:id/edit';
  static const myVillages = '/my-villages';
  static const invite = '/invite';

  static String villageDetail(String id) => '/villages/$id';
  static String villageEdit(String id) => '/villages/$id/edit';
}
