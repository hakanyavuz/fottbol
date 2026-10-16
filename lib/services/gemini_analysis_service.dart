import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/api_constants.dart';
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

      final home = prediction.homeTeam;
      final away = prediction.awayTeam;
      final homeTop = home.topScorer;
      final awayTop = away.topScorer;
      final ref = prediction.refereeStat;

      final prompt = '''
[Proje Bağlamı - Sabit Kurallar]
Flutter proje: FOTTBOL Quant Futbol Tahmin Uygulaması
Temel Kurallar:
1. Tüm olasılık, Elo, son 5/10 maç formu, iç saha/deplasman puan ortalaması (PPG), H2H ve kadro güç kaybı hesaplamaları Dart kodunda deterministik olarak tamamlanmıştır.
2. ASLA kendi başına olasılık, tarih, puan veya istatistik hesaplama! Sadece aşağıda sağlanan kesin Dart verilerini yorumla.

[Sağlanan Veri (Dart Motoru Çıktısı)]
- Karşılaşma: ${home.name} (Ev Sahibi) vs ${away.name} (Deplasman)
- Club Elo Güçleri: ${home.name}: ${prediction.homeElo?.toInt() ?? 1500} Elo | ${away.name}: ${prediction.awayElo?.toInt() ?? 1500} Elo (Fark: ${prediction.eloDifference != null ? prediction.eloDifference!.toStringAsFixed(0) : "0"})
- İç Saha / Deplasman Puan Ortalaması (PPG): ${home.name} İç Saha: ${home.stats.homePointsPerGame.toStringAsFixed(2)} PPG (Son 5 İç Saha: ${home.stats.effectiveHomeForm.join('-')}) | ${away.name} Deplasman: ${away.stats.awayPointsPerGame.toStringAsFixed(2)} PPG (Son 5 Deplasman: ${away.stats.effectiveAwayForm.join('-')})
- Son 10 Maç Genel Form: ${home.name}: ${home.stats.effectiveLast10Form.join('-')} (${home.stats.overallPointsPerGame.toStringAsFixed(2)} PPG) | ${away.name}: ${away.stats.effectiveLast10Form.join('-')} (${away.stats.overallPointsPerGame.toStringAsFixed(2)} PPG)
- Gol Ortalamaları: ${home.name} Evde Attığı: ${home.stats.avgHomeGoalsScored.toStringAsFixed(2)}, Yediği: ${home.stats.avgHomeGoalsConceded.toStringAsFixed(2)} | ${away.name} Deplasmanda Attığı: ${away.stats.avgAwayGoalsScored.toStringAsFixed(2)}, Yediği: ${away.stats.avgAwayGoalsConceded.toStringAsFixed(2)}
- Yıldız Oyuncu Düellosu: ${home.name}: ${homeTop != null ? '${homeTop.name} (${homeTop.goals}G/${homeTop.assists}A, Reyting ${homeTop.rating.toStringAsFixed(1)})' : 'Standart'} vs ${away.name}: ${awayTop != null ? '${awayTop.name} (${awayTop.goals}G/${awayTop.assists}A, Reyting ${awayTop.rating.toStringAsFixed(1)})' : 'Standart'}
- Sakat / Cezalı Etkisi: ${home.name} (-%${home.attackAvailabilityLossPercent.toStringAsFixed(1)} güç kaybı): ${home.injuredPlayers.isEmpty ? 'Tam kadro' : home.injuredPlayers.map((p) => '${p.name} (${p.position})').join(', ')} | ${away.name} (-%${away.attackAvailabilityLossPercent.toStringAsFixed(1)} güç kaybı): ${away.injuredPlayers.isEmpty ? 'Tam kadro' : away.injuredPlayers.map((p) => '${p.name} (${p.position})').join(', ')}
- Hakem & Disiplin: ${ref != null ? '${ref.name} (${ref.strictnessRating}, Ort. ${ref.avgYellowCards} Sarı, %${(ref.avgPenalties * 100).toInt()} Penaltı)' : 'Standart Hakem'}
- H2H & Ters Takım: ${prediction.bogeyAnalysis?.hasBogeyEffect == true ? '⚠️ TERS TAKIM UYARISI (${prediction.bogeyAnalysis!.description})' : 'Normal H2H dengesi'}
- Algoritmanın Tahmin Ettiği Skor: ${prediction.predictedScoreString} (xG: ${home.name} ${prediction.lambdaHome.toStringAsFixed(2)} - ${away.name} ${prediction.lambdaAway.toStringAsFixed(2)})
- Olasılık Dağılımı: Ev: %${prediction.homeWinProbability.toStringAsFixed(1)} | Beraberlik: %${prediction.drawProbability.toStringAsFixed(1)} | Deplasman: %${prediction.awayWinProbability.toStringAsFixed(1)}
- 2.5 Gol Üstü: %${prediction.over25Probability.toStringAsFixed(1)} | KG Var: %${prediction.bothTeamsToScoreProbability.toStringAsFixed(1)}
- 🎯 Modelin Banko Tercihi: ${prediction.primaryPick} (Güven: %${prediction.primaryPickConfidence.toStringAsFixed(1)}) | ⚽ Gol Pazarı: ${prediction.secondaryPick} | 🛡️ Sigorta: ${prediction.safetyPick}
- 💰 Değerli Bahis (Value Bet): ${prediction.isValueBet ? "EV Avantajı Var (EV: ${prediction.expectedValue.toStringAsFixed(2)})" : "Normal Oran Dengesi (EV: ${prediction.expectedValue.toStringAsFixed(2)})"}

[Görev]
Yukarıdaki hazır Dart hesaplamalarına dayanarak şu 3 ana başlıkta Türkçe, net ve analitik bir maç raporu yaz:
1. ⚽ Saha İçi Senaryosu, Son 5/10 Maç Formu & Deplasman Karnesi
2. 🌟 Yıldız Oyuncu Düellosu, Eksikler, Hakem & H2H Etkisi
3. 🎯 Bahis Karnesi Denetimi & Model Kararı
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
        final lossPct = home.attackAvailabilityLossPercent.toStringAsFixed(1);
        injuryNote += '${home.name} cephesindeki ${home.injuredCount} eksik (-%$lossPct güç kaybı) ev sahibinin baskısını kırabilir. ';
      }
      if (away.injuredCount > 0) {
        final lossPct = away.attackAvailabilityLossPercent.toStringAsFixed(1);
        injuryNote += '${away.name} takımında ${away.injuredCount} eksik (-%$lossPct güç kaybı) deplasmanda direnci düşürebilir.';
      }
    } else {
      injuryNote = 'Her iki takım da sahaya tam kadroya yakın çıkıyor; taktiksel disiplin son düdüğe kadar korunacaktır.';
    }

    String eloNote = '';
    if (p.eloDifference != null && p.eloDifference!.abs() >= 60) {
      eloNote = p.eloDifference! > 0
          ? 'Elo derecelendirmesinde ${home.name} rakibinden +${p.eloDifference!.toStringAsFixed(0)} puan üstün (${p.homeElo?.toInt()} vs ${p.awayElo?.toInt()}).'
          : 'Elo derecelendirmesinde ${away.name} rakibinden +${(-p.eloDifference!).toStringAsFixed(0)} puan üstün (${p.awayElo?.toInt()} vs ${p.homeElo?.toInt()}).';
    }

    final starNote = (home.topScorer != null && away.topScorer != null)
        ? 'Yıldız düellosunda ${home.topScorer!.name} (${home.topScorer!.goals}G/${home.topScorer!.assists}A) ile ${away.topScorer!.name} (${away.topScorer!.goals}G/${away.topScorer!.assists}A) karşı karşıya geliyor.'
        : (home.topScorer != null ? 'Ev sahibinde ${home.topScorer!.name} (${home.topScorer!.goals} gol) kilit tehdit oluşturuyor.' : '');

    final refNote = p.refereeStat != null
        ? 'Maçın hakemi ${p.refereeStat!.name} (${p.refereeStat!.strictnessRating}, maç başı ${p.refereeStat!.avgYellowCards} sarı kart).'
        : '';

    final bogeyNote = p.bogeyAnalysis?.hasBogeyEffect == true
        ? '\n• ⚠️ Ters Takım (H2H) Uyarısı: ${p.bogeyAnalysis!.description}'
        : '';

    final valueNote = p.isValueBet
        ? '💰 Quant Değerli Bahis Radarı: Piyasa oranları ile model olasılıkları arasında pozitif beklenen değer (+%${((p.expectedValue - 1.0) * 100).toStringAsFixed(1)} EV) tespit edildi.'
        : '📊 Oran Dengesi: Piyasa oranları ile olasılık modeli dengeli seyrediyor.';

    return '''
1. ⚽ Saha İçi Senaryosu, Son 5/10 Form & Deplasman Karnesi:
${home.name}, iç sahada maç başı ${home.stats.homePointsPerGame.toStringAsFixed(2)} puan ortalaması (Son 5 İç Saha: ${home.stats.effectiveHomeForm.join('-')}) ve ${home.stats.avgHomeGoalsScored.toStringAsFixed(2)} gol ortalaması ile oynuyor. ${away.name} ise deplasmanda ${away.stats.awayPointsPerGame.toStringAsFixed(2)} puan ortalaması (Son 5 Deplasman: ${away.stats.effectiveAwayForm.join('-')}) ve ${away.stats.avgAwayGoalsScored.toStringAsFixed(2)} gol üretimi sergiliyor. $tempo $eloNote

2. 🌟 Yıldız Düellosu, Eksikler & Hakem Etkisi:
$starNote $injuryNote $refNote$bogeyNote

3. 🎯 Bahis Karnesi Denetimi & Model Kararı:
• Banko Tercih: ${p.primaryPick} (Güven: %${p.primaryPickConfidence.toStringAsFixed(1)})
• Gol Pazarı: ${p.secondaryPick}
• Sigorta Çifte Şans: ${p.safetyPick}
• Öngörülen Skor: ${p.predictedScoreString} (xG: ${p.lambdaHome.toStringAsFixed(2)} - ${p.lambdaAway.toStringAsFixed(2)})
$valueNote
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
