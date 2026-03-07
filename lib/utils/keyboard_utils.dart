import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyboardUtils {
  static Future<void> hide({bool withDelay = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (withDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
