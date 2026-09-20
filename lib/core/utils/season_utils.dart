/// Sezon hesaplama yardımcıları.
///
/// API-Football sezonları başlangıç yılı ile adlandırır: 2025-2026 sezonu = 2025.
/// Sabit bir yıl (örn. 2024) kullanmak takvim ilerledikçe boş lig/takım listesine
/// yol açtığı için sezon her zaman güncel tarihten türetilir.
class SeasonUtils {
  /// Avrupa sezonları temmuzda başlar: Temmuz-Aralık -> içinde bulunulan yıl,
  /// Ocak-Haziran -> bir önceki yıl.
  static int currentSeason([DateTime? now]) {
    final date = now ?? DateTime.now();
    return date.month >= 7 ? date.year : date.year - 1;
  }

  /// Sezon seçicide gösterilecek son [count] sezon (en yeni başta)
  static List<int> recentSeasons({int count = 6, DateTime? now}) {
    final current = currentSeason(now);
    return List<int>.generate(count, (i) => current - i);
  }
}
