import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // ✅ Elimina el glow blanco de Android
    return child;
  }
}

class WorkerChoicePills extends StatefulWidget {
  const WorkerChoicePills({
    super.key,
    required this.value,
    required this.onChanged,
    this.anyLabel = "Any",
  });

  /// null => Any worker
  final String? value;
  final ValueChanged<String?> onChanged;
  final String anyLabel;

  @override
  State<WorkerChoicePills> createState() => _WorkerChoicePillsState();
}

class _WorkerChoicePillsState extends State<WorkerChoicePills> {
  final ScrollController _controller = ScrollController();
  static const Color kPurple = Color(0xff721c80);

  String? _lastSelected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeScrollToStartOnSelectionChange(String? selectedNow) {
    if (_lastSelected == selectedNow) return;
    _lastSelected = selectedNow;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value; // null => ANY
    _maybeScrollToStartOnSelectionChange(selected);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("workers").snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // Seleccionado primero (después de Any)
        QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;
        if (selected != null) {
          for (final d in docs) {
            if (d.id == selected) {
              selectedDoc = d;
              break;
            }
          }
        }

        final ordered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (selectedDoc != null) ordered.add(selectedDoc);
        ordered.addAll(docs.where((d) => d.id != selected));

        final pills = <Widget>[
          _pillBase(
            label: widget.anyLabel,
            active: selected == null,
            onTap: () => widget.onChanged(null),
          ),
          for (final d in ordered) ...[
            const SizedBox(width: 8),
            _pillBase(
              label: BookingRequestUtils.workerLabelFrom(d.data(), d.id),
              active: selected == d.id,
              onTap: () => widget.onChanged(d.id),
            ),
          ],
        ];

        // ✅ SIN Stack / SIN fades / SIN sombreado blanco
        return ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Row(children: pills),
          ),
        );
      },
    );
  }

  Widget _pillBase({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color bg = active ? kPurple.withOpacity(0.92) : kPurple.withOpacity(0.12);
    final Color border = active ? kPurple.withOpacity(0.92) : kPurple.withOpacity(0.28);
    final Color fg = active ? Colors.white : kPurple;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: active ? FontWeight.w900 : FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}