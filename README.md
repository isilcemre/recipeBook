# My Recipe Book

Flutter ile geliştirilmiş kişisel tarif defteri uygulaması. Firebase Authentication ve Firestore kullanır.

## Kurulum

### 1. Bağımlılıkları yükle

```bash
flutter pub get
```

### 2. Firebase yapılandırması

Bu proje Firebase kullanmaktadır. Hassas yapılandırma dosyaları (API key'ler) git'e dahil edilmemiştir. Kurulum için:

**a) Firebase projeni oluştur veya mevcut projeye bağlan:**

```bash
# FlutterFire CLI kur
dart pub global activate flutterfire_cli

# Firebase projene bağla (firebase_options.dart otomatik oluşturulur)
flutterfire configure
```

**b) Android için `google-services.json` dosyasını al:**

- [Firebase Console](https://console.firebase.google.com) → Proje Ayarları → Android uygulaması
- İndir: `google-services.json`
- Şuraya koy: `android/app/google-services.json`

> Şablon için: `android/app/google-services.json.example` dosyasına bak.

### 3. Uygulamayı çalıştır

```bash
flutter run
```

## Güvenlik Notu

`firebase_options.dart`, `google-services.json` ve `GoogleService-Info.plist` dosyaları `.gitignore`'a eklenmiştir.  
Firebase Security Rules ile verilerini korumayı unutma.
