import '../models/prediction_result.dart';

/// Yapay Zeka Taktiksel Yorum ve Doğal Dil Analiz Motoru (Local NLG)
///
/// Gemini API anahtarı olmadığında veya kota dolduğunda spor yorumcusu ve veri
/// analisti diliyle profesyonel maç raporu üretir.
class TacticalNarrativeEngine {
  static String generateNarrative(PredictionResult p) {
    final home = p.homeTeam.name;
    final away = p.awayTeam.name;
    final hGoals = p.predictedHomeGoals;
    final aGoals = p.predictedAwayGoals;
    final conf = p.confidenceScore;
    final risk = p.riskLevel;

    final paragraphs = <String>[];

    // 1. Giriş ve Genel Maç Senaryosu
    String intro = 'Karşılaşmada $home iç saha avantajıyla oyunu yönlendiren taraf olmaya yakın görünüyor. '
        'Poisson ve Dixon-Coles modellememiz, maçın en yüksek olasılıklı sonucunu $hGoals - $aGoals olarak işaret ediyor. '
        'Model genelinde %${conf.toStringAsFixed(0)} güven skoru ile bu mücadele "$risk" kategorisinde değerlendirildi.';
    paragraphs.add(intro);

    // 2. Taktik ve Gol Beklentisi (xG) Analizi
    String xgAnalysis = 'Hücum parametrelerine bakıldığında, $home için beklenen gol (xG) değeri ${p.lambdaHome.toStringAsFixed(2)}, '
        '$away için ise ${p.lambdaAway.toStringAsFixed(2)} seviyesinde hesaplandı. ';
    if (p.over25Probability >= 55.0) {
      xgAnalysis += 'Her iki takımın geçiş hücumlarındaki etkinliği ve kalede gördüğü pozisyonlar, '
          'mücadelenin gollü geçme ihtimalini (%${p.over25Probability.toStringAsFixed(0)} 2.5 Üst) kuvvetlendiriyor.';
    } else {
      xgAnalysis += 'Orta saha bloklarının birbirini kilitlemesi ve temkinli oyun planı nedeniyle '
          'kontrollü ve düşük skorlu bir mücadele bekleniyor.';
    }
    paragraphs.add(xgAnalysis);

    // 3. Hakem ve Disiplin Dinamiği
    if (p.refereeStat != null) {
      final ref = p.refereeStat!;
      String refText = 'Müsabakanın hakemi ${ref.name}, maç başı ${ref.avgYellowCards.toStringAsFixed(1)} sarı kart ve '
          '${ref.avgFouls.toStringAsFixed(0)} faul ortalamasıyla ${ref.strictnessRating} bir yönetim profili çiziyor. ';
      if (ref.hasHighPenaltyTendency) {
        refText += 'Hakemin ceza sahası içindeki temaslarda penaltı noktasına gitme sıklığı (%${(ref.avgPenalties * 100).toStringAsFixed(0)}), '
            'duran top ve penaltı ihtimalini maçın kırılma noktalarından biri haline getirebilir.';
      } else {
        refText += 'Oyunun akışına izin veren ve düdüğünü idareli kullanan stili, tempolu bir 90 dakikayı destekleyecektir.';
      }
      paragraphs.add(refText);
    }

    // 4. Sonuç ve Özet Bahis Önerisi
    String conclusion = 'Özetle; istatistiksel üstünlük ';
    if (p.homeWinProbability >= 50.0) {
      conclusion += '$home galibiyetini (%${p.homeWinProbability.toStringAsFixed(0)}) öncelikli kılıyor. ';
    } else if (p.awayWinProbability >= 45.0) {
      conclusion += '$away takımının deplasman direncini (%${p.awayWinProbability.toStringAsFixed(0)}) öne çıkarıyor. ';
    } else {
      conclusion += 'dengeli bir mücadeleyi ve beraberlik riskini (%${p.drawProbability.toStringAsFixed(0)}) işaret ediyor. ';
    }

    if (p.bothTeamsToScoreProbability >= 55.0) {
      conclusion += 'Karşılıklı Gol Var (KG Var) tercihi maçın en değerli opsiyonlarından biri olarak dikkat çekiyor.';
    }
    paragraphs.add(conclusion);

    return paragraphs.join('\n\n');
  }
}
