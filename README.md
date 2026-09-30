# Runner Trap

A 2D mobile game made with Godot 4. The runner never stops and dodges on its own: it jumps, slides or stops when it sees a trap. You drag trap cards onto the track in real time and try to knock it down 3 times before it reaches the finish line.

- 11 levels, 4 runner types (basic, fast and clumsy, jumper, pro)
- Level 8 uses a separate veteran fast-runner profile (0.08s reaction, +/-0.02s jitter) so the closest legal lone traps are avoidable. Earlier fast-runner levels keep their original reaction settings; mistakes and trap combinations can still cause hits.
- Pit, wall, saw and slippery floor traps; energy cost per trap
- Levels 4 and 7: a single-use Spring (2 energy) launches the runner without damage. A hit during the flight or within 0.25 seconds after landing grants a spring combo (+2 energy). Level 7's jumper retains its air jump and can change its landing to dodge a pit.
- Level 7 trial: a fixed seesaw at track position 850 is visible from the start, rests tilted, and rocks during normal crossings. Its 240px beam stands 44px above ground on a teal support, with 100px approach ramps on both sides. Landing on the beam from a spring at 400px/s or faster triggers one stronger launch (740px/s), with no damage or free combo. The jumper retains its air jump and spring-combo eligibility. Trap drops overlapping the beam or ramps are rejected without spending energy; place a spring before it and aim the landing onto the beam. Pausing freezes it, and restarting resets it.
- Level 5 trial: Magnet (3 energy) activates as the runner passes through its field, then pulls backward at 240 px/s for 0.65 seconds. It is single-use and harmless alone; pulling the runner back into a dodged trap can earn a chain combo. Damage interrupts the pull, and pausing freezes it. The retired Snap prototype remains in the source and tests but is not offered in any level.
- The runner learns: a trap used again and again gets dodged faster
- Level 11 trial (unreleased): after recovering from the hit that leaves one life, the runner opens an umbrella once and glides about 84px above the track, clearing pits and walls. It never times out: only a saw closes it during play. This level's slightly raised saw reaches both grounded and gliding runners. Closing the umbrella takes no life and awards no combo; set a pit beyond it to catch the landing. Ordinary damage is blocked while open, including during ascent, and works normally after closure. Pause freezes movement; retry resets the opportunity and the real finish still ends the level. Beat level 10 to unlock this level; the first ten level configurations are unchanged.
- Level 10 trial (unreleased): the runner uproots the first placed wall when approaching it on the ground and throws it toward the screen. Tap the large brick before its 1.5-second ring expires to send that same wall falling back onto the track for free. It uses normal collision damage and invulnerability; a miss simply loses the original wall. Later walls behave normally. Card dragging passes through the target; pause freezes the catch window and return flight, and level end cancels both.
- Level 9 trial (unreleased): Fake finish costs 2 energy and can be placed once per run. A grounded runner raises its arms and celebrates for 1.8 seconds at 45% speed without dodging. Place a real trap ahead during this window. If it escapes unharmed, it becomes angry and runs 35% faster for 1.8 seconds, with dodging restored. Damage cancels the effect; pausing freezes it and restarting restores the card. The fake line never ends the level or deals damage itself.
- On normal ground, newly spotted pits, walls and saws cap reaction delay using time to contact, reserving 0.18 seconds for an evasive action. Closest legal lone traps are avoidable in all levels; random mistakes still apply. Airborne and slippery-floor encounters retain their original reaction timing so late landing traps and slippery combos remain effective.
- Combos (hit right after a dodge, or while slipping) give bonus energy
- 1–3 stars per level, pause menu, English and Turkish
- Optional challenges in levels 1–6 with live progress and permanent medals: win with at most 6 traps, win with at least 2 combos, win with only one trap type, win with at least 1 spring combo, win with at least 1 damaging hit during a magnet pull, or win using all 3 offered trap types. Level 6 counts successful placements of pit, wall and saw, not hits; repeats and rejected drops do not add types. Levels 4 and 5 track their own qualifying hits, including the knockout hit. Pulling alone or damage after a pull ends does not count toward level 5; existing combo bonuses are unchanged. Challenges do not affect stars or level unlocks; rewarded-ad retries are ineligible.
- AdMob rewarded ad to continue a lost level, with UMP consent

Unreleased (2026-09-30): level 7 adds the optional Seesaw master challenge. Trigger at least one successful spring-to-seesaw launch, then win in a fresh run to earn its medal. Ordinary crossings and spring combos alone do not count; rewarded-ad retries remain ineligible. Level 8 adds Quick hunter: win at or before the halfway point in a fresh run. Live track progress marks a missed deadline without ending the level; the knockout position determines the medal. Speed, energy and star rules are unchanged. Levels 9-11 have no optional challenge.

Status: closed testing on Google Play (Android). The design plan and progress are in [PLAN.md](PLAN.md) (Turkish).

For the next development session, see [Current Game State](docs/game-state.md): level-by-level cards, challenges, tuning, phone feedback and unreleased work.

## Requirements

- Godot 4.7 (`brew install --cask godot`)
- For Android builds: JDK 17, Android SDK command-line tools and the Godot 4.7 Android export templates

## Run

Open `project.godot` in Godot and press Play. The main scene is `scenes/level_select.tscn`.

Debug keys in a level: `Space`/`Up` jump, `Down` slide, `S` stop, `H` hit, `A` toggle runner AI, `R` restart, `N` next level, `Esc` level select.

After surviving damage, the runner looks surprised during the stun, then angry for two seconds. Another hit within six gameplay seconds intensifies the face and fist gesture for three seconds. This is visual only: speed, AI, health rules and difficulty are unchanged. Pausing freezes the reaction; restarting clears it.

## Tests

Headless test scripts live in `tests/`:

```sh
godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
```

`tests/balance_sim.gd -- runs=40 levels=6,7` runs bot players against levels and prints win rates.

After adding a `class_name` or editing `locale/translations.csv`, run `godot --headless --import` first.

Challenge lifecycle tests: `perl -e 'alarm 120; exec @ARGV' godot --headless --audio-driver Dummy --fixed-fps 60 -s res://tests/challenge_test.gd`. Only when a rendered UI check is necessary, omit `--headless`, keep `--audio-driver Dummy`, and append `-- --capture tr` (or `en`); screenshots go to `build/challenges/`. Tests use isolated progress and never overwrite the player's save.

## Android builds

```sh
# Debug APK
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ANDROID_HOME=/opt/homebrew/share/android-commandlinetools \
  godot --headless --export-debug "Android" build/runner-trap.apk

# Signed release bundle for Google Play (keystore lives outside the repo)
tools/export_release.sh
```

Both presets use the Gradle build (required by the AdMob plugin).

## Releasing to Google Play

Edit `docs/release-notes.json`, then:

```sh
tools/release.sh [version_name] [track]   # e.g. tools/release.sh 1.0.1
```

It bumps the version code, runs the tests, builds the bundle, asks for confirmation, uploads it with [gplay](https://github.com/tamtom/play-console-cli) (default track: `alpha`, the closed test), then commits, tags `v<name>-<code>` and pushes. `DRY_RUN=1` stops after the build.

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
