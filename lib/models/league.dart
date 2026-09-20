/// API-Football Lig ve Kupa Modeli (GET /leagues)
class League {
  final int id;
  final String name;
  final String type; // 'League' veya 'Cup'
  final String logo;
  final String country;
  final String? countryCode;
  final String? countryFlag;
  final List<int> seasons;

  League({
    required this.id,
    required this.name,
    required this.type,
    required this.logo,
    required this.country,
    this.countryCode,
    this.countryFlag,
    required this.seasons,
  });

  bool get isCup => type.toLowerCase() == 'cup';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'logo': logo,
    'country': country,
    'countryCode': countryCode,
    'countryFlag': countryFlag,
    'seasons': seasons,
  };

  factory League.fromJson(Map<String, dynamic> json) {
    // API-Football iç içe yapıyı (nested) veya düz JSON'ı destekler
    if (json.containsKey('league')) {
      final l = json['league'] as Map<String, dynamic>;
      final c = json['country'] as Map<String, dynamic>? ?? {};
      final sList = (json['seasons'] as List? ?? []);
      final List<int> years = sList
          .map((item) => (item['year'] as num?)?.toInt())
          .whereType<int>()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // En yeni sezon en başta

      return League(
        id: (l['id'] as num?)?.toInt() ?? 0,
        name: l['name'] ?? '',
        type: l['type'] ?? 'League',
        logo: l['logo'] ?? '',
        country: c['name'] ?? '',
        countryCode: c['code'],
        countryFlag: c['flag'],
        seasons: years.isNotEmpty ? years : [2024, 2023],
      );
    }

    return League(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'League',
      logo: json['logo'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['countryCode'],
      countryFlag: json['countryFlag'],
      seasons: (json['seasons'] as List? ?? []).cast<int>(),
    );
  }
}
