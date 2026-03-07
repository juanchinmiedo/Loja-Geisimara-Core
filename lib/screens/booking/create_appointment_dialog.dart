import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';

import 'package:salon_app/services/appointment_service.dart';
import 'package:salon_app/repositories/booking_request_repo.dart';

import 'package:salon_app/utils/booking_request_utils.dart';
import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/services/client_service.dart';
import 'package:salon_app/utils/app_time_picker.dart';
import 'package:salon_app/utils/business_hours_utils.dart';
import 'package:salon_app/utils/keyboard_utils.dart';
import 'package:salon_app/utils/pending_confirmation_utils.dart';
import 'package:salon_app/utils/service_types_utils.dart';
import 'package:salon_app/utils/time_of_day_utils.dart';
import 'package:salon_app/widgets/pending_confirmation_toggle.dart';
import 'package:salon_app/services/conflict_service.dart';

// ✅ ARB
import 'package:salon_app/generated/l10n.dart';

// ✅ selectors bonitos
import 'package:salon_app/components/service_type_selectors.dart';

// ✅ Las tarjetas de cliente
import 'package:salon_app/components/client_card.dart';

class CreateAppointmentDialog extends StatefulWidget {
  const CreateAppointmentDialog({
    super.key,
    required this.selectedDay,
    required this.clients,
    required this.services,
    required this.clientService,
    required this.conflictService,
    this.preselectedClientId,
    this.initialStartTime,
  });

  final TimeOfDay? initialStartTime;
  final String? preselectedClientId;

  final DateTime selectedDay;

  /// ✅ ya cargados desde BookingAdminScreen
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> clients;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> services;

  final ClientService clientService;
  final ConflictService conflictService;

  @override
  State<CreateAppointmentDialog> createState() => _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool existingClientMode = true;
  bool saving = false;
  bool pendingConfirmation = false;

  // Existing
  final clientSearchCtrl = TextEditingController();
  final suggestionsController = ScrollController();

  // ✅ Focus (para que no se quede enganchado el input)
  final clientSearchFocus = FocusNode();

  String selectedClientId = '';
  Map<String, dynamic>? selectedClientData;

  // New client
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final instagramCtrl = TextEditingController();

  // FocusNodes (Next/Done)
  final firstNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final countryFocus = FocusNode();
  final phoneFocus = FocusNode();
  final instagramFocus = FocusNode();

  late final AppointmentService _apptService;
  late final BookingRequestRepo _brRepo;

  // Service + type
  String? selectedServiceId;
  Map<String, dynamic>? selectedServiceData;

  Map<String, dynamic>? selectedType; // doc data + _id
  String selectedTypeKey = ''; // nameKey o _id
  String selectedTypeId = ''; // _id real del doc type

  // Types subcollection cache
  List<Map<String, dynamic>> serviceTypes = const [];
  bool loadingTypes = false;

  // Time
  TimeOfDay? selectedTime;
  String? _timeError;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ✅ pulso lento
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  void _unfocus() => FocusScope.of(context).unfocus();

  TimeOfDay _clampStartToBusinessHours(TimeOfDay picked, int durationMin) {
    return BusinessHoursUtils.clampStartToBusinessHours(
      picked,
      durationMin: durationMin,
    );
  }

  Future<void> _closeKeyboard() => KeyboardUtils.hide(withDelay: true);


  @override
  void initState() {
    super.initState();

    if (widget.initialStartTime != null) {
      selectedTime = widget.initialStartTime;
      _timeError = null;
    }

    _apptService = AppointmentService(FirebaseFirestore.instance);
    _brRepo = BookingRequestRepo(FirebaseFirestore.instance);

    clientSearchCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ✅ AUTO-SELECT CLIENT si viene desde ClientsAdmin
    final pid = widget.preselectedClientId;
    if (pid != null && pid.isNotEmpty) {
      existingClientMode = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadClient(pid);
        if (!mounted) return;
        setState(() {
          selectedClientId = pid;
        });
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();

    clientSearchCtrl.dispose();
    suggestionsController.dispose();
    clientSearchFocus.dispose();

    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    instagramCtrl.dispose();

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    countryFocus.dispose();
    phoneFocus.dispose();
    instagramFocus.dispose();

    super.dispose();
  }

  /// ✅ pulso durante ~1.8s
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

  Future<void> _loadClient(String clientId) async {
    // cache
    final match = widget.clients.where((d) => d.id == clientId).toList();
    if (match.isNotEmpty) {
      final data = match.first.data();
      if (!mounted) return;
      setState(() {
        selectedClientId = clientId;
        selectedClientData = data;
      });
      return;
    }

    // fallback
    final snap = await FirebaseFirestore.instance.collection('clients').doc(clientId).get();
    final data = snap.data();
    if (data == null) return;

    if (!mounted) return;
    setState(() {
      selectedClientId = clientId;
      selectedClientData = data;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // TYPES: subcolección services/{id}/types (common primero + label)
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
      final types = await ServiceTypesUtils.loadSortedTypes(
        firestore: FirebaseFirestore.instance,
        serviceId: sid,
      );

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

        final common = ServiceTypesUtils.pickDefaultType(types)!;
        selectedType = common;
        selectedTypeId = (common['_id'] ?? '').toString();
        selectedTypeKey = (common['nameKey'] ?? common['_id'] ?? common['key'] ?? '').toString();
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

  bool _hasLoadedTypes() => serviceTypes.isNotEmpty;

  double _finalPriceSmart(Map<String, dynamic>? svc, Map<String, dynamic>? type) {
    return ServiceTypesUtils.finalPriceSmart(
      service: svc,
      type: type,
      loadedTypes: serviceTypes,
    );
  }

  int _finalMinutesSmart(Map<String, dynamic>? svc, Map<String, dynamic>? type) {
    return ServiceTypesUtils.finalMinutesSmart(
      service: svc,
      type: type,
      loadedTypes: serviceTypes,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUGGESTIONS BOX
  // ─────────────────────────────────────────────────────────────
  Widget _buildSuggestionsBox(List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered) {
    final screenH = MediaQuery.of(context).size.height;
    final maxH = (screenH * 0.30).clamp(170.0, 280.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        padding: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Scrollbar(
          controller: suggestionsController,
          thumbVisibility: false,
          child: ListView.separated(
            controller: suggestionsController,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Divider(
              height: 10,
              color: Colors.black.withOpacity(0.06),
            ),
            itemBuilder: (context, i) {
              final d = filtered[i];
              final data = d.data();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ClientCard(
                  data: data,
                  variant: ClientCardVariant.compact,
                  seeking: ClientCard.isSeeking(data),
                  showChevron: false,
                  onTap: () {
                    _unfocus();
                    _loadClient(d.id);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isDuplicateNameCancel(Object e) => e.toString().contains("Duplicate name");

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final width = MediaQuery.of(context).size.width;
    final maxDialogWidth = (width * 0.90).clamp(300.0, 440.0);

    final serviceNameKey = (selectedServiceData?['name'] ?? '').toString();
    final serviceLabel = serviceNameKey.isNotEmpty ? trServiceOrAddon(context, serviceNameKey) : '';

    final price = _finalPriceSmart(selectedServiceData, selectedType);
    final minutes = _finalMinutesSmart(selectedServiceData, selectedType);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              s.createAppointmentTitle,
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
      content: SizedBox(
        width: maxDialogWidth,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _unfocus,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // MODE TOGGLE
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _unfocus();
                              setState(() {
                                existingClientMode = true;
                                firstNameCtrl.clear();
                                lastNameCtrl.clear();
                                countryCtrl.clear();
                                phoneCtrl.clear();
                                instagramCtrl.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: existingClientMode ? const Color(0xff721c80) : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  s.modeExisting,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: existingClientMode ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _unfocus();
                              setState(() {
                                existingClientMode = false;
                                selectedClientId = '';
                                selectedClientData = null;
                                clientSearchCtrl.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: !existingClientMode ? const Color(0xff721c80) : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  s.modeNew,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: !existingClientMode ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  PendingConfirmationToggle(
                    value: pendingConfirmation,
                    enabled: !saving,
                    onChanged: (value) {
                      _unfocus();
                      setState(() => pendingConfirmation = value);
                      final msg = value
                          ? 'Marked as reservation: pending client confirmation.'
                          : 'Marked as confirmed appointment.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
                  ),

                  const SizedBox(height: 12),

                  if (existingClientMode) ...[
                    TextFormField(
                      controller: clientSearchCtrl,
                      focusNode: clientSearchFocus,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _unfocus(),
                      decoration: InputDecoration(
                        labelText: s.searchClientLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Builder(
                      builder: (_) {
                        final q = clientSearchCtrl.text.trim().toLowerCase();

                        final filtered = q.isEmpty
                            ? widget.clients.take(12).toList()
                            : widget.clients.where((d) {
                                final data = d.data();
                                final search = (data['search'] as List<dynamic>?)
                                        ?.map((e) => e.toString().toLowerCase())
                                        .toList() ??
                                    [];
                                return search.any((t) => t.contains(q));
                              }).toList();

                        if (filtered.isEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(s.noMatches, style: TextStyle(color: Colors.grey[700])),
                          );
                        }

                        return _buildSuggestionsBox(filtered);
                      },
                    ),

                    if (selectedClientData != null) ...[
                      const SizedBox(height: 10),
                      ClientCard(
                        data: selectedClientData!,
                        variant: ClientCardVariant.selected,
                        seeking: ClientCard.isSeeking(selectedClientData!),
                        showChevron: false,
                      ),
                    ],
                  ],

                  if (!existingClientMode) ...[
                    TextFormField(
                      controller: firstNameCtrl,
                      focusNode: firstNameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(lastNameFocus),
                      decoration: InputDecoration(
                        labelText: s.firstNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.firstNameRequired : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: lastNameCtrl,
                      focusNode: lastNameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(countryFocus),
                      decoration: InputDecoration(
                        labelText: s.lastNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? s.lastNameRequired : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: countryCtrl,
                            focusNode: countryFocus,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(phoneFocus),
                            decoration: InputDecoration(
                              labelText: s.countryLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: phoneCtrl,
                            focusNode: phoneFocus,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(instagramFocus),
                            decoration: InputDecoration(
                              labelText: s.phoneLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: instagramCtrl,
                      focusNode: instagramFocus,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _unfocus(),
                      decoration: InputDecoration(
                        labelText: s.instagramOptionalLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ✅ selectores bonitos (service + type)
                  Listener(
                    onPointerDown: (_) {
                      KeyboardUtils.unfocus();
                      KeyboardUtils.hide();
                    },
                    child: ServiceTypeSelectors(
                      services: widget.services,
                      selectedServiceId: selectedServiceId,
                      selectedServiceData: selectedServiceData,
                      onPickService: (serviceId, serviceData) async {
                        await _closeKeyboard();

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
                        await _closeKeyboard();

                        setState(() {
                          selectedType = type;
                          selectedTypeId = (type?['_id'] ?? '').toString();
                          selectedTypeKey =
                              (type?['nameKey'] ?? type?['_id'] ?? type?['key'] ?? '').toString();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TIME (dial + snap 5m) + ✅ BUSINESS HOURS CLAMP
                  InkWell(
                    onTapDown: (_) {
                      KeyboardUtils.unfocus();
                      KeyboardUtils.hide();
                    },
                    onTap: () async {
                      await _closeKeyboard();
                      final initial = selectedTime ?? TimeOfDay.now();

                      final picked = await AppTimePicker.pick5m(
                        context: context,
                        initial: initial,
                        bounded: true,
                        onSnap: () {
                          if (mounted) _pulseTime();
                        },
                      );

                      if (picked != null && mounted) {
                        final dur = _finalMinutesSmart(selectedServiceData, selectedType);
                        final durMin = dur > 0 ? dur : 30;
                        final adjusted = _clampStartToBusinessHours(picked, durMin);

                        setState(() {
                          selectedTime = adjusted;
                          _timeError = null;
                        });
                      }
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
                                selectedTime == null
                                    ? s.selectTimePlaceholder
                                    : TimeOfDayUtils.format24h(selectedTime!),
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

                  if (_timeError != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _timeError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  if (selectedServiceData != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.priceLabel(price.toStringAsFixed(0)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          minutes > 0 ? s.timeMinutesLabel(minutes) : s.timeMinutesEmpty,
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                  if (selectedServiceData != null && serviceLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(serviceLabel, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    ),
                  ],
                ],
              ),
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
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff721c80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        _unfocus();
                        final ok = _formKey.currentState?.validate() == true;
                        if (!ok) return;

                        if (selectedTime == null) {
                          setState(() {
                            _timeError = s.timeRequired;
                          });
                          _pulseTime();
                          return;
                        }

                        if (selectedServiceId == null || selectedServiceData == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.procedureRequired)),
                          );
                          return;
                        }

                        if (_hasLoadedTypes() && (selectedType == null || selectedTypeId.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.typeRequired)),
                          );
                          return;
                        }

                        if (existingClientMode) {
                          if (selectedClientData == null || selectedClientId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.selectExistingClient)),
                            );
                            return;
                          }
                        } else {
                          final country = _parseInt(countryCtrl.text);
                          final phone = _parseInt(phoneCtrl.text);
                          final ig = widget.clientService.normalizeInstagram(instagramCtrl.text);

                          final hasPhone = country > 0 && phone > 0;
                          if (!hasPhone && ig.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.phoneOrInstagramRequired)),
                            );
                            return;
                          }
                        }

                        setState(() => saving = true);

                        try {
                          // ✅ construir dt + snap PRO (:00 / :30) SOLO si viene de Week
                          final isFromWeek = widget.initialStartTime != null;

                          int h = selectedTime!.hour;
                          int m = selectedTime!.minute;

                          if (isFromWeek) {
                            if (m < 15) {
                              m = 0;
                            } else if (m < 45) {
                              m = 30;
                            } else {
                              m = 0;
                              h = h + 1;
                            }
                          }

                          final durationMinRaw = _finalMinutesSmart(selectedServiceData, selectedType);
                          final durationMin = durationMinRaw > 0 ? durationMinRaw : 30;
                          final basePrice = _finalPriceSmart(selectedServiceData, selectedType);

                          // ✅ NEW: clamp business hours 07:00..21:00 (shift start back if needed)
                          final bounded = _clampStartToBusinessHours(TimeOfDay(hour: h, minute: m), durationMin);
                          h = bounded.hour;
                          m = bounded.minute;
                          selectedTime = bounded; // refleja ajuste en UI

                          DateTime dt = DateTime(
                            widget.selectedDay.year,
                            widget.selectedDay.month,
                            widget.selectedDay.day,
                            h,
                            m,
                          );

                          final day0 = DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day);
                          if (dt.isBefore(day0) || !_isSameDay(dt, day0)) {
                            // con el clamp debería ser raro, pero por seguridad:
                            dt = DateTime(day0.year, day0.month, day0.day, 20, 59);
                          }

                          final userProv = context.read<UserProvider>();
                          final workerId = userProv.workerIdForCreate();
                          final createdByUid = userProv.user?.uid ?? '';

                          final maxOverlap = await widget.conflictService.maxOverlapForCandidate(
                            day: widget.selectedDay,
                            candidateStart: dt,
                            candidateDurationMin: durationMin,
                            workerId: workerId,
                            excludeAppointmentId: null,
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

                          // ✅ client resolve
                          late String clientId;
                          late String clientName;
                          late int clientCountry;
                          late int clientPhone;
                          late String clientInstagram;

                          if (existingClientMode) {
                            final d = selectedClientData!;
                            clientId = selectedClientId;

                            final fn = (d['firstName'] ?? '').toString();
                            final ln = (d['lastName'] ?? '').toString();
                            clientName = "$fn $ln".trim();

                            clientCountry = (d['country'] is num) ? (d['country'] as num).toInt() : 0;
                            clientPhone = (d['phone'] is num) ? (d['phone'] as num).toInt() : 0;
                            clientInstagram = (d['instagram'] ?? '').toString();
                          } else {
                            final res = await widget.clientService.createOrGetClient(
                              context: context,
                              firstName: firstNameCtrl.text.trim(),
                              lastName: lastNameCtrl.text.trim(),
                              country: _parseInt(countryCtrl.text),
                              phone: _parseInt(phoneCtrl.text),
                              instagramRaw: instagramCtrl.text,
                            );

                            clientId = res.clientId;
                            clientName = res.fullName;
                            clientCountry = res.country;
                            clientPhone = res.phone;
                            clientInstagram = res.instagram;
                          }

                          final svcNameKey = (selectedServiceData?['name'] ?? '').toString();
                          final translatedName =
                              svcNameKey.isNotEmpty ? trServiceOrAddon(context, svcNameKey) : 'Service';

                          final typeLabel = (selectedType?['label'] ?? '').toString();
                          final typeExtraPrice = (selectedType?['extraPrice'] is num)
                              ? (selectedType!['extraPrice'] as num).toDouble()
                              : 0.0;

                          final db = FirebaseFirestore.instance;
                          final baseId = BookingRequestUtils.appointmentBaseId(
                            clientName: clientName,
                            date: dt,
                            serviceName: translatedName,
                          );

                          final apptRef = await BookingRequestUtils.uniqueAppointmentRef(
                            db: db,
                            baseId: baseId,
                          );

                          await apptRef.set({
                            'clientId': clientId,
                            'clientName': clientName,
                            'clientCountry': clientCountry,
                            'clientPhone': clientPhone,
                            'clientInstagram': clientInstagram,

                            'serviceId': selectedServiceId,
                            'serviceNameKey': svcNameKey,
                            'serviceName': translatedName,

                            'typeId': selectedTypeId,
                            'typeKey': selectedTypeKey,
                            'typeLabel': typeLabel,
                            'typeExtraPrice': typeExtraPrice,

                            'durationMin': durationMin,
                            'basePrice': basePrice,
                            'total': basePrice,

                            'status': 'scheduled',
                            PendingConfirmationUtils.kField: pendingConfirmation,
                            'appointmentDate': Timestamp.fromDate(dt),

                            'workerId': workerId,
                            'createdByUid': createdByUid,

                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          await _apptService.onAppointmentCreated(
                            appointmentId: apptRef.id,
                            clientId: clientId,
                            initialStatus: 'scheduled',
                            appointmentDate: dt,
                            lastSummary: translatedName,
                          );

                          // ✅ NEW: borrar requests SOLO si cumplen TODOS los requisitos.
                          // Si hay requests (misma category) que NO cumplen, pedimos confirmación.
                          try {
                            final serviceCategory = (selectedServiceData?['category'] ?? 'hands').toString();

                            final plan = await _brRepo.buildDeletePlanForNewAppointment(
                              clientId: clientId,
                              appointmentStart: dt,
                              appointmentDurationMin: durationMin,
                              workerId: workerId,
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
                                              final workerLabel = w.trim().isEmpty ? 'Any' : w;
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
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.appointmentCreated)),
                          );
                        } catch (e) {
                          if (_isDuplicateNameCancel(e)) {
                            if (!mounted) return;
                            setState(() {
                              existingClientMode = false;
                            });
                            return;
                          }

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
                        s.create,
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