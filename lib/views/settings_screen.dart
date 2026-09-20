import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import '../core/cache/cache_manager.dart';
import '../core/constants/app_colors.dart';
import '../providers/global_football_providers.dart';
import '../providers/match_prediction_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import 'history_screen.dart';

/// Ayarlar Ekranı: Tema Değişimi, AI Entegrasyonu ve Veri Yönetimi
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _geminiKeyCtrl;
  bool _isSaving = false;
  bool _isLoadingPrefs = true;

  // Kullanıcı tercihleri
  bool _goalAlertEnabled = true;
  bool _redCardAlertEnabled = true;
  bool _favoriteOnlyAlerts = false;
  int _refreshIntervalSeconds = 30;
  String _riskProfile = 'Dengeli';
  String _defaultLeague = 'Tümü';

  @override
  void initState() {
    super.initState();
    final provider = context.read<MatchPredictionProvider>();
    _geminiKeyCtrl = TextEditingController(text: provider.geminiApiKey);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final goal = await StorageService.getGoalAlertEnabled();
    final red = await StorageService.getRedCardAlertEnabled();
    final favOnly = await StorageService.getFavoriteOnlyAlerts();
    final refresh = await StorageService.getRefreshIntervalSeconds();
    final risk = await StorageService.getRiskProfile();
    final league = await StorageService.getDefaultLeague();

    if (mounted) {
      setState(() {
        _goalAlertEnabled = goal;
        _redCardAlertEnabled = red;
        _favoriteOnlyAlerts = favOnly;
        _refreshIntervalSeconds = refresh;
        _riskProfile = risk;
        _defaultLeague = league;
        _isLoadingPrefs = false;
      });
    }
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final geminiKey = _geminiKeyCtrl.text.trim();
    final predProv = context.read<MatchPredictionProvider>();

    try {
      await predProv.updateApiKeys(geminiKey: geminiKey);
      await StorageService.saveGoalAlertEnabled(_goalAlertEnabled);
      await StorageService.saveRedCardAlertEnabled(_redCardAlertEnabled);
      await StorageService.saveFavoriteOnlyAlerts(_favoriteOnlyAlerts);
      await StorageService.saveRefreshIntervalSeconds(_refreshIntervalSeconds);
      await StorageService.saveRiskProfile(_riskProfile);
      await StorageService.saveDefaultLeague(_defaultLeague);

      // Yenileme sıklığı değiştiyse arka plan zamanlayıcısını güncelle
      await predProv.restartLiveBackgroundUpdates();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ayarlar ve tercihler başarıyla kaydedildi.'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearCache() async {
    await CacheManager.clearAll();
    ref.invalidate(countriesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🧹 Ağ ve analiz önbelleği temizlendi.')),
    );
  }

  Future<void> _clearCouponHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Kupon Geçmişini Sil'),
        content: const Text('Tüm kaydedilmiş kupon geçmişiniz silinecektir. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearSavedCoupons();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Kupon geçmişi temizlendi.')),
      );
    }
  }

  Future<void> _clearPredictionHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Tahmin Geçmişini Sil'),
        content: const Text('Tüm tekli maç tahmin geçmişiniz silinecektir. Onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      final predProv = context.read<MatchPredictionProvider>();
      predProv.clearHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Tekli tahmin geçmişi temizlendi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    if (_isLoadingPrefs) {
      return Scaffold(
        appBar: AppBar(title: const Text('⚙️ Ayarlar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Ayarlar ve Tercihler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Canlı Veri & Motor Sağlık Paneli
            _buildDataEngineStatusCard(),
            const SizedBox(height: 20),

            // 2. Sesli ve Canlı Alarmlar
            const _SectionHeader(title: '🔔 Canlı Alarm ve Bildirimler'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.sports_soccer, color: Colors.greenAccent),
                    title: const Text('Sesli Gol Bildirimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Canlı maçlarda gol olduğunda anlık ses ve bildirim uyarısı verir.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _goalAlertEnabled,
                    onChanged: (val) => setState(() => _goalAlertEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.crop_portrait, color: Colors.redAccent),
                    title: const Text('Kırmızı Kart Uyarısı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Kırmızı kart çıktığında özel dikkat alarmı çalar ve model oranlarını revize eder.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _redCardAlertEnabled,
                    onChanged: (val) => setState(() => _redCardAlertEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.star_rounded, color: Colors.amber),
                    title: const Text('Yalnızca Favori Maçlarım İçin Çal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Açıldığında sadece yıldızladığınız takip maçlarında sesli alarm çalar.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _favoriteOnlyAlerts,
                    onChanged: (val) => setState(() => _favoriteOnlyAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Canlı Yenileme ve Performans
            const _SectionHeader(title: '⚡ Canlı Akış & Yenileme Hızı'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skor ve Olay Yenileme Sıklığı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Canlı maçların arka planda kaç saniyede bir taranacağını belirler.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChoiceChip('15 sn', 15),
                        _buildChoiceChip('30 sn (Önerilen)', 30),
                        _buildChoiceChip('60 sn', 60),
                        _buildChoiceChip('Manuel', 0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Model Analiz & Risk Profili
            const _SectionHeader(title: '🎯 Kupon & Risk Profili'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tahmin ve Kupon Sihirbazı Stratejisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Günün kuponu ve önerilen maçlarda modelin risk toleransını ayarlar.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRiskChip('Garanti (%65+ Güven)', 'Garanti'),
                        _buildRiskChip('Dengeli (İdeal)', 'Dengeli'),
                        _buildRiskChip('Sürpriz / Yüksek Oran', 'Sürpriz'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Varsayılan Açılış Ligi
            const _SectionHeader(title: '📌 Varsayılan Açılış Ligi'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Uygulama Açıldığında İlk Gösterilecek Lig', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _defaultLeague,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tümü', child: Text('🌍 Tümü (Tüm Dünya)')),
                        DropdownMenuItem(value: 'Trendyol Süper Lig', child: Text('🇹🇷 Trendyol Süper Lig')),
                        DropdownMenuItem(value: 'Trendyol 1. Lig', child: Text('🇹🇷 Trendyol 1. Lig')),
                        DropdownMenuItem(value: 'Premier League', child: Text('🏴󠁧󠁢󠁥󠁮󠁧󠁿 Premier League')),
                        DropdownMenuItem(value: 'La Liga', child: Text('🇪🇸 La Liga')),
                        DropdownMenuItem(value: 'Serie A', child: Text('🇮🇹 Serie A')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultLeague = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Görünüm & Tema
            const _SectionHeader(title: '🎨 Görünüm & Tema'),
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  themeProv.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primary,
                ),
                title: const Text('Koyu Tema (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(
                  themeProv.isDarkMode ? 'Stadyum Gece Teması Aktif' : 'Açık Tema Aktif',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
                value: themeProv.isDarkMode,
                onChanged: (_) => themeProv.toggleTheme(),
              ),
            ),
            const SizedBox(height: 20),

            // 7. Yapay Zeka (Gemini AI)
            const _SectionHeader(title: '🤖 Yapay Zeka (AI Taktik Raporu)'),
            _KeyCard(
              title: 'Google Gemini AI Anahtarı',
              titleColor: Colors.purpleAccent,
              description: 'Maç öncesi teknik direktör brifingi, taktik analiz ve kupon değerlendirmeleri için ücretsiz Google Gemini anahtarı (aistudio.google.com).',
              controller: _geminiKeyCtrl,
              hintText: 'AIzaSy...',
              icon: Icons.auto_awesome,
              iconColor: Colors.purpleAccent,
              obscure: true,
            ),
            const SizedBox(height: 16),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Kaydediliyor...' : 'Değişiklikleri ve Tercihleri Kaydet'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _isSaving ? null : _save,
              ),
            ),
            const SizedBox(height: 28),

            // 8. Veri ve Geçmiş Yönetimi
            const _SectionHeader(title: '💾 Veri & Geçmiş Yönetimi'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blueAccent),
                    title: const Text('Tahmin Geçmişini İncele', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: Colors.amber),
                    title: const Text('Önbelleği Temizle', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Geçici ağ ve analiz verilerini sıfırlar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    onTap: _clearCache,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
                    title: const Text('Kayıtlı Kupon Geçmişini Sil', style: TextStyle(fontSize: 13)),
                    onTap: _clearCouponHistory,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                    title: const Text('Tekli Tahmin Geçmişini Sil', style: TextStyle(fontSize: 13)),
                    onTap: _clearPredictionHistory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sürüm Bilgisi
            const Center(
              child: Column(
                children: [
                  Text(
                    'BüyükDefter / Football Quantitative Engine',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sürüm 2.5.0 (All-in-One Super Analytics & TFF Motoru)',
                    style: TextStyle(fontSize: 11, color: Colors.white24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, int seconds) {
    final isSelected = _refreshIntervalSeconds == seconds;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _refreshIntervalSeconds = seconds),
    );
  }

  Widget _buildRiskChip(String label, String profile) {
    final isSelected = _riskProfile == profile;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _riskProfile = profile),
    );
  }

  Widget _buildDataEngineStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Canlı Veri & Motor Sağlık Paneli',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildEngineStatusRow(
            icon: '🇹🇷',
            title: 'TFF Resmi Fikstür Motoru',
            subtitle: 'Süper Lig, 1. Lig, 2. Lig (Kırmızı/Beyaz), 3. Lig (1-4) ve Kupalar aktif.',
            status: 'AKTİF & RESMİ',
            statusColor: Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          _buildEngineStatusRow(
            icon: '🌍',
            title: 'Açık Küresel Canlı Skor Motoru',
            subtitle: 'Premier League, La Liga, Serie A ve tüm dünya ligleri kotasız aktif.',
            status: 'KOTASIZ & CANLI',
            statusColor: Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          _buildEngineStatusRow(
            icon: '🤖',
            title: 'Yapay Zeka (Gemini AI)',
            subtitle: 'Taktiksel maç analizi ve kupon strateji asistanı.',
            status: _geminiKeyCtrl.text.trim().isNotEmpty ? 'BAĞLI' : 'HAZIR',
            statusColor: _geminiKeyCtrl.text.trim().isNotEmpty ? Colors.purpleAccent : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildEngineStatusRow({
    required String icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 1),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white60),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final String title;
  final String description;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color? titleColor;
  final Color? iconColor;
  final bool obscure;

  const _KeyCard({
    required this.title,
    required this.description,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.titleColor,
    this.iconColor,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 12.5, color: Colors.white30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
