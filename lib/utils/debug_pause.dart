import 'package:flutter/material.dart';

class DebugPause {
  /// Muestra un popup (NO pausa si no haces await).
  static Future<void> show(
    BuildContext context,
    String message, {
    String title = "Debug",
    bool barrierDismissible = false,
  }) async {
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'DebugPause',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.transparent,
                child: _DebugPauseCard(
                  title: title,
                  message: message,
                  onAccept: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Alias semántico para cuando QUIERES pausar.
  /// Uso:
  ///   await DebugPause.pause(context, "checkpoint");
  static Future<void> pause(
    BuildContext context,
    String message, {
    String title = "Execution paused",
  }) {
    return show(context, message, title: title, barrierDismissible: false);
  }

  /// Para usar en callbacks NO-async: devuelve un VoidCallback que abre el popup.
  /// Ej:
  ///   onPressed: DebugPause.action(context, "tap guardar"),
  static VoidCallback action(
    BuildContext context,
    String message, {
    String title = "Debug",
  }) {
    return () {
      // ignore: discarded_futures
      show(context, message, title: title);
    };
  }
}

class _DebugPauseCard extends StatelessWidget {
  const _DebugPauseCard({
    required this.title,
    required this.message,
    required this.onAccept,
  });

  final String title;
  final String message;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 10),
            color: Colors.black54,
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(message, style: const TextStyle(fontSize: 13, height: 1.2)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: onAccept,
                  child: const Text("Aceptar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
