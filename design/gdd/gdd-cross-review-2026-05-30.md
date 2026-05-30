# Cross-GDD Review — 猫村物语 (Cat Village Story)

*Date: 2026-05-30*
*Methodology: Phase 1 (Load), Phase 2 (Cross-GDD Consistency), Phase 3 (Game Design Holism), Phase 4 (Cross-System Scenario Walkthrough)*
*Scope: All 17 system GDDs + game-concept.md + systems-index.md*
*Review mode: Full (Opus-level synthesis)*

---

## Verdict: FAIL — MAJOR REVISION NEEDED

**10 consolidated BLOCKERS, 30 WARNINGS, 6 INFO items** across all three review phases.

The GDDs are individually well-designed but the set is not internally consistent. Three cross-cutting issues must be resolved before `/create-architecture`:

1. **C5 Economy/Inventory GDD must be rewritten** — it uses an old "interaction points + binary fish gate" model that C3 replaced with per-loop affection
2. **Warmth decay must be finalized** — game-concept.md and F1 say warmth decays; C3 says it never decays. One decision across all docs.
3. **Narrative model must be unified** — game-concept.md describes "cosmic entity / ancient pact"; F6 redesigned to 银定亲王/箱庭/裂界生物. Every doc must tell the same story.

---

## Consolidated BLOCKERS (10)

### B1: C5 Economy/Inventory must be rewritten
**Sources**: Phase 2 (2b-1, 2c-2, 2d-1, 2f-1), Phase 3 (3d-1)
**Files**: C5 §§3.3, 3.5, 4, 5, 8; C3 §6 flag

C5 describes fish gifts in terms of "interaction points" and a "binary gate" (warmth 0→1 = 1 fish). C3's two-layer model uses per-loop affection (0-10) where fish is always +2 affection regardless of warmth tier. C5's acceptance criteria AC-03 through AC-05 test the old model and would fail against C3. C3 §6 explicitly flags this inconsistency. **A programmer implementing C5 before C3 will build the wrong system.**

### B2: Warmth decay must be finalized
**Sources**: Phase 2 (2b-2, 2f-2, 2f-3)
**Files**: game-concept.md §5, F1 §8 AC-02, C3 §3.2, C3 §5 Edge Case 2

game-concept.md §5: "Warmth decays by 1 tier per loop unless reinforced." F1 §8 AC-02: "After loop reset, all NPC warmth tiers are reduced by exactly 1." C3 §3.2: "No decay: Warmth never decreases." C3 is authoritative (user decision: "1 will stay"). game-concept.md, F1, and any other GDD referencing decay must be updated to match.

### B3: Narrative model must be unified
**Sources**: Phase 2 (2b-3, 2c-1, 2c-4, 2c-5), Phase 3 (3f-4)
**Files**: game-concept.md §4 lines 49-51, F4 dialogue system, F5 boss system, C4 combat system, F6 §§1-3

game-concept.md describes "cosmic entity / ancient pact" lore. F6 redesigns with 银定亲王 of 狮心帝国 / 箱庭 / 裂界生物. These are fundamentally different narratives. F4, F5, C4 may reference old lore. Every document describing the game's story must tell the same story.

### B4: C2 year display formula bug
**Sources**: Phase 2 (2b-4)
**File**: C2 §4

The year display formula `year = 7 - floor(elapsed_time_units / (100 / 7))` produces values 7, 6, 5, ... 1. It never produces 0 ("zero hour"). At exactly 100 time units, it produces `7 - floor(100 / 14.28) = 7 - 7 = 0` — but that's at exactly 0 remaining, which may be handled by the collapse event. Test: can the player ever see the countdown display "0 years"?

### B5: F7 formula bugs
**Sources**: Phase 2 (2b-5)
**File**: F7 §4

Two bugs: (1) `day_number = 7 - floor(time_units × 7 / 100)` produces 7 at time_units=0, but the formula says "Day 1 through Day 7" — day 7 at start means day 0 at end, which is non-standard. (2) The night check `is_night = (time_units × 7 / 100) % 1 >= 0.6` identifies loop start (0%1=0, which is < 0.6) as day, which is correct, but edge cases at day boundaries need verification.

### B6: C4 XP-to-SPD conversion undefined
**Sources**: Phase 3 (3e-3)
**File**: C4 §4

The XP formula produces a flat `stat_bonus` number applied to HP, ATK, DEF, and SPD. But SPD is a time interval (seconds between attacks), not a flat stat. The combat example suggests `SPD = base_SPD − some_conversion` (Hunter: 2.0s → 1.4s at 3 XP) but no formula is documented. An implementer cannot derive the correct calculation.

### B7: Missing dependency declarations
**Sources**: Phase 2 (2a)
**Files**: F1, F2, F3, C2, C3, F4

Several dependencies are one-directional:
- F2 depends on F1 (node persistence) but F1 does not list F2
- C2 depends on F2 (node graph for loop events) but F2 does not list C2
- C3 depends on F3 (warmth indicators) but F3 does not list C3
- F4 depends on C2 (loop-aware branching) but C2 does not list F4
- F4 depends on C3 (warmth-gated dialogue) but C3 does not list F4

### B8: F2 missing boss-trigger node type
**Sources**: Phase 2
**File**: F2 §3.1 node type taxonomy

C4 and F5 reference "battle-trigger" and "boss-trigger" node types, but F2's node taxonomy does not include them. F2 must define these node types with their properties (trigger conditions, one-time vs. repeatable, time cost).

### B9: C3 internal inconsistency — visit affection value
**Sources**: Phase 2
**File**: C3 §3.1 vs §3.8

C3 §3.1 (Detailed Rules): "visit NPC: +0 affection" (clarified by user). C3 §3.8 (MVP Simplifications): "visit (+1 affection), battle-together (+3 affection)." The MVP section contradicts the detailed rules. MVP section should reflect the actual design even if simplified.

### B10: F4 "interaction point" terminology
**Sources**: Phase 2 (2c-4)
**File**: F4 §3, §4

F4 (Dialogue System) uses "interaction points" to describe mechanical outputs of dialogue choices. C3 replaced this with "affection" (per-loop, 0-10 scale). F4 must align its terminology and value references with C3's affection model.

---

## Phase 3 — Game Design Holism WARNINGS (5)

### W-3a-2: Combat mandatory for true ending
F6 requires ≥3 boss victories. Relationship-only players must engage with combat. Telegraph this early in the game (Old Tom dialogue, tutorial hints) so players understand combat is not optional for the true ending.

### W-3c-5: 银定亲王 warmth trivializable
With 5 warmth-3 NPCs, a player can gain 15 affection in one loop just from the "bring NPC" source, maxing 银定亲王's affection in a single loop. His warmth 0-2 dialogue tiers would be entirely skipped. Consider capping "bring NPC" affection or requiring ≥2 loops with him before Phase 2 unlocks.

### W-3d-3: Fish sink degradation at warmth 3
After all NPCs reach warmth 3, fish has zero mechanical value. Consider this an intentional "endgame signal" (the village can offer you nothing more — pursue the true ending) or add an alternative sink (Shrine offering, combat consumable).

### W-3e-1: Player outscales basic enemies by loop 4+
Hunter at loop 5 with warmth 3 deals 21 damage to a Shadow-ling (takes 2 damage in return). This is intentional per P4 ("game gets richer, not harder") but should be tested with 3v3 mixed-type encounters where multiple enemies with complementary abilities are harder than the 1v1 math suggests.

### W-3g-2: 银定亲王 role pivot narrative risk
Player transitions from "detective exposing the villain" (Phase 1) to "friend redeeming the broken person" (Phase 2). This is the highest narrative risk in the game. The dialogue writing and warmth track must carry this pivot convincingly. Consider showing the empire's real crisis before the confrontation so empathy is seeded.

---

## Phase 4 — Scenario Walkthrough Findings

### W-4a: Opening sequence validation — PASS with notes
Walkthrough of the player's first 10 minutes (tutorial → movement → first NPC → first fish gift): all systems activate in correct sequence. Old Tom's fish grant (C5) → fish gift to fisherman (C3) → affection display (F3) chain is sound in the new C3 model. C5 must be updated for this chain to hold in implementation.

### W-4b: Loop transition multi-system handoff — 1 BLOCKER, 2 WARNINGS
Walkthrough of loop end → collapse → reawaken → systems reset:
- **BLOCKER**: F1's warmth decay AC-02 contradicts C3's no-decay rule. If implemented as written, warmth would incorrectly decrease.
- **WARNING**: C2 collapse sequence timing vs. C4 in-progress battle — if player is in battle when time expires, does battle abort or complete? C2 §5 Edge Case 4 covers this but C4 does not reference it.
- **WARNING**: P1 Traces deposit timing — traces are deposited "at loop end" but the exact moment (before or after collapse) affects whether the player sees them in the current loop's final moments.

### W-4c: Combat-then-gift sequence — PASS with note
Walkthrough of battle victory → affection gain → warmth check → possible tier up → Traces mark → dialogue change: all systems hand off correctly in the C3 model. C5's old interaction-point model would break this chain.

### W-4d: True ending multi-NPC convergence — PASS
Walkthrough of Phase 1 → 银定亲王 encounter → Phase 2 心魔 battle: the warmth-3 NPC support mechanic (each one weakens 心魔 by 10%) is mechanically sound. The clue assembly from F6 (4 clues from different sources) naturally gates Phase 1 behind relationship breadth.

---

## INFO Items (6)

1. **I-3a-1**: Progression loops are complementary (combat + social), not competitive — good design
2. **I-3a-2**: XP is combat-only; social-only players must eventually fight — intentional, telegraph it
3. **I-3b-1**: Attention budget: 2-3 active systems during gameplay, under the 4-active threshold — good
4. **I-3b-2**: UI density at 1280×720 during dialogue scenes — 7 visual elements, worth playtesting
5. **I-3c-1**: Fish spam not dominant — 3 fish/loop prevents trivializing full village of 10 NPCs
6. **I-3c-4**: Maxing all NPCs in one loop is theoretically possible in MVP (3 NPCs) but impossible in full vision (10 NPCs) — P3 preserved at scale

---

## STRENGTHS (Notable Design Quality)

1. **Progression loop complementarity**: Combat + relationships feed each other bidirectionally (C3↔C4). Neither dominates the reward structure.
2. **Central tension intentionality**: Explorer vs. strategist is the game's core dynamic, not a design flaw. Acknowledged in game-concept.md §5.
3. **P3 preservation at full scale**: 10 NPCs × 10 affection = 100 time units without combat. Realistically impossible to max all in one loop.
4. **F6 mechanical excellence**: Phase 1/2 structure, clue collection as passive gameplay outcome, 银定亲王's unique warmth track, 心魔 NPC support mechanic — all mechanically sound.
5. **Anti-pillar compliance**: Zero violations across 17 systems. No manual combat, no open world, no voice acting.
6. **Fish economic baseline**: 2 guaranteed fish per loop via non-combat path ensures relationship progression is always possible.
7. **Difficulty curve intent**: Player outscales basic enemies while boss scaling remains challenging — matches P4 ("richer, not harder") and P5 ("strategic mastery").

---

## Resolution Priority

| Priority | Blocker | Estimated Work | Blocks |
|----------|---------|---------------|--------|
| **P0** | B2 — Warmth decay decision | 1 decision + ~5 file edits | F1, game-concept, C3 consistency |
| **P0** | B3 — Narrative unification | game-concept rewrite + check F4/F5/C4 | All narrative-referencing GDDs |
| **P0** | B1 — C5 Economy rewrite | Full GDD revision (~2-3 sections changed) | C3 integration, implementation |
| **P1** | B4 — C2 formula bug | 1 line fix | HUD implementation |
| **P1** | B5 — F7 formula bugs | ~3 line fixes | Scheduling implementation |
| **P1** | B6 — C4 XP-to-SPD formula | 1 formula addition | Combat implementation |
| **P1** | B7 — Missing dependencies | ~5 edits across 5 files | Architecture design |
| **P1** | B8 — F2 boss-trigger tag | 1 section addition | C4/F5 implementation |
| **P1** | B9 — C3 MVP inconsistency | 1 section edit | C3 clarity |
| **P2** | B10 — F4 terminology | Global find-replace in F4 | F4/C3 integration |

---

## Next Pipeline Steps

Architecture (`/create-architecture`) should NOT proceed until P0 and P1 blockers are resolved. The architecture blueprint inherits GDD inconsistencies as architectural constraints — fixing them post-architecture is 3-5× more expensive than fixing the GDDs first.

### Recommended order:
1. **Resolve B2 (warmth decay)**: Single decision with cascading file updates
2. **Resolve B3 (narrative unification)**: Rewrite game-concept.md §4, audit F4/F5/C4
3. **Resolve B1 (C5 rewrite)**: Update Economy GDD to C3's affection model
4. **Fix B4-B10**: Formula bugs, missing deps, terminology
5. **Re-run `/review-all-gdds`** for a clean re-review
6. **Then `/create-architecture`**

Estimated time: 1-2 sessions to resolve all 10 blockers.
