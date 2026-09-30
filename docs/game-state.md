# Current Game State

Last updated: 2026-09-30. This describes local development after version 1.0.1/code 3: 11 levels, including the unreleased level 7 and 8 challenges, level 9's fake finish, level 10's wall revenge and level 11's last-life umbrella. Play status was last checked on 2026-09-28: code 3 was in review and code 2 remained published; it has not been rechecked in this development session.

## Start Here Next Session

- Unreleased addition (2026-09-30): level 7's Seesaw master challenge requires at least one successful spring-to-seesaw launch and a win in a fresh run. Live progress, an end result and a persistent medal use the existing challenge system. The debug APK was installed and the owner approved the phone trial. No release-version bump or Play upload was made for this change.
- Unreleased addition (2026-09-30): level 8's Quick hunter challenge requires a fresh-run win at or before 50% of the track (x = 3750). Live track percentage shows when the deadline is missed without ending the level. Medal evaluation snapshots the knockout position; exact halfway is eligible, any distance beyond is not. The debug APK was installed and the owner approved the phone trial. No Play upload was made for this change.
- Read [AGENTS.md](../AGENTS.md) for working rules, tooling, tests and release safeguards.
- Unreleased trial (2026-09-30): level 9 offers Fake finish for 2 energy, once per run. A grounded, vulnerable runner celebrates for 1.8 seconds at 45% speed without dodging, then recovers with a 1.8-second 35% speed boost and anger. Damage cancels both phases. The owner approved the phone trial; no Play upload is authorized for this change.
- Unreleased trial (2026-09-30): level 10 enables wall revenge. The first placed wall becomes a one-time tap duel when the grounded runner approaches. A successful tap returns the wall as a free falling attack; missing adds no penalty beyond losing the wall. The owner approved the phone trial.
- Unreleased trial (2026-09-30): level 11 adds a last-life umbrella, enabled only by its new `last_life_umbrella` flag. It unlocks after level 10; existing level configurations, stars and saved progress remain unchanged. The owner reported wall collisions and requested permanent flight until saw contact. The revised version passed all eight gameplay tests and umbrella pixel checks at 960x432 and 1280x720. Actual APK checks for levels 7-11 passed, including the raised saw's blade/collision heights. It was installed and launched on the phone with progress preserved; approval of this revision is pending. No Play upload was made.
- Use this document for the current playable content. Use [PLAN.md](../PLAN.md) for decisions, change history and future work.
- The latest debug APK includes all 11 levels. It passed actual APK checks for levels 7-11, was installed with save preservation on the Galaxy S25 Ultra and launched successfully. The level 11 phone trial is pending; no Play upload was made.
- The owner approved uploading 1.0.1/code 3 to alpha. Upload, edit validation and edit commit succeeded; Play reports `RELEASE_LIFECYCLE_STATE_IN_REVIEW`. Production is empty. Approval and tester availability have not yet been confirmed.
- Preparation commit `833816b` was pushed to origin/main; both the signed dry run and the actual release build passed all eight gameplay tests. The release preset now remains at 1.0.1/code 3; the next upload must use code 4. Release tag: `v1.0.1-3`.
- The first upload command rejected locale-keyed release notes before creating an edit. Notes were corrected to a `language`/`text` array and checked with gplay's own dry-run mode, then the existing code-3 AAB was uploaded successfully. Do not rerun the incrementing release script blindly after a failure.
- `jarsigner -verify` reported `jar verified`; it also reported self-signed certificate, missing timestamp and JarInputStream archive-order warnings. The dry-run AAB's compiled level 7 resource was byte-identical to the verified debug APK. Google Play subsequently accepted the actual release bundle upload; review is still pending.
- Do not add more features or upload merely because the session ended. Ask the owner what to do next; Play uploads require explicit approval.

## Level Contents

All challenges require a win. "None" means no optional challenge, not an unavailable level. Trap names below correspond to the offered cards, in card order.

| Level | Runner profile | Cards | Optional challenge | Fixed track objects |
|---|---|---|---|---|
| 1 | Basic | Pit, Wall | Win using at most 6 traps | None |
| 2 | Basic | Pit, Wall, Saw | Win with at least 2 combos | None |
| 3 | Fast | Pit, Wall, Saw, Slippery | Win using only one trap type | None |
| 4 | Basic | Pit, Wall, Slippery, Spring | Win with at least 1 spring combo | None |
| 5 | Fast | Pit, Saw, Slippery, Magnet | Win with at least 1 damaging hit during a magnet pull | None |
| 6 | Jumper | Pit, Wall, Saw | Win using all 3 offered trap types | None |
| 7 | Jumper | Pit, Wall, Saw, Spring | Win with at least 1 spring-to-seesaw launch | Seesaw at x = 850 |
| 8 | Fast veteran | Pit, Wall, Saw, Slippery | Win within the first 50% of the track | None |
| 9 | Jumper | Pit, Wall, Saw, Slippery, Fake finish | None | None |
| 10 | Pro | Pit, Wall, Saw, Slippery | None | None |
| 11 | Fast | Pit, Wall, Saw, Slippery | None | None |

Jumper can jump again in the air. Fast veteran is a separate profile used only in level 8; changing it must not alter the Fast profile in levels 3 and 5.

Level 10 keeps the same cards and profile; `LevelData.wall_revenge` enables its one-time first-wall interaction.

Level 11 uses the existing Fast profile, with `LevelData.last_life_umbrella` enabled and an inherited saw scene whose blade and collision center are 72px above ground (other levels retain 54px). Level 10 now has a Next button after winning; level 11 is the final level. The existing menu accommodates all 11 buttons without reducing their sizes.

### Track And Energy Settings

These include inherited defaults from LevelData, not only values explicitly written in each resource.

| Level | Track length (px) | Starting energy | Maximum energy | Energy regenerated per second |
|---|---|---|---|---|
| 1 | 6000 | 6 | 10 | 1.2 |
| 2 | 6000 | 5 | 10 | 1.0 |
| 3 | 7000 | 5 | 10 | 1.0 |
| 4 | 6500 | 5 | 10 | 1.0 |
| 5 | 7000 | 5 | 10 | 1.0 |
| 6 | 6500 | 7 | 10 | 1.3 |
| 7 | 7000 | 5 | 10 | 1.0 |
| 8 | 7500 | 5 | 10 | 0.8 |
| 9 | 7500 | 5 | 10 | 0.7 |
| 10 | 8000 | 6 | 12 | 1.1 |
| 11 | 8000 | 6 | 12 | 1.1 |

Sources: [level resources](../resources/levels/), [LevelData defaults and challenge rules](../scripts/resources/level_data.gd), [runner profiles](../resources/runners/).

## Mechanics To Preserve

- **Spring:** levels 4 and 7 only; costs 2 energy, single-use, launches at 650 px/s, no damage by itself. A hit during its flight or within 0.25 seconds after landing qualifies for a spring combo (+2 energy). Jumper retains its air jump.
- **Magnet:** level 5 only; costs 3 energy, single-use. After the runner passes through its field, pulls backward at 240 px/s for 0.65 seconds. No damage by itself; damage ends the pull. Returning into a dodged trap can trigger a chain combo.
- **Seesaw:** level 7 only; not a card. The 240 px beam is 44 px above ground with 100 px ramps on both sides. A normal crossing rocks it without damage. Landing from a spring at 400 px/s or faster triggers one launch at 740 px/s. No free damage or combo; spring-combo eligibility and air jump remain. Trap placements overlapping its 440 px footprint plus placement spacing are rejected without cost.
- **Snap:** retired prototype. Source and tests remain, but no level offers it. The owner disliked its phone trial; do not silently re-enable it.
- **Last-life umbrella:** level 11 only. Opens once when the runner has one life, is grounded and has recovered from stun/invulnerability. At the owner's request, it now glides toward 84px above ground, clears walls as well as pits, and has no timeout. Ordinary damage is rejected while open, including during ascent; only saw contact closes it during play. This level's raised saw still hits standing runners and can be avoided by sliding. It consumes itself when closing the umbrella, without life loss or a free combo, and cannot also hurt the runner. Closure starts descent at at least 140px/s; a saw followed 150px later by a pit was verified to defeat the glider with AI enabled. Normal damage resumes after closure, including wall hits. Pause freezes flight, restart/ad replay resets the opportunity, and the real finish ends the level and clears the umbrella. New EN/TR text is limited to the level name.
- **Wall revenge:** level 10 only. First successfully placed wall costs its normal 3 energy and is reserved from AI/damage until the runner gets within 100 px. A grounded, unhurt runner pauses for 0.3 seconds, gestures and throws it into a 112x112 HUD target. Tap/click during its 1.5-second countdown to return the same wall, without another cost or placement count. It falls for 0.55 seconds toward the runner's predicted track position, capped before the finish. Physical collision and normal invulnerability decide damage; no automatic hit or combo is awarded. AI resumes treating it as a wall after landing if unconsumed. Missing hides the spent wall; later walls remain ordinary. If an airborne or hurt runner passes without throwing, the original wall returns to ordinary behavior and the opportunity is spent. Pause freezes both phases, end cancels them, restart/ad replay resets the opportunity. During card dragging, the target does not intercept input.
- **Fake finish:** level 9 only, 2 energy, one placement per run (including a fresh rewarded-ad replay). The spent card displays Used. Ground contact triggers a harmless, single-use celebration with raised arms: 1.8 seconds at 45% running speed, no AI reactions or evasive actions. A surviving runner resumes dodging with an angry 1.8-second 35% speed boost. Jump planning uses the effective speed. Damage, including knockout, cancels the celebration and boost; airborne, hurt and knocked-out runners cannot activate it. Pause freezes both timers; restart resets the card. It neither ends the level nor grants damage, stars or a free combo. Track length, runner profile, energy regeneration and real finish rules remain unchanged.
- **Seesaw challenge:** only a successful second launch advances level 7's counter. Normal crossings, ordinary jump landings and spring combos alone do not count. A spent seesaw cannot count twice. A launch without a win or in a rewarded-ad retry earns no medal; restarting resets the counter, and later losses preserve an earned medal. No extra damage or combo is required for the launch itself. Physics, energy and AI settings are unchanged.
- **Quick hunter challenge:** uses the same absolute track-position ratio as stars, not elapsed time. Uses the unrounded knockout position for the 50% threshold, captured before deferred challenge evaluation. The display rounds progress upward so crossing the deadline is not displayed as still below it. Late wins retain their normal stars and unlocks; losses and rewarded-ad retries earn no medal. Speed, reaction time, energy, traps and star thresholds are unchanged.
- **Challenges:** optional medals, independent of stars and level unlocks. Losses and rewarded-ad retries cannot earn medals. Only successful placements count. Level 6 requires placement of each type, not a hit from each. Final knockout hits count toward qualifying combos and magnet hits; a harmless pull or a hit after pulling ends does not satisfy the magnet challenge.
- **Close trap reactions:** on normal ground, newly spotted Pit/Wall/Saw traps cap reaction delay by time to contact, reserving 0.18 seconds for evasion. Random mistakes remain. Airborne, slippery and timed Snap encounters retain their own timing. Avoid introducing guaranteed last-instant hits or global invulnerability as a shortcut.
- **Level 8 tuning:** its separate veteran profile uses 0.08 second reaction time, +/-0.02 second jitter and a 0.06 second learned reaction floor. The owner approved the change. Short bot runs are regression evidence, not proof of human difficulty.
- **Expressions:** successful dodge shows confidence; a learned trap can show focus; damage shows surprise. Surviving damage then shows anger for 2 seconds. Another hit within 6 gameplay seconds strengthens the expression for 3 seconds, adding clenched teeth and a red anger mark. This changes no movement, health, AI or difficulty rules. Knockout takes visual priority; pause freezes timers; restart clears anger history.
- **Level selection:** buttons size to their themed content after entering the scene tree. Keep challenge labels and stars inside the buttons on small Turkish-language screens.

## Phone Feedback And Remaining Checks

- Approved during this session: original runner expressions; challenges in levels 1-6; Spring in level 4; Magnet in level 5; level 8 reaction tuning; seesaw visibility in level 7.
- The owner approved the level 7 challenge and level 8's Quick hunter challenge on the phone on 2026-09-30.
- The owner approved level 9's fake finish and level 10's wall revenge on the phone on 2026-09-30. Level 11's revised wall-clearing, no-timeout umbrella still needs phone confirmation and feedback on timing and difficulty.
- Anger was installed, passed automated tests and a 960x432 rendered check. The owner ended the session, but did not give separate detailed feedback on its phone readability.
- The global close-trap change passed deterministic tests across all ten levels. Broad human difficulty remains a playtest concern.
- "Jump now" sabotage and more environmental objects were ideas only. They are not implemented. Do not treat them as an approved next task.

## Verification And Export Pitfall

Level 11 validation: all eight gameplay tests passed after the no-timeout/wall-clearance change, including wall/pit avoidance, ascent protection, flight beyond twice the former timeout, saw closure, landing counterattack, wall damage after closure, raised-saw damage on the ground, pause, final-level win/escape and ad replay. All 11 levels are covered by the closest-trap tests; unlock tests verify level 10 opens level 11. The initial trial passed silent umbrella pixel checks and direct menu/text-bounds checks in Turkish at 960x432 and 1280x720. A longer challenge screenshot run timed out before reaching its menu capture; the direct level-select render test replaced that visual check.

Release safety: `node --test tests/release_test.mjs` covers ten isolated scenarios, including misleading test summaries, build failure, cancelled confirmation, dry runs, uncertain uploads and successful release bookkeeping. A failed or interrupted upload retains the bumped version; check Play Console before retrying. Updated English/Turkish notes for 1.0.1 are in [release-notes.json](release-notes.json).

Latest code validation: all eight test scripts reported `DONE: 0 failure(s)`. The anger render check confirmed the extra red mark appears only in the stronger reaction. Existing ObjectDB/resource cleanup warnings still occur at test exit; they were not fixed in this session.

The fake finish addition passed all eight gameplay tests, plus silent Turkish rendered checks at 960x432 and 1280x720 (banner pixels, card bounds and text bounds). Its debug APK passed the level 7 seesaw/challenge, level 8 challenge and level 9 card/scene checks, and the owner approved the phone trial.

Wall revenge passed all eight gameplay tests and silent Turkish render checks at 960x432 and 1280x720. Coverage includes actual viewport touch/mouse input, target bounds and brick/ring pixels, card-drag passthrough, first-wall exclusivity, physical return damage, misses, pause, end cancellation and restart/ad replay reset. The actual APK retained the level 10 wall revenge flag and passed all level 7-10 resource checks before phone installation. No new UI text or translations are needed.

Run the full test commands in [AGENTS.md](../AGENTS.md) after gameplay changes. Tests may print failures or script errors without a nonzero exit code, so inspect both the output and the completion summary.

The seesaw once existed in source and desktop renders but was absent on Android: `PackedFloat32Array` positions became an empty array in the exported level resource. Reimporting and rebuilding did not solve it. Keep the field as `Array[float]`, and the resource value as `Array[float]([850.0])` while that is its configured position.

After exporting, before installing:

```sh
perl -e 'alarm 120; exec @ARGV' godot --headless --audio-driver Dummy -s res://tools/check_seesaw_export.gd
```

This checks the actual APK resource against the source. A source-only test is not enough. The latest installed APK passed this check.

Append `-- --level-8` to the same command to check the exported level 8 challenge and its 50% target. Both level checks passed for the latest built debug APK.

Append `-- --level-9` to check the exported level 9 card list and presence of the fake finish scene. The focused gameplay/render check is `tests/trap_test.gd -- --fake-finish-only`; append `--capture tr` for silent rendered checks at 960x432 or 1280x720. It checks banner pixels and card text bounds as well as physical triggering, follow-up damage, expiry, pause, restart and knockout.

Append `-- --level-10` to check the exported wall revenge flag. Its focused test is `tests/trap_test.gd -- --wall-revenge-only`, optionally with `--capture tr` in a silent rendered run. Screenshots are written to `/tmp/runner-trap-<width>x<height>-wall-revenge-*.png`.

Append `-- --level-11` to check the exported umbrella flag, level resource and actual raised-saw scene's blade/collision heights. Its focused test is `tests/trap_test.gd -- --umbrella-only`, optionally with `--capture tr` for silent rendering. `tests/level_select_test.gd -- --capture` directly captures the fully unlocked Turkish menu and verifies all 11 buttons and their contents fit. These tests do not overwrite the player's save.

## Keeping This Useful

Update the relevant table and mechanic here whenever playable content changes. Keep chronological decisions and pending work in [PLAN.md](../PLAN.md), operational rules in [AGENTS.md](../AGENTS.md), and tester-facing release text in [release-notes.json](release-notes.json). Do not copy the full session transcript into documentation. Update the dated build/release status when committing or shipping so it does not become a misleading handover.