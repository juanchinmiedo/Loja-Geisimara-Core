import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/components/bottom_sheet_picker.dart';
import 'package:salon_app/generated/l10n.dart';

class ServiceTypeSelectors extends StatelessWidget {
  const ServiceTypeSelectors({
    super.key,
    required this.services,
    required this.selectedServiceId,
    required this.selectedServiceData,
    required this.onPickService,
    required this.loadingTypes,
    required this.serviceTypes,
    required this.selectedType,
    required this.onPickType,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> services;

  final String? selectedServiceId;
  final Map<String, dynamic>? selectedServiceData;
  final Future<void> Function(String? serviceId, Map<String, dynamic>? serviceData) onPickService;

  final bool loadingTypes;
  final List<Map<String, dynamic>> serviceTypes;
  final Map<String, dynamic>? selectedType;
  final Future<void> Function(Map<String, dynamic>? type) onPickType;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // Fondo “suave” para encajar con tu dialog (tipo el de suggestions box)
    final softFieldColor = Colors.grey.withOpacity(0.06);

    // labels
    String serviceLabel() {
      final data = selectedServiceData;
      if (data == null) return s.procedureLabel;
      final key = (data['name'] ?? '').toString();
      return key.isNotEmpty ? trServiceOrAddon(context, key) : s.procedureLabel;
    }

    String typeLabel() {
      if (selectedType == null) return s.typeLabel;
      final lbl = (selectedType?['label'] ?? selectedType?['name'] ?? selectedType?['_id'] ?? '').toString();
      return lbl.isEmpty ? s.typeLabel : lbl;
    }

    Widget field({
      required String label,
      required String value,
      required VoidCallback? onTap,
      required bool enabled,
      Widget? trailing,
      String? helper,
    }) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? softFieldColor : softFieldColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: enabled ? Colors.black87 : Colors.black38,
                      ),
                    ),
                    if (helper != null && helper.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        helper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled ? Colors.black54 : Colors.black26,
                    size: 24,
                  ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ✅ SERVICE PICKER
        FormField<String>(
          validator: (_) => (selectedServiceId == null || selectedServiceId!.isEmpty) ? s.procedureRequired : null,
          builder: (state) {
            final hasError = state.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                field(
                  label: s.procedureLabel,
                  value: (selectedServiceData == null) ? s.selectProcedurePlaceholder : serviceLabel(),
                  helper: (selectedServiceData != null) ? null : s.selectProcedureHelper,
                  enabled: services.isNotEmpty,
                  onTap: () async {
                    final picked = await BottomSheetPicker.showSearchable<QueryDocumentSnapshot<Map<String, dynamic>>>(
                      context: context,
                      title: s.pickProcedureTitle,
                      items: services,
                      selected: services.where((d) => d.id == selectedServiceId).isNotEmpty
                          ? services.firstWhere((d) => d.id == selectedServiceId)
                          : null,
                      itemLabel: (d) {
                        final data = d.data();
                        final key = (data['name'] ?? d.id).toString();
                        return trServiceOrAddon(context, key);
                      },
                      trailingBuilder: (_) => const Icon(Icons.check_circle_outline, size: 18),
                    );

                    if (picked == null) return;
                    await onPickService(picked.id, picked.data());
                    state.didChange(picked.id);
                  },
                ),
                if (hasError) ...[
                  const SizedBox(height: 6),
                  Text(state.errorText ?? "", style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        // ✅ TYPES (si existen)
        if (loadingTypes) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 10),
        ],

        if (!loadingTypes && serviceTypes.isNotEmpty)
          FormField<String>(
            validator: (_) => (selectedType == null) ? s.typeRequired : null,
            builder: (state) {
              final hasError = state.hasError;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  field(
                    label: s.typeLabel,
                    value: (selectedType == null) ? s.selectTypePlaceholder : typeLabel(),
                    enabled: true,
                    trailing: (selectedType != null && selectedType?['common'] == true)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xff721c80).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xff721c80).withOpacity(0.25)),
                            ),
                            child: Text(
                              s.mostCommonBadge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff721c80),
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      final picked = await BottomSheetPicker.showSearchable<Map<String, dynamic>>(
                        context: context,
                        title: s.pickTypeTitle,
                        items: serviceTypes,
                        selected: selectedType,
                        itemLabel: (t) => (t['label'] ?? t['name'] ?? t['_id'] ?? '').toString(),
                        trailingBuilder: (t) {
                          final isCommon = t['common'] == true;
                          if (!isCommon) return const Icon(Icons.check_circle_outline, size: 18);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xff721c80).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xff721c80).withOpacity(0.25)),
                            ),
                            child: Text(
                              s.mostCommonBadge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff721c80),
                              ),
                            ),
                          );
                        },
                      );

                      if (picked == null) return;
                      await onPickType(picked);
                      state.didChange((picked['_id'] ?? '').toString());
                    },
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 6),
                    Text(state.errorText ?? "", style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}
