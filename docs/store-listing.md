# Play Store listing

Limits: title 30 characters, short description 80, full description 4000.

## English (en-US)

**Title:** Runner Trap

**Short description:**
Drag traps, outsmart the runner. Knock it down 3 times before the finish!

**Full description:**

The runner never stops, and it's smart. Your job is to stop it.

Drag trap cards onto the track in real time: pits, walls, saw blades and slippery floors. The runner sees them coming and reacts by jumping, sliding or stopping. Knock it down 3 times before it reaches the finish line to win.

HOW IT WORKS
• Every trap costs energy, and energy refills over time. Spend it wisely.
• The runner learns. Use the same trap again and again, and it reacts faster every time.
• Chain traps into combos to earn bonus energy. Hit it right after a dodge, or while it slips.
• Place a trap too early and the runner has time to react. Place it too late and you miss your chance.

FEATURES
• 10 levels with 4 runner types: basic, fast and clumsy, double-jumping jumper, and pro
• Up to 3 stars per level. Knock the runner down early for more stars.
• Simple one-finger drag controls
• Clean flat graphics, short rounds, and no internet needed to play
• English and Turkish

Can you outsmart the runner?

## Türkçe (tr-TR)

**Başlık:** Runner Trap

**Kısa açıklama:**
Tuzakları sürükle, runner'ı alt et. Bitiş çizgisinden önce 3 kez düşür!

**Tam açıklama:**

Runner hiç durmuyor, üstelik akıllı. Onu durdurmak senin işin.

Tuzak kartlarını gerçek zamanlı olarak yola sürükle: çukur, duvar, testere ve kaygan zemin. Runner tuzakları görüyor; zıplıyor, kayıyor ya da duruyor. Bitiş çizgisine varmadan onu 3 kez düşürürsen kazanırsın.

NASIL OYNANIR
• Her tuzağın bir enerji maliyeti var ve enerji zamanla doluyor. Akıllıca harca.
• Runner öğreniyor. Aynı tuzağı tekrar tekrar kullanırsan her seferinde daha hızlı tepki veriyor.
• Tuzakları birleştirip kombo yap, bonus enerji kazan. Bir tuzaktan kaçtığı anda ya da kayarken vur.
• Tuzağı çok erken koyarsan runner tepki verir. Çok geç koyarsan fırsat kaçar.

ÖZELLİKLER
• 10 bölüm, 4 runner tipi: basit, hızlı ve sakar, çift zıplayan ve profesyonel
• Her bölümde 3 yıldıza kadar. Runner'ı ne kadar erken düşürürsen o kadar çok yıldız.
• Tek parmakla basit sürükle-bırak kontrolü
• Sade, düz grafikler, kısa bölümler, oynamak için internet gerekmez
• Türkçe ve İngilizce

Runner'ı alt edebilir misin?

## Store settings

| Field | Value |
|---|---|
| Category | Game › Puzzle (alternative: Casual) |
| Contains ads | Yes (AdMob rewarded ads) |
| Privacy policy | https://sites.google.com/view/runnertrap-privacy/ana-sayfa (Google Sites, from `docs/privacy-policy.md`) |
| Target audience | 13+ (not directed at children) |
| Content rating | IARC questionnaire: no violence against people, no gambling, no user-generated content |

## Graphics

| Asset | Size | Source |
|---|---|---|
| App icon | 512 x 512 PNG | `assets/icon/icon.png` |
| Feature graphic | 1024 x 500 PNG/JPG | `build/store/feature_graphic.png` |
| Phone screenshots | 2 to 8, 16:9 landscape | `build/store/en_1..6.png`, `tr_1..6.png` (1920 x 1080) |

Regenerate: `godot --path . --resolution 1920x1080 --fixed-fps 60 -s res://tools/capture_store.gd -- en` (or `tr`) writes to /tmp/runner-trap-store/; screenshots used are select, play_18, play_24, play_30, play_46, win.
