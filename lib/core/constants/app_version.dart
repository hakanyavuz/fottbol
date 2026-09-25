/// Uygulama sürüm ve derleme sabitleri
class AppVersion {
  static const String version = '1.0.4';
  static const int buildNumber = 5;
  static final DateTime buildDate = DateTime(2026, 9, 25, 13, 0);

  /// Sürüm dizgilerini karşılaştırır (örn: "v1.0.2" ile "1.0.1")
  /// v1 > v2 ise pozitif, v1 < v2 ise negatif, eşitse 0 döner.
  static int compareVersions(String v1, String v2) {
    String clean(String v) {
      final match = RegExp(r'(\d+(\.\d+)+)').firstMatch(v);
      if (match != null) return match.group(1)!;
      return v.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    }

    final c1 = clean(v1);
    final c2 = clean(v2);
    if (c1.isEmpty && c2.isEmpty) return 0;
    if (c1.isEmpty) return -1;
    if (c2.isEmpty) return 1;

    final parts1 = c1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = c2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}
