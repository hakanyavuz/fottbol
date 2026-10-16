import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/prediction_result.dart';
import '../models/team.dart';

/// Kilit Oyuncu Düellosu, Sakat/Cezalı Eksikler ve Son 5/10 İç-Dış Saha Form Karşılaştırma Kartı
/// Tüm hesaplamalar %100 deterministik Dart kodunda yapılır.
class PlayerAndFormComparisonCard extends StatelessWidget {
  final PredictionResult prediction;

  const PlayerAndFormComparisonCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final home = prediction.homeTeam;
    final away = prediction.awayTeam;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DETAYLI FORM (SON 5/10) & OYUNCU DÜELLOSU',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'İç Saha / Deplasman Ayrımı, Kilit Yıldızlar ve Cezalı/Sakat Etkisi',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // 1. İÇ SAHA vs DEPLASMAN PERFORMANS VE SON 5/10 MAÇ FORMU
          _buildSectionTitle('1. İç Saha vs Deplasman & Son 10 Maç Formu', isDark),
          const SizedBox(height: 10),
          _buildStatComparisonRow(
            label: 'Saha Maç Başı Puan (İç vs Dış)',
            homeVal: '${home.stats.homePointsPerGame.toStringAsFixed(2)} PPG',
            awayVal: '${away.stats.awayPointsPerGame.toStringAsFixed(2)} PPG',
            homeRatio: home.stats.homePointsPerGame / 3.0,
            awayRatio: away.stats.awayPointsPerGame / 3.0,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildStatComparisonRow(
            label: 'Saha Gol Ortalaması (İç vs Dış)',
            homeVal: '${home.stats.avgHomeGoalsScored.toStringAsFixed(2)} Gol',
            awayVal: '${away.stats.avgAwayGoalsScored.toStringAsFixed(2)} Gol',
            homeRatio: (home.stats.avgHomeGoalsScored / 3.0).clamp(0.0, 1.0),
            awayRatio: (away.stats.avgAwayGoalsScored / 3.0).clamp(0.0, 1.0),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormBadgesBox(
                  title: '${home.shortName} İç Saha Son 5',
                  form: home.stats.effectiveHomeForm,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormBadgesBox(
                  title: '${away.shortName} Deplasman Son 5',
                  form: away.stats.effectiveAwayForm,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormBadgesBox(
                  title: '${home.shortName} Genel Son 10 (${_calcPts(home.stats.effectiveLast10Form)}p)',
                  form: home.stats.effectiveLast10Form,
                  isDark: isDark,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormBadgesBox(
                  title: '${away.shortName} Genel Son 10 (${_calcPts(away.stats.effectiveLast10Form)}p)',
                  form: away.stats.effectiveLast10Form,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // 2. KİLİT OYUNCU KARŞILAŞTIRMASI (GOL KRALLARI & OYUN KURUCULAR)
          _buildSectionTitle('2. Kilit Oyuncu Karşılaştırması (Sağlam Kadro)', isDark),
          const SizedBox(height: 10),
          _buildPlayerDuelSection(home, away, isDark),

          const Divider(height: 24),

          // 3. SAKAT / CEZALI / EKSİK OYUNCULAR VE GÜÇ KAYBI
          _buildSectionTitle('3. Sakat, Cezalı ve Eksik Oyuncu Etkisi', isDark),
          const SizedBox(height: 8),
          _buildMissingPlayersSection(home, away, isDark),
        ],
      ),
    );
  }

  int _calcPts(List<String> form) {
    int pts = 0;
    for (final r in form) {
      if (r == 'W') pts += 3;
      if (r == 'D') pts += 1;
    }
    return pts;
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      ),
    );
  }

  Widget _buildStatComparisonRow({
    required String label,
    required String homeVal,
    required String awayVal,
    required double homeRatio,
    required double awayRatio,
    required bool isDark,
  }) {
    final total = (homeRatio + awayRatio) > 0 ? (homeRatio + awayRatio) : 1.0;
    final hFlex = ((homeRatio / total) * 100).round().clamp(15, 85);
    final aFlex = 100 - hFlex;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeVal,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.greenAccent : Colors.green.shade700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              awayVal,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amberAccent : Colors.orange.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: hFlex,
                child: Container(height: 6, color: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: aFlex,
                child: Container(height: 6, color: const Color(0xFFF59E0B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormBadgesBox({
    required String title,
    required List<String> form,
    required bool isDark,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: compact ? 3 : 4,
            runSpacing: 3,
            children: form.map((res) {
              final Color bg = res == 'W'
                  ? const Color(0xFF10B981)
                  : res == 'D'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);
              return Container(
                width: compact ? 16 : 20,
                height: compact ? 16 : 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  res == 'W' ? 'G' : (res == 'D' ? 'B' : 'M'),
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDuelSection(Team home, Team away, bool isDark) {
    final hHealthy = home.squad.where((p) => !p.isInjured).toList();
    final aHealthy = away.squad.where((p) => !p.isInjured).toList();

    if (hHealthy.isEmpty || aHealthy.isEmpty) {
      return Text(
        'Kadro oyuncu istatistikleri yüklenemedi.',
        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
      );
    }

    final hScorers = [...hHealthy]..sort((a, b) => b.goals.compareTo(a.goals));
    final aScorers = [...aHealthy]..sort((a, b) => b.goals.compareTo(a.goals));

    final hPlaymakers = [...hHealthy]..sort((a, b) => b.assists.compareTo(a.assists));
    final aPlaymakers = [...aHealthy]..sort((a, b) => b.assists.compareTo(a.assists));

    final hTopRated = [...hHealthy]..sort((a, b) => b.rating.compareTo(a.rating));
    final aTopRated = [...aHealthy]..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      children: [
        _buildPlayerDuelRow(
          role: '⚽ Gol Lideri',
          homePlayer: hScorers.first,
          awayPlayer: aScorers.first,
          statBuilder: (p) => '${p.goals} Gol / ${p.assists} Asist',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildPlayerDuelRow(
          role: '🎯 Asist / Oyun Kurucu',
          homePlayer: hPlaymakers.first,
          awayPlayer: aPlaymakers.first,
          statBuilder: (p) => '${p.assists} Asist (${p.rating.toStringAsFixed(1)})',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildPlayerDuelRow(
          role: '⭐ En Yüksek Reyting',
          homePlayer: hTopRated.first,
          awayPlayer: aTopRated.first,
          statBuilder: (p) => '${p.position} • ${p.rating.toStringAsFixed(1)} Puan',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPlayerDuelRow({
    required String role,
    required Player homePlayer,
    required Player awayPlayer,
    required String Function(Player) statBuilder,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homePlayer.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  statBuilder(homePlayer),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  awayPlayer.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
                Text(
                  statBuilder(awayPlayer),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFFF59E0B)),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingPlayersSection(Team home, Team away, bool isDark) {
    final hInjured = home.squad.where((p) => p.isInjured).toList();
    final aInjured = away.squad.where((p) => p.isInjured).toList();

    double hPenalty = 0.0;
    for (final p in hInjured) {
      hPenalty += p.dynamicAttackPenalty(home.stats.goalsScored) * 100.0;
    }
    double aPenalty = 0.0;
    for (final p in aInjured) {
      aPenalty += p.dynamicAttackPenalty(away.stats.goalsScored) * 100.0;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTeamMissingColumn(
            teamName: home.name,
            missing: hInjured,
            penaltyPct: hPenalty,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTeamMissingColumn(
            teamName: away.name,
            missing: aInjured,
            penaltyPct: aPenalty,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMissingColumn({
    required String teamName,
    required List<Player> missing,
    required double penaltyPct,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: missing.isEmpty
            ? (isDark ? Colors.green.withValues(alpha: 0.06) : Colors.green.shade50)
            : (isDark ? Colors.red.withValues(alpha: 0.08) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          if (missing.isEmpty)
            const Text(
              '✅ Tam Kadro (Eksik/Cezalı Yok)',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF10B981)),
            )
          else ...[
            Text(
              '⚠️ Hücum Gücü Kaybı: -%${penaltyPct.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 4),
            ...missing.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• ${p.name} (${p.position} - ${p.goals}G) [${p.injuryReason ?? "Sakat/Cezalı"}]',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
