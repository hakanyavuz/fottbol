import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/team.dart';
import '../models/weather_pitch_condition.dart';
import '../providers/match_prediction_provider.dart';
import 'prediction_screen.dart';

/// Serbest Çarpışma Arenası (Cross-League Head-to-Head & Custom Arena)
class CustomMatchArenaScreen extends StatefulWidget {
  const CustomMatchArenaScreen({super.key});

  @override
  State<CustomMatchArenaScreen> createState() => _CustomMatchArenaScreenState();
}

class _CustomMatchArenaScreenState extends State<CustomMatchArenaScreen> {
  Team? _teamA;
  Team? _teamB;
  bool _isNeutralGround = false;
  WeatherCondition _selectedWeather = WeatherCondition.clear;
  String _selectedReferee = 'Atilla Karaoğlan';

  final List<String> _referees = [
    'Atilla Karaoğlan',
    'Halil Umut Meler',
    'Ali Şansalan',
    'Cihan Aydın',
    'Yasin Kol',
    'Mehmet Türkmen',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<MatchPredictionProvider>();
    _teamA = provider.homeTeam;
    _teamB = provider.awayTeam;

    // Varsayılan takım ataması yoksa popüler takımlardan seç
    if (_teamA == null && provider.allTeams.isNotEmpty) {
      _teamA = provider.allTeams.firstWhere(
        (t) => t.name.contains('Galatasaray'),
        orElse: () => provider.allTeams.first,
      );
    }
    if (_teamB == null && provider.allTeams.length > 1) {
      _teamB = provider.allTeams.firstWhere(
        (t) => t.name.contains('Fenerbahçe') || t.name.contains('Real'),
        orElse: () => provider.allTeams.last,
      );
    }
  }

  void _openTeamSelector(bool isTeamA) {
    final provider = context.read<MatchPredictionProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = provider.allTeams.where((t) {
              return t.name.toLowerCase().contains(query.toLowerCase()) ||
                  t.league.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isTeamA ? '1. Takımı (A) Seç' : '2. Takımı (B) Seç',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Takım veya Lig ara...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        query = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final t = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            child: Text(t.shortName, style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text(t.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(t.league, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          onTap: () {
                            setState(() {
                              if (isTeamA) {
                                _teamA = t;
                              } else {
                                _teamB = t;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _simulateArenaMatch() async {
    if (_teamA == null || _teamB == null) return;
    if (_teamA!.id == _teamB!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen iki farklı takım seçiniz.')),
      );
      return;
    }

    final provider = context.read<MatchPredictionProvider>();
    provider.selectHomeTeam(_teamA!);
    provider.selectAwayTeam(_teamB!);

    final pred = await provider.executePrediction(
      referee: _selectedReferee,
      isNeutralGround: _isNeutralGround,
      weatherCondition: _selectedWeather,
    );

    if (mounted && pred != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PredictionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_kabaddi, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Serbest Çarpışma Arenası'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.15),
                    Colors.deepOrange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Özel Senaryo & Ligler Arası Karşılaşma',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dünyanın dilediğiniz iki takımını seçin; zemin, hava ve hakem şartlarını simüle edin.',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Takım Seçiciler
            Row(
              children: [
                Expanded(
                  child: _buildTeamCard(
                    title: _isNeutralGround ? 'TAKIM A' : 'EV SAHİBİ',
                    team: _teamA,
                    onTap: () => _openTeamSelector(true),
                    color: AppColors.homeTeamColor,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Icon(Icons.close, color: Colors.white38, size: 24),
                      Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.orange)),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildTeamCard(
                    title: _isNeutralGround ? 'TAKIM B' : 'DEPLASMAN',
                    team: _teamB,
                    onTap: () => _openTeamSelector(false),
                    color: AppColors.awayTeamColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Arena Parametreleri Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ ÇARPIŞMA SENARYO AYARLARI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Nötr Saha Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tarafsız Saha (Nötr Zemin)', style: TextStyle(fontSize: 14, color: Colors.white)),
                    subtitle: const Text(
                      'Ev sahibi avantajını sıfırlar (Kupa finali veya Avrupa turnuvası modu)',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                    value: _isNeutralGround,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setState(() {
                        _isNeutralGround = val;
                      });
                    },
                  ),

                  const Divider(color: Colors.white12, height: 24),

                  // Hava & Zemin Koşulu
                  const Text('🌦️ Hava & Zemin Koşulu', style: TextStyle(fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<WeatherCondition>(
                    value: _selectedWeather,
                    dropdownColor: const Color(0xFF1C2128),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: WeatherCondition.values.map((w) {
                      return DropdownMenuItem(
                        value: w,
                        child: Text(w.label, style: const TextStyle(fontSize: 13, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWeather = val);
                    },
                  ),

                  const Divider(color: Colors.white12, height: 24),

                  // Hakem Seçimi
                  const Text('⚖️ Maçın Hakemi', style: TextStyle(fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReferee,
                    dropdownColor: const Color(0xFF1C2128),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _referees.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 13, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReferee = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Simüle Et Butonu
            Consumer<MatchPredictionProvider>(
              builder: (context, provider, _) {
                final isLoading = provider.isPredicting;
                return FilledButton.icon(
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.bolt, color: Colors.black, size: 22),
                  label: Text(
                    isLoading ? 'Hesaplanıyor...' : '⚔️ ARENADA ÇARPIŞTIR & SİMÜLE ET',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isLoading ? null : _simulateArenaMatch,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required String title,
    required Team? team,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.15),
              child: team != null
                  ? Text(
                      team.shortName,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : const Icon(Icons.add, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              team?.name ?? 'Takım Seç',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              team?.league ?? 'Tıkla ve değiştir',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
