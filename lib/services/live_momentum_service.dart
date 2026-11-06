import 'dart:math' as math;
import '../models/match_event.dart';

/// Canlı Maç İçi Momentum ve Baskı Analiz Modeli
class MomentumSnapshot {
  final int minute;
  final double homeMomentum; // [-100.0 (Aşırı Deplasman Baskısı) ile +100.0 (Aşırı Ev Baskısı)]
  final double homeXg;
  final double awayXg;
  final bool isHomeSurge; // Ev sahibi yoğun baskı kurdu mu?
  final bool isAwaySurge; // Deplasman yoğun baskı kurdu mu?
  final String? tacticalAlert;

  const MomentumSnapshot({
    required this.minute,
    required this.homeMomentum,
    required this.homeXg,
    required this.awayXg,
    required this.isHomeSurge,
    required this.isAwaySurge,
    this.tacticalAlert,
  });
}

/// Canlı Maç İçi xG & Şut Momentum Avcısı (Live Momentum Hunter)
class LiveMomentumService {
  /// Canlı maç olayları (şut, korner, kart, gol) ve xG verilerinden momentum akışını modeller
  static MomentumSnapshot analyzeMomentum({
    required int currentMinute,
    required List<MatchEvent> events,
    double? liveHomeXg,
    double? liveAwayXg,
    String homeTeamName = 'Ev Sahibi',
    String awayTeamName = 'Deplasman',
  }) {
    if (currentMinute <= 0) {
      return const MomentumSnapshot(
        minute: 0,
        homeMomentum: 0.0,
        homeXg: 0.0,
        awayXg: 0.0,
        isHomeSurge: false,
        isAwaySurge: false,
      );
    }

    // Son 15 dakikadaki olayları filtrele (Rolling 15-minute window)
    final recentWindowMinutes = math.max(0, currentMinute - 15);
    final recentEvents = events.where((e) => e.time >= recentWindowMinutes && e.time <= currentMinute).toList();

    double rawHomePoints = 0.0;
    double rawAwayPoints = 0.0;

    int recentHomeShots = 0;
    int recentAwayShots = 0;

    for (final ev in recentEvents) {
      final isHome = ev.teamName == homeTeamName;
      final type = ev.type;
      final detail = (ev.detail ?? '').toLowerCase();

      double eventWeight = 1.0;
      if (type == MatchEventType.goal) {
        eventWeight = 10.0;
      } else if (detail.contains('penalty')) {
        eventWeight = 8.0;
      } else if (type == MatchEventType.card && detail.contains('red')) {
        // Kırmızı kart rakibe devasa momentum kazandırır
        if (isHome) {
          rawAwayPoints += 12.0;
        } else {
          rawHomePoints += 12.0;
        }
        continue;
      } else if (detail.contains('woodwork') || detail.contains('direk')) {
        eventWeight = 5.0;
      } else if (detail.contains('shot') || detail.contains('target')) {
        eventWeight = 3.5;
        if (isHome) {
          recentHomeShots++;
        } else {
          recentAwayShots++;
        }
      } else if (detail.contains('corner')) {
        eventWeight = 2.0;
      }

      if (isHome) {
        rawHomePoints += eventWeight;
      } else {
        rawAwayPoints += eventWeight;
      }
    }

    // xG ivmesini dahil et
    final hXg = liveHomeXg ?? 0.0;
    final aXg = liveAwayXg ?? 0.0;
    rawHomePoints += (hXg * 6.0);
    rawAwayPoints += (aXg * 6.0);

    // Normalize edilmiş momentum skoru [-100, +100]
    final total = rawHomePoints + rawAwayPoints;
    double momentumIndex = 0.0;
    if (total > 0) {
      momentumIndex = ((rawHomePoints - rawAwayPoints) / total) * 100.0;
    }

    final isHomeSurge = momentumIndex >= 55.0 || recentHomeShots >= 3;
    final isAwaySurge = momentumIndex <= -55.0 || recentAwayShots >= 3;

    String? alert;
    if (isHomeSurge) {
      alert = '🔥 Canlı Baskı Alarmı ($currentMinute\'): $homeTeamName son dakikalarda vites yükseltti! ($recentHomeShots şut / baskı endeksi: +${momentumIndex.toStringAsFixed(0)}). Sıradaki Gol Ev Sahibi ihtimali yüksek.';
    } else if (isAwaySurge) {
      alert = '⚡ Kontra Baskı Alarmı ($currentMinute\'): $awayTeamName deplasmanda yoğun şut ve ceza sahası etkinliği yakaladı (baskı endeksi: ${momentumIndex.toStringAsFixed(0)}).';
    }

    return MomentumSnapshot(
      minute: currentMinute,
      homeMomentum: momentumIndex.clamp(-100.0, 100.0),
      homeXg: hXg,
      awayXg: aXg,
      isHomeSurge: isHomeSurge,
      isAwaySurge: isAwaySurge,
      tacticalAlert: alert,
    );
  }

  /// Maçın başından güncel dakikaya kadar 10 eşit zaman dilimindeki momentum trendini [-10.0, +10.0] skalasında üretir
  static List<double> generateTimeline({
    required int currentMinute,
    required List<MatchEvent> events,
    double? liveHomeXg,
    double? liveAwayXg,
    String homeTeamName = 'Ev Sahibi',
    String awayTeamName = 'Deplasman',
  }) {
    final minute = math.max(10, currentMinute);
    final slice = minute / 10.0;
    final timeline = <double>[];

    for (int i = 1; i <= 10; i++) {
      final pointMinute = (i * slice).round();
      final snapshot = analyzeMomentum(
        currentMinute: pointMinute,
        events: events,
        liveHomeXg: (liveHomeXg != null && liveHomeXg > 0) ? (liveHomeXg * (i / 10.0)) : null,
        liveAwayXg: (liveAwayXg != null && liveAwayXg > 0) ? (liveAwayXg * (i / 10.0)) : null,
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
      );

      // [-100, +100] aralığını bar chart için [-10, +10] aralığına ölçekle
      double scaled = (snapshot.homeMomentum / 10.0).clamp(-10.0, 10.0);

      // Eğer hiç olay yoksa dakikaya göre hafif dinamik salınım ver (sabit kalmasın)
      if (events.isEmpty && (scaled == 0.0)) {
        scaled = math.sin(i * 0.7) * 2.5;
      }

      timeline.add(double.parse(scaled.toStringAsFixed(1)));
    }

    return timeline;
  }
}
