/// Stadyum ve Hava Durumu Koşulları Modeli
enum WeatherCondition {
  clear('Açık / İdeal', 1.0, 1.0),
  rainy('Yağmurlu / Kaygan Zemin', 0.94, 1.08),
  heavyRain('Aşırı Yağış / Ağır Zemin', 0.88, 1.15),
  snowy('Karlı / Zorlu Koşul', 0.82, 1.25),
  windy('Şiddetli Rüzgar', 0.92, 1.05);

  final String label;
  final double goalExpectancyMultiplier; // Ağır sahada gol beklentisi düşer
  final double foulRateMultiplier; // Kötü zeminde faul ve kart riski artar

  const WeatherCondition(this.label, this.goalExpectancyMultiplier, this.foulRateMultiplier);

  static WeatherCondition fromVenueOrDate(String? venueName, DateTime? date) {
    if (venueName == null) return WeatherCondition.clear;
    final v = venueName.toLowerCase();

    // Doğu ve yüksek rakım stadyumlarında mevsime göre koşul simülasyonu
    if (v.contains('erzurum') || v.contains('sivas')) {
      if (date != null && (date.month >= 11 || date.month <= 2)) {
        return WeatherCondition.snowy;
      }
    }
    if (v.contains('rize') || v.contains('trabzon')) {
      return WeatherCondition.rainy;
    }
    return WeatherCondition.clear;
  }
}
