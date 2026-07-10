/// Le Griot (maquette 4b) — dialog de chat qui répond RÉELLEMENT depuis
/// l'arbre via l'analyseur pur Dart [ai_insights] : aucun LLM, aucun réseau.
///
/// Moteur de réponse à règles :
/// 1. extraction du nom dans la question (containsIgnoreAccents + fallback
///    [findPersonByName] sur les mots significatifs) ;
/// 2. personne trouvée → [buildPersonNarrative] + chaîne de parenté
///    ([findKinshipPath]) rendue en chips + « Ouvrir dans l'arbre » ;
/// 3. « chef » / « transmet » → ordre de succession dérivé (aînesse) ;
/// 4. sinon → invitation à réessayer avec des exemples réels de l'arbre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/genealogy/models/family_tree.dart';
import 'package:gwangmeu/features/genealogy/models/person_genealogy.dart';
import 'package:gwangmeu/features/genealogy/state/ai_insights.dart';
import 'package:gwangmeu/features/genealogy/state/tree_view_state.dart';

/// Ouvre le dialog du Griot pour l'arbre [tree], du point de vue de la
/// personne [subjectId] (les chaînes de parenté partent d'elle).
Future<void> showGriotDialog(
  BuildContext context,
  FamilyTree tree,
  String subjectId,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _GriotDialog(tree: tree, subjectId: subjectId),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Couleurs locales de la maquette 4b (en-tête brun / crème)
// ─────────────────────────────────────────────────────────────────────────────

const Color _brown = Color(0xFF3B2A16);
const Color _cream = Color(0xFFF0EBE1);

// ─────────────────────────────────────────────────────────────────────────────
// Modèle de message
// ─────────────────────────────────────────────────────────────────────────────

class _GriotMsg {
  final bool isUser;
  final String text;

  /// Chaîne de parenté sujet → personne (chips « badge initiales + prénom »).
  final List<KinshipStep>? kinshipSteps;

  /// Personne à ouvrir dans l'arbre (bouton « Ouvrir dans l'arbre »).
  final PersonGenealogy? openPerson;

  /// Questions suggérées, cliquables (chips sous la bulle).
  final List<String> suggestions;

  const _GriotMsg.user(this.text)
      : isUser = true,
        kinshipSteps = null,
        openPerson = null,
        suggestions = const [];

  const _GriotMsg.griot(
    this.text, {
    this.kinshipSteps,
    this.openPerson,
    this.suggestions = const [],
  }) : isUser = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _GriotDialog extends ConsumerStatefulWidget {
  final FamilyTree tree;
  final String subjectId;

  const _GriotDialog({required this.tree, required this.subjectId});

  @override
  ConsumerState<_GriotDialog> createState() => _GriotDialogState();
}

class _GriotDialogState extends ConsumerState<_GriotDialog> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  late final List<PersonGenealogy> _members;
  late final PersonGenealogy _subject;
  final List<_GriotMsg> _messages = [];

  @override
  void initState() {
    super.initState();
    _members = _collectMembers(widget.tree);
    _subject = _members.firstWhere(
      (p) => p.id == widget.subjectId,
      orElse: () => widget.tree.subject,
    );
    _messages.add(_GriotMsg.griot(
      "Demandez-moi d'où vient un membre de la famille, "
      'ou votre lien avec lui.',
      suggestions: _welcomeSuggestions(),
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Collecte des membres visibles de l'arbre ──────────────────────────────

  static List<PersonGenealogy> _collectMembers(FamilyTree tree) {
    final seen = <String>{};
    final out = <PersonGenealogy>[];
    void add(PersonGenealogy? p) {
      if (p != null && seen.add(p.id)) out.add(p);
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
    return out;
  }

  // ── Suggestions construites depuis l'arbre réel ───────────────────────────

  List<String> _welcomeSuggestions() {
    final out = <String>[];
    final usedIds = <String>{};

    final wife = widget.tree.unions
        .map((u) => u.wife)
        .whereType<PersonGenealogy>()
        .where((p) => p.id != _subject.id)
        .firstOrNull;
    if (wife != null) {
      out.add("D'où vient ${wife.firstName} ?");
      usedIds.add(wife.id);
    }

    final child = widget.tree.children
        .where((c) => c.id != _subject.id && !usedIds.contains(c.id))
        .firstOrNull;
    if (child != null) {
      out.add('Quel est mon lien avec ${child.firstName} ?');
      usedIds.add(child.id);
    }

    for (final p in _members) {
      if (out.length >= 3) break;
      if (p.id == _subject.id || usedIds.contains(p.id)) continue;
      out.add(out.length.isEven
          ? "D'où vient ${p.firstName} ?"
          : 'Quel est mon lien avec ${p.firstName} ?');
      usedIds.add(p.id);
    }
    return out.take(3).toList();
  }

  /// 2 questions de relance sur d'autres membres que [excludeId].
  List<String> _followUpSuggestions(String excludeId) {
    final out = <String>[];
    for (final p in _members) {
      if (out.length >= 2) break;
      if (p.id == excludeId || p.id == _subject.id) continue;
      out.add(out.isEmpty
          ? "D'où vient ${p.firstName} ?"
          : 'Quel est mon lien avec ${p.firstName} ?');
    }
    return out;
  }

  // ── Moteur de réponse (règles, aucun réseau) ──────────────────────────────

  static const Set<String> _stopwords = {
    'avec', 'lien', 'vient', 'viennent', 'quel', 'quelle', 'quels',
    'quelles', 'mon', 'ma', 'mes', 'notre', 'votre', 'est', 'sont',
    'qui', 'que', 'quoi', 'dans', 'pour', 'elle', 'lui', 'vous',
    'nous', 'famille', 'chef', 'transmet', 'transmission', 'arbre',
    'origine', 'comment', 'pourquoi', 'histoire', 'raconte', 'moi',
    'membre', 'lignee', 'clan', 'entre', 'aussi', 'donc', 'alors',
  };

  PersonGenealogy? _matchPerson(String question) {
    final q = _norm(question);
    if (q.isEmpty) return null;

    // 1. Prénom / nom / nom complet contenu dans la question
    //    (insensible à la casse et aux accents).
    PersonGenealogy? best;
    var bestLen = 0;
    for (final p in _members) {
      final candidates = <String>[
        _norm('${p.firstName} ${p.lastName}'),
        _norm(p.firstName),
        _norm(p.lastName),
      ];
      for (final c in candidates) {
        if (c.length >= 3 && q.contains(c) && c.length > bestLen) {
          best = p;
          bestLen = c.length;
        }
      }
    }
    if (best != null) return best;

    // 2. Fallback : findPersonByName sur les mots significatifs de la question.
    final tokens = q
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 4 && !_stopwords.contains(t));
    for (final t in tokens) {
      final found = findPersonByName(widget.tree, t);
      if (found != null) return found;
    }
    return null;
  }

  _GriotMsg _answer(String question) {
    final person = _matchPerson(question);

    // ── Règle 2 : personne reconnue → récit + chaîne de parenté ──
    if (person != null) {
      final narrative = buildPersonNarrative(widget.tree, person);
      final path = person.id == _subject.id
          ? null
          : findKinshipPath(widget.tree, _subject.id, person.id);
      return _GriotMsg.griot(
        narrative,
        kinshipSteps: (path != null && path.isNotEmpty) ? path : null,
        openPerson: person,
        suggestions: _followUpSuggestions(person.id),
      );
    }

    // ── Règle 3 : succession (« chef » / « transmet ») ──
    final qn = _norm(question);
    if (qn.contains('chef') || qn.contains('transmet')) {
      return _successionAnswer();
    }

    // ── Règle 4 : nom non reconnu ──
    final examples = _members
        .where((p) => p.id != _subject.id)
        .take(3)
        .map((p) => p.firstName)
        .join(', ');
    return _GriotMsg.griot(
      "Je n'ai pas reconnu ce nom dans l'arbre. Essayez avec le prénom "
      "d'un membre — par exemple $examples.",
      suggestions: _followUpSuggestions(_subject.id),
    );
  }

  _GriotMsg _successionAnswer() {
    final children = [...widget.tree.children];
    if (children.isEmpty) {
      return _GriotMsg.griot(
        "L'arbre ne mentionne pas encore d'enfant du sujet : je ne peux pas "
        "dériver l'ordre de succession. La transmission demande de toute "
        'façon la validation de 2 témoins du clan.',
        suggestions: _followUpSuggestions(_subject.id),
      );
    }
    children.sort((a, b) {
      final da = a.birthDate;
      final db = b.birthDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    final heir = children.first;
    final isF = heir.gender.trim().toUpperCase().startsWith('F');
    return _GriotMsg.griot(
      "Selon l'ordre d'aînesse, ${heir.firstName} serait "
      '${isF ? 'pressentie' : 'pressenti'} pour reprendre le rôle de chef '
      'de famille — la transmission demande la validation de 2 témoins '
      'du clan.',
      openPerson: heir,
      suggestions: _followUpSuggestions(heir.id),
    );
  }

  // ── Envoi & auto-scroll ───────────────────────────────────────────────────

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_GriotMsg.user(text));
      _messages.add(_answer(text));
    });
    _input.clear();
    _focus.requestFocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openInTree(PersonGenealogy p) {
    ref.read(treeViewProvider.notifier).selectPerson(p.id);
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    return Dialog(
      backgroundColor: t.ink,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Expanded(child: _messagesArea(t)),
            _inputBar(t),
          ],
        ),
      ),
    );
  }

  // ── En-tête brun ──────────────────────────────────────────────────────────

  Widget _header() {
    return Container(
      color: _brown,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: GwTokens.gold,
              shape: BoxShape.circle,
            ),
            child: const Text('🗣', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le Griot',
                  style: GwType.display(fontSize: 16, color: _cream),
                ),
                const SizedBox(height: 1),
                Text(
                  'mémoire de la lignée '
                  '${_subject.firstName} ${_subject.lastName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GwType.ui(
                    fontSize: 11.5,
                    color: _cream.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              size: 18,
              color: _cream.withValues(alpha: 0.8),
            ),
            tooltip: 'Fermer',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ── Zone messages ─────────────────────────────────────────────────────────

  Widget _messagesArea(GwTokens t) {
    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in _messages)
            m.isUser ? _userBubble(t, m) : _griotBubble(t, m),
        ],
      ),
    );
  }

  Widget _userBubble(GwTokens t, _GriotMsg m) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.goldBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(3),
          ),
        ),
        child: Text(
          m.text,
          style: GwType.ui(fontSize: 12.5, color: t.stone, height: 1.4),
        ),
      ),
    );
  }

  Widget _griotBubble(GwTokens t, _GriotMsg m) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 48),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: t.inkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: GwType.quote(fontSize: 13, color: t.stone, height: 1.5),
            ),
            if (m.kinshipSteps != null) ...[
              const SizedBox(height: 8),
              Text(
                'VOICI LA CHAÎNE',
                style: GwType.mono(
                  fontSize: 10,
                  color: t.stoneDim,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              _kinshipRow(t, m.kinshipSteps!),
            ],
            if (m.openPerson != null) ...[
              const SizedBox(height: 8),
              _openInTreeButton(t, m.openPerson!),
            ],
            if (m.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in m.suggestions) _suggestionChip(t, s),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Chaîne de parenté : chips séparées par « → » ─────────────────────────

  Widget _kinshipRow(GwTokens t, List<KinshipStep> steps) {
    final children = <Widget>[
      _personChip(t, _subject, 'vous', highlighted: true),
    ];
    for (final step in steps) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text('→', style: GwType.ui(fontSize: 12, color: t.stoneDim)),
      ));
      children.add(_personChip(t, step.person, step.relation));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _personChip(
    GwTokens t,
    PersonGenealogy p,
    String relation, {
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 9, 3),
      decoration: BoxDecoration(
        color: highlighted ? t.goldBg : t.inkLift,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: highlighted ? t.goldLine : t.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? GwTokens.gold : t.inkHigh,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(p),
              style: GwType.display(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: highlighted ? GwTokens.inkOnGold : t.stone,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                p.firstName,
                style: GwType.ui(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: t.stone,
                  height: 1.1,
                ),
              ),
              Text(
                relation,
                style: GwType.ui(
                  fontSize: 10,
                  color: t.stoneDim,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(PersonGenealogy p) {
    final f = p.firstName.trim();
    final l = p.lastName.trim();
    final result =
        '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  // ── Boutons & chips ───────────────────────────────────────────────────────

  Widget _openInTreeButton(GwTokens t, PersonGenealogy p) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: () => _openInTree(p),
        icon: Icon(Icons.account_tree_outlined, size: 14, color: t.goldText),
        label: Text(
          "Ouvrir dans l'arbre",
          style: GwType.ui(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: t.goldText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: t.goldLine),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _suggestionChip(GwTokens t, String question) {
    return InkWell(
      onTap: () => _send(question),
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: t.goldBg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: t.goldLine),
        ),
        child: Text(
          question,
          style: GwType.ui(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: t.goldText,
          ),
        ),
      ),
    );
  }

  // ── Barre de saisie ───────────────────────────────────────────────────────

  Widget _inputBar(GwTokens t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: t.inkCard,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: t.inkLift,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.line),
              ),
              child: Center(
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  onSubmitted: _send,
                  textInputAction: TextInputAction.send,
                  style: GwType.ui(fontSize: 12.5, color: t.stone),
                  decoration: InputDecoration(
                    hintText: 'Demandez au Griot…',
                    hintStyle: GwType.ui(fontSize: 12.5, color: t.stoneDim),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La saisie vocale arrive bientôt.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(Icons.mic_none, size: 18, color: t.stoneMid),
              tooltip: 'Saisie vocale (bientôt)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            height: 34,
            child: Material(
              color: GwTokens.gold,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _send(_input.text),
                child: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: GwTokens.inkOnGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Normalisation locale (minuscules + accents) — containsIgnoreAccents
// ─────────────────────────────────────────────────────────────────────────────

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

String _norm(String s) {
  final lower = s.toLowerCase().trim();
  final sb = StringBuffer();
  for (final ch in lower.split('')) {
    sb.write(_accentMap[ch] ?? ch);
  }
  return sb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
