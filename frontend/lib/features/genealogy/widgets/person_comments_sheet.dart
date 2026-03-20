import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:gwangmeu/features/genealogy/models/person_comment_model.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

/// Provider pour charger les commentaires d'une personne
final personCommentsProvider =
    FutureProvider.autoDispose.family<List<PersonCommentModel>, String>((ref, personId) {
  return ref.read(genealogyApiServiceProvider).getPersonComments(personId);
});

/// Bottom sheet affichant les commentaires/notes sur une fiche personne.
class PersonCommentsSheet extends ConsumerStatefulWidget {
  const PersonCommentsSheet({super.key, required this.personId, required this.personName});

  final String personId;
  final String personName;

  @override
  ConsumerState<PersonCommentsSheet> createState() => _PersonCommentsSheetState();
}

class _PersonCommentsSheetState extends ConsumerState<PersonCommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(genealogyApiServiceProvider).addPersonComment(widget.personId, text);
      _controller.clear();
      ref.invalidate(personCommentsProvider(widget.personId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(genealogyApiServiceProvider).deletePersonComment(widget.personId, commentId);
      ref.invalidate(personCommentsProvider(widget.personId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(personCommentsProvider(widget.personId));

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.comment_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes - ${widget.personName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Comments list
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speaker_notes_off, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Aucune note pour le moment',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return _CommentCard(
                          comment: c,
                          onDelete: () => _deleteComment(c.id),
                        );
                      },
                    );
                  },
                ),
              ),
              // Input
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Ajouter une note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _sendComment,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.onDelete});

  final PersonCommentModel comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.authorAvatarUrl != null
                      ? NetworkImage(comment.authorAvatarUrl!)
                      : null,
                  child: comment.authorAvatarUrl == null
                      ? Text(
                          comment.authorName.isNotEmpty
                              ? comment.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        timeago.format(comment.createdAt, locale: 'fr'),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// Helper pour ouvrir le sheet depuis n'importe ou
void showPersonCommentsSheet(BuildContext context, String personId, String personName) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PersonCommentsSheet(personId: personId, personName: personName),
  );
}
