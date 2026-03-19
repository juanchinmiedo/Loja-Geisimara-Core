// lib/screens/booking/block_slot_dialog.dart
//
// Dialog para ver, añadir y eliminar franjas horarias bloqueadas de un día.
//
// Uso:
//   await showDialog(
//     context: context,
//     builder: (_) => BlockSlotDialog(
//       workerId: workerId,
//       date: selectedDay,
//       repo: BlockedSlotRepo(FirebaseFirestore.instance),
//     ),
//   );

import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/repositories/blocked_slot_repo.dart';
import 'package:salon_app/utils/app_time_picker.dart';
import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/utils/time_of_day_utils.dart';

class BlockSlotDialog extends StatefulWidget {
  const BlockSlotDialog({
    super.key,
    required this.workerId,
    required this.date,
    required this.repo,
    this.initialStartMin,
    this.initialEndMin,
  });

  final String workerId;
  final DateTime date;
  final BlockedSlotRepo repo;
  final int? initialStartMin;
  final int? initialEndMin;

  @override
  State<BlockSlotDialog> createState() => _BlockSlotDialogState();
}

class _BlockSlotDialogState extends State<BlockSlotDialog> {
  static const Color kPurple = Color(0xff721c80);

  late int _startMin;
  late int _endMin;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  List<BlockedSlot> _existing = [];
  bool _loadingExisting = true;

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now    = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final rounded = (nowMin ~/ 30) * 30;
    _startMin = widget.initialStartMin ?? rounded.clamp(7 * 60, 19 * 60);
    _endMin   = widget.initialEndMin   ??
        (_startMin + 60).clamp(7 * 60 + 30, 21 * 60);
    _loadExisting();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final slots = await widget.repo.fetchForDay(
        widget.workerId, _yyyymmdd(widget.date));
    if (!mounted) return;
    setState(() {
      _existing        = slots;
      _loadingExisting = false;
    });
  }

  Future<void> _pickStart() async {
    final picked = await AppTimePicker.pick5m(
        context: context,
        initial: TimeOfDayUtils.fromMinutes(_startMin));
    if (picked == null) return;
    final min = TimeOfDayUtils.toMinutes(picked).clamp(7 * 60, 19 * 60);
    setState(() {
      _startMin = min;
      if (_endMin <= _startMin) {
        _endMin = (_startMin + 60).clamp(0, 21 * 60);
      }
    });
  }

  Future<void> _pickEnd() async {
    final s = S.of(context);
    final picked = await AppTimePicker.pick5m(
        context: context,
        initial: TimeOfDayUtils.fromMinutes(_endMin));
    if (picked == null) return;
    final min =
        TimeOfDayUtils.toMinutes(picked).clamp(7 * 60 + 30, 21 * 60);
    if (min <= _startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.endMustBeAfterStart)));
      return;
    }
    setState(() => _endMin = min);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repo.addSlot(
        workerId: widget.workerId,
        date:     _yyyymmdd(widget.date),
        startMin: _startMin,
        endMin:   _endMin,
        reason:   _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSlot(BlockedSlot slot) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.removeBlock),
        content: Text(
          'Remove ${DateTimeUtils.hhmmFromMinutes(slot.startMin)} – '
          '${DateTimeUtils.hhmmFromMinutes(slot.endMin)}'
          '${slot.reason.isNotEmpty ? "  ·  ${slot.reason}" : ""}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.remove,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.repo.deleteSlot(
        workerId: widget.workerId, slotId: slot.id);
    if (!mounted) return;
    setState(() => _existing.removeWhere((s) => s.id == slot.id));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dateLabel = DateTimeUtils.formatYyyyMmDdToDdMmYyyy(
        _yyyymmdd(widget.date));

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Block time – $dateLabel',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 14),

              // Existing blocks
              Text(s.existingBlocks,style: 
                const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (_loadingExisting)
                const Center(
                    child: CircularProgressIndicator(color: kPurple))
              else if (_existing.isEmpty)
                Text(s.none, style: TextStyle(color: Colors.grey[600]))
              else
                ..._existing.map((s) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline,
                          color: Colors.redAccent, size: 18),
                      title: Text(
                        '${DateTimeUtils.hhmmFromMinutes(s.startMin)} – '
                        '${DateTimeUtils.hhmmFromMinutes(s.endMin)}'
                        '${s.reason.isNotEmpty ? "  ·  ${s.reason}" : ""}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        onPressed: () => _deleteSlot(s),
                      ),
                    )),

              const Divider(height: 24),

              // New block form
              Text(s.addNewBlock,
                style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _TimePill(
                      label: s.from,
                      value: DateTimeUtils.hhmmFromMinutes(_startMin),
                      onTap: _pickStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimePill(
                      label: 'To',
                      value: DateTimeUtils.hhmmFromMinutes(_endMin),
                      onTap: _pickEnd,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  labelText: s.reasonOptional,
                  hintText: 'e.g. Lunch, Meeting…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.block, color: Colors.white),
                  label: Text(s.blockThisTime,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
