import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'core/theme/app_theme.dart';
import 'core/cache/cache_manager.dart';
import 'providers/theme_provider.dart';
import 'providers/match_prediction_provider.dart';
import 'providers/global_football_providers.dart';
import 'services/storage_service.dart';
import 'views/home_nav_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheManager.init(); // Hive 12 saatlik önbellek motorunu başlat
  await CacheManager.purgeExpired(); // Çok eski kayıtları temizle

  // API-Football anahtarı Riverpod ağacına açılıştan önce enjekte edilir;
  // aksi halde ülke/lig/takım servisleri anahtarsız (demo) modda başlar.
  final savedKeys = await StorageService.getApiKeys();

  runApp(
    ProviderScope(
      overrides: [
        apiFootballKeyProvider.overrideWith((ref) => savedKeys['apiFootball'] ?? ''),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => MatchPredictionProvider()),
        ],
        child: const FootballPredictionApp(),
      ),
    ),
  );
}

class FootballPredictionApp extends StatelessWidget {
  const FootballPredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Futbol Maç & Skor Tahmini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeNavScreen(),
    );
  }
}
