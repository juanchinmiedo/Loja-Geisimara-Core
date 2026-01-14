import 'dart:async';
import 'package:flutter/material.dart';

typedef SwitchSaver = Future<void> Function(bool value);

class AsyncOptimisticSwitch extends StatefulWidget {
  const AsyncOptimisticSwitch({
    super.key,
    required this.value,
    required this.onSave,
    this.enabled = true,
    this.debounce = const Duration(milliseconds: 250),
    this.switchActiveColor,
    this.switchInactiveThumbColor,
    this.switchInactiveTrackColor,
  });

  final bool value;
  final SwitchSaver onSave;
  final bool enabled;

  /// si el usuario hace on/off rápido, solo guarda el último
  final Duration debounce;

  final Color? switchActiveColor;
  final Color? switchInactiveThumbColor;
  final Color? switchInactiveTrackColor;

  @override
  State<AsyncOptimisticSwitch> createState() => _AsyncOptimisticSwitchState();
}

class _AsyncOptimisticSwitchState extends State<AsyncOptimisticSwitch> {
  bool? _localOverride;
  Timer? _debounceTimer;

  bool get _current => _localOverride ?? widget.value;

  void _onChanged(bool v) {
    if (!widget.enabled) return;

    // ✅ animación siempre
    setState(() => _localOverride = v);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () async {
      try {
        await widget.onSave(v);
      } finally {
        if (mounted) {
          // soltamos override para volver al valor externo
          setState(() => _localOverride = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _current,
      onChanged: widget.enabled ? _onChanged : null,
      activeColor: widget.switchActiveColor,
      inactiveThumbColor: widget.switchInactiveThumbColor,
      inactiveTrackColor: widget.switchInactiveTrackColor,
    );
  }
}
