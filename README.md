# ⚽ Futbol Maç Tahmin ve İstatistik Analiz Uygulaması (Flutter)

Bu proje; iki futbol takımının geçmiş maç sonuçları, gol ortalamaları, iç/dış saha performansları, son 5-10 maçlık form durumları ve kadro sakatlık verilerini girdi alarak **Poisson Dağılımı** ile istatistiksel maç skoru hesaplayan ve **Google Gemini AI** ile doğal dilde taktiksel maç analizi sunan cross-platform (Android & iOS) bir Flutter uygulamasıdır.

---

## 🚀 Özellikler

1. **Dünya Genelinde Takım Seçimi & Arama:**
   - Ülke → Lig/Kupa → Takım gezinmesi (API-Football anahtarı ile 200+ ülkenin tüm ligleri, kupaları ve takımları).
   - Ülke/lig gezmeden doğrudan isimle **global takım araması** (üst çubuktaki 🔎 ikonu).
   - Popüler lig kısayolları, anlık arama ve Ev/Deplasman tek tuşla yer değiştirme (Swap).
   - Sezon seçici; varsayılan sezon takvimden otomatik hesaplanır.
2. **📅 Maç Programı ile Tahmin:**
   - Lig ekranında **Maçlar** sekmesi: yaklaşan maçlar gün gün listelenir (`GET /fixtures?league=&season=&next=`), son sonuçlar da görüntülenebilir.
   - Yaklaşan bir maça "Tahmin" dendiğinde iki takım gerçek verileriyle hazırlanır ve tahmin fikstür kimliğiyle kaydedilir.
   - Aynı maç tekrar tahmin edilirse geçmişte kopya oluşmaz, kayıt güncellenir.
3. **Gerçek Sezon Verisi:**
   - Takım seçildiğinde `GET /teams/statistics` ile o lig ve sezona ait **gerçek** oynanan maç, iç/dış saha gol ortalamaları, clean sheet ve form verisi çekilir.
   - `GET /players` ile kadro ve oyuncu gol/asist/reyting verisi, `GET /injuries` ile güncel sakatlar alınır.
   - Veri bulunamazsa uydurma istatistik üretilmez: tahmin lig ortalamasına düşer ve ekranda "Sınırlı Veri" uyarısı gösterilir.
   - Tüm istekler 12 saat önbelleklenir; kota dolarsa eski önbellek kullanılır.
4. **Poisson + Dixon-Coles Skor & Olasılık Motoru:**
   - Bağımsız Poisson'un düşük tahmin ettiği 0-0 ve 1-1 skorları Dixon-Coles düzeltmesiyle dengelenir; toplam olasılık korunur.
   - Sonuçlanan maçlar üzerinden **MLE ile kalibre edilen dinamik $\rho$** ve **MSE ile optimize edilen H2H ağırlığı** (`ModelCalibrator`).
   - Takımlar arasındaki son karşılaşmalar **üstel zaman sönümlemesi (time-decay)** ile değerlendirilir; yakın tarihteki maçlar daha yüksek ağırlık taşır.
   - Tek tip kimlik mimarisi sayesinde H2H analizi tüm takımlarda istisnasız çalışır.
   - Tahmin ekranında **skor olasılık ısı haritası** (6x6, tablo görünümüyle) ve **gol dağılımı grafiği** (`fl_chart`).
   - Ev ve Deplasman beklenen gol (xG / $\lambda$) hesabı.
   - En yüksek olasılıklı skor ve en olası ilk 3 skor tercihi.
   - 1X2 Maç sonucu olasılık yüzdeleri (Ev % - Beraberlik % - Deplasman %).
   - 2.5 Üst ve Karşılıklı Gol Var (KG Var) olasılıkları.
   - Adım adım anlaşılır matematiksel gerekçe listesi.
5. **Kadro & İnteraktif Sakatlık Simülasyonu:**
   - Oyuncuların gol, asist, maç sayısı ve sezon puanları.
   - Tıbbi ikonla oyuncuları anında "Sakat" olarak işaretleyip Poisson algoritmasına etkisini (hücum/savunma zafiyeti) canlı gözlemleme imkanı.
6. **Yan Yana Karşılaştırma Ekranı:**
   - Çift yönlü görsel barlar (Topla oynama, maç başı şut, isabetli şut, gol ortalamaları, clean sheet).
7. **🤖 Google Gemini AI Taktiksel Maç Raporu:**
   - Hesaplanan istatistikleri ve oyuncu eksiklerini yorumlayıp taktik kurgu, kilit eşleşmeler ve maçın kırılma anını anlatan futbol yorumcusu raporu.
8. **⚖️ Bahis Oranları Kıyaslama & Value Bet Analizi:**
   - API-Football üzerinden büroların 1X2 oranları (`GET /odds?fixture=`).
   - Kâr marjından (overround) arındırılmış saf piyasa olasılıkları ile model olasılıklarının kıyaslanması.
   - Farkın yüksek olduğu ve pozitif beklenen değer ($EV > 0$) taşıyan tercihlerde `⚡ Değerli Tercih (Value Bet)` vurgusu.
9. **📜 Tahmin Geçmişi, İsabet Karnesi ve Model Kalibratörü:**
   - `SharedPreferences` ile geçmiş tahminlerin yerel olarak kaydedilmesi ve salt okunur incelenmesi.
   - Maç oynandıktan sonra gerçek skor `GET /fixtures?id=` ile çekilir.
   - Karne: 1X2, tam skor, ilk 3 skor, 2.5 Üst/Alt ve KG Var isabet oranları.
   - Oynanmış maç sonuçlarından kalibre edilen $\rho$ ve H2H ağırlıklarının canlı gösterimi.
10. **🎨 Modern Arayüz (Material 3):**
    - Stadyum gece teması (Dark Mode) ve Aydınlık tema desteği.
11. **🔌 Çevrimdışı (Offline) Demo Desteği:**
    - API anahtarı olmadan anında zengin veriler ve simüle edilmiş piyasa oranlarıyla test edilebilir.

---

## 🧮 Tahmin Algoritmasının Matematiksel Temeli (Poisson Modeli)

Poisson dağılımı, belirli bir zaman aralığında sabit bir ortalama oranla meydana gelen bağımsız olayların sayısını modellemek için kullanılır:

$$P(k; \lambda) = \frac{\lambda^k \cdot e^{-\lambda}}{k!}$$

- **$k$**: Gerçekleşecek gol sayısı ($0, 1, 2, 3 \dots$)
- **$\lambda$ (Lambda / xG)**: Takımın beklenen gol sayısı
- **$e$**: Euler sayısı ($\approx 2.71828$)

### Adım Adım Hesaplama Akışı:
1. **Lig Gol Ortalamaları:**
   - $\text{Lig Ev Gol Ortalaması} \approx 1.55$
   - $\text{Lig Deplasman Gol Ortalaması} \approx 1.20$
2. **Hücum & Savunma Katsayıları:**
   - $\text{Ev Hücum Gücü} = \frac{\text{Ev sahibinin evde attığı gol ort.}}{1.55}$
   - $\text{Deplasman Savunma Zafiyeti} = \frac{\text{Deplasmanın dışarıda yediği gol ort.}}{1.55}$
   - $\text{Deplasman Hücum Gücü} = \frac{\text{Deplasmanın dışarıda attığı gol ort.}}{1.20}$
   - $\text{Ev Savunma Zafiyeti} = \frac{\text{Ev sahibinin evde yediği gol ort.}}{1.20}$
   - Deplasman takımlarının yediği gol ortalaması ev sahiplerinin attığına (1.55), ev sahiplerinin yediği ise deplasmanların attığına (1.20) eşittir.
   - Veri yoksa tüm katsayılar 1.0 olur ve tahmin saf lig ortalamasına yakınsar.
3. **Son 5 Maç Form Ağırlığı ($FF$):**
   - Galibiyet: 3 puan, Beraberlik: 1 puan, Mağlubiyet: 0 puan.
   - Form katsayısı $0.85$ ile $1.15$ arasında ağırlıklandırılır.
4. **Oyuncu & Sakatlık Faktörü:**
   - Kilit forvet sakatsa hücum gücü $\%12$ düşürülür.
   - As kaleci/stoper sakatsa rakibin gol beklentisi $\%10-15$ artırılır.
5. **Aralarındaki Maçlar (H2H):**
   - $w = 0.15 \times \min(n, 10) / 10$ ($n$: aralarındaki son maç sayısı)
   - $\lambda' = (1 - w)\,\lambda + w \times \text{H2H gol ortalaması}$
   - Yalnızca iki takım da API-Football kaynaklıysa uygulanır (farklı kaynakların takım kimlikleri farklı takımları gösterir).
6. **Beklenen Gol Değerleri ($\lambda_H$ ve $\lambda_A$):**
   $$\lambda_{\text{home}} = \text{EvHücum} \times \text{DepSavunma} \times 1.55 \times FF_{\text{home}} \times \text{KadroFaktörü}$$
   $$\lambda_{\text{away}} = \text{DepHücum} \times \text{EvSavunma} \times 1.20 \times FF_{\text{away}} \times \text{KadroFaktörü}$$
7. **$6 \times 6$ Skor Matrisi (Dixon-Coles):**
   - $P(h, a) = P(h; \lambda_H) \times P(a; \lambda_A) \times \tau(h, a)$
   - $\tau(0,0) = 1 - \lambda_H \lambda_A \rho$, $\tau(0,1) = 1 + \lambda_H \rho$, $\tau(1,0) = 1 + \lambda_A \rho$, $\tau(1,1) = 1 - \rho$; diğer skorlarda $\tau = 1$
   - Matris, 1X2, 2.5 Üst ve KG Var aynı toplama normalize edilir.
   - En yüksek $P(h, a)$ değerine sahip skor **Tahmini Skor** olarak belirlenir.
   - $h > a$ toplamı Ev Galibiyetini, $h == a$ Beraberliği, $h < a$ Deplasman Galibiyetini verir.

---

## 📂 Klasör Mimarisi

```
FOTTBOL/
├── pubspec.yaml                       # Bağımlılıklar (provider, fl_chart, google_generative_ai vb.)
├── lib/
│   ├── main.dart                      # Uygulama başlangıcı ve Provider sağlayıcıları
│   ├── core/
│   │   ├── cache/
│   │   │   └── cache_manager.dart     # Hive 12 saatlik TTL önbellek + stale fallback
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Koyu ve açık tema renk paletleri
│   │   │   ├── api_constants.dart     # Football API ve Gemini sabitleri
│   │   │   └── league_constants.dart  # Lig gol ortalaması referansları (1.55 / 1.20)
│   │   ├── network/
│   │   │   └── api_exceptions.dart    # Kota, ağ ve API hata tipleri
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Material 3 Açık/Koyu tema tanımları
│   │   └── utils/
│   │       ├── debouncer.dart         # Arama kutusu gecikmesi
│   │       ├── math_utils.dart        # Faktöriyel ve Poisson olasılık formülü
│   │       └── season_utils.dart      # Güncel sezonun takvimden hesaplanması
│   ├── models/
│   │   ├── team.dart                  # Takım modeli
│   │   ├── match_stat.dart            # İstatistik modeli (iç/dış saha, form, şut vb.)
│   │   ├── player.dart                # Oyuncu ve sakatlık modeli
│   │   ├── prediction_result.dart     # Tahmin, skor matrisi, gerçek sonuç ve isabet karnesi
│   │   ├── fixture.dart               # API-Football maç (fikstür) modeli
│   │   └── head_to_head.dart          # Aralarındaki maçların özeti
│   ├── services/
│   │   ├── poisson_engine.dart        # İstatistiksel skor hesaplama motoru
│   │   ├── gemini_analysis_service.dart # Gemini AI taktiksel yorum servisi
│   │   ├── api_football_service.dart  # API-Football: ülke/lig/takım + gerçek istatistik, kadro, sakatlık
│   │   ├── football_api_service.dart  # Football-Data.org: takımlar + puan durumu + gol krallığı
│   │   ├── mock_football_service.dart # Çevrimdışı hazır takım ve oyuncu verileri
│   │   └── storage_service.dart       # SharedPreferences ile geçmiş ve anahtarlar
│   ├── providers/
│   │   ├── match_prediction_provider.dart # Ana uygulama durumu ve tahmin yürütme
│   │   └── theme_provider.dart        # Koyu/Açık tema geçiş yöneticisi
│   ├── widgets/
│   │   ├── comparison_bar.dart        # Çift taraflı istatistik kıyaslama çubuğu
│   │   ├── form_badge.dart            # G/B/M renkli form butonları
│   │   ├── player_card.dart           # Oyuncu kartı ve sakatlık simülasyon butonu
│   │   ├── score_board_card.dart      # Stadyum tarzı skorbord kartı
│   │   ├── score_matrix_heatmap.dart  # 6x6 skor olasılık ısı haritası + tablo görünümü
│   │   ├── goal_distribution_chart.dart # Takım başına gol dağılımı (fl_chart)
│   │   ├── head_to_head_card.dart     # Aralarındaki son maçlar kartı
│   │   ├── fixture_tile.dart          # Fikstür maç kartı
│   │   └── accuracy_card.dart         # İsabet karnesi ve sonuç rozetleri
│   └── views/
│       ├── home_nav_screen.dart       # Alt gezinti çubuğu (Bottom Navigation)
│       ├── country_list_screen.dart   # Ülke seçimi (200+ ülke)
│       ├── league_list_screen.dart    # Ülkenin ligleri/kupaları + sezon seçici
│       ├── team_list_screen.dart      # Lig detayı: "Maçlar" ve "Takımlar" sekmeleri
│       ├── league_fixtures_view.dart  # Yaklaşan maçlar / sonuçlar, maçtan tahmin
│       ├── global_team_search_screen.dart # Dünya genelinde isimle takım arama
│       ├── team_picker.dart           # Takımı gerçek verisiyle çekip seçen ortak akış
│       ├── team_selection_screen.dart # 1. Ekran: Takım arama ve Ev/Deplasman seçimi
│       ├── team_stats_screen.dart     # 2. Ekran: Takım form ve istatistik detayları
│       ├── squad_screen.dart          # 3. Ekran: Kadro ve sakatlık kontrol ekranı
│       ├── comparison_screen.dart     # 4. Ekran: Yan yana iki takım kıyaslaması
│       ├── prediction_screen.dart     # 5. Ekran: Tahmini skor, yüzdeler & AI analizi
│       ├── history_screen.dart        # 6. Ekran: Geçmiş tahminler ve takip
│       └── settings_screen.dart       # 7. Ekran: API anahtarları & tema ayarları
```

---

## 🛠️ Nasıl Çalıştırılır?

1. **Bağımlılıkları Yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Cihazda veya Emülatörde Çalıştırın:**
   ```bash
   flutter run
   ```

3. **API Anahtarları:**
   Uygulama içerisindeki **Ayarlar & API** sekmesinden girilir:

   | Anahtar | Ne sağlar | Ücretsiz limit |
   |---|---|---|
   | **API-Football** (önerilen) | Tüm ülkeler, ligler, kupalar, takımlar + gerçek sezon istatistikleri, kadrolar, sakatlıklar ve 1X2 bahis oranları | 100 istek/gün ([api-football.com](https://www.api-football.com/)) |
   | **Gemini** | Doğal dilde taktiksel maç raporu | [aistudio.google.com](https://aistudio.google.com/) |

   - **API-Football anahtarı girilmezse** zengin çevrimdışı demo verisi ve simüle piyasa oranları kullanılır.
   - Gemini anahtarı girilmezse kural tabanlı yerel taktiksel analiz motoru devreye girer.
   - Tüm API yanıtları 12 saat önbelleklenir; kota dolduğunda eski önbellekten okunur ve kullanıcı uyarılır.
