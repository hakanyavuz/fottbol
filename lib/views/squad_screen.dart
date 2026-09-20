import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/team.dart';
import '../providers/match_prediction_provider.dart';
import '../widgets/player_card.dart';

/// 3. Ekran: Kadro ve Oyuncu Performans Verileri Ekranı
///
/// Gösterilen takım her zaman [team] parametresidir. Bu takım maçın ev sahibi
/// veya deplasmanı olarak seçiliyse provider'daki canlı kaydı (sakatlık
/// simülasyonuyla birlikte) gösterilir; seçili değilse yalnızca görüntülenir.
class SquadScreen extends StatefulWidget {
  final Team team;

  const SquadScreen({super.key, required this.team});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  String _selectedPosition = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchPredictionProvider>();

    // Sakatlık güncellemelerini yansıtmak için takımın canlı kaydını kullan
    final currentTeam = provider.selectedTeamById(widget.team.id) ?? widget.team;
    final canSimulate = provider.isTeamSelected(widget.team.id);

    final filteredSquad = currentTeam.squad.where((p) {
      if (_selectedPosition == 'Tümü') return true;
      return p.position == _selectedPosition;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentTeam.shortName} Kadrosu'),
      ),
      body: Column(
        children: [
          // Sakatlık Simülasyon Bilgilendirme Kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (canSimulate ? AppColors.primary : Colors.amber).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (canSimulate ? AppColors.primary : Colors.amber).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canSimulate ? Icons.info_outline : Icons.lock_outline,
                  color: canSimulate ? AppColors.primary : Colors.amber,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    canSimulate
                        ? 'İpucu: Oyuncu yanındaki tıbbi ikona basarak sakatlık simülasyonu yapabilirsiniz. Bu durum Poisson skor tahmin algoritmasını anında etkiler.'
                        : 'Bu takım maçta seçili değil. Sakatlık simülasyonu için önce takımı EV veya DEP olarak seçin.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Pozisyon Filtreleme Çipleri
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Tümü', 'Forvet', 'Orta Saha', 'Defans', 'Kaleci'].map((pos) {
                final isSelected = _selectedPosition == pos;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(pos),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedPosition = pos;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Oyuncular Listesi
          Expanded(
            child: filteredSquad.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        currentTeam.squad.isEmpty
                            ? 'Bu takım için oyuncu verisi bulunamadı.\nAyrıntılı kadro ve sakatlık verisi API-Football anahtarı ile gelir.'
                            : 'Bu pozisyonda kayıtlı oyuncu bulunamadı.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSquad.length,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemBuilder: (context, index) {
                      final player = filteredSquad[index];
                      return PlayerCard(
                        player: player,
                        onToggleInjury: canSimulate
                            ? () => provider.togglePlayerInjury(currentTeam.id, player.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
