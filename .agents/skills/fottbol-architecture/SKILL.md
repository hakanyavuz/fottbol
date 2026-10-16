---
name: fottbol-architecture
description: FOTTBOL projesinin tam mimari haritası, deterministik hesaplama kuralları, modül indeksleri ve veri akış şeması. Bu projede tahmin, kadro, hakem, saha, cezalılar, H2H veya istatistik güncellemesi yapılırken tüm kod tabanını taramadan doğrudan ilgili dosyayı bulmak ve token tasarrufu sağlamak için kullanılır.
---

# FOTTBOL Proje Bilgi Haritası & Deterministik Kurallar (Argon Bağlam Önbelleği)

## 1. Temel Mimari Prensipler (Altın Kurallar)
1. **Deterministik Hesaplama Kuralı:** Kazanma olasılıkları, beklenen gol ($\lambda$), Club Elo farkı, son 5/10 maç formu, iç saha/deplasman ayrımı, oyuncu sakatlık/ceza kesintileri, hakem sertlik çarpanları ve H2H ağırlıkları **%100 Dart kodunda (`PoissonEngine`, `ClubEloService`, `SpecializedMarketsEngine`)** hesaplanır. LLM (Gemini) **ASLA** matematiksel olasılık veya tarih hesaplamaz; yalnızca Dart tarafından üretilen yapılandırılmış sayıları (`PredictionResult`) yorumlar.
2. **Sıfır Kopya Şablon Kuralı:** Hiçbir iki takım aynı varsayılan istatistik veya aynı sabit H2H (2-1, 1-1) şablonunu paylaşamaz. Canlı puan durumu (`RealSportsLiveService.getLiveTeamStats`) önceliklidir; çevrimdışı durumda `ClubEloService` + taktiksel DNA motoru (`FootballOfflineRepository._buildDynamicClubStats`) her takıma özgün profil üretir.
3. **Kotasız Çoklu Kaynak (Multi-Source):** Uygulama paralı API anahtarına bağımlı değildir:
   - Canlı Skor, Puan Durumu, Kadro & Olaylar: `RealSportsLiveService` (ESPN API - 5'erli paket sorgulama ile TLS darboğazı önlenir).
   - Canlı Oranlar & xG: `SofascoreLiveService` + ESPN Odds.
   - Küresel Takım Gücü: `ClubEloService` (160+ kulüp + canlı puan durumu kalibrasyonu).

---

## 2. Modül ve Dosya Haritası (Hızlı Erişim İndeksi)

### A. Tahmin ve Matematik Motorları (`lib/services/`)
- `lib/services/poisson_engine.dart`:
  - Dixon-Coles düzeltmeli Poisson dağılımı (`calculatePrediction`).
  - İç saha hücum / deplasman savunma gücü, son 5 maç formu (`_calculateFormFactor`), sakat/cezalı oyuncu gol payı kesintisi (`dynamicAttackPenalty`), dinlenme günü yorgunluk çarpanı (`homeRestMultiplier`), şut isabet verimi (`homeShotMultiplier`), hakem penaltı çarpanı (`refereePenaltyXgMultiplier`), nötr saha ve hava/zemin etkisi.
  - **Bayesian Oran Füzyonu:** Model olasılığı (%50) ile piyasa bahis oranı (%50) harmanlanır; en olası skorlar (`topScores`) baskın sonuca (1X2) kilitlenir.
- `lib/services/club_elo_service.dart`:
  - `getTeamElo(teamName)` ve `calculateGoalMultipliers(eloDiff)`.
  - `updateTeamElo(teamName, elo)` ile canlı puan durumundan dinamik kalibrasyon.
- `lib/services/specialized_markets_engine.dart`:
  - `calculateCardsAndCorners`: Takım korner ortalamaları ve hakem kart sertliğine göre 8.5/9.5 Korner ve 3.5/4.5 Kart Poisson olasılıkları.
  - `detectBogeyTeam`: Elo olarak favori takımın H2H geçmişinde ters gelen "Kabus Rakip" (Frustration Index) tespiti.
- `lib/services/live_momentum_service.dart`: Son 15 dakikalık yuvarlanan pencerede canlı şut/korner/tehlikeli atak baskı ivmesi.
- `lib/services/dropping_odds_service.dart`: Açılış/adil oran ile güncel piyasa oranı arasındaki %10+ sert düşüş (Smart Money) takibi.
- `lib/services/model_calibrator.dart`: Geçmiş tahminlerin Brier skoru ve gerçek sonuçlarına göre `rho` ve `maxH2hWeight` öz-kalibrasyonu.

### B. Veri ve Canlı Akış Servisleri (`lib/services/`)
- `lib/services/multi_source_football_service.dart`: ESPN, Sofascore ve Club Elo orkestratörü.
- `lib/services/real_sports_live_service.dart`:
  - `getLiveFixtures`: 25+ ligi 5'erli paketler halinde sorgular.
  - `getLiveTeamStats`: ESPN `/standings` uç noktasından gerçek sezon GP, W, D, L, GF, GA ve Form dizilimini çeker.
  - `getFixtureLineups` & `getFixtureEvents`: Resmi ilk 11, yedekler, goller ve kartlar.
- `lib/services/football_offline_repository.dart`:
  - `getRealisticStats`: Süper Lig özel istatistikleri + `_buildDynamicClubStats` (Elo ve taktiksel DNA tabanlı özgün takım istatistiği).
  - `getHeadToHead`: Eşleşmeye özgü simetrik tohumlu ve Kabus Rakip duyarlı 6 maçlık H2H geçmişi.

### C. Durum Yönetimi (`lib/providers/`)
- `lib/providers/match_prediction_provider.dart`:
  - `executePrediction`: Canlı puan durumu tazeleme -> H2H yükleme -> Elo & Oran çekme -> `PoissonEngine.calculatePrediction` -> `GeminiAnalysisService`.
  - `_analyzeLineupImpact`: Resmi ilk 11 açıklandığında kadroda olmayan yıldızları tespit edip tahmini otomatik revize eder.

### D. Veri Modelleri (`lib/models/`)
- `prediction_result.dart`: `lambdaHome`, `lambdaAway`, 1X2, 2.5 Alt/Üst, KG Var, `primaryPick` (Banko), `secondaryPick` (Gol), `safetyPick` (Sigorta), `expectedValue`, `cardCornerPrediction`, `bogeyAnalysis`.
- `team.dart`, `match_stat.dart`, `player.dart`, `head_to_head.dart`, `referee_stat.dart`, `weather_pitch_condition.dart`, `odds_comparison.dart`, `value_bet.dart`.

---

## 3. Argon İçin Token Dostu Görev Şablonu
Yeni bir özellik veya düzeltme isterken şu kısa formatı kullanabilirsiniz:
- **Hedef Modül:** (Örn: `poisson_engine.dart` veya `real_sports_live_service.dart`)
- **İstenen Değişiklik:** (Örn: "Son 10 maç deplasman gol ağırlığını %15 artır")
- **Kısıtlama:** "Sadece ilgili servisi güncelle, diğer dosyaları tarama."
