import 'team.dart';
import 'match_stat.dart';
import 'player.dart';

/// API-Football Takım ve Stadyum Modeli (GET /teams)
class ApiTeam {
  final int id;
  final String name;
  final String? code;
  final String country;
  final int? founded;
  final bool national;
  final String logo;

  // Stadyum bilgileri
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;
  final int? venueCapacity;
  final String? venueImage;

  ApiTeam({
    required this.id,
    required this.name,
    this.code,
    required this.country,
    this.founded,
    this.national = false,
    required this.logo,
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.venueCapacity,
    this.venueImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'country': country,
    'founded': founded,
    'national': national,
    'logo': logo,
    'venueName': venueName,
    'venueAddress': venueAddress,
    'venueCity': venueCity,
    'venueCapacity': venueCapacity,
    'venueImage': venueImage,
  };

  factory ApiTeam.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('team')) {
      final t = Map<String, dynamic>.from(json['team'] as Map);
      final v = json['venue'] is Map
          ? Map<String, dynamic>.from(json['venue'] as Map)
          : <String, dynamic>{};

      return ApiTeam(
        id: (t['id'] as num?)?.toInt() ?? 0,
        name: t['name'] ?? '',
        code: t['code'],
        country: t['country'] ?? '',
        founded: (t['founded'] as num?)?.toInt(),
        national: t['national'] ?? false,
        logo: t['logo'] ?? '',
        venueName: v['name'],
        venueAddress: v['address'],
        venueCity: v['city'],
        venueCapacity: (v['capacity'] as num?)?.toInt(),
        venueImage: v['image'],
      );
    }

    return ApiTeam(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      country: json['country'] ?? '',
      founded: (json['founded'] as num?)?.toInt(),
      national: json['national'] ?? false,
      logo: json['logo'] ?? '',
      venueName: json['venueName'],
      venueAddress: json['venueAddress'],
      venueCity: json['venueCity'],
      venueCapacity: (json['venueCapacity'] as num?)?.toInt(),
      venueImage: json['venueImage'],
    );
  }

  /// Tahmin motorunda (`PoissonEngine`) kullanılmak üzere Team modeline dönüştürücü.
  ///
  /// [stats] ve [squad] `ApiFootballService` tarafından gerçek uç noktalardan
  /// doldurulur. Veri çekilemediğinde uydurma istatistik üretilmez; boş
  /// [MatchStat.unknown] ile lig ortalaması baz alınır ve tahmin ekranında
  /// "Sınırlı Veri" uyarısı gösterilir.
  Team toTeam({
    String leagueName = 'Lig',
    MatchStat? stats,
    List<Player>? squad,
  }) {
    return Team(
      id: id.toString(),
      name: name,
      shortName: code ?? name,
      crestUrl: logo,
      league: leagueName,
      venue: venueName ?? 'Stadyum',
      stats: stats ?? MatchStat.unknown(),
      squad: squad ?? const [],
      dataSource: Team.sourceApiFootball,
    );
  }
}
