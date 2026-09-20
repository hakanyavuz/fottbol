# 📱 Android ve iOS Build Alma ve Test Rehberi

Bu rehber, **FOTTBOL** uygulamasını hem **Android** hem de **iOS (iPhone)** için Windows üzerinden kolayca test etmeniz ve derlemeniz için gereken tüm araçları içerir.

---

## ⚡ HIZLI TEST VE ÇALIŞTIRMA (Windows Üzerinden Tek Tıkla)

### 🍏 1. iPhone 15/16 Pro Simülatöründe Çalıştırma (Mac Gerekmez)
Proje kök dizinindeki hazır başlatıcıyı çift tıklayarak çalıştırabilirsiniz:
- **Dosya:** `RUN_IPHONE_SIMULATOR.bat`
- **Ne Yapar:** Chrome üzerinde doğrudan iPhone 15/16 Pro çözünürlüğü (430x932), iOS dokunmatik kaydırma fiziği ve iOS User-Agent ile uygulamayı başlatır.
- **Farklı iPhone Seçme:** Açılan pencerede klavyeden `F12` tuşuna basıp `Ctrl + Shift + M` ile cihaz listesinden (iPhone 14 Pro, iPhone SE, iPad mini vb.) dilediğinizi seçebilirsiniz.

### 🤖 2. Android Emülatörde Canlı Test
- **Dosya:** `RUN_ANDROID_EMULATOR.bat`
- **Ne Yapar:** Bilgisayarınızdaki `Testing_Device` emülatörünü otomatik açar ve uygulamayı içine yükler.

### 📦 3. Hazır Derlenmiş Android APK Dosyası
Uygulamanız Android için derlenmiş ve hazırdır:
- **Konum:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Kullanım:** Bu dosyayı doğrudan kendi Android telefonunuza (WhatsApp, Google Drive veya USB kablosu ile) gönderip kurabilirsiniz.

### ☁️ 4. GitHub Actions ile Bulutta Ücretsiz Gerçek iOS (.IPA) Derlemesi
Windows üzerinde Xcode çalışmadığı için projenize otomatik bir GitHub Actions iş akışı kurulmuştur:
- **İş Akışı Dosyası:** `.github/workflows/build_mobile.yml`
- **Nasıl Çalışır?** Projenizi GitHub'a yüklediğinizde, GitHub'ın ücretsiz **macOS** bulut sunucuları otomatik olarak devreye girer, gerçek bir Mac üzerinde projeyi derler ve size indirilebilir bir **`FOTTBOL_iOS_unsigned.ipa`** ve **`app-release.apk`** dosyası üretir!

---

## 🤖 1. ANDROID DERLEME VE YAYINLAMA

### 1.1 İnternet İznini Ekleyin
API istekleri ve Gemini bağlantısı için Android'in internete erişim iznine ihtiyacı vardır:
`android/app/src/main/AndroidManifest.xml` dosyasını açıp `<manifest ...>` etiketinin hemen altına ekleyin:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 1.2 İmzalama Anahtarı (Keystore) Oluşturma
Google Play'e uygulama yüklemek için bir release keystore oluşturmanız gerekir:

Windows PowerShell üzerinde şu komutu çalıştırın:
```powershell
keytool -genkey -v -keystore "C:\Users\DELL\upload-keystore.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*(Sizden şifre ve isim gibi bilgiler isteyecektir; şifrenizi güvenli bir yere not edin).*

### 1.3 `key.properties` Dosyasını Oluşturma
`android/key.properties` isimli bir dosya oluşturup içine şunları yazın:
```properties
storePassword=VERDIGINIZ_SIFRE
keyPassword=VERDIGINIZ_SIFRE
keyAlias=upload
storeFile=C:\\Users\\DELL\\upload-keystore.jks
```

### 1.4 `android/app/build.gradle` Yapılandırması
`android/app/build.gradle` dosyanızda imzalama ayarını bağlayın:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = file(keystoreProperties['storeFile'])
            storePassword = keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 1.5 App Bundle (.aab) Üretimi
Google Play artık `.apk` yerine `.aab` formatı zorunlu tutmaktadır:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
- Çıktı dosyanız: `build/app/outputs/bundle/release/app-release.aab` adresinde oluşacaktır.

### 1.6 Google Play Console Adımları
1. [Google Play Console](https://play.google.com/console) hesabınıza giriş yapın.
2. **Uygulama Oluştur** diyerek isim, dil ve tür (Ücretsiz) seçin.
3. **Dahili Test (Internal Testing)** veya **Üretim (Production)** sekmesinden yeni sürüm oluşturup `.aab` dosyasını sürükleyin.
4. Mağaza giriş bilgilerini (Ekran görüntüleri, açıklama, gizlilik politikası) tamamlayıp incelemeye gönderin.

---

## 🍏 2. iOS DERLEME VE YAYINLAMA

> **Not:** iOS derlemesi alabilmek için macOS yüklü bir bilgisayar ve Xcode gereklidir.

### 2.1 CocoaPods ve Bağımlılıkları Kurma
Terminal üzerinden proje dizininde:
```bash
cd ios
pod install --repo-update
cd ..
```

### 2.2 Xcode ile Projeyi Açma
`ios/Runner.xcworkspace` dosyasını Xcode ile açın.

### 2.3 Signing & Capabilities (İmzalama ve Sertifikalar)
1. Xcode sol menüsünden **Runner** projesini seçin.
2. **Signing & Capabilities** sekmesine gelin.
3. **Automatically manage signing** kutusunu işaretleyin.
4. **Team** kısmından Apple Geliştirici Hesabınızı seçin.
5. **Bundle Identifier** kısmına benzersiz bir kimlik verin (örneğin: `com.fottbol.prediction`).

### 2.4 Sürüm Numarasını Güncelleme
`pubspec.yaml` içindeki versiyon numarasını düzenleyin:
```yaml
version: 1.0.0+1
```
*(Her yeni App Store gönderiminde `+1` olan build numarasını `+2`, `+3` şeklinde artırın).*

### 2.5 IPA Arşivi Alma
Terminalden derleme:
```bash
flutter clean
flutter pub get
flutter build ipa --release
```
Veya Xcode içinden:
1. Xcode menüsünden hedef cihazı **Any iOS Device (arm64)** olarak seçin.
2. Üst menüden **Product -> Archive** seçeneğine tıklayın.
3. Arşivleme tamamlandığında açılan Organizer penceresinde **Distribute App** butonuna basın.
4. **App Store Connect** seçeneğini seçip sertifikaları doğrulayarak yüklemeyi başlatın.

### 2.6 App Store Connect ve TestFlight
1. [App Store Connect](https://appstoreconnect.apple.com) sitesine gidin.
2. **TestFlight** sekmesinden yüklenen derlemeyi seçip dahili test kullanıcılarına dağıtın.
3. Ekran görüntüleri, ikonlar (1024x1024) ve açıklama metinlerini girerek uygulamayı Apple incelemesine gönderin.
