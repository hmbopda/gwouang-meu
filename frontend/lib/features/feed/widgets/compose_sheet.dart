import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:gwangmeu/core/storage/media_storage.dart';
import 'package:gwangmeu/core/theme/gw_tokens.dart';
import 'package:gwangmeu/features/feed/feed_notifier.dart';
import 'package:gwangmeu/features/villages/villages_notifier.dart';
import 'package:gwangmeu/shared/widgets/gw_dialog.dart';

/// Ouvre la feuille de composition. [startWithPhoto] ouvre directement le
/// sélecteur d'image (bouton « Photo » du Fil).
Future<void> showComposeSheet(BuildContext context,
    {bool startWithPhoto = false}) {
  return showGwDialog(context,
      builder: (_) => _ComposeSheet(startWithPhoto: startWithPhoto));
}

class _ComposeSheet extends ConsumerStatefulWidget {
  const _ComposeSheet({this.startWithPhoto = false});

  final bool startWithPhoto;

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _ctrl = TextEditingController();
  String? _villageId; // null = publication personnelle
  Uint8List? _imageBytes;
  String? _imageName;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.startWithPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = x.name;
      });
    } catch (_) {
      /* annulé / non supporté */
    }
  }

  Future<void> _publish() async {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _imageBytes == null) || _publishing) return;
    setState(() => _publishing = true);
    try {
      String? mediaUrl;
      if (_imageBytes != null) {
        mediaUrl = await MediaStorage.upload(
          bytes: _imageBytes!,
          folder: 'posts',
          filename: _imageName,
        );
      }
      await ref.read(feedNotifierProvider.notifier).createPost(
            content: text,
            villageId: _villageId,
            mediaUrl: mediaUrl,
          );
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GwTokens.ember,
            content: Text("La publication n'a pas pu être envoyée",
                style: GwType.ui(fontSize: 14, color: GwTokens.inkOnGold)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = GwTokens.of(context);
    final villages =
        ref.watch(myVillagesNotifierProvider).valueOrNull ?? const [];

    return GwDialog(
      title: 'Partager un souvenir',
      subtitle: 'Une photo, une histoire, une nouvelle de la famille',
      icon: Symbols.auto_stories,
      actions: [
        GwDialogAction(
          label: 'Publier',
          primary: true,
          loading: _publishing,
          onPressed: _publish,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: !widget.startWithPhoto,
            minLines: 3,
            maxLines: 7,
            style: GwType.ui(fontSize: 15, color: t.stone, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Partagez un souvenir, une histoire de famille…',
              hintStyle: GwType.ui(fontSize: 14.5, color: t.stoneDim),
              filled: true,
              fillColor: t.inkLift,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: BorderSide(color: t.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: BorderSide(color: t.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GwTokens.rBtn),
                borderSide: const BorderSide(color: GwTokens.gold, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_imageBytes != null) _imagePreview(t) else _addPhotoButton(t),
          const SizedBox(height: 16),
          Text('PUBLIER DANS',
              style: GwType.mono(
                  fontSize: 10, letterSpacing: 1.5, color: t.stoneFaint)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _scopePill(t,
                  label: 'Personnel',
                  icon: Symbols.person,
                  selected: _villageId == null,
                  onTap: () => setState(() => _villageId = null)),
              for (final v in villages)
                _scopePill(t,
                    label: v.name,
                    icon: Symbols.holiday_village,
                    selected: _villageId == v.id,
                    onTap: () => setState(() => _villageId = v.id)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addPhotoButton(GwTokens t) {
    return OutlinedButton.icon(
      onPressed: _pickImage,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.goldText,
        side: BorderSide(color: GwTokens.gold.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
        ),
      ),
      icon: const Icon(Symbols.add_a_photo, size: 18),
      label: Text('Ajouter une photo',
          style: GwType.ui(fontSize: 13.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _imagePreview(GwTokens t) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(GwTokens.rBtn),
          child: Image.memory(_imageBytes!,
              width: double.infinity, height: 180, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => setState(() {
                _imageBytes = null;
                _imageName = null;
              }),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Symbols.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scopePill(
    GwTokens t, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? GwTokens.gold.withValues(alpha: 0.14) : t.inkLift,
      borderRadius: BorderRadius.circular(GwTokens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GwTokens.rPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GwTokens.rPill),
            border:
                Border.all(color: selected ? GwTokens.gold : t.line, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? t.goldText : t.stoneMid),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GwType.ui(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? t.goldText : t.stone)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
