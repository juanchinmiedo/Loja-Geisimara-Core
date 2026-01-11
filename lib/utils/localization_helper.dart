import 'package:flutter/widgets.dart';
import 'package:salon_app/generated/l10n.dart';

/// Traduce las claves de servicios y addons (ej: "gelA", "nailDecorations")
/// usando S.of(context) + un Map.
///
/// En Firebase, el campo `name` debe contener exactamente esa clave.
String trServiceOrAddon(BuildContext context, String? key) {
  if (key == null || key.isEmpty) return '';
  final s = S.of(context);

  final map = <String, String>{
    "gelA": s.gelA,
    "acrylicA": s.acrylicA,
    "fiberA": s.fiberA,
    "gelM": s.gelM,
    "acrylicM": s.acrylicM,
    "fiberM": s.fiberM,
    "simpleVarnish": s.simpleVarnish,
    "gelVarnish": s.gelVarnish,
    "cutilage": s.cutilage,
    "gelVarnishPedicure": s.gelVarnishPedicure,
    "simplePedicure": s.simplePedicure,
    "nailDecorations": s.nailDecorations,
    "hands": s.hands,
    "feet": s.feet,
    // 👉 aquí añades más claves cuando crees nuevos textos en los .arb
  };

  return map[key] ?? key; // si falta en el mapa, enseñamos la key
}