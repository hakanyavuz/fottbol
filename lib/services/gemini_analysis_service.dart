import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/league_constants.dart';
import '../models/prediction_result.dart';

import '../models/coupon_slip.dart';

/// Gemini API ile maçı taktiksel olarak yorumlayan ve doğal dil raporu üreten servis
class GeminiAnalysisService {
  /// Kuponun tamamı için AI analizi üretir
  static Future<String> analyzeCoupon({
    required CouponSlip slip,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      return "Bu kupon, Poisson istatistiksel modeline göre en yüksek güven skoruna sahip maçlardan oluşturulmuştur. ${slip.category} kategorisinde dengeli bir risk dağılımı sunar.";
    }

    try {
      final model = GenerativeModel(
        model: ApiConstants.geminiDefaultModel,
        apiKey: apiKey.trim(),
      );

      final matchesInfo = slip.items.map((item) => 
        "- ${item.matchTitle} (${item.leagueName}): ${item.selectionLabel} (Güven: %${item.confidenceScore.toStringAsFixed(1)})"
      ).join("\n");

      final prompt = '''
Sen profesyonel bir spor bahisleri analistisin. Aşağıdaki "${slip.category}" kategorisindeki kuponu değerlendir.
Kuponun toplam oranı: ${slip.totalOdds}
Maçlar:
$matchesInfo

Lütfen bu kuponu analiz et:
1. Maçların birbiriyle uyumu ve risk durumu nedir?
2. Neden bu maçlar bu kuponda bir araya gelmiş olabilir?
3. Kullanıcıya bu kupon için kısa bir tavsiye ver.

Yanıtın kısa (maksimum 3-4 cümle), profesyonel ve ilgi çekici olsun. Türkçe yanıt ver.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Kupon analizi oluşturulamadı.";
    } catch (e) {
      return "Kupon analizi şu an yapılamıyor, ancak istatistiksel veriler bu seçimlerin güçlü olduğunu gösteriyor.";
    }
  }

  /// Gemini API ile ayrıntılı taktiksel yorum üretir
  static Future<String> generateTacticalAnalysis({
    required PredictionResult prediction,
    required String apiKey,
  }) async {
    // API anahtarı girilmemişse zengin şablon tabanlı yerel analiz döndür
    if (apiKey.trim().isEmpty) {
      return _generateLocalFallbackAnalysis(prediction);
    }

    try {
      final model = GenerativeModel(
        model: ApiConstants.geminiDefaultModel,
        apiKey: apiKey.trim(),
      );

      final prompt = '''
Sen tecrübeli ve profesyonel bir futbol analisti ve taktik danışmanısın.
Aşağıda istatistiksel Poisson dağılımı ile hesaplanmış maç verileri bulunmaktadır. Bu verileri yorumlayarak Türkçe, sürükleyici ve taktiksel derinliği olan bir maç analizi yaz.

MAÇ BİLGİLERİ:
- Karşılaşma: ${prediction.homeTeam.name} (Ev Sahibi) vs ${prediction.awayTeam.name} (Deplasman)
- Algoritmanın Tahmin Ettiği Skor: ${prediction.predictedScoreString}
- Beklenen Goller (xG): ${prediction.homeTeam.name}: ${prediction.lambdaHome.toStringAsFixed(2)} | ${prediction.awayTeam.name}: ${prediction.lambdaAway.toStringAsFixed(2)}
- Olasılık Dağılımı: Ev Galibiyeti: %${prediction.homeWinProbability} | Beraberlik: %${prediction.drawProbability} | Deplasman Galibiyeti: %${prediction.awayWinProbability}
- 2.5 Gol Üstü İhtimali: %${prediction.over25Probability}
- Karşılıklı Gol Var İhtimali: %${prediction.bothTeamsToScoreProbability}
- Ev Sahibi Sakatlıklar: ${prediction.homeTeam.injuredPlayers.isEmpty ? 'Eksik yok' : prediction.homeTeam.injuredPlayers.map((p) => '${p.name} (${p.position})').join(', ')}
- Deplasman Sakatlıklar: ${prediction.awayTeam.injuredPlayers.isEmpty ? 'Eksik yok' : prediction.awayTeam.injuredPlayers.map((p) => '${p.name} (${p.position})').join(', ')}

Lütfen yanıtında şu 3 ana başlığı kullan ve samimi, net bir spor yorumcusu üslubuyla açıkla:
1. ⚽ Saha İçi Senaryosu & Taktiksel Kurgu
2. ⚠️ Kilit Eşleşme & Sakatlıkların Belirleyici Etkisi
3. 🎯 Tahmin Kararı & Maçın Olası Kırılma Anı
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return _generateLocalFallbackAnalysis(prediction);
    } catch (e) {
      // Ağ hatası veya kota durumunda fallback üret
      return '⚠️ [Gemini API bağlantısı sağlanamadı: $e]\n\n${_generateLocalFallbackAnalysis(prediction)}';
    }
  }

  /// API Anahtarı girilmediğinde veya çevrimdışıyken çalışan akıllı yerel analiz
  static String _generateLocalFallbackAnalysis(PredictionResult p) {
    final home = p.homeTeam;
    final away = p.awayTeam;

    String tempo = p.over25Probability > 55
        ? 'Tempolu ve bol pozisyonlu bir 90 dakika bizi bekliyor.'
        : 'Savunma güvenliğini ön planda tutan, taktiksel bir satranç maçı görebiliriz.';

    String injuryNote = '';
    if (home.injuredCount > 0 || away.injuredCount > 0) {
      injuryNote = 'Kadro eksiklikleri açısından bakıldığında ';
      if (home.injuredCount > 0) {
        injuryNote += '${home.name} cephesindeki ${home.injuredCount} eksik, ev sahibinin baskısını kırabilir. ';
      }
      if (away.injuredCount > 0) {
        injuryNote += '${away.name} takımında ${away.injuredCount} sakat oyuncunun bulunması deplasmanda savunma direncini düşürebilir.';
      }
    } else {
      injuryNote = 'Her iki takım da sahaya tam kadro çıkmaya yakın, taktiksel disiplin son düdüğe kadar korunacaktır.';
    }

    return '''
1. ⚽ Saha İçi Senaryosu & Taktiksel Kurgu:
${home.name}, seyircisi önünde iç saha hücum gücü (%${(home.stats.avgHomeGoalsScored / LeagueConstants.avgHomeGoals * 100).toStringAsFixed(0)}) ile maça baskılı başlamayı hedefleyecektir. ${away.name} ise kontra ataklarla geçiş hücumları arayacaktır. $tempo

2. ⚠️ Kilit Eşleşme & Sakatlıkların Belirleyici Etkisi:
$injuryNote ${home.topScorer != null ? 'Ev sahibinde ${home.topScorer!.name} (${home.topScorer!.goals} gol) kilit tehdit oluşturuyor.' : ''}

3. 🎯 Tahmin Kararı & Maçın Olası Kırılma Anı:
İstatistiksel xG beklentisi (${p.lambdaHome.toStringAsFixed(2)} - ${p.lambdaAway.toStringAsFixed(2)}) doğrultusunda karşılaşmanın en kuvvetli skoru ${p.predictedScoreString} olarak öne çıkıyor. Ev sahibi galibiyeti %${p.homeWinProbability} ihtimalle en yüksek olasılık konumunda.
''';
  }

  /// Teknik Direktör Hap Brifingi (Opta / WhoScored stili 3 maddelik vurucu taktik özeti)
  static List<Map<String, String>> generateManagerBriefing(PredictionResult p) {
    final home = p.homeTeam;
    final away = p.awayTeam;

    // 1. Oyun Planı & Tempo
    String planTitle = '🎯 Oyun Planı & Tempo';
    String planText;
    if (p.over25Probability >= 55) {
      planText = '${home.name} evinde yüksek pres ve dikine paslarla gol arayacak. Karşılaşmanın yüksek tempoda ve bol pozisyonlu geçmesi bekleniyor.';
    } else {
      planText = '${away.name} deplasmanda kompakt savunma bloğu kuracak. ${home.name} set hücumlarıyla kilidi açmaya çalışacak; düşük tempolu ve sabır gerektiren bir 90 dakika öngörülüyor.';
    }

    // 2. Kadro Krizleri & Zayıf Karın
    String weakTitle = '🛡️ Kadro & Kritik Eşleşme';
    String weakText;
    if (home.injuredCount > 0 || away.injuredCount > 0) {
      final homeInjuries = home.injuredCount > 0 ? '${home.name} cephesinde ${home.injuredCount} eksik' : '';
      final awayInjuries = away.injuredCount > 0 ? '${away.name} tarafında ${away.injuredCount} eksik' : '';
      weakText = 'Eksikler kritik: ${[homeInjuries, awayInjuries].where((s) => s.isNotEmpty).join(' ve ')}. Kadro rotasyonundaki zafiyetler maçın ikinci yarısında belirleyici olabilir.';
    } else {
      weakText = 'Her iki takım da sahaya ideal kadroya yakın çıkıyor. Maçın kaderini kenardan yapılacak hamleler ve orta saha pres gücü tayin edecek.';
    }

    // 3. Hakem & Disiplin
    String refTitle = '⚖️ Hakem & Disiplin Uyarısı';
    String refText;
    if (p.refereeStat != null) {
      final r = p.refereeStat!;
      refText = 'Hakem ${r.name} (Ort. ${r.avgYellowCards} Sarı, ${r.avgRedCards} Kırmızı). ${r.strictnessRating} düdükleriyle ikili mücadelelerde kart çıkma riski yüksek.';
    } else {
      refText = 'Disiplin ve sakinlik anahtar faktör. Erken gelebilecek kartlar takımların pres yoğunluğunu doğrudan frenleyebilir.';
    }

    final briefing = [
      {'title': planTitle, 'text': planText},
      {'title': weakTitle, 'text': weakText},
      {'title': refTitle, 'text': refText},
    ];

    if (p.isHighManipulationRisk) {
      briefing.add({
        'title': '🚨 Manipülasyon & Varyans Güvenlik Kalkanı (${p.manipulationRiskRegion ?? "Bölgesel"})',
        'text': '${p.manipulationRiskRegion ?? "Bu"} lig/kupa organizasyonunda tarihsel anomali ve şüpheli sürpriz dalgalanmaları yüksek olduğundan kasa payı %30 korumaya alınmış ve model güven skoru %75 tavanı ile dengelenmiştir.',
      });
    }

    return briefing;
  }
}
