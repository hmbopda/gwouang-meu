// Dérivation PURE du parcours de migration depuis un FamilyTree.
//
// Aucune UI, aucun provider, aucun accès réseau : uniquement des
// structures immuables et la fonction [buildMigrationJourney].
//
// Il n'existe pas de table « migration » en base — tout est dérivé des
// lieux présents dans l'arbre (origine, birthPlace, résidence, unions).
//
// RÈGLE MÉTIER : la lignée S'ANCRE sur l'ORIGINE (originVillage /
// originCity / originRegion / originCountry). La RÉSIDENCE
// (residenceCity / residenceCountry) est distincte : elle ne sert qu'à
// l'ÉVOLUTION (migration, situation actuelle). birthPlace reste un FAIT
// (lieu de naissance), ni origine ni résidence.

import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

/// Nature d'une étape du parcours de migration.
enum MigrationStepKind { naissance, retour, installation, residence }

/// Une étape chronologique du parcours (lieu + éventuelle année).
class MigrationStep {
  const MigrationStep({
    required this.place,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.year,
  });

  /// Lieu, dans sa forme originale (non normalisée).
  final String place;

  /// Année associée (naissance…) — null si inconnue ou non pertinente.
  final int? year;

  /// Titre affichable de l'étape.
  final String title;

  /// Sous-titre descriptif (« naissance », « résidence actuelle »…).
  final String subtitle;

  /// Nature de l'étape.
  final MigrationStepKind kind;
}

/// Nature d'une alliance territoriale.
enum AllianceKind { maternelle, parUnion }

/// Un lieu relié à la personne par alliance (lignée maternelle ou union).
class MigrationAlliance {
  const MigrationAlliance({
    required this.place,
    required this.kind,
    this.withName,
  });

  /// Lieu de l'alliance, forme originale.
  final String place;

  /// Nature de l'alliance.
  final AllianceKind kind;

  /// Nom de la personne concernée (conjoint…) — null si non applicable.
  final String? withName;
}

/// Un membre de la famille associé à son lieu (mode « toute la famille »).
class FamilyPlace {
  const FamilyPlace({required this.person, required this.place});

  final PersonGenealogy person;

  /// Lieu (birthPlace), forme originale.
  final String place;
}

/// Parcours de migration complet dérivé de l'arbre pour une personne.
class MigrationJourney {
  const MigrationJourney({
    required this.person,
    this.pilierPlace,
    this.pilierConcession,
    this.pilierOriginDetail,
    this.steps = const [],
    this.alliances = const [],
    this.familyPlaces = const [],
  });

  /// Personne dont on décrit le parcours.
  final PersonGenealogy person;

  /// Lieu-pilier : l'ORIGINE de la personne — originVillage, sinon
  /// originCity, sinon l'origine du père (originVillage puis birthPlace),
  /// sinon le repli historique (birthPlace de la mère, puis de la
  /// personne elle-même).
  final String? pilierPlace;

  /// Nom de la concession : lastName du père — null si père inconnu.
  final String? pilierConcession;

  /// Sous-libellé du pilier « {région} · {pays d'origine} » (originRegion
  /// et/ou originCountry) — null si aucun des deux n'est renseigné.
  final String? pilierOriginDetail;

  /// Étapes chronologiques (naissance → retour → résidence actuelle).
  final List<MigrationStep> steps;

  /// Alliances territoriales (maternelle, par union).
  final List<MigrationAlliance> alliances;

  /// Tous les membres de l'arbre ayant un lieu de naissance renseigné.
  final List<FamilyPlace> familyPlaces;
}

/// Retourne la chaîne trimée, ou null si elle est nulle ou vide.
String? _clean(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Clé de normalisation pour la déduplication (trim + casse ignorée).
String _norm(String value) => value.trim().toLowerCase();

/// Vrai si les deux lieux (nullable) désignent le même endroit,
/// comparaison insensible à la casse après trim. Deux nulls => false.
bool _samePlace(String? a, String? b) {
  final ca = _clean(a);
  final cb = _clean(b);
  if (ca == null || cb == null) return false;
  return _norm(ca) == _norm(cb);
}

String _fullName(PersonGenealogy p) =>
    [p.firstName.trim(), p.lastName.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');

/// Dérive le parcours de migration de [person] à partir de [tree].
///
/// Fonction pure : ne lit que les données passées en argument.
MigrationJourney buildMigrationJourney(
  FamilyTree tree,
  PersonGenealogy person,
) {
  final father = tree.father.isNotEmpty ? tree.father.first : null;
  final mother = tree.mother.isNotEmpty ? tree.mother.first : null;

  // ── Pilier : point d'ancrage = ORIGINE ──────────────────────────────
  // Priorité : originVillage > originCity > (père : originVillage >
  // birthPlace) > repli historique (birthPlace mère, puis personne).
  final pilierPlace = _clean(person.originVillage) ??
      _clean(person.originCity) ??
      _clean(father?.originVillage) ??
      _clean(father?.birthPlace) ??
      _clean(mother?.birthPlace) ??
      _clean(person.birthPlace);
  final pilierConcession = _clean(father?.lastName);

  // Sous-libellé « {région} · {pays d'origine} » quand disponible.
  final originDetailParts = [
    _clean(person.originRegion),
    _clean(person.originCountry)?.toUpperCase(),
  ].whereType<String>().toList();
  final pilierOriginDetail =
      originDetailParts.isEmpty ? null : originDetailParts.join(' · ');

  // ── Étapes chronologiques ───────────────────────────────────────────
  final steps = <MigrationStep>[];

  void addStep({
    required String? place,
    required String title,
    required String subtitle,
    required MigrationStepKind kind,
    int? year,
  }) {
    final cleaned = _clean(place);
    if (cleaned == null) return;
    // Pas de doublon consécutif (comparaison normalisée).
    if (steps.isNotEmpty && _norm(steps.last.place) == _norm(cleaned)) {
      return;
    }
    steps.add(MigrationStep(
      place: cleaned,
      year: year,
      title: title,
      subtitle: subtitle,
      kind: kind,
    ));
  }

  // 1. Naissance.
  final birthPlace = _clean(person.birthPlace);
  final bornInMaternalQuarter =
      _samePlace(person.birthPlace, mother?.birthPlace);
  addStep(
    place: birthPlace,
    title: 'Naissance',
    subtitle:
        bornInMaternalQuarter ? 'naissance — quartier maternel' : 'naissance',
    kind: MigrationStepKind.naissance,
    year: person.birthDate?.year,
  );

  // 2. Retour à la concession (pilier), sans année.
  if (pilierPlace != null && !_samePlace(pilierPlace, birthPlace)) {
    addStep(
      place: pilierPlace,
      title: 'Retour à la concession',
      subtitle: pilierConcession != null
          ? 'concession $pilierConcession'
          : 'concession familiale',
      kind: MigrationStepKind.retour,
    );
  }

  // 3. Résidence actuelle (ÉVOLUTION) : residenceCity en libellé principal
  //    quand présent, sinon residenceCountry, sinon birthPlace de repli
  //    SEULEMENT s'il diffère du pilier.
  final residenceCity = _clean(person.residenceCity);
  final residenceCountry = _clean(person.residenceCountry)?.toUpperCase();
  final residence = residenceCity ??
      residenceCountry ??
      (!_samePlace(birthPlace, pilierPlace) ? birthPlace : null);
  final profession = _clean(person.profession);
  final residenceSubtitle = StringBuffer('résidence actuelle');
  if (residenceCity != null && residenceCountry != null) {
    residenceSubtitle.write(' · $residenceCountry');
  }
  if (profession != null) {
    residenceSubtitle.write(' — $profession');
  }
  addStep(
    place: residence,
    title: 'Résidence actuelle',
    subtitle: residenceSubtitle.toString(),
    kind: MigrationStepKind.residence,
  );

  // ── Alliances ───────────────────────────────────────────────────────
  final alliances = <MigrationAlliance>[];
  final allianceKeys = <String>{};

  void addAlliance({
    required String? place,
    required AllianceKind kind,
    String? withName,
  }) {
    final cleaned = _clean(place);
    if (cleaned == null) return;
    if (_samePlace(cleaned, pilierPlace)) return;
    final key = '${kind.name}|${_norm(cleaned)}|${withName ?? ''}';
    if (!allianceKeys.add(key)) return;
    alliances.add(
      MigrationAlliance(place: cleaned, kind: kind, withName: withName),
    );
  }

  // a. Alliance maternelle.
  addAlliance(
    place: mother?.birthPlace,
    kind: AllianceKind.maternelle,
    withName: mother != null ? _fullName(mother) : null,
  );

  // b. Alliances par union (unions de la personne ou de son foyer).
  for (final union in tree.unions) {
    PersonGenealogy? spouse;
    if (union.husbandId == person.id) {
      spouse = union.wife;
    } else if (union.wifeId == person.id) {
      spouse = union.husband;
    }
    if (spouse == null) continue;
    addAlliance(
      place: spouse.birthPlace,
      kind: AllianceKind.parUnion,
      withName: _fullName(spouse),
    );
  }

  // ── Toute la famille ────────────────────────────────────────────────
  final familyPlaces = <FamilyPlace>[];
  final seenPersonIds = <String>{};

  void addFamilyPlace(PersonGenealogy? member) {
    if (member == null) return;
    final place = _clean(member.birthPlace);
    if (place == null) return;
    if (!seenPersonIds.add(member.id)) return;
    familyPlaces.add(FamilyPlace(person: member, place: place));
  }

  addFamilyPlace(tree.subject);
  tree.father.forEach(addFamilyPlace);
  tree.mother.forEach(addFamilyPlace);
  tree.paternalGP.forEach(addFamilyPlace);
  tree.maternalGP.forEach(addFamilyPlace);
  for (final sibling in tree.siblings) {
    addFamilyPlace(sibling.person);
  }
  tree.children.forEach(addFamilyPlace);
  tree.cousins.forEach(addFamilyPlace);
  tree.uncles.forEach(addFamilyPlace);
  for (final union in tree.unions) {
    addFamilyPlace(union.husband);
    addFamilyPlace(union.wife);
  }

  return MigrationJourney(
    person: person,
    pilierPlace: pilierPlace,
    pilierConcession: pilierConcession,
    pilierOriginDetail: pilierOriginDetail,
    steps: List.unmodifiable(steps),
    alliances: List.unmodifiable(alliances),
    familyPlaces: List.unmodifiable(familyPlaces),
  );
}
