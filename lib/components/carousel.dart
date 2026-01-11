import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/screens/booking/booking_screen.dart';

class Carousel extends StatelessWidget {
  final VoidCallback? onBookNow; // 👈 callback opcional

  const Carousel({
    super.key,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    void handleTap() {
      if (onBookNow != null) {
        onBookNow!();                         // 👈 cambia de pestaña
      } else {
        // Fallback por si algún día lo usas sin bottom nav
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BookingScreen(),
          ),
        );
      }
    }

    return SizedBox(
      height: 140,
      child: Center(
        child: GestureDetector(
          onTap: handleTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff721c80),
                  Color.fromARGB(255, 196, 103, 169),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título – usamos tu key booknow
                        Text(
                          s.bookNowTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtítulo – de momento reutilizamos también booknow
                        Text(
                          s.bookNowSubtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      s.bookNowButton, // botón – también booknow como dijiste
                      style: const TextStyle(
                        color: Color(0xff721c80),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}