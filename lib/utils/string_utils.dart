class StringUtils {
  /// Slug simple y estable para IDs (a-z0-9_).
  /// - lower
  /// - quita espacios raros
  /// - reemplaza acentos comunes
  /// - colapsa '_' repetidos
  static String slug(String input, {String emptyFallback = 'unknown'}) {
    var s = input.trim().toLowerCase();

    // Normaliza algunos acentos comunes (sin paquetes).
    const map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));

    s = s.replaceAll(RegExp(r'\s+'), '_');
    s = s.replaceAll('-', '_');
    s = s.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_+'), '');
    s = s.replaceAll(RegExp(r'_+$'), '');

    return s.isEmpty ? emptyFallback : s;
  }
}
