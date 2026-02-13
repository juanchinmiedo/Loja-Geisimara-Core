import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';

class WorkerSelectorPills extends StatefulWidget {
  const WorkerSelectorPills({
    super.key,
    this.allLabel = "All",
  });

  final String allLabel;

  @override
  State<WorkerSelectorPills> createState() => _WorkerSelectorPillsState();
}

class _WorkerSelectorPillsState extends State<WorkerSelectorPills> {
  final ScrollController _controller = ScrollController();
  bool _canLeft = false;
  bool _canRight = false;

  static const Color kPurple = Color(0xff721c80);

  String? _lastSelected; // detecta cambios reales de selección

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFades);
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    final off = _controller.offset;

    final left = off > 4;
    final right = off < max - 4;

    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
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
      _updateFades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    if (!up.isAdmin) return const SizedBox.shrink();

    final selected = up.selectedWorkerId; // null => ALL
    _maybeScrollToStartOnSelectionChange(selected);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("workers").snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        // ✅ Reordenar workers: seleccionado siempre primero en la lista de workers
        // (pero ALL siempre va antes de todo)
        QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;
        if (selected != null) {
          for (final d in docs) {
            if (d.id == selected) {
              selectedDoc = d;
              break;
            }
          }
        }

        final orderedWorkers = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (selectedDoc != null) orderedWorkers.add(selectedDoc);
        orderedWorkers.addAll(docs.where((d) => d.id != selected));

        // ✅ Pills: ALL primero, luego worker seleccionado (si existe), luego el resto
        final pills = <Widget>[
          _pillBase(
            label: widget.allLabel,
            active: selected == null,
            onTap: () => up.setWorkerFilter(null),
          ),
          for (final d in orderedWorkers) ...[
            const SizedBox(width: 8),
            _pillBase(
              label: _labelFromWorker(d),
              active: selected == d.id,
              onTap: () => up.setWorkerFilter(d.id),
            ),
          ],
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(children: pills),
              ),

              if (_canLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(child: _fade(isLeft: true)),
                ),

              if (_canRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(child: _fade(isLeft: false)),
                ),
            ],
          ),
        );
      },
    );
  }

  String _labelFromWorker(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    final ns = data["nameShown"];
    if (ns is String && ns.trim().isNotEmpty) return ns.trim();

    final name = data["name"];
    if (name is String && name.trim().isNotEmpty) return name.trim();

    return d.id;
  }

  Widget _fade({required bool isLeft}) {
    return Container(
      width: 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.white.withOpacity(0.75),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
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
