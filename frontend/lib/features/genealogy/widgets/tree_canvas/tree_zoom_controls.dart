import 'package:flutter/material.dart';

import 'package:gwangmeu/features/genealogy/state/tree_tokens.dart';

/// Floating zoom controls (+, -, reset).
class TreeZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const TreeZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.ink3,
        borderRadius: BorderRadius.circular(T.rSm),
        border: Border.all(color: T.border2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.add, onZoomIn),
          const Divider(color: T.border, height: 1),
          _btn(Icons.remove, onZoomOut),
          const Divider(color: T.border, height: 1),
          _btn(Icons.center_focus_strong, onReset),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: T.txt2),
        ),
      ),
    );
  }
}
