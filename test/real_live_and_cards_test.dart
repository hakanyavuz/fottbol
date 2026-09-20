import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fottbol_prediction/models/fixture.dart';
import 'package:fottbol_prediction/providers/match_prediction_provider.dart';
import 'package:fottbol_prediction/services/in_play_engine.dart';
import 'package:fottbol_prediction/services/match_tracker_service.dart';
import 'package:fottbol_prediction/views/live_matches_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InPlayEngine Kırmızı Kart ve Eksik Etkisi Testleri', () {
    test('Ev sahibi kırmızı kart gördüğünde beklenen golü düşer ve rakip avantaj kazanır', () {
      final normalAnalysis = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 0,
        currentAwayGoals: 0,
        elapsedMinutes: 30,
        preMatchLambdaHome: 1.5,
        preMatchLambdaAway: 1.0,
        homeRedCards: 0,
        awayRedCards: 0,
      );

      final redCardAnalysis = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 0,
        currentAwayGoals: 0,
        elapsedMinutes: 30,
        preMatchLambdaHome: 1.5,
        preMatchLambdaAway: 1.0,
        homeRedCards: 1, // Ev sahibi 10 kişi
        awayRedCards: 0,
        homeTeamName: 'Galatasaray',
        awayTeamName: 'Kocaelispor',
      );

      // Kırmızı kart görünce ev sahibinin kazanma ihtimali düşmeli
      expect(redCardAnalysis.homeWinProb, lessThan(normalAnalysis.homeWinProb));
      // Deplasmanın kazanma ihtimali artmalı
      expect(redCardAnalysis.awayWinProb, greaterThan(normalAnalysis.awayWinProb));
      // Lambda değerleri -%35 ve +%25 oranında etkilenmeli
      expect(redCardAnalysis.lambdaHomeRem, lessThan(normalAnalysis.lambdaHomeRem));
      expect(redCardAnalysis.lambdaAwayRem, greaterThan(normalAnalysis.lambdaAwayRem));
      // Gerekçe metni dolu olmalı
      expect(redCardAnalysis.cardRationale, contains('10 kişi'));
    });

    test('Deplasman takımı 2 kırmızı kart gördüğünde ev sahibi ezici üstünlük sağlar', () {
      final normal = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 1,
        currentAwayGoals: 1,
        elapsedMinutes: 60,
        preMatchLambdaHome: 1.4,
        preMatchLambdaAway: 1.4,
        homeRedCards: 0,
        awayRedCards: 0,
      );

      final doubleTwoReds = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 1,
        currentAwayGoals: 1,
        elapsedMinutes: 60,
        preMatchLambdaHome: 1.4,
        preMatchLambdaAway: 1.4,
        homeRedCards: 0,
        awayRedCards: 2, // Deplasman 9 kişi
        homeTeamName: 'Arsenal',
        awayTeamName: 'Chelsea',
      );

      // 9 kişi kalan deplasmanın kazanma şansı yarıdan fazla düşerken ev sahibinin kazanma şansı sıçrar
      expect(doubleTwoReds.homeWinProb, greaterThan(normal.homeWinProb * 1.5));
      expect(doubleTwoReds.awayWinProb, lessThan(normal.awayWinProb / 2.0));
      expect(doubleTwoReds.cardRationale, contains('kırmızı kart'));
      expect(doubleTwoReds.momentum, contains('Arsenal Sayısal Üstünlükle Baskıda'));
    });

    test('Kilit ilk 11 eksikleri gol beklentisini düşürür', () {
      final baseline = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 0,
        currentAwayGoals: 0,
        elapsedMinutes: 10,
        preMatchLambdaHome: 1.6,
        preMatchLambdaAway: 1.2,
      );

      final missingStars = InPlayEngine.calculateLiveProbabilities(
        currentHomeGoals: 0,
        currentAwayGoals: 0,
        elapsedMinutes: 10,
        preMatchLambdaHome: 1.6,
        preMatchLambdaAway: 1.2,
        missingKeyStartersHome: 2, // 2 kilit yıldız eksik
        homeTeamName: 'Real Madrid',
      );

      expect(missingStars.homeWinProb, lessThan(baseline.homeWinProb));
      expect(missingStars.cardRationale, contains('kilit eksik'));
    });
  });

  group('MatchTrackerService Canlı Olay Takip ve Alarm Testleri', () {
    test('Skor arttığında anlık gol uyarısı (Goal Alert) üretir', () async {
      MatchLiveAlert? receivedAlert;
      final sub = MatchTrackerService.alertStream.listen((alert) {
        receivedAlert = alert;
      });

      final f1 = Fixture(
        id: 99999,
        statusShort: '1H',
        leagueId: 203,
        leagueName: 'Süper Lig',
        season: 2026,
        homeTeamId: 10,
        homeTeamName: 'Fenerbahçe',
        awayTeamId: 20,
        awayTeamName: 'Beşiktaş',
        homeGoals: 0,
        awayGoals: 0,
      );

      // İlk durumu kaydet
      MatchTrackerService.processFixturesUpdate([f1]);

      // Gol atıldı (1 - 0)
      final f1Goal = f1.copyWith(homeGoals: 1, elapsed: 24);
      MatchTrackerService.processFixturesUpdate([f1Goal]);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(receivedAlert, isNotNull);
      expect(receivedAlert!.isGoal, isTrue);
      expect(receivedAlert!.title, contains('GOOOOL! Fenerbahçe'));
      expect(receivedAlert!.message, contains('1 - 0'));

      await sub.cancel();
    });

    test('Kırmızı kart çıktığında Kırmızı Kart Uyarısı üretir', () async {
      MatchLiveAlert? receivedAlert;
      final sub = MatchTrackerService.alertStream.listen((alert) {
        receivedAlert = alert;
      });

      final f2 = Fixture(
        id: 88888,
        statusShort: '2H',
        leagueId: 39,
        leagueName: 'Premier League',
        season: 2026,
        homeTeamId: 1,
        homeTeamName: 'Liverpool',
        awayTeamId: 2,
        awayTeamName: 'Everton',
        homeGoals: 1,
        awayGoals: 0,
        homeRedCards: 0,
        awayRedCards: 0,
      );

      MatchTrackerService.processFixturesUpdate([f2]);

      // Everton kırmızı kart gördü
      final f2Red = f2.copyWith(awayRedCards: 1, elapsed: 65);
      MatchTrackerService.processFixturesUpdate([f2Red]);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(receivedAlert, isNotNull);
      expect(receivedAlert!.isRedCard, isTrue);
      expect(receivedAlert!.title, contains('KIRMIZI KART! Everton'));
      expect(receivedAlert!.message, contains('10 kişi kaldı'));

      await sub.cancel();
    });
  });

  group('Tarih Filtresi ve Ülke Ligleri Entegrasyon Testleri', () {
    test('Tarih seçici ileri/geri navigasyonu tarihi 1 gün kaydırır', () {
      final provider = MatchPredictionProvider();
      addTearDown(provider.dispose);
      final today = DateTime.now();

      // Varsayılan tarih bugündür
      expect(provider.selectedLiveDate.day, equals(today.day));

      // 1 gün geri git
      provider.previousLiveDay();
      final yesterday = today.subtract(const Duration(days: 1));
      expect(provider.selectedLiveDate.day, equals(yesterday.day));

      // 1 gün ileri git
      provider.nextLiveDay();
      expect(provider.selectedLiveDate.day, equals(today.day));

      // Manuel spesifik bir tarih ata
      final specificDate = DateTime(2026, 9, 12);
      provider.setLiveDate(specificDate);
      expect(provider.selectedLiveDate.year, equals(2026));
      expect(provider.selectedLiveDate.month, equals(9));
      expect(provider.selectedLiveDate.day, equals(12));

      // Bugüne dön
      provider.resetLiveDateToToday();
      expect(provider.selectedLiveDate.day, equals(today.day));
    });

    testWidgets('LiveMatchesScreen üzerinde tarih çubuğu ve ileri/geri butonları görüntülenir', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = MatchPredictionProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const LiveMatchesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tarih navigasyon butonlarının ve takvim ikonunun ekranda olduğunu doğrula
      expect(find.byIcon(Icons.arrow_back_ios_new), findsWidgets);
      expect(find.byIcon(Icons.arrow_forward_ios), findsWidgets);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.text('BUGÜN'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  });
}

