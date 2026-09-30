# Runner Trap — Proje Planı

Güncel bölüm içerikleri, mekanikler ve sonraki seans için durum özeti: [Current Game State](docs/game-state.md). Bu dosya kararları, geçmişi ve yapılacak işleri tutar; güncel bölüm tablosu oradadır.

## Konsept
Runner sonsuz koşuyor ve yapay zekayla kendini koruyor. Oyuncu gerçek zamanlı tuzak kartları atarak runner'ı bitiş çizgisine varmadan düşürmeye çalışıyor.

Tasarım ilkesi (kullanıcı onayı, 2026-09-30): sürpriz var, karşı hamle var, haksız ceza yok. Sürprizleri seyrek ve bölüme özgü kullan; oyuncuya karşılık verme fırsatı bırak.

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
- [x] Kaybedince "reklam izle, runner -1 canla tekrar" butonu
- [x] AdMob eklentisi + AB izin ekranı (UMP) + level seçme ekranında gizlilik butonu (telefonda test reklamı doğrulandı)
- [x] Oyun içi duraklatma menüsü (devam, yeniden başla, level'lar; Android geri tuşu ve uygulamadan çıkınca otomatik duraklatma)
- [x] Play Console CLI (`gplay`) + tek komutla yayın (`tools/release.sh`), kod GitHub'da (private)
- [x] Data safety + reklam kimliği formları AdMob'a göre güncellendi, mağaza sayfası TR/EN
- [x] Kapalı teste versionCode 2 yüklendi, onaylandı (2026-09-28)
- [x] AdMob ödeme profili + ABD vergi formu W-8BEN (onaylandı, %0 stopaj, 2026-09-28)
- [x] Upload key yedeği: şifreli `runner-trap-keys.dmg`, sahibinin kişisel Google Drive'ında (2026-09-28)
- [x] Gizlilik politikası taslağı (docs/privacy-policy.md): web'de yayınlanmalı (Google Sites)
- [x] Mağaza açıklaması TR/EN (docs/store-listing.md)
- [x] Mağaza görselleri: feature graphic 1024x500, ekran görüntüleri (`tools/capture_store.gd` → build/store/)
- [ ] **Kapalı test: en az 12 test kullanıcısı, 14 gün kesintisiz** (kişisel hesaplar için zorunlu)
- [ ] Production yayını
- [ ] Yayından sonra: AdMob uygulamasını Play mağaza sayfasına bağla

## Oynanış iyileştirmeleri
- [x] Koşucu kişiliği: başarılı kaçışta gülümseme ve kısa el hareketi, öğrenilmiş tuzağı tekrar görünce odaklanma, darbe ve komboda şaşkınlık (2026-09-28). Hız, can, enerji ve yapay zekâ dengesi değişmedi.
- [x] Yeni ifadelerin telefondaki okunabilirliği kontrol edildi; kullanıcı onayladı (2026-09-28).
- [x] İlk üç bölüme isteğe bağlı görevler: en fazla 6 tuzakla kazan, en az 2 kombo yaparak kazan, tek tuzak türüyle kazan. İlk bölüm sınırı kullanıcı geri bildirimiyle 5'ten 6'ya çıkarıldı. Canlı sayaç, bitiş sonucu ve kalıcı madalya eklendi; yıldızlar ve bölüm kilitleri bağımsız kaldı (2026-09-28).
- [x] Görevler normal kazanılan turlarda değerlendirilir; reklamla yeniden başlatılan tur rozet kazandırmaz. Başarısız yerleştirmeler sayılmaz, tekrar denemede sayaçlar sıfırlanır, son darbede gelen kombo hesaba katılır.
- [ ] Görevlerin zorluğunu ve telefondaki görünümünü oynayarak kontrol et.
- [x] Yaylı zemin yalnızca 4. bölüme deneme olarak eklendi (2 enerji, tek kullanımlık). Can götürmeden fırlatır; uçuşta veya inişten sonraki 0,25 saniyede başka tuzakla darbe alınırsa +2 enerji kombo verir. Türkçe kart adı: Yay.
- [x] Yayın 4. bölümdeki telefon denemesi kullanıcı tarafından beğenildi; yay 7. bölüme de eklendi. Çift zıplayan koşucunun yay sonrası iniş çukurundan havada tekrar zıplayarak kaçabildiği test edildi.
- [ ] Yayın 7. bölümdeki hissini telefonda dene; diğer bölümlere şimdilik ekleme.
- [x] Gecikmeli kapan yalnızca 5. bölüme eklendi (2 enerji). Yerleştirmeden 0,5 saniye sonra kapanır, 0,18 saniye vurabilir ve isabet etmese de tükenir. Dolan gösterge, hareketli çeneler ve Türkçe "Kapan" kartı eklendi.
- [x] Kapan telefon denemesinde beğenilmedi; bölüm kartlarından çıkarıldı, kodu ve testleri saklandı.
- [x] Kapanın yerine yalnızca 5. bölüme Mıknatıs eklendi (3 enerji, tek kullanımlık). Koşucu alanı geçtikten sonra 0,65 saniye boyunca 240 px/sn hızla geri çekilir; tek başına can götürmez, darbe alınca çekim kesilir. Testereye geri çekilerek zincir kombo kurulabildiği test edildi.
- [x] Mıknatıs telefon denemesinde kullanıcı tarafından beğenildi; 5. bölümde mevcut haliyle kalıyor. Diğer bölümlere şimdilik ekleme.
- [x] 4. bölüme "Yay ustası" görevi eklendi: en az 1 yay kombosu yaparak kazan. Ayrı canlı sayaç ve kalıcı madalya kullanır; son darbede gelen yay kombosu sayılır, diğer kombo türleri ve reklamlı tekrarlar sayılmaz.
- [x] 4. bölümde yay görevi telefonda kullanıcı tarafından onaylandı.
- [x] 5. bölüme "Mıknatıs ustası" görevi eklendi: mıknatıs çekerken en az 1 darbe vurarak kazan. Ayrı sayaç ve kalıcı madalya; son darbe sayılır, hasarsız çekim ve çekim sonrası darbeler sayılmaz. Mevcut kombo/enerji ödülleri değişmedi.
- [x] 5. bölümde mıknatıs görevi telefonda kullanıcı tarafından onaylandı.
- [x] 8. bölümde en yakın çukur, duvar ve testerenin sürekli vurduğu testle doğrulandı. Yalnızca bu bölüme ayrı hızlı koşucu profili eklendi (tepki 0,08 sn, sapma +/-0,02 sn, öğrenme alt sınırı 0,06 sn); diğer bölümler değişmedi. Hatasız koşucu en yakın tekli tuzaklardan kaçabiliyor. 20'şer bot turunda casual %10, good %15 kazandı; bu insan oyuncu zorluğunun kesin ölçüsü değil.
- [x] 8. bölümün yeni zorluğu telefonda kullanıcı tarafından onaylandı; önceki ayardan daha iyi bulundu.
- [x] 6. bölüme "Tam cephanelik" görevi eklendi: çukur, duvar ve testereyi kullanarak kazan. Üç türün başarılı yerleştirmeleri sayılır; her türün vurması gerekmez. Tekrarlar ve reddedilen bırakmalar tür sayısını artırmaz; kayıp ve reklamlı tekrar madalya kazandırmaz.
- [x] 6. bölümün "Tam cephanelik" görevi telefonda kullanıcı tarafından onaylandı.
- [x] Sabit parkur cismi denemesi: yalnızca 7. bölüme 1400 px noktasında tahterevalli eklendi. Normal koşuda sallanır; yaydan en az 400 px/sn inişte bir kez 740 px/sn hızla yeniden fırlatır. Tek başına hasar/kombo vermez, çift zıplama hakkını ve yay kombosu penceresini korur. Üstüne kart bırakılamaz; duraklatma ve yeniden başlatma test edildi.
- [ ] 7. bölümde tahterevalliyi telefonda dene: önce normal geçiş, sonra önüne yay koyarak ikinci sıçrama. Görünürlüğü ve inişi ayarlama zorluğunu değerlendir.
- [x] Tahterevalli görünürlük geri bildirimi: 1400 px yerine 850 px noktasına alındı; ilk ekranda tamamen görünür, boşta eğik durur. Normal geçiş ve yaydan fırlatma yeniden test edildi.
- [x] İkinci görünürlük düzeltmesi: zemine gömülü ince çizim yerine 44 px yükseltilmiş kiriş, belirgin turkuaz ayak ve iki yanda 100 px geçiş rampaları eklendi. 960x432 sessiz görsel testinde zeminin üstünde gerçek kiriş/ayak pikselleri doğrulandı; yalnızca nesnenin konumunu kontrol etmek yeterli değildi.
- [x] Asıl Android farkı APK okunarak bulundu: kaynakta dolu olan `PackedFloat32Array` tahterevalli konumları derlenmiş bölümde boş kalıyordu; yeniden içe aktarma/önbellek yenileme çözmedi. `Array[float]` ile APK da `[850]` taşıyor. `tools/check_seesaw_export.gd` kaynak, normal ikili kayıt ve gerçek APK bölümünü karşılaştırıyor.
- [x] Bölüm seçiminde görev yazılarının kutudan taşması düzeltildi: kutu ölçüleri tema yüklendikten sonra içerik ve iç boşluğa göre hesaplanıyor. Türkçe küçük ekran testinde her yazı ve yıldız satırının kutu içinde kaldığı doğrulandı.
- [x] Tüm bölümlerde en yakın tekli tuzağın kaçınılmaz vurması düzeltildi: normal zeminde yeni görülen çukur/duvar/testere için tepki beklemesi yaklaşma süresine göre kısaltılıyor. 10 bölümde kaçış testi geçti; rastgele hatalar, kaygan zemin ve havada geç konan tuzaklar korunuyor. Kısa bot denemesinde her bölümde galibiyet görüldü; telefon dengesi ayrıca değerlendirilecek.
- [x] Tahterevallinin 7. bölümde telefonda göründüğü kullanıcı tarafından onaylandı (2026-09-28).
- [x] Öfkeli koşucu: darbe sonrası şaşkınlıktan 2 saniyelik çatık kaş/sıkılı yumruk tepkisine geçer. 6 saniye içinde yeniden vurulursa diş sıkma ve kırmızı öfke işaretiyle 3 saniye sürer. Hız, can, yapay zekâ ve zorluk değişmez; yere düşme ifadesi önceliklidir.
- [ ] Öfke ifadelerinin telefondaki görünümünü kullanıcıyla kontrol et.
- [ ] Sonraki deney fikri: tek kartlık "şimdi zıpla" sabotajı kullanıcı tarafından beğenildi; henüz uygulanmadı.

## Açık konular
- [x] 7. bölüme "Tahterevalli ustası" görevi eklendi (2026-09-30): yaydan tahterevalliye en az 1 başarılı yeniden fırlatma ve normal turda galibiyet. Canlı sayaç, sonuç ve kalıcı madalya mevcut görev sistemine bağlandı. Normal geçiş/yalnızca yay kombosu sayılmaz; reklamlı tekrar madalya vermez. Fizik ve enerji dengesi değişmedi; APK içindeki görev de doğrulandı. Henüz yayınlanmadı.
- [x] 7. bölüm görevi telefona kuruldu ve kullanıcı tarafından onaylandı (2026-09-30).
- [x] 8. bölüme "Hızlı avcı" görevi eklendi: parkurun ilk %50'sinde normal turda kazan. Tam yarı çizgisi sayılır; hemen sonrası sayılmaz. Canlı yüzde, kaçırılan hedef bildirimi ve kalıcı madalya mevcut sisteme bağlandı; son darbe konumu kaydediliyor. Hız, yapay zekâ, enerji ve yıldız kuralları değişmedi. Sekiz oyun testi ve APK görev kontrolü geçti; henüz yayınlanmadı.
- [x] 8. bölüm "Hızlı avcı" görevi telefonda kullanıcı tarafından onaylandı (2026-09-30).
- [x] 9. bölüme "Sahte bitiş" deneyi eklendi (2026-09-30): 2 enerji, tur başına tek yerleştirme. Koşucu kollarını kaldırıp 1,8 saniye %45 hızla kutlar ve kaçınmaz; kurtulursa 1,8 saniye %35 hızlanıp öfkelenir. Darbe etkiyi iptal eder; çizgi tek başına can götürmez veya bölümü bitirmez. Henüz yayınlanmadı.
- [x] 9. bölüm "Sahte bitiş" deneyi telefonda kullanıcı tarafından onaylandı (2026-09-30).
- [x] Sahte bitiş için sekiz oyun testi, 960x432 ve 1280x720 Türkçe çizim/yazı sınırı kontrolleri geçti. Paket içindeki 7, 8 ve 9. bölüm verileri doğrulandı. Kablosuz ADB yeniden bağlandı; APK ilerleme korunarak telefona kuruldu ve oyun açıldı (2026-09-30). Kullanıcı onayladı; Play'e yüklenmedi.
- [x] 10. bölüme "Koşucunun intikamı" deneyi eklendi: ilk duvarı koşucu yerden söküp ekrana fırlatır. 1,5 saniyelik halkası bitmeden dokununca aynı duvar ücretsiz geri düşer; kaçırınca sadece o duvar kaybolur. Turda tek fırsat, sonraki duvarlar normal. Sekiz oyun testi ve 960x432 Türkçe piksel/yerleşim kontrolü geçti; henüz yayınlanmadı.
- [x] 10. bölümün duvar düellosu telefonda kullanıcı tarafından onaylandı (2026-09-30).
- [x] Duvar düellosu 960x432 ve 1280x720 Türkçe görünüm kontrollerini geçti. Gerçek APK'daki 7–10. bölüm verileri doğrulandı; telefon bağlantısı yenilenip ilerleme korunarak kuruldu ve oyun açıldı (2026-09-30). Kullanıcı onayladı; Play'e yüklenmedi.
- [x] 11. bölüm "Son can, son numara" deneyi eklendi: hızlı koşucu son canda toparlanınca turda bir kez şemsiye açar. Testere can götürmeden şemsiyeyi kapatır; arkasındaki çukur inişi yakalayabilir. Duraklatma, tekrar ve bitiş durumları test edildi. İlk 10 bölümün ayarları değişmedi; 11. bölüm 10'u geçince açılır. Uçuş yüksekliği ve süre kuralı aşağıdaki kullanıcı geri bildirimiyle güncellendi.
- [x] Şemsiye için sekiz oyun testi, 960x432 ve 1280x720 Türkçe şemsiye/11 bölümlü menü kontrolleri geçti. Gerçek APK'nın 7–11. bölüm verileri doğrulandı; telefon ilerleme korunarak güncellendi ve oyun açıldı (2026-09-30). Play'e yüklenmedi.
- [ ] 11. bölümü telefonda dene: son canda şemsiye açıldığında testere ve hemen arkasına çukur yerleştir; görünürlüğü ve zamanlama zorluğunu değerlendir.
- [x] Kullanıcı geri bildirimiyle şemsiye güncellendi: artık 84 piksel yüksekte duvarları da aşar, süreyle kapanmaz; oyun sırasında yalnızca testere kapatır. Kalkışta da normal hasar alamaz, kapandıktan sonra duvarlar tekrar etkili olur. Sadece 11. bölümün testeresi hem yer hem uçuş yüksekliğine ulaşacak şekilde yükseltildi; ilk 10 bölüm değişmedi. Sekiz oyun testi geçti (2026-09-30).
- [x] Güncellenmiş şemsiye iki çözünürlükte piksel kontrollerinden geçti; yeni APK'da 7–11. bölüm verileri ve yükseltilmiş testerenin çizim/çarpışma yüksekliği doğrulandı. Telefon ilerleme korunarak güncellendi ve oyun açıldı; yeni kuralın telefon onayı bekleniyor. Play'e yüklenmedi (2026-09-30).
- [x] 1.0.1 hazırlığı: yayın test kapısı çıkış kodu ve hata satırlarını da denetliyor; belirsiz yüklemede sürüm kodu korunuyor. 10 izole yayın testi geçti; Türkçe/İngilizce sürüm notları güncellendi.
- [x] 1.0.1 / kod 3 imzalı deneme derlemesi tamamlandı; sekiz oyun testi geçti. Hazırlık commit'i `833816b` GitHub'a gönderildi. AAB imzası doğrulandı; 7. bölüm verisi doğrulanmış APK ile aynı. Yerel sürüm ayarı 1.0.0 / kod 2'ye geri alındı; Play'e yükleme yapılmadı.
- [x] Kullanıcı onayıyla 1.0.1 / kod 3 kapalı teste yüklendi (2026-09-28). İlk deneme sürüm notlarının nesne biçimini reddetti; language/text listesine dönüştürülüp CLI dry-run kontrolünden sonra aynı kod 3 paketi başarıyla gönderildi. Play durumu incelemede; kod 2 hâlâ yayınlı. Sürüm etiketi: `v1.0.1-3`, sonraki kod 4.
- [ ] 1.0.1 inceleme sonucunu ve kapalı test kullanıcılara açılmasını kontrol et.
- ~~Oyunun adı~~ → **Runner Trap** (paket: `com.goezkazanc.runnertrap`)
- 12 test kullanıcısı listesi
