import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/league_constants.dart';
import '../models/fixture.dart';
import '../models/odds_comparison.dart';
import '../models/prediction_result.dart';
import '../models/value_bet.dart';
import '../providers/global_football_providers.dart';
import '../services/poisson_engine.dart';
import '../services/real_sports_live_service.dart';
import '../widgets/value_bet_card.dart';
import 'prediction_screen.dart';

/// Değerli Bahis (Value Bet) Radarı — Piyasa oranları ile Poisson ihtimallerini kıyaslar
class ValueBetRadarScreen extends ConsumerStatefulWidget {
  const ValueBetRadarScreen({super.key});

  @override
  ConsumerState<ValueBetRadarScreen> createState() => _ValueBetRadarScreenState();
}

class _ValueBetRadarScreenState extends ConsumerState<ValueBetRadarScreen> {
  bool _isScanning = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedCountry = 'Tümü';
  double _minEdge = 5.0; // Asgari %5 matematiksel avantaj

  List<ValueBet> _allDetectedBets = [];
  Map<ValueBet, PredictionResult> _betPredictions = {};
  int _scannedMatchCount = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanForValue();
    });
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    _scanForValue();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _scanForValue();
    }
  }

  Future<void> _scanForValue() async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    try {
      final footballService = ref.read(apiFootballServiceProvider);

      // 1. Önce gerçek ESPN maçlarını çek
      List<Fixture> fixtures = await RealSportsLiveService.getLiveFixtures(date: _selectedDate);

      // 2. Boşsa API-Football'dan dene
      if (fixtures.isEmpty) {
        fixtures = await footballService.getFixturesByDate(_selectedDate);
      }

      final List<ValueBet> results = [];
      final Map<ValueBet, PredictionResult> betPreds = {};
      _scannedMatchCount = fixtures.length;

      // En önemli 35 maçı tara (Performans ve akıcılık için)
      final scanList = fixtures.take(35).toList();

      for (var f in scanList) {
        try {
          final teams = await footballService.buildTeamsForFixture(f).timeout(const Duration(seconds: 3));

          final pred = PoissonEngine.calculatePrediction(
            homeTeam: teams.home,
            awayTeam: teams.away,
            fixtureId: f.id,
            matchDate: f.date,
          );

          // Oranları çek veya simüle et
          final odds = footballService.simulateMarketOdds(lambdaHome: pred.lambdaHome, lambdaAway: pred.lambdaAway);
          pred.oddsComparison = OddsComparison.fromModelAndOdds(
            odds: odds,
            modelHomeProb: pred.homeWinProbability,
            modelDrawProb: pred.drawProbability,
            modelAwayProb: pred.awayWinProbability,
          );

          final found = ValueBet.findValueBets(pred, minEdge: _minEdge);
          for (var vb in found) {
            results.add(vb);
            betPreds[vb] = pred;
          }
        } catch (_) {}
      }

      results.sort((a, b) => b.edgePercentage.compareTo(a.edgePercentage));

      if (mounted) {
        setState(() {
          _allDetectedBets = results;
          _betPredictions = betPreds;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  List<ValueBet> get _filteredBets {
    if (_selectedCountry == 'Tümü') return _allDetectedBets;
    return _allDetectedBets.where((b) {
      final pred = _betPredictions[b];
      if (pred == null) return true;
      final league = pred.homeTeam.league;
      return LeagueConstants.countryMatches(league, _selectedCountry);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBets;
    final maxEdge = filtered.isNotEmpty ? filtered.first.edgePercentage : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('DEĞERLİ BAHİS RADARI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yeniden Tara',
            onPressed: _isScanning ? null : _scanForValue,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tarih Gezinme Çubuğu
          _buildDateBar(),

          // 2. Ülke & Hassasiyet Filtresi
          _buildFilterBar(),

          // 3. Özet İstatistik Çubuğu
          if (!_isScanning && filtered.isNotEmpty)
            _buildSummaryStats(filtered.length, maxEdge),

          // 4. Ana Liste
          Expanded(
            child: _isScanning
                ? _buildScanningState()
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final bet = filtered[index];
                          final pred = _betPredictions[bet];
                          return ValueBetCard(
                            bet: bet,
                            onTap: pred != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PredictionScreen(historyItem: pred),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar() {
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Önceki Gün',
            onPressed: _isScanning ? null : () => _changeDate(-1),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isScanning ? null : _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('BUGÜN', style: TextStyle(fontSize: 9.5, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Sonraki Gün',
            onPressed: _isScanning ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final countries = [
      'Tümü', 'Turkey', 'England', 'Spain', 'Germany', 'Italy', 'France', 'Netherlands'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: countries.map((c) {
                final isSel = _selectedCountry == c;
                final label = c == 'Turkey' ? '🇹🇷 Türkiye'
                    : c == 'England' ? '🏴󠁧󠁢󠁥󠁮󠁧󠁿 İngiltere'
                    : c == 'Spain' ? '🇪🇸 İspanya'
                    : c == 'Germany' ? '🇩🇪 Almanya'
                    : c == 'Italy' ? '🇮🇹 İtalya'
                    : c == 'France' ? '🇫🇷 Fransa'
                    : c == 'Netherlands' ? '🇳🇱 Hollanda'
                    : '🌍 Tümü';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    selectedColor: Colors.greenAccent.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSel ? Colors.greenAccent : null, fontSize: 11),
                    onSelected: (_) => setState(() => _selectedCountry = c),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Asgari Avantaj Eşiği:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Wrap(
                  spacing: 4,
                  children: [3.0, 5.0, 8.0, 12.0].map((edge) {
                    final isEdgeSel = _minEdge == edge;
                    return ActionChip(
                      label: Text('%${edge.toInt()}+', style: TextStyle(fontSize: 10.5, color: isEdgeSel ? Colors.black : Colors.white70)),
                      backgroundColor: isEdgeSel ? Colors.greenAccent : Theme.of(context).cardColor,
                      onPressed: () {
                        setState(() => _minEdge = edge);
                        _scanForValue();
                      },
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int count, double maxEdge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.greenAccent.withOpacity(0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                '$_scannedMatchCount Maç Tarandı • $count Değerli Bahis Bulundu',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          Text(
            'En Yüksek: +%${maxEdge.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PİYASA VE MODEL ORANLARI TARANIYOR...',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Seçilen tarihteki karşılaşmalar Poisson dağılımı ile kıyaslanıyor...',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year} tarihinde %${_minEdge.toInt()} ve üzeri değerli bahis bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eşik değerini düşürebilir (%3+) veya başka bir güne geçebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tekrar Tara'),
              style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              onPressed: _scanForValue,
            ),
          ],
        ),
      ),
    );
  }
}
