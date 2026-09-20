import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/global_football_providers.dart';
import '../widgets/search_bar_with_debounce.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/quota_warning_banner.dart';
import 'league_list_screen.dart';

/// 1. Aşama: 200+ Dünya Ülkesi Seçim Ekranı (Arama + Bayraklar + Lazy Loading)
class CountryListScreen extends ConsumerWidget {
  const CountryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Ülke Seçimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(countriesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu (300ms Debounce)
          SearchBarWithDebounce(
            hintText: 'Ülke ara (Örn: Turkey, England, Spain...)',
            initialValue: ref.read(countrySearchQueryProvider),
            onChanged: (val) {
              ref.read(countrySearchQueryProvider.notifier).state = val;
            },
          ),

          // Ülke Listesi ve Durum Yönetimi (Riverpod AsyncValue)
          Expanded(
            child: countriesAsync.when(
              loading: () => const SkeletonLoadingList(itemCount: 10),
              error: (err, stack) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QuotaWarningBanner(
                          message: err.toString(),
                          isUsingCache: false,
                          onRetry: () => ref.invalidate(countriesProvider),
                        ),
                      ],
                    ),
                  ),
                );
              },
              data: (countries) {
                if (countries.isEmpty) {
                  return const Center(
                    child: Text('Aradığınız kriterde ülke bulunamadı.'),
                  );
                }

                return ListView.separated(
                  itemCount: countries.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final country = countries[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: _CountryFlag(flagUrl: country.flag, code: country.code),
                      title: Text(
                        country.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: country.code != null
                          ? Text('Kod: ${country.code}', style: const TextStyle(fontSize: 12, color: Colors.grey))
                          : null,
                      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      onTap: () {
                        ref.read(selectedCountryProvider.notifier).state = country;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeagueListScreen(country: country),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryFlag extends StatelessWidget {
  final String? flagUrl;
  final String? code;

  const _CountryFlag({this.flagUrl, this.code});

  @override
  Widget build(BuildContext context) {
    if (flagUrl != null && flagUrl!.isNotEmpty && !flagUrl!.endsWith('.svg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          flagUrl!,
          width: 32,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 32,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          code ?? '🌍',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
