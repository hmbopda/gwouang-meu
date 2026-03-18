import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_suggestion.dart';
import '../models/family_tree.dart';
import '../models/person_genealogy.dart';
import '../services/genealogy_api_service.dart';
import 'person_comments_sheet.dart';

class FamilyTreeWidget extends ConsumerStatefulWidget {
  final String personId;
  final FamilyTree tree;
  const FamilyTreeWidget({super.key, required this.personId, required this.tree});

  @override
  ConsumerState<FamilyTreeWidget> createState() => _FamilyTreeWidgetState();
}

class _FamilyTreeWidgetState extends ConsumerState<FamilyTreeWidget> {
  static const Color gold = Color(0xFFC8A020);
  static const Color male = Color(0xFF2A4A6A);
  static const Color female = Color(0xFF5A2A4A);
  static const Color dead = Color(0xFF2A2A2A);

  String _currentView = 'full'; // full, ancestors, descendants, unions

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tree = widget.tree;
    debugPrint('[TREE-WIDGET] build — subject=${tree.subject.firstName} ${tree.subject.lastName}, '
        'father=${tree.father.length}, mother=${tree.mother.length}, '
        'children=${tree.children.length}, siblings=${tree.siblings.length}');
    return Column(
      children: [
        // DEBUG BANNER — à supprimer après diagnostic
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1A3A1A),
          child: Text(
            'Arbre: ${tree.subject.firstName} ${tree.subject.lastName} | '
            'Parents: ${tree.father.length + tree.mother.length} | '
            'Enfants: ${tree.children.length} | '
            'Fratrie: ${tree.siblings.length}',
            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11),
          ),
        ),
        _buildToolbar(cs, isDark),
        _buildLegend(cs),
        Expanded(child: _buildTreeView(tree, cs, isDark)),
        if (_isTreeEmpty(tree))
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
            child: Text(
              'Utilisez les boutons "Ajouter un parent" ou "Ajouter un enfant" pour construire votre arbre genealogique.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 13),
            ),
          ),
        if (tree.pendingSuggestions.isNotEmpty)
          _buildAiSuggestionsPanel(tree.pendingSuggestions, cs),
      ],
    );
  }

  bool _isTreeEmpty(FamilyTree tree) {
    return tree.father.isEmpty &&
        tree.mother.isEmpty &&
        tree.children.isEmpty &&
        tree.siblings.isEmpty &&
        tree.paternalGP.isEmpty &&
        tree.maternalGP.isEmpty;
  }

  Widget _buildToolbar(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _viewChip('Complet', 'full', cs, isDark),
          const SizedBox(width: 8),
          _viewChip('Ascendants', 'ancestors', cs, isDark),
          const SizedBox(width: 8),
          _viewChip('Descendants', 'descendants', cs, isDark),
          const SizedBox(width: 8),
          _viewChip('Unions', 'unions', cs, isDark),
        ],
      ),
    );
  }

  Widget _viewChip(String label, String view, ColorScheme cs, bool isDark) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () => setState(() => _currentView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? gold : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : cs.onSurface.withAlpha(180),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _legendDot(gold, 'Sujet', cs),
          _legendDot(male, 'Homme', cs),
          _legendDot(female, 'Femme', cs),
          _legendDot(dead, 'Decede', cs),
          _legendDot(const Color(0xFF3DAA6E), 'Suggestion IA', cs),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 10)),
      ],
    );
  }

  Widget _buildTreeView(FamilyTree tree, ColorScheme cs, bool isDark) {
    final treeWidth = _calculateWidth(tree);
    final treeHeight = _calculateHeight(tree);
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.12);

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(48),
      minScale: 0.5,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomPaint(
          painter: _TreePainter(tree, _currentView, lineColor),
          child: SizedBox(
            width: treeWidth,
            height: treeHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: _buildPersonCards(tree, cs),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateWidth(FamilyTree tree) {
    int maxNodes = [
      tree.paternalGP.length + tree.maternalGP.length,
      tree.father.length + tree.mother.length,
      1, // subject
      tree.children.length,
    ].reduce((a, b) => a > b ? a : b);
    return (maxNodes * 140.0).clamp(400, 2000);
  }

  double _calculateHeight(FamilyTree tree) {
    int levels = 1; // subject
    if (tree.father.isNotEmpty || tree.mother.isNotEmpty) levels++;
    if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) levels++;
    if (tree.children.isNotEmpty) levels++;
    return (levels * 160.0).clamp(300, 800);
  }

  List<Widget> _buildPersonCards(FamilyTree tree, ColorScheme cs) {
    final cards = <Widget>[];
    double centerX = _calculateWidth(tree) / 2;
    int level = 0;

    // Grands-parents (level 0)
    if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) {
      final allGP = [...tree.paternalGP, ...tree.maternalGP];
      _addPersonRow(cards, allGP, centerX, level * 150.0, cs);
      level++;
    }

    // Parents (level 1)
    if (tree.father.isNotEmpty || tree.mother.isNotEmpty) {
      final parents = [...tree.father, ...tree.mother];
      _addPersonRow(cards, parents, centerX, level * 150.0, cs);
      level++;
    }

    // Sujet + freres/soeurs (level 2)
    final subjectRow = [tree.subject, ...tree.siblings.map((s) => s.person)];
    _addPersonRow(cards, subjectRow, centerX, level * 150.0, cs, highlightFirst: true);
    level++;

    // Enfants (level 3)
    if (tree.children.isNotEmpty) {
      _addPersonRow(cards, tree.children, centerX, level * 150.0, cs);
    }

    return cards;
  }

  void _addPersonRow(List<Widget> cards, List<PersonGenealogy> persons,
      double centerX, double y, ColorScheme cs, {bool highlightFirst = false}) {
    double totalWidth = persons.length * 130.0;
    double startX = centerX - totalWidth / 2;

    for (int i = 0; i < persons.length; i++) {
      final p = persons[i];
      final isSubject = highlightFirst && i == 0;
      cards.add(Positioned(
        left: startX + (i * 130.0),
        top: y,
        child: _PersonCard(
          person: p,
          color: isSubject ? gold : _colorForPerson(p),
          size: isSubject ? 32.0 : 26.0,
          cs: cs,
        ),
      ));
    }
  }

  Color _colorForPerson(PersonGenealogy p) {
    if (!p.isAlive) return dead;
    return p.gender == 'MALE' ? male : female;
  }

  Widget _buildAiSuggestionsPanel(List<AiSuggestion> suggestions, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3DAA6E).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF3DAA6E), size: 18),
              const SizedBox(width: 8),
              Text(
                'Suggestions IA (${suggestions.length})',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => _AiSuggestionTile(
            suggestion: s,
            onAccept: () => _reviewSuggestion(s.id, true),
            onReject: () => _reviewSuggestion(s.id, false),
            cs: cs,
          )),
        ],
      ),
    );
  }

  void _reviewSuggestion(String id, bool accepted) async {
    try {
      await ref.read(genealogyApiServiceProvider).reviewSuggestion(id, accepted);
      ref.invalidate(familyTreeProvider(widget.personId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

// ── Person Card Widget ──────────────────────────────────────

class _PersonCard extends StatelessWidget {
  final PersonGenealogy person;
  final Color color;
  final double size;
  final ColorScheme cs;

  const _PersonCard({
    required this.person,
    required this.color,
    required this.cs,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showPersonCommentsSheet(
          context,
          person.id,
          '${person.firstName} ${person.lastName}',
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: cs.onSurface.withAlpha(60),
                  width: 2,
                ),
              ),
              child: person.photoUrl != null
                  ? ClipOval(child: Image.network(person.photoUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        '${person.firstName[0]}${person.lastName[0]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.6,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              person.firstName,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              person.lastName,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withAlpha(180), fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            if (person.clan != null)
              Text(
                person.clan!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC8A020), fontSize: 9),
              ),
            // Icone notes
            const SizedBox(height: 2),
            Icon(Icons.chat_bubble_outline, size: 12, color: cs.onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}

// ── AI Suggestion Tile ──────────────────────────────────────

class _AiSuggestionTile extends StatelessWidget {
  final AiSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final ColorScheme cs;

  const _AiSuggestionTile({
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceColor = suggestion.confidence >= 0.75
        ? Colors.green
        : suggestion.confidence >= 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${suggestion.personA?.firstName ?? "?"} ← ${suggestion.suggestedRelation} → ${suggestion.personB?.firstName ?? "?"}',
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                ),
              ),
              Text(
                '${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: confidenceColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: suggestion.confidence,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(confidenceColor),
          ),
          if (suggestion.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...suggestion.reasons.map((r) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('- $r', style: TextStyle(color: cs.onSurface.withAlpha(140), fontSize: 11)),
            )),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Rejeter'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DAA6E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tree Painter ────────────────────────────────────────────

class _TreePainter extends CustomPainter {
  final FamilyTree tree;
  final String currentView;
  final Color lineColor;

  _TreePainter(this.tree, this.currentView, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double centerX = size.width / 2;
    int level = 0;

    // Lines from grandparents to parents
    if (tree.paternalGP.isNotEmpty || tree.maternalGP.isNotEmpty) {
      final allGP = [...tree.paternalGP, ...tree.maternalGP];
      final parents = [...tree.father, ...tree.mother];
      _drawConnections(canvas, paint, allGP.length, parents.length,
          centerX, level * 150.0 + 100, (level + 1) * 150.0 + 10);
      level++;
    }

    // Lines from parents to subject
    if (tree.father.isNotEmpty || tree.mother.isNotEmpty) {
      final parents = [...tree.father, ...tree.mother];
      final subjectRow = [tree.subject, ...tree.siblings.map((s) => s.person)];
      _drawConnections(canvas, paint, parents.length, subjectRow.length,
          centerX, level * 150.0 + 100, (level + 1) * 150.0 + 10);
      level++;
    }

    // Lines from subject to children
    if (tree.children.isNotEmpty) {
      final subjectRow = [tree.subject, ...tree.siblings.map((s) => s.person)];
      _drawConnections(canvas, paint, subjectRow.length, tree.children.length,
          centerX, level * 150.0 + 100, (level + 1) * 150.0 + 10);
    }
  }

  void _drawConnections(Canvas canvas, Paint paint, int topCount, int bottomCount,
      double centerX, double topY, double bottomY) {
    double topTotalWidth = topCount * 130.0;
    double topStartX = centerX - topTotalWidth / 2;
    double bottomTotalWidth = bottomCount * 130.0;
    double bottomStartX = centerX - bottomTotalWidth / 2;

    // Draw vertical line from each top node to midpoint, then to each bottom node
    double midY = (topY + bottomY) / 2;

    for (int i = 0; i < topCount; i++) {
      double x = topStartX + (i * 130.0) + 60;
      canvas.drawLine(Offset(x, topY), Offset(x, midY), paint);
    }
    for (int i = 0; i < bottomCount; i++) {
      double x = bottomStartX + (i * 130.0) + 60;
      canvas.drawLine(Offset(x, midY), Offset(x, bottomY), paint);
    }

    // Horizontal connector at midpoint
    if (topCount > 0 && bottomCount > 0) {
      double leftX = (topStartX + 60).clamp(0, centerX);
      double rightX = bottomStartX + ((bottomCount - 1) * 130.0) + 60;
      leftX = [leftX, bottomStartX + 60].reduce((a, b) => a < b ? a : b);
      rightX = [rightX, topStartX + ((topCount - 1) * 130.0) + 60].reduce((a, b) => a > b ? a : b);
      canvas.drawLine(Offset(leftX, midY), Offset(rightX, midY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
