import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/fixture.dart';
import '../services/in_play_engine.dart';
import '../widgets/match_probability_chart.dart';
import '../widgets/momentum_graph.dart';
import '../models/prediction_result.dart';
import '../models/team.dart';
import '../models/match_stat.dart';
import '../providers/match_prediction_provider.dart';
import 'prediction_screen.dart';

class LiveAnalysisScreen extends StatefulWidget {
  final Fixture fixture;
  const LiveAnalysisScreen({super.key, required this.fixture});

  @override
  State<LiveAnalysisScreen> createState() => _LiveAnalysisScreenState();
}

class _LiveAnalysisScreenState extends State<LiveAnalysisScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData();
    });

    // Her 12 saniyede bir kadroları ve maç akışını canlı yenile
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _fetchData() {
    final provider = context.read<MatchPredictionProvider>();
    provider.fetchAndAnalyzeLineups(widget.fixture.id, null, widget.fixture.leagueCode);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MatchPredictionProvider>(context);

    // Provider'daki güncel canlı maç verisini bulalım
    final liveMatch = provider.liveFixtures.firstWhere(
      (f) => f.id == widget.fixture.id,
      orElse: () => widget.fixture,
    );

    // Maçın pre-match gücünü (lambda) tahmin motorundan veya varsayılanlardan alalım
    double homeLambda = 1.6;
    double awayLambda = 1.1;

    final existingPred = provider.pastPredictions.cast<PredictionResult?>().firstWhere(
      (p) => p?.fixtureId == liveMatch.id,
      orElse: () => null,
    );

    if (existingPred != null) {
      homeLambda = existingPred.lambdaHome;
      awayLambda = existingPred.lambdaAway;
    }

    // Kırmızı kartlar ve kadro eksiklerini doğrudan Poisson/InPlay motoruna bağla
    final analysis = InPlayEngine.calculateLiveProbabilities(
      currentHomeGoals: liveMatch.homeGoals ?? 0,
      currentAwayGoals: liveMatch.awayGoals ?? 0,
      elapsedMinutes: liveMatch.elapsed ?? 45,
      preMatchLambdaHome: homeLambda,
      preMatchLambdaAway: awayLambda,
      homeRedCards: liveMatch.homeRedCards,
      awayRedCards: liveMatch.awayRedCards,
      homeYellowCards: liveMatch.homeYellowCards,
      awayYellowCards: liveMatch.awayYellowCards,
      homeTeamName: liveMatch.homeTeamName,
      awayTeamName: liveMatch.awayTeamName,
    );

    final dummyResult = PredictionResult(
      id: 'live',
      homeTeam: Team(
        id: '1',
        name: liveMatch.homeTeamName,
        shortName: '',
        crestUrl: liveMatch.homeTeamLogo,
        league: liveMatch.leagueName,
        venue: liveMatch.venueName ?? '',
        stats: MatchStat.unknown(),
        squad: [],
      ),
      awayTeam: Team(
        id: '2',
        name: liveMatch.awayTeamName,
        shortName: '',
        crestUrl: liveMatch.awayTeamLogo,
        league: liveMatch.leagueName,
        venue: liveMatch.venueName ?? '',
        stats: MatchStat.unknown(),
        squad: [],
      ),
      predictedHomeGoals: 0,
      predictedAwayGoals: 0,
      lambdaHome: analysis.lambdaHomeRem,
      lambdaAway: analysis.lambdaAwayRem,
      homeWinProbability: analysis.homeWinProb,
      drawProbability: analysis.drawProb,
      awayWinProbability: analysis.awayWinProb,
      over25Probability: 0,
      bothTeamsToScoreProbability: 0,
      topScores: [],
      mathematicalRationale: [
        if (analysis.cardRationale != null) analysis.cardRationale!,
        'Kalan dakikalara ve kadro durumuna göre dinamik Poisson matrisi',
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 ANLIK TAHMİN ANALİZİ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLiveScoreCard(liveMatch),
            const SizedBox(height: 16),

            // Kırmızı Kart veya Eksik Etki Kartı
            if (analysis.cardRationale != null)
              _buildCardImpactCard(analysis),

            _buildStatusBanner(analysis),
            const SizedBox(height: 16),

            // CANLI KADRO TAKİBİ
            LiveLineupTrackerCard(
              fixtureId: liveMatch.id,
              homeTeamName: liveMatch.homeTeamName,
              awayTeamName: liveMatch.awayTeamName,
            ),

            // CANLI MAÇ OLAYLARI
            if (provider.getEventsForFixture(liveMatch.id).isNotEmpty)
              LiveMatchEventsCard(events: provider.getEventsForFixture(liveMatch.id)),

            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.premiumGold, size: 18),
                SizedBox(width: 8),
                Text('CANLI BASKI MOMENTUMU',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: MomentumGraph(),
              ),
            ),

            const SizedBox(height: 24),
            const Text('KALAN SÜRE VE KARTLARA GÖRE İHTİMALLER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MatchProbabilityChart(prediction: dummyResult),
              ),
            ),

            const SizedBox(height: 24),
            _buildInsightCard(analysis, liveMatch),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImpactCard(InPlayAnalysis analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🟥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KIRMIZI KART VE EKSİK ETKİSİ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.cardRationale ?? '',
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScoreCard(Fixture f) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${f.leagueName} ${f.leagueCountry.isNotEmpty ? '• ${f.leagueCountry}' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (f.homeTeamLogo.isNotEmpty)
                      Image.network(f.homeTeamLogo, width: 36, height: 36,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    const SizedBox(height: 6),
                    Text(
                      f.homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (f.homeRedCards > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text('🟥 ${f.homeRedCards} Kırmızı',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  '${f.homeGoals ?? 0} - ${f.awayGoals ?? 0}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (f.awayTeamLogo.isNotEmpty)
                      Image.network(f.awayTeamLogo, width: 36, height: 36,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    const SizedBox(height: 6),
                    Text(
                      f.awayTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (f.awayRedCards > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: Text('🟥 ${f.awayRedCards} Kırmızı',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              f.elapsed != null ? "${f.elapsed}'" : f.statusLabel,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(InPlayAnalysis analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('MOMENTUM: ${analysis.momentum}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(InPlayAnalysis analysis, Fixture f) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text('🤖 AI & Taktik Canlı Analizi', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Maçın ${f.elapsed ?? 90}. dakikasında skor ${f.homeGoals ?? 0}-${f.awayGoals ?? 0}. '
              '${f.homeRedCards > 0 ? "${f.homeTeamName} takımının gördüğü kırmızı kart hücum gücünü -%35 düşürdü. " : ""}'
              '${f.awayRedCards > 0 ? "${f.awayTeamName} takımının gördüğü kırmızı kart hücum gücünü -%35 düşürdü. " : ""}'
              'Modelimiz kalan sürede ${_getRecommendation(analysis, f)}. '
              'En güçlü senaryo güven skoru: %${(analysis.homeWinProb > analysis.awayWinProb ? analysis.homeWinProb : analysis.awayWinProb).toStringAsFixed(0)}.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendation(InPlayAnalysis a, Fixture f) {
    if (a.drawProb > 40) return "beraberliğin bozulmayacağını öngörüyor";
    if (a.homeWinProb > 60) return "${f.homeTeamName} galibiyetine yakın duruyor";
    if (a.awayWinProb > 60) return "${f.awayTeamName} üstünlüğünü koruyacak gibi görünüyor";
    return "tempolu ve gollü bir oyun bekliyor";
  }
}
