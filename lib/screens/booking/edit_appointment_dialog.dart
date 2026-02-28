import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';

import 'package:salon_app/components/bounded_time_picker.dart';
import 'package:salon_app/services/conflict_service.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/generated/l10n.dart';

// ✅ nuevo selector bonito
import 'package:salon_app/components/service_type_selectors.dart';

// ✅ NEW
import 'package:salon_app/services/appointment_service.dart';
import 'package:salon_app/repositories/booking_request_repo.dart';
import 'package:salon_app/utils/date_time_utils.dart';

class EditAppointmentDialog extends StatefulWidget {
  const EditAppointmentDialog({
    super.key,
    required this.appointmentId,
    required this.data,
    required this.selectedDay,
    required this.services,
    required this.conflictService,
  });

  final String appointmentId;
  final Map<String, dynamic> data;
  final DateTime selectedDay;

  /// ✅ cache de services desde BookingAdminScreen
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> services;

  final ConflictService conflictService;

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  late TimeOfDay selectedTime;

  String? selectedServiceId;
  Map<String, dynamic>? selectedServiceData;

  // ✅ types subcolección
  List<Map<String, dynamic>> serviceTypes = const [];
  bool loadingTypes = false;

  Map<String, dynamic>? selectedType;
  String selectedTypeKey = '';
  String selectedTypeId = '';

  // ✅ pulso lento
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ✅ NEW
  late final AppointmentService _apptService;
  late final BookingRequestRepo _brRepo;

  @override
  void initState() {
    super.initState();

    _apptService = AppointmentService(FirebaseFirestore.instance);
    _brRepo = BookingRequestRepo(FirebaseFirestore.instance);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Time init
    final originalTs = widget.data['appointmentDate'];
    final originalDt =
        originalTs is Timestamp ? originalTs.toDate() : DateTime.now();
    selectedTime = TimeOfDay(hour: originalDt.hour, minute: originalDt.minute);

    // Service init
    final currentServiceId = (widget.data['serviceId'] ?? '').toString();
    selectedServiceId = currentServiceId.isNotEmpty ? currentServiceId : null;

    // Type init
    selectedTypeId = (widget.data['typeId'] ?? '').toString();
    selectedTypeKey = (widget.data['typeKey'] ?? '').toString();

    // Try load serviceData from cache
    if (selectedServiceId != null) {
      final cached =
          widget.services.where((d) => d.id == selectedServiceId).toList();
      if (cached.isNotEmpty) {
        selectedServiceData = cached.first.data();
      }
    }

    // load types after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTypesForSelectedService(autoPickCommon: false);
      _autoPickExistingOrCommonType();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _pulseTime() {
    if (!mounted) return;
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    _pulseCtrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // TYPES: subcolección
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadTypesForSelectedService({bool autoPickCommon = true}) async {
    final sid = selectedServiceId;
    if (sid == null || sid.isEmpty) {
      if (!mounted) return;
      setState(() {
        serviceTypes = const [];
        selectedType = null;
        selectedTypeKey = '';
        selectedTypeId = '';
      });
      return;
    }

    if (mounted) setState(() => loadingTypes = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('services')
          .doc(sid)
          .collection('types')
          .get();

      final types = snap.docs.map((d) {
        final m = d.data();
        return {
          ...m,
          '_id': d.id,
        };
      }).toList(growable: false);

      bool isCommon(Map<String, dynamic> t) => t['common'] == true;

      types.sort((a, b) {
        final ac = isCommon(a) ? 0 : 1;
        final bc = isCommon(b) ? 0 : 1;
        if (ac != bc) return ac - bc;

        final al = (a['label'] ?? a['name'] ?? a['_id'] ?? '')
            .toString()
            .toLowerCase();
        final bl = (b['label'] ?? b['name'] ?? b['_id'] ?? '')
            .toString()
            .toLowerCase();
        return al.compareTo(bl);
      });

      if (!mounted) return;

      setState(() {
        serviceTypes = types;

        if (types.isEmpty) {
          selectedType = null;
          selectedTypeKey = '';
          selectedTypeId = '';
          return;
        }

        if (!autoPickCommon) return;

        final common = types.firstWhere(
          (t) => t['common'] == true,
          orElse: () => types.first,
        );

        selectedType = common;
        selectedTypeId = (common['_id'] ?? '').toString();
        selectedTypeKey =
            (common['nameKey'] ?? common['_id'] ?? common['key'] ?? '')
                .toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        serviceTypes = const [];
        selectedType = null;
        selectedTypeKey = '';
        selectedTypeId = '';
      });
    } finally {
      if (mounted) setState(() => loadingTypes = false);
    }
  }

  void _autoPickExistingOrCommonType() {
    if (serviceTypes.isEmpty) return;

    if (selectedTypeId.isNotEmpty) {
      final match = serviceTypes
          .where((t) => (t['_id'] ?? '').toString() == selectedTypeId)
          .toList();
      if (match.isNotEmpty) {
        selectedType = match.first;
        return;
      }
    }

    if (selectedTypeKey.isNotEmpty) {
      final match = serviceTypes.where((t) {
        final key = (t['nameKey'] ?? t['_id'] ?? t['key'] ?? '').toString();
        return key == selectedTypeKey;
      }).toList();
      if (match.isNotEmpty) {
        selectedType = match.first;
        selectedTypeId = (match.first['_id'] ?? '').toString();
        return;
      }
    }

    final common = serviceTypes.firstWhere(
      (t) => t['common'] == true,
      orElse: () => serviceTypes.first,
    );
    selectedType = common;
    selectedTypeId = (common['_id'] ?? '').toString();
    selectedTypeKey =
        (common['nameKey'] ?? common['_id'] ?? common['key'] ?? '').toString();
  }

  // ─────────────────────────────────────────────────────────────
  // PRICE & TIME (SMART)
  // ─────────────────────────────────────────────────────────────
  bool _hasLoadedTypes() => serviceTypes.isNotEmpty;

  double _finalPriceSmart(Map<String, dynamic>? svc, Map<String, dynamic>? type) {
    final base = svc?['price'];
    final baseD = base is num ? base.toDouble() : 0.0;

    if (!_hasLoadedTypes()) return baseD;

    final extra = type?['extraPrice'];
    final extraD = extra is num ? extra.toDouble() : 0.0;
    return baseD + extraD;
  }

  int _finalMinutesSmart(Map<String, dynamic>? svc, Map<String, dynamic>? type) {
    if (_hasLoadedTypes()) {
      final v = type?['durationMin'];
      return v is num ? v.toInt() : 0;
    }
    final v = svc?['durationMin'];
    return v is num ? v.toInt() : 0;
  }

  Future<void> _ensureServiceLoaded() async {
    if (selectedServiceData != null || selectedServiceId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('services')
        .doc(selectedServiceId!)
        .get();
    selectedServiceData = doc.data();
  }

  // ✅ NUEVO dialog bonito: sin "Cancel", con X, y 3 opciones (ambar/rojo/morado)
  Future<void> _removeAppointment() async {
    final s = S.of(context);

    // ✅ slot actual (si estaba scheduled, al cancelar/borrar queda libre)
    final oldTs = widget.data['appointmentDate'];
    final oldDt = oldTs is Timestamp ? oldTs.toDate() : DateTime.now();
    final oldDur = (widget.data['durationMin'] is num)
        ? (widget.data['durationMin'] as num).toInt()
        : 0;
    final oldWorkerId = (widget.data['workerId'] ?? '').toString().trim();

    final clientId = (widget.data['clientId'] ?? '').toString();
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.errorWithValue("Missing clientId in appointment"))),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),

          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "Remove appointment",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: s.cancel,
                onPressed: () => Navigator.pop(ctx, null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          content: Text(
            "Choose what happened. This updates the appointment status and the client counters.",
            style: TextStyle(color: Colors.grey[700]),
          ),

          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReasonButton(
                  icon: Icons.event_busy,
                  title: "Cancelled",
                  subtitle: "Client cancelled the appointment",
                  color: Colors.orange,
                  onTap: () => Navigator.pop(ctx, 'cancelled'),
                ),
                const SizedBox(height: 10),
                _ReasonButton(
                  icon: Icons.person_off_outlined,
                  title: "No show",
                  subtitle: "Client did not attend",
                  color: Colors.redAccent,
                  onTap: () => Navigator.pop(ctx, 'noShow'),
                ),
                const SizedBox(height: 10),
                _ReasonButton(
                  icon: Icons.auto_fix_high,
                  title: "My error",
                  subtitle: "Remove permanently (wrong booking)",
                  color: const Color(0xff721c80), // morado app
                  onTap: () => Navigator.pop(ctx, 'deletePermanent'),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (choice == null) return;

    setState(() => saving = true);
    try {
      if (choice == 'cancelled') {
        await _apptService.cancelAppointment(
          appointmentId: widget.appointmentId,
          clientId: clientId,
        );

        if (oldWorkerId.isNotEmpty && oldDur > 0) {
          try {
            await _brRepo.notifyIfFreedSlotMatchesRequests(
              freedStart: oldDt,
              freedDurationMin: oldDur,
              workerId: oldWorkerId,
              reason: 'cancelled',
              sourceAppointmentId: widget.appointmentId,
            );
          } catch (_) {
            // Nunca romper el flujo por notificaciones.
          }
        }
      } else if (choice == 'noShow') {
        await _apptService.noShowAppointment(
          appointmentId: widget.appointmentId,
          clientId: clientId,
        );

        if (oldWorkerId.isNotEmpty && oldDur > 0) {
          try {
            await _brRepo.notifyIfFreedSlotMatchesRequests(
              freedStart: oldDt,
              freedDurationMin: oldDur,
              workerId: oldWorkerId,
              reason: 'noShow',
              sourceAppointmentId: widget.appointmentId,
            );
          } catch (_) {}
        }
      } else if (choice == 'deletePermanent') {
        await _apptService.deletePermanent(
          appointmentId: widget.appointmentId,
          clientId: clientId,
        );

        if (oldWorkerId.isNotEmpty && oldDur > 0) {
          try {
            await _brRepo.notifyIfFreedSlotMatchesRequests(
              freedStart: oldDt,
              freedDurationMin: oldDur,
              workerId: oldWorkerId,
              reason: 'deletePermanent',
              sourceAppointmentId: widget.appointmentId,
            );
          } catch (_) {}
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      final msg = (choice == 'cancelled')
          ? "Marked as cancelled"
          : (choice == 'noShow')
              ? "Marked as no-show"
              : "Deleted permanently";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.errorWithValue(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Client preview
    final clientName = (widget.data['clientName'] ?? s.clientFallback).toString();
    final ctry = (widget.data['clientCountry'] is num)
        ? (widget.data['clientCountry'] as num).toInt()
        : 0;
    final ph = (widget.data['clientPhone'] is num)
        ? (widget.data['clientPhone'] as num).toInt()
        : 0;
    final ig = (widget.data['clientInstagram'] ?? '').toString();

    final contact = [
      (ctry > 0 && ph > 0) ? "+$ctry $ph" : null,
      ig.isNotEmpty ? "@$ig" : null,
    ].whereType<String>().join(' • ');

    final width = MediaQuery.of(context).size.width;
    final maxDialogWidth = (width * 0.92).clamp(280.0, 440.0);

    final svcNameKey =
        (selectedServiceData?['name'] ?? widget.data['serviceNameKey'] ?? '')
            .toString();
    final svcLabel = svcNameKey.isNotEmpty
        ? trServiceOrAddon(context, svcNameKey)
        : (widget.data['serviceName'] ?? s.serviceFallback).toString();

    final price = _finalPriceSmart(selectedServiceData ?? widget.data, selectedType);
    final minutes = _finalMinutesSmart(selectedServiceData ?? widget.data, selectedType);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      title: Row(
        children: [
          Expanded(
            child: Text(
              s.editAppointmentTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: s.cancel,
            onPressed: saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black87),
          ),
        ],
      ),

      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxDialogWidth),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff721c80).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff721c80).withOpacity(0.20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(contact, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                ServiceTypeSelectors(
                  services: widget.services,
                  selectedServiceId: selectedServiceId,
                  selectedServiceData: selectedServiceData,
                  onPickService: (serviceId, serviceData) async {
                    setState(() {
                      selectedServiceId = serviceId;
                      selectedServiceData = serviceData;

                      serviceTypes = const [];
                      loadingTypes = false;
                      selectedType = null;
                      selectedTypeKey = '';
                      selectedTypeId = '';
                    });

                    await _loadTypesForSelectedService(autoPickCommon: true);
                  },
                  loadingTypes: loadingTypes,
                  serviceTypes: serviceTypes,
                  selectedType: selectedType,
                  onPickType: (type) async {
                    setState(() {
                      selectedType = type;
                      selectedTypeId = (type?['_id'] ?? '').toString();
                      selectedTypeKey = (type?['nameKey'] ?? type?['_id'] ?? type?['key'] ?? '').toString();
                    });
                  },
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: () async {
                    final picked = await BoundedTimePicker.show(
                      context: context,
                      initialTime: selectedTime,
                      minuteStep: 5,
                      use24h: true,
                      hapticsOnSnap: true,
                      onSnapped: (_, __) {
                        if (mounted) _pulseTime();
                      },
                    );

                    if (picked != null && mounted) setState(() => selectedTime = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                      color: Colors.grey.withOpacity(0.06),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: ScaleTransition(
                            scale: _pulseAnim,
                            child: Text(
                              "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        svcLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Text(
                      "€${price.toStringAsFixed(0)} • ${minutes > 0 ? "${minutes}m" : "—"}",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              IconButton(
                tooltip: "Remove",
                onPressed: saving ? null : _removeAppointment,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff721c80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final ok = formKey.currentState?.validate() == true;
                        if (!ok) return;

                        await _ensureServiceLoaded();

                        if (_hasLoadedTypes() && (selectedType == null || selectedTypeId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.typeRequired)),
                          );
                          return;
                        }

                        setState(() => saving = true);
                        try {
                          final dt = DateTime(
                            widget.selectedDay.year,
                            widget.selectedDay.month,
                            widget.selectedDay.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final durationMin = _finalMinutesSmart(selectedServiceData ?? widget.data, selectedType);
                          final basePrice = _finalPriceSmart(selectedServiceData ?? widget.data, selectedType);

                          // ✅ OLD slot (antes del edit) para detectar hueco liberado
                          final oldTs = widget.data['appointmentDate'];
                          final oldDt = oldTs is Timestamp ? oldTs.toDate() : DateTime.now();
                          final oldDur = (widget.data['durationMin'] is num)
                              ? (widget.data['durationMin'] as num).toInt()
                              : 0;

                          final userProv = context.read<UserProvider>();

                          final existingWorkerId = (widget.data['workerId'] ?? '').toString().trim();

                          // ✅ workerId efectivo:
                          // - si el appointment ya tiene workerId -> ese
                          // - si NO tiene (appointment viejo) -> intentamos asignarlo según el usuario actual
                          String? effectiveWorkerId = existingWorkerId.isNotEmpty ? existingWorkerId : null;

                          if (effectiveWorkerId == null || effectiveWorkerId.isEmpty) {
                            // si es worker: su workerId
                            if (userProv.isWorker && (userProv.workerId ?? '').isNotEmpty) {
                              effectiveWorkerId = userProv.workerId!;
                            }
                            // si es admin: el seleccionado (no debería ser null si va a crear/editar en un worker concreto)
                            if (userProv.isAdmin && (userProv.selectedWorkerId ?? '').isNotEmpty) {
                              effectiveWorkerId = userProv.selectedWorkerId!;
                            }
                          }

                          // Si sigue null, no bloqueamos el edit (por compat),
                          // pero NO podremos calcular conflictos por worker correctamente.
                          final bool canCheckConflicts = effectiveWorkerId != null && effectiveWorkerId.isNotEmpty;

                          int maxOverlap = 0;
                          if (canCheckConflicts) {
                            maxOverlap = await widget.conflictService.maxOverlapForCandidate(
                              day: widget.selectedDay,
                              candidateStart: dt,
                              candidateDurationMin: durationMin,
                              workerId: effectiveWorkerId,
                              excludeAppointmentId: widget.appointmentId,
                            );
                          }

                          final canSave = await widget.conflictService.confirmSaveIfConflict(
                            context: context,
                            maxOverlapMin: maxOverlap,
                            amberThresholdMin: 30,
                          );

                          if (!canSave) {
                            if (mounted) setState(() => saving = false);
                            return;
                          }

                          final svcKey = (selectedServiceData?['name'] ??
                                  widget.data['serviceNameKey'] ??
                                  '')
                              .toString();
                          final translatedName = svcKey.isNotEmpty
                              ? trServiceOrAddon(context, svcKey)
                              : (widget.data['serviceName'] ?? s.serviceFallback).toString();

                          final typeLabel = (selectedType?['label'] ?? '').toString();
                          final typeExtraPrice = (selectedType?['extraPrice'] is num)
                              ? (selectedType!['extraPrice'] as num).toDouble()
                              : 0.0;

                          await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
                            'serviceId': selectedServiceId,
                            'serviceNameKey': svcKey,
                            'serviceName': translatedName,

                            'typeId': selectedTypeId,
                            'typeKey': selectedTypeKey,
                            'typeLabel': typeLabel,
                            'typeExtraPrice': typeExtraPrice,

                            'durationMin': durationMin,
                            'basePrice': basePrice,
                            'total': basePrice,

                            if (canCheckConflicts && existingWorkerId.isEmpty) 'workerId': effectiveWorkerId,

                            'appointmentDate': Timestamp.fromDate(dt),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          
                          final clientId = (widget.data['clientId'] ?? '').toString().trim();
                          if (clientId.isNotEmpty) {
                            try {
                              final serviceCategory =
                                  (selectedServiceData?['category'] ?? 'hands').toString();

                              final plan = await _brRepo.buildDeletePlanForNewAppointment(
                                clientId: clientId,
                                appointmentStart: dt,
                                appointmentDurationMin: durationMin,
                                workerId: (effectiveWorkerId ?? existingWorkerId).toString(),
                                serviceCategory: serviceCategory,
                              );

                              await _brRepo.deleteRequestsByDocs(
                                clientId: clientId,
                                docs: plan.autoDelete,
                              );

                              if (plan.confirmDelete.isNotEmpty && mounted) {
                                String rangeLabelFrom(Map<String, dynamic> br) {
                                  final ranges = (br['preferredTimeRanges'] as List?) ?? const [];
                                  if (ranges.isEmpty) return 'Any time';
                                  final parts = <String>[];
                                  for (final rr in ranges) {
                                    if (rr is! Map) continue;
                                    final m = Map<String, dynamic>.from(rr);
                                    final s = (m['startMin'] ?? m['start']);
                                    final e = (m['endMin'] ?? m['end']);
                                    final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? 0;
                                    final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? 0;
                                    parts.add(
                                      "${DateTimeUtils.hhmmFromMinutes(sm)}-${DateTimeUtils.hhmmFromMinutes(em)}",
                                    );
                                  }
                                  return parts.join('; ');
                                }

                                String daysLabelFrom(Map<String, dynamic> br) {
                                  final days = (br['preferredDays'] as List?) ?? const [];
                                  if (days.isEmpty) return '—';
                                  return days
                                      .map((d) => DateTimeUtils.formatYyyyMmDdToDdMmYyyy(d.toString()))
                                      .join(', ');
                                }

                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (dctx) {
                                        return AlertDialog(
                                          title: const Text('Delete booking request(s)?'),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: plan.confirmDelete.length,
                                              separatorBuilder: (_, __) => const Divider(height: 14),
                                              itemBuilder: (_, i) {
                                                final doc = plan.confirmDelete[i];
                                                final br = doc.data();
                                                final proc = (br['serviceNameLabel'] ??
                                                        br['serviceNameKey'] ??
                                                        '')
                                                    .toString();
                                                final w = (br['workerId'] ?? '').toString();
                                                final workerLabel =
                                                    w.trim().isEmpty ? 'Any' : w;
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      proc.isEmpty ? 'Request' : proc,
                                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text('Worker: $workerLabel'),
                                                    Text('Day(s): ${daysLabelFrom(br)}'),
                                                    Text('Range(s): ${rangeLabelFrom(br)}'),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dctx, false),
                                              child: const Text('Keep'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(dctx, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ??
                                    false;

                                if (ok) {
                                  await _brRepo.deleteRequestsByDocs(
                                    clientId: clientId,
                                    docs: plan.confirmDelete,
                                  );
                                }
                              }
                            } catch (_) {}
                          }

                          // ✅ Si el edit movió la cita (o cambió duración), ese hueco viejo quedó libre.
                          if (canCheckConflicts &&
                              effectiveWorkerId != null &&
                              effectiveWorkerId.isNotEmpty &&
                              oldDur > 0) {
                            final moved = oldDt.year != dt.year ||
                                oldDt.month != dt.month ||
                                oldDt.day != dt.day ||
                                oldDt.hour != dt.hour ||
                                oldDt.minute != dt.minute;
                            final durChanged = oldDur != durationMin;

                            if (moved || durChanged) {
                              try {
                                await _brRepo.notifyIfFreedSlotMatchesRequests(
                                  freedStart: oldDt,
                                  freedDurationMin: oldDur,
                                  workerId: effectiveWorkerId,
                                  reason: 'edit',
                                  sourceAppointmentId: widget.appointmentId,
                                );
                              } catch (_) {}
                            }
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.appointmentUpdated)),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.errorWithValue(e.toString()))),
                          );
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        s.save,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// UI: botón bonito para elegir motivo (ambar / rojo / morado)
// ─────────────────────────────────────────────────────────────
class _ReasonButton extends StatelessWidget {
  const _ReasonButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.9)),
          ],
        ),
      ),
    );
  }
}
