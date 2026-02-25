import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/components/service_type_selectors.dart';
import 'package:salon_app/services/appointment_service.dart';

class PastAppointmentDialog extends StatefulWidget {
  const PastAppointmentDialog({
    super.key,
    required this.appointmentId,
    required this.data,
    required this.selectedDay,
    required this.services,
  });

  final String appointmentId;
  final Map<String, dynamic> data;
  final DateTime selectedDay;

  /// cache de services desde BookingAdminScreen
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> services;

  @override
  State<PastAppointmentDialog> createState() => _PastAppointmentDialogState();
}

class _PastAppointmentDialogState extends State<PastAppointmentDialog>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  // Hora se muestra pero NO se edita
  late TimeOfDay selectedTime;

  String? selectedServiceId;
  Map<String, dynamic>? selectedServiceData;

  // types subcolección
  List<Map<String, dynamic>> serviceTypes = const [];
  bool loadingTypes = false;

  Map<String, dynamic>? selectedType;
  String selectedTypeKey = '';
  String selectedTypeId = '';

  // NEW
  late final AppointmentService _apptService;

  // Precio final (opcional)
  final TextEditingController finalPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _apptService = AppointmentService(FirebaseFirestore.instance);

    // Hora init
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

    // finalPrice init
    final fp = widget.data['finalPrice'];
    finalPriceCtrl.text = (fp == null) ? '' : fp.toString();

    // Try load serviceData from cache
    if (selectedServiceId != null) {
      final cached =
          widget.services.where((d) => d.id == selectedServiceId).toList();
      if (cached.isNotEmpty) {
        selectedServiceData = cached.first.data();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTypesForSelectedService(autoPickCommon: false);
      _autoPickExistingOrCommonType();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    finalPriceCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // TYPES: subcolección (igual que tu edit)
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
        return {...m, '_id': d.id};
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
    } catch (_) {
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
  // SMART price/minutes (igual que tu edit)
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

  // ─────────────────────────────────────────────────────────────
  // Remove: MISMO dialog bonito que el edit normal
  // ─────────────────────────────────────────────────────────────
  Future<void> _removeAppointment() async {
    final s = S.of(context);

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
                  color: const Color(0xff721c80),
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
      } else if (choice == 'noShow') {
        await _apptService.noShowAppointment(
          appointmentId: widget.appointmentId,
          clientId: clientId,
        );
      } else if (choice == 'deletePermanent') {
        await _apptService.deletePermanent(
          appointmentId: widget.appointmentId,
          clientId: clientId,
        );
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

  String _fmtTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Client preview (igual que edit)
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

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      title: Row(
        children: [
          Expanded(
            child: Text(
              s.editAppointmentTitle, // mismo título (puedes cambiarlo si quieres)
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
                // tarjeta cliente igual
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

                // Selector servicio/tipo (editable)
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
                      selectedTypeKey =
                          (type?['nameKey'] ?? type?['_id'] ?? type?['key'] ?? '')
                              .toString();
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Hora: MISMO look, pero SIN onTap, sin lápiz, con candado
                Container(
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
                      Text(
                        _fmtTime(selectedTime),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Icon(Icons.lock, size: 16, color: Colors.black.withOpacity(0.45)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ Precio final (opcional) - “cuadrado”
                TextFormField(
                  controller: finalPriceCtrl,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: "Precio final (opcional)",
                    hintText: "Si vacío, se usa el original",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.06),
                  ),
                ),

                // ❌ BORRAMOS lo de abajo:
                // Row( svcLabel + "€price • minutes" )
                // (no lo mostramos)
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

                        if (_hasLoadedTypes() &&
                            (selectedType == null || selectedTypeId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.typeRequired)),
                          );
                          return;
                        }

                        setState(() => saving = true);
                        try {
                          // NO cambiamos appointmentDate (pasado)
                          final durationMin =
                              _finalMinutesSmart(selectedServiceData ?? widget.data, selectedType);
                          final basePrice =
                              _finalPriceSmart(selectedServiceData ?? widget.data, selectedType);

                          final userProv = context.read<UserProvider>();

                          final existingWorkerId =
                              (widget.data['workerId'] ?? '').toString().trim();

                          String? effectiveWorkerId =
                              existingWorkerId.isNotEmpty ? existingWorkerId : null;

                          if (effectiveWorkerId == null || effectiveWorkerId.isEmpty) {
                            if (userProv.isWorker && (userProv.workerId ?? '').isNotEmpty) {
                              effectiveWorkerId = userProv.workerId!;
                            }
                            if (userProv.isAdmin && (userProv.selectedWorkerId ?? '').isNotEmpty) {
                              effectiveWorkerId = userProv.selectedWorkerId!;
                            }
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

                          // finalPrice opcional
                          final fpText = finalPriceCtrl.text.trim();
                          num? finalPrice;
                          if (fpText.isNotEmpty) {
                            final parsed = num.tryParse(fpText.replaceAll(',', '.'));
                            if (parsed == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.errorWithValue("Invalid final price"))),
                              );
                              setState(() => saving = false);
                              return;
                            }
                            finalPrice = parsed;
                          }

                          await FirebaseFirestore.instance
                              .collection('appointments')
                              .doc(widget.appointmentId)
                              .update({
                            'serviceId': selectedServiceId,
                            'serviceNameKey': svcKey,
                            'serviceName': translatedName,

                            'typeId': selectedTypeId,
                            'typeKey': selectedTypeKey,
                            'typeLabel': typeLabel,
                            'typeExtraPrice': typeExtraPrice,

                            'durationMin': durationMin,
                            'basePrice': basePrice,
                            'total': basePrice, // tu lógica actual

                            // Si faltaba workerId en docs viejos, se puede asignar
                            if ((effectiveWorkerId ?? '').isNotEmpty && existingWorkerId.isEmpty)
                              'workerId': effectiveWorkerId,

                            // ✅ finalPrice solo si se rellena
                            if (finalPrice != null)
                              'finalPrice': finalPrice
                            else
                              'finalPrice': FieldValue.delete(),

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
// UI: botón bonito para elegir motivo (igual que tu edit)
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
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
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
