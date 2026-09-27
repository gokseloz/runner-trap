# Runner Trap

A 2D mobile game made with Godot 4. The runner never stops and dodges on its own: it jumps, slides or stops when it sees a trap. You drag trap cards onto the track in real time and try to knock it down 3 times before it reaches the finish line.

- 10 levels, 4 runner types (basic, fast and clumsy, jumper, pro)
- Pit, wall, saw and slippery floor traps; energy cost per trap
- The runner learns: a trap used again and again gets dodged faster
- Combos (hit right after a dodge, or while slipping) give bonus energy
- 1–3 stars per level, pause menu, English and Turkish
- AdMob rewarded ad to continue a lost level, with UMP consent

Status: closed testing on Google Play (Android). The design plan and progress are in [PLAN.md](PLAN.md) (Turkish).

## Requirements

- Godot 4.7 (`brew install --cask godot`)
- For Android builds: JDK 17, Android SDK command-line tools and the Godot 4.7 Android export templates

## Run

Open `project.godot` in Godot and press Play. The main scene is `scenes/level_select.tscn`.

Debug keys in a level: `Space`/`Up` jump, `Down` slide, `S` stop, `H` hit, `A` toggle runner AI, `R` restart, `N` next level, `Esc` level select.

## Tests

Headless test scripts live in `tests/`:

```sh
godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
```

`tests/balance_sim.gd -- runs=40 levels=6,7` runs bot players against levels and prints win rates.

After adding a `class_name` or editing `locale/translations.csv`, run `godot --headless --import` first.

## Android builds

```sh
# Debug APK
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ANDROID_HOME=/opt/homebrew/share/android-commandlinetools \
  godot --headless --export-debug "Android" build/runner-trap.apk

# Signed release bundle for Google Play (keystore lives outside the repo)
tools/export_release.sh
```

Both presets use the Gradle build (required by the AdMob plugin). Bump `version/code` in `export_presets.cfg` before every Play upload.

## Project layout

| Path | Contents |
|---|---|
| `scenes/` | Level, level select, runner and trap scenes |
| `scripts/autoload/` | `GameState` (progress, save file), `Audio`, `Ads` |
| `scripts/level/`, `scripts/runner/`, `scripts/traps/`, `scripts/ui/` | Gameplay and UI code |
| `resources/` | Level and runner data (`.tres`), add a level without code |
| `locale/` | Translations (EN, TR) |
| `audio/` | Generated sound effects and music |
| `assets/icon/` | Generated app icon |
| `tools/` | Sound, icon and store screenshot generators, release export |
| `addons/admob/` | Poing Studios AdMob plugin |
| `docs/` | Privacy policy and store listing text |
