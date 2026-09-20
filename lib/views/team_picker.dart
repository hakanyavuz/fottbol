import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../core/constants/app_colors.dart';
import '../core/network/api_exceptions.dart';
import '../models/api_team.dart';
import '../models/team.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';

/// API-Football takımını gerçek sezon istatistikleri, kadrosu ve sakatlıklarıyla
/// birlikte çekip maçın ev sahibi/deplasman takımı olarak seçer.
///
/// [leagueId] biliniyorsa (lig listesinden gelindiyse) doğrudan kullanılır;
/// bilinmiyorsa (global arama) takımın ligi otomatik tespit edilir.
/// Veri çekilemezse takım yine seçilir, ancak lig ortalaması baz alınır ve
/// kullanıcı bilgilendirilir — uydurma istatistik üretilmez.
Future<void> pickApiTeam({
  required BuildContext context,
  required WidgetRef ref,
  required ApiTeam apiTeam,
  required bool asHome,
  required int season,
  int? leagueId,
  String? leagueName,
  bool popToRoot = true,
}) async {
  final service = ref.read(apiFootballServiceProvider);
  final predictionProvider = context.read<MatchPredictionProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  Team team;
  String? warning;

  try {
    team = leagueId != null
        ? await service.buildTeam(
            apiTeam: apiTeam,
            leagueId: leagueId,
            season: season,
            leagueName: leagueName ?? 'Lig',
          )
        : await service.buildTeamAutoLeague(apiTeam: apiTeam, season: season);
  } on ApiQuotaExceededException catch (e) {
    team = apiTeam.toTeam(leagueName: leagueName ?? apiTeam.country);
    warning = e.message;
  } catch (_) {
    team = apiTeam.toTeam(leagueName: leagueName ?? apiTeam.country);
    warning = service.hasKey
        ? 'İstatistikler alınamadı.'
        : 'Gerçek istatistikler için Ayarlar ekranından API-Football anahtarı girin.';
  }

  if (asHome) {
    predictionProvider.selectHomeTeam(team);
  } else {
    predictionProvider.selectAwayTeam(team);
  }

  final role = asHome ? 'EV SAHİBİ' : 'DEPLASMAN';
  final hasRealStats = team.stats.hasData;

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        hasRealStats
            ? '${apiTeam.name} $role olarak seçildi (${team.stats.played} maçlık gerçek sezon verisi).'
            : '${apiTeam.name} $role olarak seçildi. ${warning ?? 'Sezon istatistiği bulunamadı, lig ortalaması kullanılacak.'}',
      ),
      duration: Duration(milliseconds: hasRealStats ? 1800 : 3200),
      backgroundColor: hasRealStats
          ? (asHome ? AppColors.homeTeamColor : AppColors.awayTeamColor)
          : Colors.orange.shade800,
    ),
  );

  if (popToRoot) {
    navigator.popUntil((route) => route.isFirst);
  }
}
