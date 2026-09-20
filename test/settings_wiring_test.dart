import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fottbol_prediction/models/fixture.dart';
import 'package:fottbol_prediction/models/league.dart';
import 'package:fottbol_prediction/providers/global_football_providers.dart';
import 'package:fottbol_prediction/providers/match_prediction_provider.dart';
import 'package:fottbol_prediction/providers/theme_provider.dart';
import 'package:fottbol_prediction/views/global_team_search_screen.dart';
import 'package:fottbol_prediction/views/team_list_screen.dart';
import 'package:fottbol_prediction/widgets/fixture_tile.dart';
import 'package:fottbol_prediction/views/settings_screen.dart';

Widget wrap(Widget child, {String apiFootballKey = ''}) {
  return ProviderScope(
    overrides: [
      apiFootballKeyProvider.overrideWith((ref) => apiFootballKey),
    ],
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MatchPredictionProvider()),
      ],
      child: MaterialApp(home: child),
    ),
  );
}

void main() {
  setUp(() {
    // Ağ isteği yok: anahtarsız modda mock/çevrimdışı veri kullanılır
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Ayarlar ekranı Gemini AI alanını gösterir ve API-Football kaldırılmıştır', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // API-Football kaldırılmış, sadece Gemini AI ve 1 adet TextField olmalı
    expect(find.textContaining('Google Gemini AI'), findsOneWidget);
    expect(find.textContaining('API-Football'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Ayarlar ekranı canlı veri ve motor sağlık panelini gösterir', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Canlı Veri & Motor Sağlık Paneli'), findsOneWidget);
    expect(find.textContaining('TFF Resmi Fikstür Motoru'), findsOneWidget);
    expect(find.textContaining('Açık Küresel Canlı Skor Motoru'), findsOneWidget);
  });

  testWidgets('Ayarlar ekranı alarm ve yenileme tercihlerini gösterir', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sesli Gol Bildirimi'), findsOneWidget);
    expect(find.textContaining('Kırmızı Kart Uyarısı'), findsOneWidget);
    expect(find.textContaining('Skor ve Olay Yenileme Sıklığı'), findsOneWidget);
  });

  testWidgets('Ayarlar ekranı veri ve geçmiş yönetimi seçeneklerini gösterir', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pump();

    expect(find.textContaining('Tahmin Geçmişini'), findsWidgets);
    expect(find.textContaining('Önbelleği Temizle'), findsOneWidget);
  });

  testWidgets('Global takım arama ekranı 3 harf ipucunu gösterir', (tester) async {
    await tester.pumpWidget(wrap(const GlobalTeamSearchScreen()));
    await tester.pump();

    expect(find.textContaining('en az 3 harf'), findsOneWidget);
  });

  testWidgets('Lig ekranı Maçlar sekmesiyle açılır ve Takımlar sekmesine geçilebilir', (tester) async {
    final league = League(
      id: 203,
      name: 'Süper Lig',
      type: 'League',
      logo: '',
      country: 'Turkey',
      seasons: const [],
    );

    await tester.pumpWidget(wrap(TeamListScreen(league: league, season: 2026)));
    await tester.pump();

    // Varsayılan Maçlar sekmesi açık
    expect(find.text('Yaklaşan'), findsOneWidget);

    await tester.tap(find.text('Takımlar'));
    await tester.pumpAndSettle();
    expect(find.text('Galatasaray'), findsOneWidget);
  });

  testWidgets('Yalnızca oynanmamış maçta Tahmin butonu görünür', (tester) async {
    Fixture make(String status, int? h, int? a) => Fixture(
          id: 1,
          date: DateTime(2026, 9, 13, 20),
          statusShort: status,
          leagueId: 203,
          leagueName: 'Süper Lig',
          season: 2026,
          homeTeamId: 1,
          homeTeamName: 'Ev',
          awayTeamId: 2,
          awayTeamName: 'Dep',
          homeGoals: h,
          awayGoals: a,
        );

    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          FixtureTile(fixture: make('NS', null, null), onPredict: () => tapped = true),
          FixtureTile(fixture: make('FT', 2, 1), onPredict: () {}),
        ]),
      ),
    ));

    expect(find.text('Tahmin'), findsOneWidget);
    expect(find.text('Bitti'), findsOneWidget);

    await tester.tap(find.text('Tahmin'));
    expect(tapped, true);
  });
}
