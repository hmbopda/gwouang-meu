/// Analyseur pur Dart de l'arbre généalogique — aucun réseau, aucun LLM.
///
/// Tout est calculé localement depuis [FamilyTree] : complétude, incohérences,
/// doublons potentiels, récit narratif d'une personne, chemin de parenté et
/// recherche par nom (insensible à la casse et aux accents).
///
/// Aucune dépendance UI (pas de material), null-safe, listes immuables.
library;

import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/genealogy_union.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Structures exposées
// ─────────────────────────────────────────────────────────────────────────────

/// Gravité d'une incohérence détectée dans l'arbre.
enum InsightSeverity { info, warning }

/// Une incohérence détectée dans les données de l'arbre.
class TreeInconsistency {
  final String title;
  final String detail;
  final String personId;
  final InsightSeverity severity;

  const TreeInconsistency({
    required this.title,
    required this.detail,
    required this.personId,
    required this.severity,
  });
}

/// Deux personnes potentiellement identiques.
class DuplicateCandidate {
  final PersonGenealogy a;
  final PersonGenealogy b;
  final String reason;

  const DuplicateCandidate({
    required this.a,
    required this.b,
    required this.reason,
  });
}

/// Synthèse de l'analyse de l'arbre.
class TreeInsights {
  /// Pourcentage (0-100) de champs remplis sur l'ensemble des membres
  /// (birthDate, birthPlace, clan, photoUrl, residenceCountry).
  final int completenessPct;

  /// 2-3 libellés lisibles, ex. « 5 dates de naissance manquantes ».
  final List<String> missingHighlights;

  final List<TreeInconsistency> inconsistencies;
  final List<DuplicateCandidate> duplicates;

  TreeInsights({
    required this.completenessPct,
    required List<String> missingHighlights,
    required List<TreeInconsistency> inconsistencies,
    required List<DuplicateCandidate> duplicates,
  })  : missingHighlights = List.unmodifiable(missingHighlights),
        inconsistencies = List.unmodifiable(inconsistencies),
        duplicates = List.unmodifiable(duplicates);
}

/// Un pas dans une chaîne de parenté : la personne atteinte et le libellé
/// de la relation depuis le pas précédent (« mère », « épouse », « fils »…).
class KinshipStep {
  final PersonGenealogy person;
  final String relation;

  const KinshipStep({required this.person, required this.relation});
}

// ─────────────────────────────────────────────────────────────────────────────
// API publique
// ─────────────────────────────────────────────────────────────────────────────

/// Analyse complète de l'arbre : complétude, incohérences, doublons.
TreeInsights buildTreeInsights(FamilyTree tree) {
  final index = _personIndex(tree);
  final members = index.values.toList(growable: false);

  // ── Complétude ──
  var filled = 0;
  var missingBirthDate = 0;
  var missingBirthPlace = 0;
  var missingClan = 0;
  var missingPhoto = 0;
  var missingResidence = 0;

  for (final p in members) {
    if (p.birthDate != null) {
      filled++;
    } else {
      missingBirthDate++;
    }
    if (_hasText(p.birthPlace)) {
      filled++;
    } else {
      missingBirthPlace++;
    }
    if (_hasText(p.clan)) {
      filled++;
    } else {
      missingClan++;
    }
    if (_hasText(p.photoUrl)) {
      filled++;
    } else {
      missingPhoto++;
    }
    if (_hasText(p.residenceCountry)) {
      filled++;
    } else {
      missingResidence++;
    }
  }

  final totalFields = members.length * 5;
  final completenessPct =
      totalFields == 0 ? 100 : (filled * 100 / totalFields).round();

  final highlights = <String>[];
  final missingCounts = <MapEntry<int, String Function(int)>>[
    MapEntry(missingBirthDate,
        (n) => n == 1 ? '1 date de naissance manquante' : '$n dates de naissance manquantes'),
    MapEntry(missingPhoto,
        (n) => n == 1 ? '1 photo manquante' : '$n photos manquantes'),
    MapEntry(missingBirthPlace,
        (n) => n == 1 ? '1 lieu de naissance manquant' : '$n lieux de naissance manquants'),
    MapEntry(missingClan,
        (n) => n == 1 ? '1 clan non renseigné' : '$n clans non renseignés'),
    MapEntry(missingResidence,
        (n) => n == 1 ? '1 pays de résidence manquant' : '$n pays de résidence manquants'),
  ]..sort((a, b) => b.key.compareTo(a.key));
  for (final entry in missingCounts) {
    if (entry.key > 0 && highlights.length < 3) {
      highlights.add(entry.value(entry.key));
    }
  }

  // ── Incohérences ──
  final inconsistencies = <TreeInconsistency>[];

  for (final union in tree.unions) {
    _checkUnionAges(union, index, inconsistencies);
  }

  for (final p in members) {
    _checkChildConsistency(p, tree, index, inconsistencies);
  }

  // ── Doublons ──
  final duplicates = <DuplicateCandidate>[];
  for (var i = 0; i < members.length; i++) {
    for (var j = i + 1; j < members.length; j++) {
      final a = members[i];
      final b = members[j];
      final fullA = _normalize('${a.firstName} ${a.lastName}');
      final fullB = _normalize('${b.firstName} ${b.lastName}');
      if (fullA.isNotEmpty && fullA == fullB) {
        duplicates.add(DuplicateCandidate(
          a: a,
          b: b,
          reason: 'Même prénom et même nom (${a.firstName} ${a.lastName})',
        ));
        continue;
      }
      final lastA = _normalize(a.lastName);
      final lastB = _normalize(b.lastName);
      final yearA = a.birthDate?.year;
      final yearB = b.birthDate?.year;
      if (lastA.isNotEmpty &&
          lastA == lastB &&
          yearA != null &&
          yearB != null &&
          (yearA - yearB).abs() <= 2) {
        duplicates.add(DuplicateCandidate(
          a: a,
          b: b,
          reason:
              'Même nom de famille (${a.lastName}) et naissances rapprochées ($yearA / $yearB)',
        ));
      }
    }
  }

  return TreeInsights(
    completenessPct: completenessPct,
    missingHighlights: highlights,
    inconsistencies: inconsistencies,
    duplicates: duplicates,
  );
}

/// Récit narratif en français (2-3 phrases) construit uniquement à partir
/// des champs réellement disponibles — aucun champ inventé.
String buildPersonNarrative(FamilyTree tree, PersonGenealogy p) {
  final index = _personIndex(tree);
  final female = _isFemale(p);

  var father = p.fatherId == null ? null : index[p.fatherId];
  var mother = p.motherId == null ? null : index[p.motherId];
  if (p.id == tree.subject.id) {
    father ??= tree.father.isNotEmpty ? tree.father.first : null;
    mother ??= tree.mother.isNotEmpty ? tree.mother.first : null;
  }

  final sentences = <String>[];

  // ── Phrase 1 : naissance + clan(s) ──
  final ne = female ? 'Née' : 'Né';
  final place = p.birthPlace?.trim();
  final year = p.birthDate?.year;
  String opening;
  if (place != null && place.isNotEmpty && year != null) {
    opening = '$ne à $place en $year, ${p.firstName}';
  } else if (place != null && place.isNotEmpty) {
    opening = '$ne à $place, ${p.firstName}';
  } else if (year != null) {
    opening = '$ne en $year, ${p.firstName}';
  } else {
    opening = '${p.firstName} ${p.lastName}';
  }

  final fatherClan = father?.clan?.trim();
  final motherClan = mother?.clan?.trim();
  if (fatherClan != null &&
      fatherClan.isNotEmpty &&
      motherClan != null &&
      motherClan.isNotEmpty &&
      _normalize(fatherClan) != _normalize(motherClan)) {
    sentences.add('$opening relie les clans $fatherClan et $motherClan.');
  } else if (_hasText(p.clan)) {
    sentences.add('$opening appartient au clan ${p.clan!.trim()}.');
  } else {
    sentences.add('$opening fait partie de cette lignée familiale.');
  }

  // ── Phrase 2 : foyer / mère si connus ──
  final pronoun = female ? 'Elle' : 'Il';
  final filiation = female ? 'la fille' : 'le fils';
  if (father != null && mother != null) {
    sentences.add(
        '$pronoun est $filiation de ${father.firstName} ${father.lastName} '
        'et de ${mother.firstName} ${mother.lastName}.');
  } else if (mother != null) {
    sentences.add(
        '$pronoun est $filiation de ${mother.firstName} ${mother.lastName}.');
  } else if (father != null) {
    sentences.add(
        '$pronoun est $filiation de ${father.firstName} ${father.lastName}.');
  }

  // ── Phrase 3 : résidence / profession si connues ──
  final residence = _hasText(p.residenceCountry)
      ? _residenceLabel(p.residenceCountry!.trim())
      : null;
  final profession = _hasText(p.profession) ? p.profession!.trim() : null;
  final lives = p.isAlive;
  if (residence != null && profession != null) {
    sentences.add(lives
        ? "$pronoun vit aujourd'hui $residence et exerce la profession de $profession."
        : '$pronoun a vécu $residence et exerçait la profession de $profession.');
  } else if (residence != null) {
    sentences.add(lives
        ? "$pronoun vit aujourd'hui $residence."
        : '$pronoun a vécu $residence.');
  } else if (profession != null) {
    sentences.add(lives
        ? '$pronoun exerce la profession de $profession.'
        : '$pronoun exerçait la profession de $profession.');
  }

  return sentences.take(3).join(' ');
}

/// Chemin de parenté (BFS) de [fromId] vers [toId] sur les relations
/// disponibles dans l'arbre. Retourne la chaîne de pas libellés
/// (« père », « épouse », « fils »…), une liste vide si les deux ids sont
/// identiques, ou null si aucun chemin n'existe.
List<KinshipStep>? findKinshipPath(FamilyTree tree, String fromId, String toId) {
  final index = _personIndex(tree);
  if (!index.containsKey(fromId) || !index.containsKey(toId)) return null;
  if (fromId == toId) return List.unmodifiable(const <KinshipStep>[]);

  final graph = _buildGraph(tree, index);

  final prevNode = <String, String>{};
  final prevLabel = <String, String>{};
  final visited = <String>{fromId};
  final queue = <String>[fromId];
  var head = 0;

  while (head < queue.length) {
    final current = queue[head++];
    for (final edge in graph[current] ?? const <_Edge>[]) {
      if (visited.contains(edge.toId)) continue;
      visited.add(edge.toId);
      prevNode[edge.toId] = current;
      prevLabel[edge.toId] = edge.label;
      if (edge.toId == toId) {
        // Reconstruction du chemin.
        final steps = <KinshipStep>[];
        var node = toId;
        while (node != fromId) {
          final person = index[node];
          final label = prevLabel[node];
          final parent = prevNode[node];
          if (person == null || label == null || parent == null) return null;
          steps.add(KinshipStep(person: person, relation: label));
          node = parent;
        }
        return List.unmodifiable(steps.reversed.toList(growable: false));
      }
      queue.add(edge.toId);
    }
  }
  return null;
}

/// Recherche une personne par nom, insensible à la casse et aux accents.
/// Meilleur score retenu : égalité > contient > préfixe de mots > fuzzy simple.
PersonGenealogy? findPersonByName(FamilyTree tree, String query) {
  final q = _normalize(query);
  if (q.isEmpty) return null;

  PersonGenealogy? best;
  var bestScore = 0;
  var bestLength = 1 << 30;

  for (final p in _personIndex(tree).values) {
    final full = _normalize('${p.firstName} ${p.lastName}');
    final reversed = _normalize('${p.lastName} ${p.firstName}');

    var score = 0;
    if (full == q || reversed == q) {
      score = 100;
    } else if (full.contains(q) || reversed.contains(q)) {
      score = 80;
    } else {
      final queryTokens =
          q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final nameTokens =
          full.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final allPrefixes = queryTokens.isNotEmpty &&
          queryTokens.every(
              (t) => nameTokens.any((w) => w.startsWith(t)));
      if (allPrefixes) {
        score = 60;
      } else if (_isSubsequence(
          q.replaceAll(' ', ''), full.replaceAll(' ', ''))) {
        score = 30;
      }
    }

    if (score > bestScore ||
        (score == bestScore && score > 0 && full.length < bestLength)) {
      best = p;
      bestScore = score;
      bestLength = full.length;
    }
  }
  return bestScore > 0 ? best : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers internes
// ─────────────────────────────────────────────────────────────────────────────

bool _hasText(String? s) => s != null && s.trim().isNotEmpty;

bool _isFemale(PersonGenealogy p) =>
    p.gender.trim().toUpperCase().startsWith('F');

/// Nombre d'années révolues entre deux dates ([from] antérieure à [to]).
int _yearsBetween(DateTime from, DateTime to) {
  var years = to.year - from.year;
  if (to.month < from.month ||
      (to.month == from.month && to.day < from.day)) {
    years--;
  }
  return years;
}

const Map<String, String> _accentMap = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'œ': 'oe', 'æ': 'ae',
  '-': ' ', '\'': ' ', '’': ' ',
};

/// Minuscule + suppression des accents + espaces normalisés.
String _normalize(String s) {
  final lower = s.toLowerCase().trim();
  final sb = StringBuffer();
  for (final ch in lower.split('')) {
    sb.write(_accentMap[ch] ?? ch);
  }
  return sb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// [needle] est-il une sous-séquence ordonnée de [haystack] ?
bool _isSubsequence(String needle, String haystack) {
  if (needle.isEmpty) return false;
  var i = 0;
  for (var j = 0; j < haystack.length && i < needle.length; j++) {
    if (needle[i] == haystack[j]) i++;
  }
  return i == needle.length;
}

/// Index id → personne de tous les membres visibles de l'arbre.
Map<String, PersonGenealogy> _personIndex(FamilyTree tree) {
  final index = <String, PersonGenealogy>{};
  void add(PersonGenealogy? p) {
    if (p != null) index.putIfAbsent(p.id, () => p);
  }

  add(tree.subject);
  tree.father.forEach(add);
  tree.mother.forEach(add);
  tree.paternalGP.forEach(add);
  tree.maternalGP.forEach(add);
  for (final s in tree.siblings) {
    add(s.person);
  }
  tree.children.forEach(add);
  for (final u in tree.unions) {
    add(u.husband);
    add(u.wife);
  }
  tree.uncles.forEach(add);
  tree.cousins.forEach(add);
  return index;
}

class _Edge {
  final String toId;
  final String label;
  const _Edge(this.toId, this.label);
}

String _parentLabel(PersonGenealogy p) => _isFemale(p) ? 'mère' : 'père';
String _childLabel(PersonGenealogy p) => _isFemale(p) ? 'fille' : 'fils';
String _spouseLabel(PersonGenealogy p) => _isFemale(p) ? 'épouse' : 'époux';
String _siblingLabel(PersonGenealogy p) => _isFemale(p) ? 'sœur' : 'frère';
String _uncleLabel(PersonGenealogy p) => _isFemale(p) ? 'tante' : 'oncle';
String _nephewLabel(PersonGenealogy p) => _isFemale(p) ? 'nièce' : 'neveu';
String _cousinLabel(PersonGenealogy p) => _isFemale(p) ? 'cousine' : 'cousin';

/// Graphe orienté étiqueté : le libellé d'une arête décrit la personne cible
/// relativement à la personne source (« mère » = la cible est la mère de la
/// source).
Map<String, List<_Edge>> _buildGraph(
    FamilyTree tree, Map<String, PersonGenealogy> index) {
  final graph = <String, List<_Edge>>{};

  void addEdge(String fromId, String toId, String label) {
    if (fromId == toId) return;
    if (!index.containsKey(fromId) || !index.containsKey(toId)) return;
    graph.putIfAbsent(fromId, () => <_Edge>[]).add(_Edge(toId, label));
  }

  void linkParentChild(PersonGenealogy parent, PersonGenealogy child) {
    addEdge(child.id, parent.id, _parentLabel(parent));
    addEdge(parent.id, child.id, _childLabel(child));
  }

  // Filiation déclarée sur chaque personne (motherId / fatherId).
  for (final p in index.values) {
    final mother = p.motherId == null ? null : index[p.motherId];
    if (mother != null) linkParentChild(mother, p);
    final father = p.fatherId == null ? null : index[p.fatherId];
    if (father != null) linkParentChild(father, p);
  }

  final subject = tree.subject;

  // Sujet ↔ parents exposés par l'arbre.
  for (final f in tree.father) {
    linkParentChild(f, subject);
  }
  for (final m in tree.mother) {
    linkParentChild(m, subject);
  }

  // Parents ↔ grands-parents.
  for (final f in tree.father) {
    for (final gp in tree.paternalGP) {
      linkParentChild(gp, f);
    }
  }
  for (final m in tree.mother) {
    for (final gp in tree.maternalGP) {
      linkParentChild(gp, m);
    }
  }

  // Sujet ↔ fratrie.
  for (final s in tree.siblings) {
    addEdge(subject.id, s.person.id, _siblingLabel(s.person));
    addEdge(s.person.id, subject.id, _siblingLabel(subject));
  }

  // Sujet ↔ enfants.
  for (final c in tree.children) {
    linkParentChild(subject, c);
  }

  // Conjoints via les unions.
  for (final u in tree.unions) {
    final husband = u.husband ?? index[u.husbandId];
    final wife = u.wife ?? index[u.wifeId];
    if (husband != null && wife != null) {
      addEdge(husband.id, wife.id, _spouseLabel(wife));
      addEdge(wife.id, husband.id, _spouseLabel(husband));
    }
  }

  // Sujet ↔ oncles/tantes.
  for (final u in tree.uncles) {
    addEdge(subject.id, u.id, _uncleLabel(u));
    addEdge(u.id, subject.id, _nephewLabel(subject));
  }

  // Sujet ↔ cousins/cousines.
  for (final c in tree.cousins) {
    addEdge(subject.id, c.id, _cousinLabel(c));
    addEdge(c.id, subject.id, _cousinLabel(subject));
  }

  return graph;
}

// ── Règles d'incohérence ──

void _checkUnionAges(GenealogyUnion union, Map<String, PersonGenealogy> index,
    List<TreeInconsistency> out) {
  final start = union.startDate;
  if (start == null) return;

  final spouses = <PersonGenealogy?>[
    union.husband ?? index[union.husbandId],
    union.wife ?? index[union.wifeId],
  ];
  for (final spouse in spouses) {
    final birth = spouse?.birthDate;
    if (spouse == null || birth == null) continue;
    if (start.isBefore(birth)) {
      out.add(TreeInconsistency(
        title: 'Union antérieure à la naissance',
        detail:
            "L'union de ${spouse.firstName} ${spouse.lastName} débute en ${start.year}, "
            'avant sa naissance en ${birth.year}.',
        personId: spouse.id,
        severity: InsightSeverity.warning,
      ));
    } else if (_yearsBetween(birth, start) < 12) {
      out.add(TreeInconsistency(
        title: 'Union précoce',
        detail:
            '${spouse.firstName} ${spouse.lastName} aurait moins de 12 ans '
            "au début de l'union (${start.year}).",
        personId: spouse.id,
        severity: InsightSeverity.warning,
      ));
    }
  }
}

void _checkChildConsistency(PersonGenealogy child, FamilyTree tree,
    Map<String, PersonGenealogy> index, List<TreeInconsistency> out) {
  final childBirth = child.birthDate;
  if (childBirth == null) return;

  // Enfant né avant les 12 ans de sa mère, ou avant sa naissance.
  final mother = child.motherId == null ? null : index[child.motherId];
  final motherBirth = mother?.birthDate;
  if (mother != null && motherBirth != null) {
    if (childBirth.isBefore(motherBirth)) {
      out.add(TreeInconsistency(
        title: 'Enfant né avant sa mère',
        detail:
            '${child.firstName} ${child.lastName} serait né·e en ${childBirth.year}, '
            'avant sa mère ${mother.firstName} (${motherBirth.year}).',
        personId: child.id,
        severity: InsightSeverity.warning,
      ));
    } else if (_yearsBetween(motherBirth, childBirth) < 12) {
      out.add(TreeInconsistency(
        title: 'Mère trop jeune',
        detail:
            '${mother.firstName} ${mother.lastName} aurait moins de 12 ans '
            'à la naissance de ${child.firstName} (${childBirth.year}).',
        personId: child.id,
        severity: InsightSeverity.warning,
      ));
    }
  }

  // Enfant né plus d'un an avant l'union correspondante (info seulement).
  if (child.unionId != null) {
    GenealogyUnion? union;
    for (final u in tree.unions) {
      if (u.id == child.unionId) {
        union = u;
        break;
      }
    }
    final start = union?.startDate;
    if (start != null) {
      final threshold = DateTime(start.year - 1, start.month, start.day);
      if (childBirth.isBefore(threshold)) {
        out.add(TreeInconsistency(
          title: "Naissance avant l'union",
          detail:
              '${child.firstName} ${child.lastName} est né·e en ${childBirth.year}, '
              "plus d'un an avant l'union correspondante (${start.year}).",
          personId: child.id,
          severity: InsightSeverity.info,
        ));
      }
    }
  }
}

// ── Libellés de pays de résidence (ISO-3166 alpha-2) ──

const Map<String, String> _countryLabels = {
  'CM': 'au Cameroun',
  'FR': 'en France',
  'BE': 'en Belgique',
  'DE': 'en Allemagne',
  'GB': 'au Royaume-Uni',
  'US': 'aux États-Unis',
  'CA': 'au Canada',
  'SN': 'au Sénégal',
  'CI': "en Côte d'Ivoire",
  'GA': 'au Gabon',
  'TD': 'au Tchad',
  'NG': 'au Nigeria',
  'GH': 'au Ghana',
  'CG': 'au Congo',
  'CD': 'en République démocratique du Congo',
  'CF': 'en Centrafrique',
  'GQ': 'en Guinée équatoriale',
  'IT': 'en Italie',
  'ES': 'en Espagne',
  'PT': 'au Portugal',
  'CH': 'en Suisse',
  'NL': 'aux Pays-Bas',
  'MA': 'au Maroc',
  'DZ': 'en Algérie',
  'TN': 'en Tunisie',
  'ZA': 'en Afrique du Sud',
  'AU': 'en Australie',
  'CN': 'en Chine',
  'JP': 'au Japon',
};

String _residenceLabel(String code) =>
    _countryLabels[code.toUpperCase()] ?? 'dans le pays $code';
