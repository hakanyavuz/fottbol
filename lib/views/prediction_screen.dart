import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/goal_timing_distribution.dart';
import '../models/prediction_result.dart';
import '../models/value_bet.dart';
import '../providers/match_prediction_provider.dart';
import '../services/gemini_analysis_service.dart';
import '../services/match_tracker_service.dart';
import '../services/tactical_narrative_engine.dart';
import '../widgets/accuracy_card.dart';
import '../widgets/confidence_badge_card.dart';
import '../widgets/goal_distribution_chart.dart';
import '../widgets/goal_timing_card.dart';
import '../widgets/head_to_head_card.dart';
import '../widgets/match_probability_chart.dart';
import '../widgets/monte_carlo_card.dart';
import '../widgets/odds_comparison_card.dart';
import '../widgets/market_consensus_card.dart';
import '../services/consensus_engine.dart';
import '../widgets/referee_card.dart';
import '../widgets/score_board_card.dart';
import '../widgets/score_matrix_heatmap.dart';
import '../widgets/stadium_weather_card.dart';
import '../widgets/value_bet_card.dart';
import '../widgets/smart_picks_report_card.dart';
import '../widgets/specialized_markets_card.dart';
import '../widgets/service_health_badge.dart';

import '../models/social_post.dart';
import '../services/social_service.dart';

import '../models/match_event.dart';
import '../models/lineup.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../core/utils/team_name_matcher.dart';
import '../services/api_football_service.dart';
import '../services/football_offline_repository.dart';
import 'ai_chat_assistant_screen.dart';

/// 5. Ekran: Tahmini Skor, Poisson İhtimalleri ve Gemini AI Taktiksel Analiz Raporu
///
/// [historyItem] verildiğinde geçmişten açılan o tahmin gösterilir; verilmezse
/// provider'daki güncel tahmin kullanılır.
class PredictionScreen extends StatelessWidget {
  final PredictionResult? historyItem;

  const PredictionScreen({super.key, this.historyItem});

  bool get _isHistoryView => historyItem != null;

  /// Sosyal Medya / WhatsApp formatında zengin bülten metni
  String _buildSocialBulletin(PredictionResult p) {
    return '''⚡ QUANT MAÇ ÖNÜ BAHİS KARNESİ ⚡
━━━━━━━━━━━━━━━━━━━━━
⚽ ${p.homeTeam.name} vs ${p.awayTeam.name}
🎯 Tahmini Skor: ${p.predictedScoreString}
📊 xG (Beklenen Gol): ${p.lambdaHome.toStringAsFixed(2)} - ${p.lambdaAway.toStringAsFixed(2)}
━━━━━━━━━━━━━━━━━━━━━
🌟 AKILLI TERCİHLER:
  👑 Banko: ${p.primaryPick} (%${p.primaryPickConfidence.toStringAsFixed(0)} Güven)
  ⚽ Gol Pazarı: ${p.secondaryPick}
  🛡️ Sigorta: ${p.safetyPick}
  ${p.isValueBet ? '💰 DEĞERLİ BAHİS: EV +%${((p.expectedValue - 1.0) * 100).toStringAsFixed(1)} Avantaj!' : '📊 Oran Durumu: Dengeli'}
━━━━━━━━━━━━━━━━━━━━━
📈 MAÇ SONUCU İHTİMALLERİ (Bayesian Konsensüs):
  [1] Ev Sahibi: %${p.homeWinProbability}
  [X] Beraberlik: %${p.drawProbability}
  [2] Deplasman : %${p.awayWinProbability}
━━━━━━━━━━━━━━━━━━━━━
🔥 2.5 Gol Üstü: %${p.over25Probability}
⚽ Karşılıklı Gol (KG): %${p.bothTeamsToScoreProbability}
🎲 En Olası Skorlar:
${p.topScores.map((s) => '  • ${s.scoreString} (%${s.probability.toStringAsFixed(1)})').join('\n')}
━━━━━━━━━━━━━━━━━━━━━
🤖 BüyükDefter / Football Quantitative Engine''';
  }

  /// Sosyal Medya Kartı Önizleme ve Paylaşım Penceresi
  void _showSocialShareDialog(BuildContext context, PredictionResult p) {
    final bulletin = _buildSocialBulletin(p);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Sosyal Paylaşım Bülteni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: SingleChildScrollView(
            child: Text(
              bulletin,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Toplulukla Paylaş'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              SocialService.addPost(
                SocialPost(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  username: 'Ben (Kullanıcı)',
                  userAvatar: 'https://i.pravatar.cc/150?u=me',
                  content: '${p.homeTeam.name} - ${p.awayTeam.name} maçı için Poisson tahminim ektedir. Skor beklentim: ${p.predictedScoreString}',
                  prediction: p,
                  createdAt: DateTime.now(),
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Tahmin topluluk akışında paylaşıldı!')),
              );
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Bülteni Kopyala'),
            style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: bulletin));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Bülten panoya kopyalandı!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Tahmin özetini panoya kopyalar
  Future<void> _copyToClipboard(BuildContext context, PredictionResult p) async {
    final messenger = ScaffoldMessenger.of(context);
    final summary = _buildSocialBulletin(p);

    await Clipboard.setData(ClipboardData(text: summary));
    messenger.showSnackBar(
      const SnackBar(content: Text('Tahmin özeti panoya kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchPredictionProvider>();
    final prediction = historyItem ?? provider.currentPrediction;
    
    // Kadroları otomatik kontrol et (eğer fixtureId varsa ve kontrol zamanı geldiyse)
    if (prediction?.fixtureId != null && !provider.isLoadingLineups) {
      if (provider.shouldCheckLineups(prediction!.fixtureId!)) {
        final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
        Future.microtask(() => provider.fetchAndAnalyzeLineups(prediction.fixtureId!, apiService));
      }
    }

    if (prediction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skor Tahmini')),
        body: const Center(
          child: Text('Henüz bir tahmin hesaplanmadı. Lütfen iki takım seçiniz.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isHistoryView ? '📜 Kayıtlı Tahmin' : '🎯 Maç Öncesi Tahmin Raporu'),
        actions: [
          if (prediction.fixtureId != null)
            FutureBuilder<bool>(
              future: MatchTrackerService.isTracked(prediction.fixtureId!),
              builder: (context, snapshot) {
                final isTracked = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isTracked ? Icons.notifications_active : Icons.notifications_none_outlined,
                    color: isTracked ? Colors.amber : null,
                  ),
                  tooltip: isTracked ? 'Takibi Bırak' : 'Maçı Takibe Al (Alarm)',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nowTracked = await MatchTrackerService.toggleTrackFixture(prediction.fixtureId!);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          nowTracked
                              ? '🔔 Maç takibe alındı. İlk 11 açıklandığında bildirim verilecek.'
                              : '🔕 Maç takipten çıkarıldı.',
                        ),
                      ),
                    );
                    (context as Element).markNeedsBuild();
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Google Takvim Hatırlatıcı Ekle',
            onPressed: () {
                final url = MatchTrackerService.generateGoogleCalendarUrl(
                  matchTitle: '${prediction.homeTeam.name} vs ${prediction.awayTeam.name}',
                  matchDate: prediction.matchDate ?? DateTime.now(),
                  venue: prediction.homeTeam.venue,
                  league: prediction.homeTeam.league,
                );
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📅 Google Takvim hatırlatıcı linki panoya kopyalandı!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.amberAccent),
            tooltip: 'Bu Maçı AI Danışmanına Sor',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatAssistantScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bülten Paylaş / Önizle',
            onPressed: () => _showSocialShareDialog(context, prediction),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Özeti panoya kopyala',
            onPressed: () => _copyToClipboard(context, prediction),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotasız Canlı Veri Hattı Sağlık Rozeti
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ServiceHealthBadge(),
            ),

            // Kadro Değişiklik Uyarısı
            if (provider.lineupAlertMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.lineupAlertMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),

            // Şike / Manipülasyon & Yüksek Varyans Risk Kalkanı Banner'ı
            if (prediction.isHighManipulationRisk)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrangeAccent.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.deepOrangeAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛡️ ${prediction.manipulationRiskRegion ?? "Bölgesel"} Lig/Kupa Risk Kalkanı Devrede',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Tarihsel manipülasyon ve şüpheli maç sonu anomalileri nedeniyle Poisson güven skoru %75 ile sınırlandırılmış, beraberlik toleransı artırılmış ve Kelly kasa payı korumalı olarak hesaplanmıştır.',
                            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Canlı Kadro & Muhtemel 11 Takip Kartı
            LiveLineupTrackerCard.fromPrediction(prediction: prediction),

            // Canlı Maç Olayları
            if (prediction.fixtureId != null && provider.getEventsForFixture(prediction.fixtureId!).isNotEmpty)
              LiveMatchEventsCard(events: provider.getEventsForFixture(prediction.fixtureId!)),

            // Alt Ligler için Sınırlı Veri Uyarı Banner'ı
            if (prediction.isSparseData)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Sınırlı Veri ile Tahmin Yapıldı: Alt lig veya kupa karşılaşması olduğundan ayrıntılı oyuncu sakatlıkları yerine genel takım performansı baz alınmıştır.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Gerçek maça bağlı tahminlerde maç tarihi ve (varsa) gerçek sonuç
            if (prediction.fixtureId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.homeTeamColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.homeTeamColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, size: 18, color: AppColors.homeTeamColor),
                        const SizedBox(width: 8),
                        Text(
                          prediction.matchDate != null
                              ? 'Maç: ${DateFormat('dd.MM.yyyy HH:mm').format(prediction.matchDate!)}'
                              : 'Gerçek fikstür maçı',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ResultBadge(prediction: prediction),
                  ],
                ),
              ),

            // Stadyum ve Canlı Hava Durumu Kartı
            StadiumWeatherCard(venueName: prediction.homeTeam.venue),
            const SizedBox(height: 12),

            // 1. Ana Skorbord Kartı
            ScoreBoardCard(prediction: prediction),
            const SizedBox(height: 16),

            // 1a. Akıllı Bahis Karnesi (Quant Multi-Market Picks & EV)
            SmartPicksReportCard(prediction: prediction),
            const SizedBox(height: 16),

            // 1b. Club Elo & xG Takım Güç Endeksi Kartı
            if (prediction.homeElo != null && prediction.awayElo != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.military_tech_outlined, color: AppColors.premiumGold, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Club Elo Güç Derecesi & Kalite Farkı',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Δ Elo: ${prediction.eloDifference != null && prediction.eloDifference! > 0 ? "+" : ""}${prediction.eloDifference?.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction.homeTeam.name,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prediction.homeElo!.toInt()} Elo',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                if (prediction.homeXg != null)
                                  Text(
                                    'xG: ${prediction.homeXg!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
                                  ),
                              ],
                            ),
                          ),
                          const Text('VS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  prediction.awayTeam.name,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${prediction.awayElo!.toInt()} Elo',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                if (prediction.awayXg != null)
                                  Text(
                                    'xG: ${prediction.awayXg!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 1c. Grafiksel Olasılık Analizi
            _SectionCard(
              icon: Icons.pie_chart_outline,
              title: 'İstatistiksel Galibiyet Olasılıkları',
              child: MatchProbabilityChart(prediction: prediction),
            ),
            const SizedBox(height: 16),

            // 1b. Güven Skoru & Risk İndeksi Kartı
            ConfidenceBadgeCard(prediction: prediction),
            const SizedBox(height: 16),

            // 2. En Yüksek İhtimalli 3 Skor Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎲 En Olası Skor Sıralaması (Poisson)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: prediction.topScores.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: index == 1
                                ? AppColors.primary.withOpacity(0.15)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: index == 1 ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '#$index Tercih',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: index == 1 ? AppColors.primary : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.scoreString,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '%${item.probability.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2b. Bahis Oranları & Value Bet Kıyaslaması
            if (prediction.oddsComparison != null) ...[
              OddsComparisonCard(comparison: prediction.oddsComparison!),
              const SizedBox(height: 16),
            ],

            // 2b+. Küresel Analiz & Piyasa Konsensüs Terminali
            MarketConsensusCard(
              consensus: prediction.consensus ??
                  ConsensusEngine.buildConsensus(
                    prediction: prediction,
                    odds: prediction.oddsComparison?.odds,
                  ),
            ),
            const SizedBox(height: 16),

            // 2c. Tam skor olasılık haritası (eski kayıtlarda matris yoksa gizlenir)
            if (prediction.scoreMatrix.isNotEmpty) ...[
              _SectionCard(
                icon: Icons.grid_on,
                title: 'Skor Olasılık Haritası',
                subtitle: prediction.dixonColesRho != 0
                    ? 'Poisson + Dixon-Coles (ρ = ${prediction.dixonColesRho.toStringAsFixed(2)})'
                    : 'Poisson',
                child: ScoreMatrixHeatmap(prediction: prediction),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.bar_chart,
                title: 'Gol Dağılımı',
                subtitle: 'Her takımın kaç gol atacağının olasılığı',
                child: GoalDistributionChart(prediction: prediction),
              ),
              const SizedBox(height: 16),
            ],

            // 2c. Aralarındaki maçlar
            if (prediction.headToHead != null) ...[
              HeadToHeadCard(
                summary: prediction.headToHead!,
                homeName: prediction.homeTeam.name,
                awayName: prediction.awayTeam.name,
              ),
              const SizedBox(height: 16),
            ],

            // 2d. Hakem Analiz Kartı (Kartlar, Fauller, Penaltı Eğilimi)
            if (prediction.refereeStat != null) ...[
              RefereeCard(referee: prediction.refereeStat!),
              const SizedBox(height: 16),
            ],

            // 2d2. Özel Pazarlar: Kart & Korner Modeli & Kabus Rakip Uyarısı
            SpecializedMarketsCard(prediction: prediction),

            // 2e. Monte Carlo 10.000 Maç Simülatörü
            MonteCarloCard(
              lambdaHome: prediction.lambdaHome,
              lambdaAway: prediction.lambdaAway,
              homeName: prediction.homeTeam.name,
              awayName: prediction.awayTeam.name,
            ),
            const SizedBox(height: 16),

            // 2e2. 15'er Dakikalık Gol Zamanlama ve Periyot Dağılımı
            GoalTimingCard(
              timing: GoalTimingDistribution.calculate(
                lambdaHome: prediction.lambdaHome,
                lambdaAway: prediction.lambdaAway,
              ),
              homeTeam: prediction.homeTeam.name,
              awayTeam: prediction.awayTeam.name,
            ),
            const SizedBox(height: 16),

            // 2f. Value Bet (Değerli Bahis) Radarı
            Builder(
              builder: (context) {
                final valueBets = ValueBet.findValueBets(prediction);
                if (valueBets.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.diamond_outlined, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Değerli Bahis Radarı (Value Bet)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...valueBets.map((vb) => ValueBetCard(bet: vb)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // 3. Yan Bahis / Gol Olasılıkları Kartı
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('2.5 Gol Üstü', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            '%${prediction.over25Probability.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Karşılıklı Gol (KG Var)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            '%${prediction.bothTeamsToScoreProbability.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. İstatistiksel Hesaplama Gerekçeleri (Poisson Adımları)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Matematiksel Tahmin Gerekçeleri',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...prediction.mathematicalRationale.map((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4b. Opta / WhoScored Stili Teknik Direktör Hap Brifingi
            Builder(
              builder: (context) {
                final briefing = GeminiAnalysisService.generateManagerBriefing(prediction);
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sports_soccer_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '👔 Teknik Direktör Taktik Brifingi (Opta / Pro)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Maç öncesi teknik heyetin ve analistlerin dikkat etmesi gereken 3 kritik nokta:',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ...briefing.map((b) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['title']!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b['text']!,
                                    style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.white70),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 5. Gemini AI Taktiksel Yorum Bölümü
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4), width: 1.2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Gemini AI Taktiksel Maç Raporu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                        if (provider.isAnalyzingGemini && !_isHistoryView)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                          )
                        // Geçmiş kaydı salt okunur gösterilir; yorum yenileme
                        // yalnızca güncel tahmin için anlamlıdır.
                        else if (!_isHistoryView)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20, color: Colors.purpleAccent),
                            tooltip: 'Yeniden Yorumlat',
                            onPressed: () => provider.refreshGeminiAnalysis(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        prediction.geminiTacticalAnalysis ??
                            TacticalNarrativeEngine.generateNarrative(prediction),
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Başlık + alt başlıklı standart bölüm kartı
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(subtitle!, style: TextStyle(fontSize: 11.5, color: muted)),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class LiveLineupTrackerCard extends StatelessWidget {
  final int? fixtureId;
  final String homeTeamName;
  final String awayTeamName;
  final List<Player> homeInjured;
  final List<Player> awayInjured;
  final Team? homeTeam;
  final Team? awayTeam;

  const LiveLineupTrackerCard({
    super.key,
    this.fixtureId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeInjured = const [],
    this.awayInjured = const [],
    this.homeTeam,
    this.awayTeam,
  });

  factory LiveLineupTrackerCard.fromPrediction({
    Key? key,
    required PredictionResult prediction,
  }) {
    return LiveLineupTrackerCard(
      key: key,
      fixtureId: prediction.fixtureId,
      homeTeamName: prediction.homeTeam.name,
      awayTeamName: prediction.awayTeam.name,
      homeInjured: prediction.homeTeam.injuredPlayers,
      awayInjured: prediction.awayTeam.injuredPlayers,
      homeTeam: prediction.homeTeam,
      awayTeam: prediction.awayTeam,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchPredictionProvider>();

    // 1. Resmi canlı kadroları fikstüre göre bul
    final lineups = (fixtureId != null ? provider.getLineupsForFixture(fixtureId!) : null) ??
        (provider.currentPrediction?.fixtureId != null && provider.currentPrediction?.fixtureId == fixtureId
            ? provider.currentLineups
            : null);

    TeamLineup? officialHomeLineup;
    TeamLineup? officialAwayLineup;

    if (lineups != null && lineups.length >= 2) {
      if (TeamNameMatcher.matches(lineups[0].teamName, homeTeamName) &&
          TeamNameMatcher.matches(lineups[1].teamName, awayTeamName)) {
        officialHomeLineup = lineups[0];
        officialAwayLineup = lineups[1];
      } else if (TeamNameMatcher.matches(lineups[1].teamName, homeTeamName) &&
                 TeamNameMatcher.matches(lineups[0].teamName, awayTeamName)) {
        officialHomeLineup = lineups[1];
        officialAwayLineup = lineups[0];
      }
      // ÖNEMLİ: Eşleşme yoksa asla kör fallback uygulanmaz!
    }

    final bool isConfirmed = officialHomeLineup != null &&
        officialAwayLineup != null &&
        officialHomeLineup.startXI.isNotEmpty &&
        officialAwayLineup.startXI.isNotEmpty;

    // 2. Canlı veya bitmiş maç kontrolü
    final liveMatch = fixtureId != null
        ? provider.liveFixtures.where((f) => f.id == fixtureId).firstOrNull
        : null;

    final bool isFinished = liveMatch?.isFinished == true ||
        (provider.currentPrediction?.fixtureId != null &&
            provider.currentPrediction?.fixtureId == fixtureId &&
            provider.currentPrediction?.fixtureStatus != null &&
            (provider.currentPrediction!.fixtureStatus == 'FT' ||
             provider.currentPrediction!.fixtureStatus == 'AET' ||
             provider.currentPrediction!.fixtureStatus == 'PEN'));

    final bool isLive = liveMatch?.isLive == true ||
        (liveMatch?.elapsed != null && liveMatch!.elapsed! > 0);

    final bool isMatchTimePast = (liveMatch?.date != null && DateTime.now().isAfter(liveMatch!.date!)) ||
        (provider.currentPrediction?.matchDate != null && DateTime.now().isAfter(provider.currentPrediction!.matchDate!));

    // 3. Muhtemel 11 (Probable Lineup) oluştur
    final effectiveHomeTeam = homeTeam ??
        (provider.homeTeam != null && TeamNameMatcher.matches(provider.homeTeam!.name, homeTeamName) ? provider.homeTeam : null) ??
        provider.findTeamByName(homeTeamName);
    final effectiveAwayTeam = awayTeam ??
        (provider.awayTeam != null && TeamNameMatcher.matches(provider.awayTeam!.name, awayTeamName) ? provider.awayTeam : null) ??
        provider.findTeamByName(awayTeamName);

    TeamLineup? homeLineup = officialHomeLineup;
    TeamLineup? awayLineup = officialAwayLineup;
    bool isProbable = false;

    if (!isConfirmed && effectiveHomeTeam != null && effectiveAwayTeam != null) {
      if (effectiveHomeTeam.squad.isNotEmpty && effectiveAwayTeam.squad.isNotEmpty) {
        homeLineup = FootballOfflineRepository.generateProbableLineup(effectiveHomeTeam, isHome: true);
        awayLineup = FootballOfflineRepository.generateProbableLineup(effectiveAwayTeam, isHome: false);
        isProbable = true;
      }
    }

    final String statusBadge;
    final Color badgeColor;
    if (isConfirmed) {
      statusBadge = '✅ RESMİ İLK 11 (Açıklandı)';
      badgeColor = Colors.green;
    } else if (isFinished) {
      statusBadge = '🏁 MAÇ BİTTİ (Kadrolar Arşivde)';
      badgeColor = Colors.tealAccent;
    } else if (isLive || isMatchTimePast) {
      statusBadge = '🏟️ OYNANIYOR / KADROLAR SAHADA';
      badgeColor = Colors.amber;
    } else if (isProbable) {
      statusBadge = '📋 MUHTEMEL 11 (Maç Önü)';
      badgeColor = Colors.orangeAccent;
    } else {
      statusBadge = '🕒 Kadro Bekleniyor (Maç Önü)';
      badgeColor = Colors.grey;
    }

    final hasLineupContent = (isConfirmed || isProbable) &&
        homeLineup != null &&
        awayLineup != null &&
        homeLineup.startXI.isNotEmpty &&
        awayLineup.startXI.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_outlined, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Kadro ve Oyuncular', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    if (provider.isLoadingLineups)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Text(
                        statusBadge,
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (fixtureId != null && !isConfirmed) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Resmi Kadroları Kontrol Et',
                        onPressed: provider.isLoadingLineups
                            ? null
                            : () {
                                final apiService = ApiFootballService(apiKey: provider.apiFootballKey);
                                provider.fetchAndAnalyzeLineups(fixtureId!, apiService);
                              },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (hasLineupContent) ...[
              const SizedBox(height: 16),
              _buildLineupHeader(isConfirmed ? 'RESMİ İLK 11 VE DİZİLİŞ' : 'MUHTEMEL İLK 11 (TAKTİK DİZİLİŞ)'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LineupCol(title: homeLineup.teamName, players: homeLineup.startXI, isXI: true)),
                  const VerticalDivider(),
                  Expanded(child: _LineupCol(title: awayLineup.teamName, players: awayLineup.startXI, isXI: true)),
                ],
              ),
              if (homeLineup.substitutes.isNotEmpty || awayLineup.substitutes.isNotEmpty) ...[
                const Divider(height: 24),
                _buildLineupHeader(isConfirmed ? 'RESMİ YEDEKLER' : 'MUHTEMEL YEDEK KULÜBESİ'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _LineupCol(title: '', players: homeLineup.substitutes, isXI: false)),
                    const VerticalDivider(),
                    Expanded(child: _LineupCol(title: '', players: awayLineup.substitutes, isXI: false)),
                  ],
                ),
              ],
              const Divider(height: 24),
              _buildLineupHeader('SAKAT VE CEZALILAR'),
              _buildAbsenteesSection(),
              if (isProbable)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Maç başlamadan yaklaşık 45-60 dakika önce federasyona verilen resmi ilk 11 açıklandığında bu alan otomatik olarak yeşil "RESMİ İLK 11" moduna güncellenecektir.',
                            style: TextStyle(fontSize: 11, color: Colors.orange.shade200, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                isFinished
                    ? 'Karşılaşma tamamlanmıştır. İlk 11 verisi veri akışında ayrıntılı isim listesi olarak yer almamış olsa da maç olayları ve oyuncu hareketleri canlı olarak kaydedilmiştir.'
                    : (isLive || isMatchTimePast
                        ? 'Karşılaşma oynanmaktadır / son düdüğe yaklaşmıştır. Oyuncular sahada mücadele etmektedir.'
                        : 'Maç başlamadan yaklaşık 45-60 dakika önce resmi ilk 11\'ler ve yedekler burada otomatik olarak güncellenecektir.'),
                style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              if (homeInjured.isNotEmpty || awayInjured.isNotEmpty) ...[
                const Divider(height: 24),
                _buildLineupHeader('KULÜP SAKATLIK VE EKSİK LİSTESİ'),
                _buildAbsenteesSection(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.2)),
    );
  }

  Widget _buildAbsenteesSection() {
    if (homeInjured.isEmpty && awayInjured.isEmpty) {
      return const Text('Kritik eksik bulunmuyor.', style: TextStyle(fontSize: 11, color: Colors.grey));
    }

    return Column(
      children: [
        ...homeInjured.map((p) => _AbsenteeTile(teamName: homeTeamName, playerName: p.name, reason: p.injuryReason ?? 'Sakat')),
        ...awayInjured.map((p) => _AbsenteeTile(teamName: awayTeamName, playerName: p.name, reason: p.injuryReason ?? 'Sakat')),
      ],
    );
  }
}

class _AbsenteeTile extends StatelessWidget {
  final String teamName;
  final String playerName;
  final String reason;
  const _AbsenteeTile({required this.teamName, required this.playerName, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.person_off_outlined, size: 14, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text('$teamName: $playerName', style: const TextStyle(fontSize: 11))),
          Text(reason, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class LiveMatchEventsCard extends StatelessWidget {
  final List<MatchEvent> events;
  const LiveMatchEventsCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_toggle_off, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Canlı Maç Akışı', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...events.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text("${e.time}'", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 12)),
                      ),
                      Text(e.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.playerName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            Text(e.teamName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (e.detail != null)
                        Text(e.detail!, style: const TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _LineupCol extends StatelessWidget {
  final String title;
  final List<LineupPlayer> players;
  final bool isXI;
  const _LineupCol({required this.title, required this.players, required this.isXI});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ...players.take(isXI ? 11 : 8).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(p.number?.toString() ?? '•', style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(p.name, style: TextStyle(fontSize: 10.5, color: isXI ? Colors.white : Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            )),
      ],
    );
  }
}
