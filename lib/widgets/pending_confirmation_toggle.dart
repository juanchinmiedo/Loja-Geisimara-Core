import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/utils/pending_confirmation_utils.dart';

class PendingConfirmationToggle extends StatelessWidget {
  const PendingConfirmationToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? PendingConfirmationUtils.pendingCardBg
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? PendingConfirmationUtils.pendingColor.withOpacity(0.55)
                : Colors.grey.withOpacity(0.20),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value ? const Color(0xff721c80) : Colors.transparent,
                border: Border.all(
                  color: value ? const Color(0xff721c80) : Colors.black26,
                  width: 1.6,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.reservationPending,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value
                        ? s.pendingConfirmationMsg
                        : s.timeIsConfirmed,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            if (value)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PendingConfirmationUtils.pendingColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  s.pendingConfirmationLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
