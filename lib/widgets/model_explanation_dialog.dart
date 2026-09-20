import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ModelExplanationDialog extends StatelessWidget {
  const ModelExplanationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Tahmin Modeli Nasıl Çalışır?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              '1. Poisson Dağılımı',
              'Uygulamanın kalbinde Poisson istatistiksel modeli yatar. Takımların geçmiş maçlardaki hücum ve savunma güçleri hesaplanarak, maçta kaç gol atabileceklerinin (xG) olasılık dağılımı çıkarılır.',
            ),
            _buildSection(
              '2. Dixon-Coles Ayarlaması',
              'Düşük skorlu maçlarda (0-0, 1-0 gibi) Poisson modelinin yanılma payını azaltmak için Dixon-Coles algoritması ile korelasyon düzeltmesi yapılır.',
            ),
            _buildSection(
              '3. Dış Etkenler (Hava & Hakem)',
              'Sadece istatistikler değil; yağmurlu hava, kar yağışı veya hakemin kart çıkarma eğilimi de gol beklentisini (lambda) dinamik olarak etkiler.',
            ),
            _buildSection(
              '4. Gemini AI Analizi',
              'Matematiksel veriler, sakatlık bilgileri ve taktiksel dizilişler Google Gemini AI modeline gönderilerek, bir spor yorumcusu gözüyle taktiksel rapor oluşturulur.',
            ),
            const Divider(),
            const Text(
              'Not: Tahminler geçmiş verilere dayalı olasılıklardır ve kesinlik içermez. Sporun doğasındaki sürprizler her zaman mümkündür.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anladım'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}
