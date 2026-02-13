import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app/provider/booking_view_provider.dart';

class BookingViewToggle extends StatelessWidget {
  const BookingViewToggle({super.key});

  static const Color kPurple = Color(0xff721c80);

  @override
  Widget build(BuildContext context) {
    final view = context.watch<BookingViewProvider>();

    return InkWell(
      onTap: () => context.read<BookingViewProvider>().toggle(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kPurple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kPurple.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(view.isWeek ? Icons.calendar_view_week : Icons.calendar_view_day,
                size: 18, color: kPurple),
            const SizedBox(width: 8),
            Text(
              view.isWeek ? "Week" : "Day",
              style: const TextStyle(fontWeight: FontWeight.w900, color: kPurple),
            ),
          ],
        ),
      ),
    );
  }
}
