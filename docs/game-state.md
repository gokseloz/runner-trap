# Current Game State

Last verified: 2026-09-28. This describes the local development build, not the currently published Play build.

## Start Here Next Session

- Read [AGENTS.md](../AGENTS.md) for working rules, tooling, tests and release safeguards.
- Use this document for the current playable content. Use [PLAN.md](../PLAN.md) for decisions, change history and future work.
- The latest debug APK, including anger expressions, was installed on the owner's Galaxy S25 Ultra. The owner ended the development session after installation.
- This session's gameplay changes have not been uploaded to Play. Last recorded closed-test release: version code 2 (1.0.0); production is empty. Confirm remote state before the next release.
- Release preparation for 1.0.1 is authorized: commit/push the work and perform a signed dry run. Actual Play upload still requires separate approval. Check git status/history for the current commit and push state; preserve any remaining changes.
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
| 7 | Jumper | Pit, Wall, Saw, Spring | None | Seesaw at x = 850 |
| 8 | Fast veteran | Pit, Wall, Saw, Slippery | None | None |
| 9 | Jumper | Pit, Wall, Saw, Slippery | None | None |
| 10 | Pro | Pit, Wall, Saw, Slippery | None | None |

Jumper can jump again in the air. Fast veteran is a separate profile used only in level 8; changing it must not alter the Fast profile in levels 3 and 5.

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

Sources: [level resources](../resources/levels/), [LevelData defaults and challenge rules](../scripts/resources/level_data.gd), [runner profiles](../resources/runners/).

## Mechanics To Preserve

- **Spring:** levels 4 and 7 only; costs 2 energy, single-use, launches at 650 px/s, no damage by itself. A hit during its flight or within 0.25 seconds after landing qualifies for a spring combo (+2 energy). Jumper retains its air jump.
- **Magnet:** level 5 only; costs 3 energy, single-use. After the runner passes through its field, pulls backward at 240 px/s for 0.65 seconds. No damage by itself; damage ends the pull. Returning into a dodged trap can trigger a chain combo.
- **Seesaw:** level 7 only; not a card. The 240 px beam is 44 px above ground with 100 px ramps on both sides. A normal crossing rocks it without damage. Landing from a spring at 400 px/s or faster triggers one launch at 740 px/s. No free damage or combo; spring-combo eligibility and air jump remain. Trap placements overlapping its 440 px footprint plus placement spacing are rejected without cost.
- **Snap:** retired prototype. Source and tests remain, but no level offers it. The owner disliked its phone trial; do not silently re-enable it.
- **Challenges:** optional medals, independent of stars and level unlocks. Losses and rewarded-ad retries cannot earn medals. Only successful placements count. Level 6 requires placement of each type, not a hit from each. Final knockout hits count toward qualifying combos and magnet hits; a harmless pull or a hit after pulling ends does not satisfy the magnet challenge.
- **Close trap reactions:** on normal ground, newly spotted Pit/Wall/Saw traps cap reaction delay by time to contact, reserving 0.18 seconds for evasion. Random mistakes remain. Airborne, slippery and timed Snap encounters retain their own timing. Avoid introducing guaranteed last-instant hits or global invulnerability as a shortcut.
- **Level 8 tuning:** its separate veteran profile uses 0.08 second reaction time, +/-0.02 second jitter and a 0.06 second learned reaction floor. The owner approved the change. Short bot runs are regression evidence, not proof of human difficulty.
- **Expressions:** successful dodge shows confidence; a learned trap can show focus; damage shows surprise. Surviving damage then shows anger for 2 seconds. Another hit within 6 gameplay seconds strengthens the expression for 3 seconds, adding clenched teeth and a red anger mark. This changes no movement, health, AI or difficulty rules. Knockout takes visual priority; pause freezes timers; restart clears anger history.
- **Level selection:** buttons size to their themed content after entering the scene tree. Keep challenge labels and stars inside the buttons on small Turkish-language screens.

## Phone Feedback And Remaining Checks

- Approved during this session: original runner expressions; challenges in levels 1-6; Spring in level 4; Magnet in level 5; level 8 reaction tuning; seesaw visibility in level 7.
- Seesaw visibility approval is not the same as approval of spring-to-seesaw aiming difficulty. The latter remains a phone playtest item, as does the feel of Spring in level 7.
- Anger was installed, passed automated tests and a 960x432 rendered check. The owner ended the session, but did not give separate detailed feedback on its phone readability.
- The global close-trap change passed deterministic tests across all ten levels. Broad human difficulty remains a playtest concern.
- "Jump now" sabotage and more environmental objects were ideas only. They are not implemented. Do not treat them as an approved next task.

## Verification And Export Pitfall

Release safety: `node --test tests/release_test.mjs` covers ten isolated scenarios, including misleading test summaries, build failure, cancelled confirmation, dry runs, uncertain uploads and successful release bookkeeping. A failed or interrupted upload retains the bumped version; check Play Console before retrying. Updated English/Turkish notes for 1.0.1 are in [release-notes.json](release-notes.json).

Latest code validation: all eight test scripts reported `DONE: 0 failure(s)`. The anger render check confirmed the extra red mark appears only in the stronger reaction. Existing ObjectDB/resource cleanup warnings still occur at test exit; they were not fixed in this session.

Run the full test commands in [AGENTS.md](../AGENTS.md) after gameplay changes. Tests may print failures or script errors without a nonzero exit code, so inspect both the output and the completion summary.

The seesaw once existed in source and desktop renders but was absent on Android: `PackedFloat32Array` positions became an empty array in the exported level resource. Reimporting and rebuilding did not solve it. Keep the field as `Array[float]`, and the resource value as `Array[float]([850.0])` while that is its configured position.

After exporting, before installing:

```sh
perl -e 'alarm 120; exec @ARGV' godot --headless --audio-driver Dummy -s res://tools/check_seesaw_export.gd
```

This checks the actual APK resource against the source. A source-only test is not enough. The latest installed APK passed this check.

## Keeping This Useful

Update the relevant table and mechanic here whenever playable content changes. Keep chronological decisions and pending work in [PLAN.md](../PLAN.md), operational rules in [AGENTS.md](../AGENTS.md), and tester-facing release text in [release-notes.json](release-notes.json). Do not copy the full session transcript into documentation. Update the dated build/release status when committing or shipping so it does not become a misleading handover.