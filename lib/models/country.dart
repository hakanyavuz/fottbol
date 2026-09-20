/// API-Football Ülke Modeli (GET /countries)
class Country {
  final String name;
  final String? code;
  final String? flag;

  Country({
    required this.name,
    this.code,
    this.flag,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'flag': flag,
  };

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json['name'] ?? '',
    code: json['code'],
    flag: json['flag'],
  );
}
