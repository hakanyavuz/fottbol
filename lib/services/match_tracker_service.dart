import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture.dart';
import 'storage_service.dart';

/// Canlı maç uyarı modeli (Gol veya Kırmızı Kart)
class MatchLiveAlert {
  final int fixtureId;
  final String title;
  final String message;
  final String icon;
  final bool isGoal;
  final bool isRedCard;
  final DateTime timestamp;

  MatchLiveAlert({
    required this.fixtureId,
    required this.title,
    required this.message,
    required this.icon,
    this.isGoal = false,
    this.isRedCard = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Maç Takip ve Canlı Bildirim / Sesli Alarm Servisi
class MatchTrackerService {
  static const String _keyTrackedFixtures = 'tracked_fixtures_ids';

  // Son bilinen skor ve kart durumları: fixtureId -> state
  static final Map<int, _FixtureState> _previousStates = {};

  // Uygulama geneli canlı bildirim akışı
  static final StreamController<MatchLiveAlert> _alertController =
      StreamController<MatchLiveAlert>.broadcast();

  static Stream<MatchLiveAlert> get alertStream => _alertController.stream;

  /// Takip edilen maç kimliklerini getirir
  static Future<List<int>> getTrackedFixtureIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrackedFixtures) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
  }

  /// Maçı takibe al / takipten çıkar
  static Future<bool> toggleTrackFixture(int fixtureId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrackedFixtures) ?? [];
    final idStr = fixtureId.toString();

    bool isNowTracked;
    if (list.contains(idStr)) {
      list.remove(idStr);
      isNowTracked = false;
    } else {
      list.add(idStr);
      isNowTracked = true;
    }

    await prefs.setStringList(_keyTrackedFixtures, list);
    return isNowTracked;
  }

  /// Bir maç takip ediliyor mu?
  static Future<bool> isTracked(int fixtureId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrackedFixtures) ?? [];
    return list.contains(fixtureId.toString());
  }

  /// Yeni gelen maç listesi ile önceki durumları karşılaştırıp gol/kart alarmlarını tetikler
  static void processFixturesUpdate(List<Fixture> fixtures) {
    for (final f in fixtures) {
      final oldState = _previousStates[f.id];
      final currentHome = f.homeGoals ?? 0;
      final currentAway = f.awayGoals ?? 0;
      final currentHomeReds = f.homeRedCards;
      final currentAwayReds = f.awayRedCards;

      if (oldState != null) {
        // 1. GOL KONTROLÜ
        if (currentHome > oldState.homeGoals) {
          final diff = currentHome - oldState.homeGoals;
          _triggerAlert(MatchLiveAlert(
            fixtureId: f.id,
            title: '⚽ GOOOOL! ${f.homeTeamName}',
            message: '${f.homeTeamName} $diff gol kaydetti! Yeni Skor: $currentHome - $currentAway (${f.elapsed ?? 90}\')',
            icon: '⚽',
            isGoal: true,
          ));
        }

        if (currentAway > oldState.awayGoals) {
          final diff = currentAway - oldState.awayGoals;
          _triggerAlert(MatchLiveAlert(
            fixtureId: f.id,
            title: '⚽ GOOOOL! ${f.awayTeamName}',
            message: '${f.awayTeamName} $diff gol kaydetti! Yeni Skor: $currentHome - $currentAway (${f.elapsed ?? 90}\')',
            icon: '⚽',
            isGoal: true,
          ));
        }

        // 2. KIRMIZI KART KONTROLÜ
        if (currentHomeReds > oldState.homeReds) {
          _triggerAlert(MatchLiveAlert(
            fixtureId: f.id,
            title: '🟥 KIRMIZI KART! ${f.homeTeamName}',
            message: '${f.homeTeamName} 10 kişi kaldı! (${f.elapsed ?? 90}\') - Model oranları revize edildi.',
            icon: '🟥',
            isRedCard: true,
          ));
        }

        if (currentAwayReds > oldState.awayReds) {
          _triggerAlert(MatchLiveAlert(
            fixtureId: f.id,
            title: '🟥 KIRMIZI KART! ${f.awayTeamName}',
            message: '${f.awayTeamName} 10 kişi kaldı! (${f.elapsed ?? 90}\') - Model oranları revize edildi.',
            icon: '🟥',
            isRedCard: true,
          ));
        }
      }

      // Yeni durumu kaydet
      _previousStates[f.id] = _FixtureState(
        homeGoals: currentHome,
        awayGoals: currentAway,
        homeReds: currentHomeReds,
        awayReds: currentAwayReds,
      );
    }
  }

  static Future<void> _triggerAlert(MatchLiveAlert alert) async {
    final goalEnabled = await StorageService.getGoalAlertEnabled();
    final redCardEnabled = await StorageService.getRedCardAlertEnabled();
    final favoriteOnly = await StorageService.getFavoriteOnlyAlerts();

    if (alert.isGoal && !goalEnabled) return;
    if (alert.isRedCard && !redCardEnabled) return;

    if (favoriteOnly) {
      final tracked = await isTracked(alert.fixtureId);
      if (!tracked) return;
    }

    _alertController.add(alert);
    playNotificationSound(isGoal: alert.isGoal);
  }

  /// Sesli uyarı çalma (Sistem sesi ve haptik titreşim)
  static void playNotificationSound({required bool isGoal}) {
    try {
      SystemSound.play(SystemSoundType.alert).catchError((_) {});
      HapticFeedback.heavyImpact().catchError((_) {});
    } catch (_) {}
  }

  /// Web ve mobil için takvim hatırlatma linki (Google Calendar) üretir
  static String generateGoogleCalendarUrl({
    required String matchTitle,
    required DateTime matchDate,
    String? venue,
    String? league,
  }) {
    final startTime = '${matchDate.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final endTime = '${matchDate.add(const Duration(minutes: 110)).toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final title = Uri.encodeComponent('⚽ $matchTitle ($league)');
    final details = Uri.encodeComponent('BüyükDefter Canlı Maç Takibi & Analizleri\nStadyum: ${venue ?? "Stadyum"}');
    final loc = Uri.encodeComponent(venue ?? '');
    return 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$startTime/$endTime&details=$details&location=$loc';
  }
}

class _FixtureState {
  final int homeGoals;
  final int awayGoals;
  final int homeReds;
  final int awayReds;

  _FixtureState({
    required this.homeGoals,
    required this.awayGoals,
    required this.homeReds,
    required this.awayReds,
  });
}
