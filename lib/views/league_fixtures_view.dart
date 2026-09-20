import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../core/constants/app_colors.dart';
import '../models/fixture.dart';
import '../models/league.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';
import '../widgets/fixture_tile.dart';
import '../widgets/quota_warning_banner.dart';
import '../widgets/skeleton_loading.dart';
import 'prediction_screen.dart';

/// Ligin yaklaşan maçları ve son sonuçları.
///
/// Yaklaşan bir maça "Tahmin" denildiğinde iki takım gerçek verileriyle
/// hazırlanır, tahmin üretilir ve fikstür kimliğiyle kaydedilir; maç
/// oynandıktan sonra Geçmiş ekranında gerçek sonuçla karşılaştırılır.
class LeagueFixturesView extends ConsumerStatefulWidget {
  final League league;
  final int season;

  const LeagueFixturesView({super.key, required this.league, required this.season});

  @override
  ConsumerState<LeagueFixturesView> createState() => _LeagueFixturesViewState();
}

class _LeagueFixturesViewState extends ConsumerState<LeagueFixturesView> {
  bool _showUpcoming = true;
  int? _busyFixtureId;

  LeagueSeasonParams get _params =>
      LeagueSeasonParams(leagueId: widget.league.id, season: widget.season);

  Future<void> _predict(Fixture fixture) async {
    final provider = context.read<MatchPredictionProvider>();
    final service = ref.read(apiFootballServiceProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busyFixtureId = fixture.id);
    final result = await provider.predictFixture(fixture, service);
    if (!mounted) return;
    setState(() => _busyFixtureId = null);

    if (result != null) {
      navigator.push(MaterialPageRoute(builder: (_) => const PredictionScreen()));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Tahmin oluşturulamadı.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fixturesAsync = ref.watch(
      _showUpcoming ? upcomingFixturesProvider(_params) : recentFixturesProvider(_params),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yaklaşan'), icon: Icon(Icons.event)),
              ButtonSegment(value: false, label: Text('Sonuçlar'), icon: Icon(Icons.scoreboard_outlined)),
            ],
            selected: {_showUpcoming},
            onSelectionChanged: (value) => setState(() => _showUpcoming = value.first),
          ),
        ),
        Expanded(
          child: fixturesAsync.when(
                  loading: () => const SkeletonLoadingList(itemCount: 6),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QuotaWarningBanner(
                        message: err.toString(),
                        isUsingCache: false,
                        onRetry: () => ref.invalidate(
                          _showUpcoming
                              ? upcomingFixturesProvider(_params)
                              : recentFixturesProvider(_params),
                        ),
                      ),
                    ),
                  ),
                  data: (fixtures) {
                    if (fixtures.isEmpty) {
                      return _EmptyFixtures(upcoming: _showUpcoming, season: widget.season);
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        final provider = _showUpcoming
                            ? upcomingFixturesProvider(_params)
                            : recentFixturesProvider(_params);
                        ref.invalidate(provider);
                        await ref.read(provider.future);
                      },
                      child: _GroupedFixtureList(
                        fixtures: fixtures,
                        busyFixtureId: _busyFixtureId,
                        onPredict: _busyFixtureId == null ? _predict : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Maçları gün başlıklarıyla gruplayarak listeler
class _GroupedFixtureList extends StatelessWidget {
  final List<Fixture> fixtures;
  final int? busyFixtureId;
  final void Function(Fixture)? onPredict;

  const _GroupedFixtureList({
    required this.fixtures,
    required this.busyFixtureId,
    required this.onPredict,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    String? currentDay;

    for (final fixture in fixtures) {
      final dayLabel = turkishDayLabel(fixture.date);
      if (dayLabel != currentDay) {
        currentDay = dayLabel;
        items.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
            child: Text(
              dayLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }

      items.add(
        FixtureTile(
          fixture: fixture,
          isBusy: busyFixtureId == fixture.id,
          onPredict: onPredict == null ? null : () => onPredict!(fixture),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: items,
    );
  }
}

/// Yerel ayar verisi yüklemeye gerek kalmadan Türkçe gün başlığı üretir
/// (örn. "Bugün", "Yarın", "13 Eylül Cumartesi").
String turkishDayLabel(DateTime? date, [DateTime? now]) {
  if (date == null) return 'Tarih belirsiz';

  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  const weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  final today = now ?? DateTime.now();
  final d0 = DateTime(today.year, today.month, today.day);
  final d1 = DateTime(date.year, date.month, date.day);
  final diff = d1.difference(d0).inDays;

  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Yarın';
  if (diff == -1) return 'Dün';
  return '${date.day} ${months[date.month - 1]} ${weekdays[date.weekday - 1]}';
}

class _EmptyFixtures extends StatelessWidget {
  final bool upcoming;
  final int season;

  const _EmptyFixtures({required this.upcoming, required this.season});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          upcoming
              ? '$season sezonunda bu lig için planlanmış maç bulunamadı.\nSezon bitmiş ya da fikstür henüz açıklanmamış olabilir.'
              : '$season sezonunda bu ligde oynanmış maç bulunamadı.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}
