# FOTTBOL Agent Geliştirme ve Kalite Kuralları

Bu dosya, FOTTBOL projesinde kod yazarken uyulması zorunlu geliştirme standartlarını, otonomi seviyesini ve doğrulama kurallarını tanımlar.

## 1. Otonomi ve Onay Standartları (Kritik Kullanıcı Kuralı)
- **Sormadan Doğrudan Yap (Full Autonomous):** Kod yazma, dosya oluşturma/düzenleme, hata ayıklama, bağımlılıkları kontrol etme, `flutter analyze` ve birim testleri (`flutter test`) çalıştırma işlemlerinde KULLANICIDAN ASLA ONAY İSTENMEZ. İşlemler doğrudan yapılır, test edilir ve sadece nihai özet sonuç bildirilir.
- **Yalnızca Şunlarda Onay İste:** Canlıya alma (deploy), üretim sürümü derleme (production release build - APK, ZIP, EXE çıkarma) ve harici ortama yayınlama adımlarında kullanıcı onayı alınır.

## 2. Kod Değişikliği Sonrası Doğrulama Zorunluluğu (Definition of Done)
- Herhangi bir Dart dosyasında (`lib/` veya `test/`) değişiklik yapıldığında:
  1. MCP aracı veya terminal üzerinden analiz (`analyze_files` / `flutter analyze`) çalıştırılmalıdır.
  2. Yapılan değişiklik bir servisi veya mantığı ilgilendiriyorsa, ilgili test dosyası (`flutter test test/...`) çalıştırılmalıdır.
  3. Yeni bir mantık veya formül eklendiğinde, `test/` altına karşılık gelen birim testi eklenmelidir.
  4. Analiz hatası veya kırılan testler giderilmeden görev tamamlandı sayılmaz.

## 3. Mimari ve Deterministik Kurallar
- Olasılık, xG, Poisson, Elo, kart/korner ve form hesaplamaları **%100 Dart tarafında deterministik** olarak hesaplanır. LLM asla matematiksel olasılık uyduramaz.
- Sabit/kopya şablon veri kullanılmaz. Her zaman gerçek API veya `FootballOfflineRepository`'nin dinamik kulüp DNA motoru devrededir.
- Null-safety kurallarına sıkı sıkıya uyulmalı, beklenmeyen JSON yapıları güvenli biçimde (`try-catch` veya `num.tryParse`) handle edilmelidir.
