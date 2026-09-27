# Runner Trap — Proje Planı

## Konsept
Runner sonsuz koşuyor ve yapay zekayla kendini koruyor. Oyuncu gerçek zamanlı tuzak kartları atarak runner'ı bitiş çizgisine varmadan düşürmeye çalışıyor.

## Kararlar
| Konu | Karar |
|---|---|
| Motor | Godot 4 + GDScript, 2D |
| Ekran | Yatay (landscape), runner soldan sağa koşar |
| Kazanma | Can sistemi: runner'ın 3 canı var, bitişe varmadan 3 kez düşür |
| Yıldız | Kalan enerji / süreye göre 1–3 yıldız |
| Görsel stil | Minimal / flat (düz renkler, basit şekiller) |
| İsim | Runner Trap (paket `com.goezkazanc.runnertrap`, ilk Play yüklemesinden sonra değişmez) |
| Dil | TR + EN baştan (Godot çeviri sistemi) |
| Para kazanma | AdMob ödüllü reklam + reklam kaldırma satın alımı + kozmetik |

## Temel mekanikler
- **Tuzak kartları:** Ekranın altında 3–4 kart var. Sürükleyip runner'ın önündeki yola bırakılıyor.
- **Enerji:** Her tuzağın maliyeti var, enerji zamanla doluyor.
- **Runner yapay zekası:** Önündeki tuzağı görüyor ve tepki veriyor (zıplama, kayma, durma). Tepki süresi ve beceri değerleri runner tipine göre değişiyor.
- **Öğrenme:** Aynı tuzak tipi tekrar tekrar kullanılırsa runner ona alışıyor, tepki süresi kısalıyor.
- **Kombolar:** Tuzak kombinasyonları (ör. kaygan zemin + çukur) başarı şansını artırıyor.
- **Runner tipleri:** Hızlı/sakar, yavaş/çift zıplayan, duvara tırmanan ninja, boss runner'lar.

## Mimari
- Level'lar `Resource` (`.tres`) veri dosyası olarak tutulur, level eklemek için kod gerekmez.
- Tüm tuzaklar ortak `Trap` temel sınıfından türer.
- Runner parametreleri (hız, tepki süresi, zıplama gücü) `RunnerProfile` resource'unda.
- Oyun durumu tek bir autoload singleton'da (`GameState`), kayıtlar `user://save.cfg` dosyasında.

## Fazlar
### Faz 0 — Kurulum
- [x] Godot 4 kurulumu (`brew install --cask godot`) — 4.7.2
- [x] Git repo, `.gitignore`, proje iskeleti

### Faz 1 — Prototip (1. hafta)
- [x] Kutu grafikler, yatay kamera takibi
- [x] 1 runner, 4 tuzak: çukur, duvar, testere, kaygan zemin (+ hızlı/sakar runner, level 3)
- [x] Enerji sistemi, kart sürükle-bırak
- [x] Can sistemi, kazanma/kaybetme ekranı
- [x] 3 test leveli
- [x] Runner yapay zekası + öğrenme (Faz 2'den öne çekildi)
- [x] **Karar noktası:** Oyun eğlenceli mi? Değilse mekaniği değiştir.

### Faz 2 — Oyun içeriği (2.–3. hafta)
- [x] Runner öğrenme sistemi (tepki süresi tuzak tipine alışıyor), kombolar (zincir + kaygan, +2 enerji)
- [x] Akıllı zıplama planı (bilinen tuzak zincirini hesaba katar; iniş tuzağı ancak geç konursa işe yarar)
- [x] 10 level, level seçme ekranı, yıldızlar (4 runner tipi: basic, fast, çift zıplayan jumper, pro)
- [x] Kayıt sistemi (yıldızlar + level kilidi)
- [x] TR/EN çeviri (CSV, sistem dili + level seçme ekranında dil butonu)

### Faz 3 — Android
- [x] JDK 17, Android SDK, Godot export templates (debug APK export çalışıyor)
- [x] Telefonda test (kablosuz ADB, Galaxy S25 Ultra): dokunmatik ve performans sorunsuz; bot simülasyonuyla 6–10 dengelendi

### Faz 4 — Görsel ve ses
- [x] Flat stil görseller (kodla çizilen karakter, parallax arka plan, tuzak detayları, kart ikonları), efektler (sarsıntı, partikül, düşme, ağır çekim, titreşim)
- [x] Müzik ve efekt sesleri (tools/make_sounds.gd ile sentezleniyor, ses aç/kapa butonu)

### Faz 5 — Yayın
- [x] Play Console hesabı (tek seferlik 25 $)
- [x] Uygulama ikonu (tools/make_icon.gd), imzalı AAB (tools/export_release.sh, upload key `~/Keys/runner-trap/`, repo dışında)
- [x] Kaybedince "reklam izle, runner -1 canla tekrar" butonu (Ads autoload şimdilik sahte, ödülü hemen veriyor)
- [ ] AdMob eklentisi + AB izin ekranı (UMP) + ayarlardan izni değiştirme
- [x] Gizlilik politikası taslağı (docs/privacy-policy.md): web'de yayınlanmalı (Google Sites)
- [x] Mağaza açıklaması TR/EN (docs/store-listing.md)
- [ ] Mağaza görselleri: feature graphic 1024x500, ekran görüntüleri
- [ ] **Kapalı test: en az 12 test kullanıcısı, 14 gün kesintisiz** (kişisel hesaplar için zorunlu)
- [ ] Production yayını

## Açık konular
- ~~Oyunun adı~~ → **Runner Trap** (paket: `com.goezkazanc.runnertrap`)
- 12 test kullanıcısı listesi
