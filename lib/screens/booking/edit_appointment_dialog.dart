import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salon_app/components/bounded_time_picker.dart';
import 'package:salon_app/services/conflict_service.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/generated/l10n.dart';

// ✅ nuevo selector bonito
import 'package:salon_app/components/service_type_selectors.dart';

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

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Time init
    final originalTs = widget.data['appointmentDate'];
    final originalDt = originalTs is Timestamp ? originalTs.toDate() : DateTime.now();
    selectedTime = TimeOfDay(hour: originalDt.hour, minute: originalDt.minute);

    // Service init
    final currentServiceId = (widget.data['serviceId'] ?? '').toString();
    selectedServiceId = currentServiceId.isNotEmpty ? currentServiceId : null;

    // Type init
    selectedTypeId = (widget.data['typeId'] ?? '').toString();
    selectedTypeKey = (widget.data['typeKey'] ?? '').toString();

    // Try load serviceData from cache
    if (selectedServiceId != null) {
      final cached = widget.services.where((d) => d.id == selectedServiceId).toList();
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

        final al = (a['label'] ?? a['name'] ?? a['_id'] ?? '').toString().toLowerCase();
        final bl = (b['label'] ?? b['name'] ?? b['_id'] ?? '').toString().toLowerCase();
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
        selectedTypeKey = (common['nameKey'] ?? common['_id'] ?? common['key'] ?? '').toString();
      });
    } catch (e) {
      // ✅ si no hay permiso o falla, lo tratamos como "sin types"
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

    // 1) intenta por typeId guardado
    if (selectedTypeId.isNotEmpty) {
      final match = serviceTypes.where((t) => (t['_id'] ?? '').toString() == selectedTypeId).toList();
      if (match.isNotEmpty) {
        selectedType = match.first;
        return;
      }
    }

    // 2) fallback por typeKey (nameKey o id)
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

    // 3) common o first
    final common = serviceTypes.firstWhere(
      (t) => t['common'] == true,
      orElse: () => serviceTypes.first,
    );
    selectedType = common;
    selectedTypeId = (common['_id'] ?? '').toString();
    selectedTypeKey = (common['nameKey'] ?? common['_id'] ?? common['key'] ?? '').toString();
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
    final doc = await FirebaseFirestore.instance.collection('services').doc(selectedServiceId!).get();
    selectedServiceData = doc.data();
  }

  Future<void> _deleteAppointment() async {
    final s = S.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteAppointmentTitle),
        content: Text(s.deleteAppointmentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: Text(s.no)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(_, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.appointmentDeleted)),
      );
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
    final ctry = (widget.data['clientCountry'] is num) ? (widget.data['clientCountry'] as num).toInt() : 0;
    final ph = (widget.data['clientPhone'] is num) ? (widget.data['clientPhone'] as num).toInt() : 0;
    final ig = (widget.data['clientInstagram'] ?? '').toString();

    final contact = [
      (ctry > 0 && ph > 0) ? "+$ctry $ph" : null,
      ig.isNotEmpty ? "@$ig" : null,
    ].whereType<String>().join(' • ');

    final width = MediaQuery.of(context).size.width;
    final maxDialogWidth = (width * 0.92).clamp(280.0, 440.0);

    final svcNameKey = (selectedServiceData?['name'] ?? widget.data['serviceNameKey'] ?? '').toString();
    final svcLabel = svcNameKey.isNotEmpty
        ? trServiceOrAddon(context, svcNameKey)
        : (widget.data['serviceName'] ?? s.serviceFallback).toString();

    final price = _finalPriceSmart(selectedServiceData ?? widget.data, selectedType);
    final minutes = _finalMinutesSmart(selectedServiceData ?? widget.data, selectedType);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      // ✅ TÍTULO con X a la derecha
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
            tooltip: s.cancel, // no crea confusión, es tooltip
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
                // Client box
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

                // ✅ selectores bonitos (service + type)
                ServiceTypeSelectors(
                  services: widget.services,
                  selectedServiceId: selectedServiceId,
                  selectedServiceData: selectedServiceData,
                  onPickService: (serviceId, serviceData) async {
                    setState(() {
                      selectedServiceId = serviceId;
                      selectedServiceData = serviceData;

                      // reset types
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

                // Time
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

      // ✅ abajo izquierda papelera, abajo derecha save
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              // 🗑️ delete icon (rojo “líneas”)
              IconButton(
                tooltip: s.delete,
                onPressed: saving ? null : _deleteAppointment,
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

                        // ✅ SOLO requerimos type si realmente cargamos types
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

                          final maxOverlap = await widget.conflictService.maxOverlapForCandidate(
                            day: widget.selectedDay,
                            candidateStart: dt,
                            candidateDurationMin: durationMin,
                            excludeAppointmentId: widget.appointmentId,
                          );

                          final canSave = await widget.conflictService.confirmSaveIfConflict(
                            context: context,
                            maxOverlapMin: maxOverlap,
                            amberThresholdMin: 30,
                          );

                          if (!canSave) {
                            if (mounted) setState(() => saving = false);
                            return;
                          }

                          final svcKey =
                              (selectedServiceData?['name'] ?? widget.data['serviceNameKey'] ?? '').toString();
                          final translatedName = svcKey.isNotEmpty
                              ? trServiceOrAddon(context, svcKey)
                              : (widget.data['serviceName'] ?? s.serviceFallback).toString();

                          final typeLabel = (selectedType?['label'] ?? '').toString();
                          final typeExtraPrice =
                              (selectedType?['extraPrice'] is num) ? (selectedType!['extraPrice'] as num).toDouble() : 0.0;

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

                            'appointmentDate': Timestamp.fromDate(dt),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

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
                    : Text(s.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
