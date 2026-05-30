# True Ending/Progression System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Feature*
*Dependency order: #13 (depends on C3 Relationship, C4 Combat, F5 Boss)*

---

## 1. Overview

The True Ending/Progression System tracks the player's progress toward the game's two-phase true ending. The 7-day countdown is a siege: 裂界生物 (rift-realm creatures) will overrun the village when time runs out. The normal ending is annihilation — the village falls.

The village chief 橘云 has been promised by 银定亲王 of the 狮心帝国 (Lionheart Empire) that through technology and combat power, the village can resist the rift creatures. This is a lie — or rather, it is only half the truth.

**Phase 1 — The Conspiracy Exposed**: By defeating rift creatures in battle and earning the trust of 橘云 and other key NPCs (warmth 3), the player uncovers the truth: 银定亲王 deliberately trapped the cat village in a 箱庭 (box-garden / pocket dimension), using the rift creatures as walls. The village is an experiment — a controlled environment to find a method to fight an apocalypse threatening the Lionheart Empire in the real world.

**Phase 2 — Redemption and Equality**: 银定亲王, exposed, falls into the village himself — becoming a special NPC. The player learns that the empire faces genuine annihilation, and the prince's actions, however cruel, were born from desperation. The player must break through 银定亲王's 心魔 (inner demon / trauma) — his belief that the cat village is merely a tool, not a people. When he acknowledges the cats as equals, the true path opens: together, cat village and prince face the real crisis.

The system tracks: rift creature defeats, trust thresholds with 橘云 and key NPCs, phase 1 conspiracy revelation, 银定亲王's integration as an NPC, his warmth/redemption track, and the final joint resolution.

## 2. Player Fantasy

The true ending fantasy unfolds in three emotional movements, mirroring the game's overall arc:

**Revelation (Phase 1 unlock)**: The player has fought rift creatures, built trust with 橘云, and assembled enough fragments to see the truth — the village is a cage, and 银定亲王 built it. The player should feel righteous anger: "We trusted him. 橘云 trusted him. He used us." But also dawning comprehension: the prince isn't a monster — he's desperate. The empire is dying. The cat village is his laboratory because he has nowhere else to turn. The emotional pivot is from "defeat the villain" to "understand the person."

**Redemption (Phase 2)**: 银定亲王 falls into the village. He is not a boss to defeat but a broken person to reach. His 心魔 manifests — the weight of an empire on his shoulders, the guilt of sacrificing an innocent village, the belief that equals are a luxury he cannot afford. The player's weapon is not combat power but the relationships they've built: 橘云's forgiveness, other NPCs' trust, the village's resilience across loops. The player breaks the 心魔 not by fighting it, but by proving — through warmth tiers, memory fragments, and the accumulated evidence of every loop — that cats are not tools. They are people. They have memories. They matter.

**Triumph (Resolution)**: 银定亲王 acknowledges the cats as equals. The box-garden experiment ends. What replaces it is not a return to isolation but a partnership — the cat village and the prince face the real crisis together, this time as allies. The player should feel: "We did this. Not by fighting harder, but by being who we are — cats who remember, who trust, who persist." The true ending is not freedom from the countdown. It is freedom from being a tool. The countdown shatters because the experiment is over — and what comes next is something new.

## 3. Detailed Rules

### 3.1 Ending Types

The game has three possible endings:

| Ending | Condition | Result |
|--------|-----------|--------|
| **Normal (Bad) End** | Time runs out (day 7 ends) without meeting Phase 1 conditions | Rift creatures overrun the village. Brief collapse sequence. Player loops to try again. |
| **Phase 1 — Conspiracy Exposed** | Meet Phase 1 conditions → trigger at Shrine | 银定亲王's 箱庭 revealed. He falls into the village as an NPC. Phase 2 path opens. |
| **True Ending** | Complete Phase 1 + Phase 2 conditions → trigger final resolution | 银定亲王's 心魔 broken. Village and prince stand as equals. 箱庭 shattered. Rift creatures repelled. Credits. |

The normal end is not a failure state — the player loops and retains all progress. Phase 1 and True Ending are permanent narrative unlocks.

### 3.2 Phase 1 — Unlock Conditions

Phase 1 triggers when ALL of the following are met:

1. **Loop count ≥ 3** — the player has experienced at least 2 full cycles
2. **橘云 warmth = 3** — the village chief fully trusts the player
3. **Key NPCs at warmth ≥ 2**: At least 2 other NPCs (of the 5 Tier 1 NPCs) have warmth tier 2 or higher
4. **Rift creature encounters defeated**: At least 3 boss victories across all loops (cumulative, not per-loop)
5. **Clue fragments collected**: At least 4 of the following clues discovered:
   - 橘云's doubt dialogue (triggers at warmth 2: "The prince's promises feel hollow lately…")
   - A boss drop (Pact fragment from Boss 2)
   - An environmental clue at a loop-gated node (Shrine at night, loop 3+)
   - A memory fragment from a warmth-3 NPC (behavioral persistence — they sense the cage)
   - 银定亲王's name mentioned by any NPC at warmth 2+

When all conditions are met, visiting the Shrine triggers the Phase 1 revelation scene.

### 3.3 Phase 1 — The Revelation

The Phase 1 scene is a dialogue-driven sequence:

1. Player visits Shrine → 橘云 is there (override schedule), troubled
2. 橘云 shares his doubts about 银定亲王
3. Memory fragments from warmth-3 NPCs surface — the player sees flashes of evidence
4. The truth crystallizes: the cat village is a 箱庭, the rift creatures are the walls, and the countdown is the experiment cycle
5. 银定亲王 is revealed — not as an enemy, but as a desperate architect
6. The prince falls into the village (stripped of his external power — he is now inside his own experiment)
7. Phase 1 completion flag set: persisted across loops
8. 银定亲王 added to the village as a special NPC (see §3.4)

### 3.4 银定亲王 as NPC

After Phase 1, 银定亲王 appears in the village. He is unique among NPCs:

**Schedule**: Always at the Shrine (day) or Observatory (night). Does not follow standard NPC scheduling (F7).

**Warmth Track**: Uses the same 0-3 system as other NPCs (C3), but affection sources differ:

| Action | Affection | Notes |
|--------|-----------|-------|
| Visit + dialogue | +1 | He is dismissive but the player persists |
| Bring an NPC at warmth 3 to meet him | +3 | Once per NPC: "This cat trusts me. You can too." |
| Defeat a boss with him observing (loop 4+) | +2 | He sees the cats' strength firsthand |
| "Challenge his belief" dialogue choice | +2 | Specific dialogue nodes where the player confronts his ideology |
| Gift fish | 0 | He does not accept fish — gifts are meaningless to him |

**Warmth tier effects**:

| Warmth | Label | 银定亲王's State |
|--------|-------|-----------------|
| 0 | Hostile | "Your village is a necessary sacrifice. You wouldn't understand." |
| 1 | Grudging | "You persist. I'll grant you that much." |
| 2 | Doubt | "I have ruled empires. Why do these cats unsettle me?" |
| 3 | Equality | "You are not tools. You never were. I see that now." |

At warmth 3, Phase 2 becomes available.

### 3.5 Phase 2 — Breaking the 心魔

Triggered when:
- Phase 1 completed
- 银定亲王 warmth = 3
- Loop ≥ 4

The player visits 银定亲王 at the Shrine at night. The 心魔 manifests:

1. **心魔 Battle**: A special combat encounter (uses C4 framework). The enemy is a representation of 银定亲王's trauma — the weight of the dying empire, the faces of those he sacrificed, the belief that equals are weakness.
2. **NPC Support**: During the battle, warmth-3 NPCs the player has bonded with appear as reinforcements (automatically, not from the player's team). Each warmth-3 NPC weakens the 心魔 — reduces its stats by 10% per NPC.
3. **Victory**: The 心魔 is not killed — it is acknowledged and released. A dialogue sequence follows where 银定亲王 faces his guilt.
4. **Acknowledgment**: 银定亲王 states: "The cat village is not my laboratory. You are my equals."
5. Phase 2 completion flag set: persisted across loops.

The 心魔 battle costs 30 time units. It can be retried if lost.

### 3.6 True Ending — Final Resolution

After Phase 2, the player can trigger the True Ending at any Shrine visit:

1. Player visits Shrine → option: "End the experiment" (appears once Phase 2 is complete)
2. 银定亲王, 橘云, and all warmth-3 NPCs gather
3. The 箱庭 barrier is broken — the rift creatures are expelled
4. The countdown in the sky shatters (visual: cerulean cracks spread, then the numbers dissolve)
5. The Lionheart Empire's real crisis is acknowledged — the cat village chooses to help, as equals
6. Credits roll over scenes of the village at peace — all warmth-3 NPCs, Traces marks fully saturated, no countdown
7. Save file marked "True Ending Achieved" — player can reload to continue playing (sandbox mode: no countdown, all NPCs at current warmth)

### 3.7 Clue Tracking

Clues are boolean flags persisted across loops via Save/Load:

```
clues:
  juyun_doubt: false          # 橘云 warmth 2 dialogue
  boss_pact_fragment: false    # Boss 2 drop
  shrine_night_clue: false     # Shrine at night, loop 3+
  npc_memory_cage: false       # Any warmth-3 NPC memory fragment
  silver_determination_name: false  # Any warmth-2+ NPC mentions the prince
```

Clues are collected passively through normal gameplay — the player does not "hunt" for them. The system checks clue conditions on each relevant event and sets the flag.

### 3.8 MVP / Tier Simplifications

**MVP**: Normal ending only. Phase 1 and Phase 2 deferred. The countdown is simply survived or not.

**Tier 1**: Phase 1 (Conspiracy Exposed). 银定亲王 NPC added. Clue tracking active. Phase 2 deferred.

**Full vision**: Full true ending — Phase 1 + Phase 2 + Final Resolution + Credits.

## 4. Formulas

### Phase 1 Eligibility

```
phase1_eligible =
    loop_count >= 3
    AND juyun.warmth == 3
    AND count(npc.warmth >= 2 for npc in key_npcs) >= 2
    AND total_boss_victories >= 3
    AND collected_clues >= 4
```

### 心魔 Stat Reduction from NPC Support

```
xinmo_stat_multiplier = 1.0 - (0.10 × supporting_npc_count)
```

Where `supporting_npc_count` is the number of warmth-3 NPCs (max 5 in Tier 1, 10 in full vision). The 心魔's minimum stats are 50% of base (with 5 NPCs).

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Phase 1 min loop | 3 | Player has experienced loops 1-2 |
| Phase 1 橘云 warmth requirement | 3 | Full trust from village chief |
| Phase 1 other NPC warmth requirement | ≥2 | At least 2 key NPCs |
| Phase 1 boss victories (cumulative) | ≥3 | Across all loops |
| Phase 1 clues required | ≥4 | Of 5 possible |
| 银定亲王 fish affection | 0 | Fish does not work on him |
| 银定亲王 "bring NPC" affection | +3 | Once per warmth-3 NPC |
| 银定亲王 "challenge belief" affection | +2 | Per specific dialogue node |
| 心魔 NPC stat reduction | −10% per warmth-3 NPC | Minimum 50% of base stats |
| Phase 2 min loop | 4 | Phase 1 must be complete |
| 心魔 battle time cost | 30 units | Same as boss encounter |

## 5. Edge Cases

1. **Player meets Phase 1 conditions in loop 2**: Not possible — loop ≥ 3 is a hard gate. The earliest Phase 1 unlock is loop 3.
2. **Player loses 心魔 battle**: Standard boss defeat rules apply (C4 §3.9, F5 §3.6). Team cats Wounded. 心魔 encounter can be retried in the same loop or next loop. 银定亲王's warmth is not reduced by the loss.
3. **Player triggers Phase 1 but then ignores 银定亲王 for many loops**: He remains at the Shrine/Observatory. His warmth stays at whatever tier it was. He does not decay (like all NPCs per C3). The player can resume his warmth track in any future loop.
4. **Player achieves True Ending, wants to keep playing**: After credits, the save file is marked "True Ending Achieved." The player can reload to continue in sandbox mode: no countdown, all NPCs at their current warmth, rift creatures still present (for battles), 银定亲王 in village. This is the post-game state.
5. **银定亲王 warmth resets across loops**: No — his warmth persists like all NPCs (C3). His affection resets to 0 each loop (standard C3 rules). The player must re-earn 10 affection with him each loop to advance his warmth tier.
6. **Player has fewer than 5 warmth-3 NPCs for 心魔 battle**: The battle is still winnable with fewer NPCs. Each warmth-3 NPC helps but is not required. With 0 warmth-3 NPCs (only 橘云 at warmth 3), the 心魔 fights at full power — a harder but not impossible fight.
7. **Phase 1 triggered, loop resets before Phase 2**: Phase 1 completion flag persists. 银定亲王 remains in the village in all future loops. The player does not need to re-trigger Phase 1.
8. **Player has not fought any bosses but meets other Phase 1 conditions**: Phase 1 requires 3 boss victories. The player must engage with combat. This is intentional — the true ending requires both relationship depth AND strategic mastery.

## 6. Dependencies

### Upstream

| System | What F6 Needs From It |
|--------|----------------------|
| **NPC Relationship System (C3)** | Warmth tiers for 橘云, key NPCs, and 银定亲王; warmth change events; affection tracking |
| **Auto-Battler Combat System (C4)** | Boss victory count (cumulative across loops); 心魔 battle framework |
| **Boss Encounter System (F5)** | Boss defeat flags; boss drop possession (Pact fragment); boss node state |
| **Time/Loop System (C2)** | Loop count (→ Phase 1/2 gate); loop start signal (→ no action, flags persist) |
| **Save/Load System (F1)** | Persist all progression flags: phase 1/2 completion, clue collection, 银定亲王 warmth, boss victory count, true ending achieved |
| **Dialogue System (F4)** | Clue delivery through dialogue (橘云 doubt, NPC name-drop, memory fragments); 银定亲王 dialogue tree |
| **Scene/World Manager (F2)** | Shrine node for Phase 1/True Ending triggers; Observatory node for 银定亲王 night location |
| **UI/HUD Framework (F3)** | Clue collection notifications; Phase completion announcements; ending sequence rendering |

### Downstream

F6 is the narrative capstone — no gameplay systems depend on it. However:

| System | What F6 Provides To It |
|--------|----------------------|
| **Save/Load System (F1)** | "True Ending Achieved" flag for post-game sandbox mode |
| **Dialogue System (F4)** | Phase completion flags for dialogue gating (post-Phase 1 dialogue references the conspiracy) |

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Phase 1 min loop | 3 | 2-4 | How quickly players can reach Phase 1 |
| Phase 1 橘云 warmth requirement | 3 | 2-3 | Difficulty of Phase 1 gate |
| Phase 1 other NPC warmth requirement | ≥2 (count ≥ 2) | 1-3 warmth, 1-3 count | How many relationships needed |
| Phase 1 boss victories required | 3 | 2-5 | Combat requirement for narrative progress |
| Phase 1 clues required | 4 | 3-5 | How many fragments to assemble |
| 银定亲王 "bring NPC" affection | +3 | +2 to +5 | Value of introducing trusted cats |
| 银定亲王 "challenge" affection | +2 | +1 to +3 | Value of ideological confrontation |
| 心魔 NPC stat reduction | −10% per NPC | −5% to −15% | How much relationships help the fight |
| Phase 2 min loop | 4 | 3-5 | Pacing between Phase 1 and Phase 2 |
| 心魔 battle time cost | 30 units | 20-30 | Opportunity cost of the confrontation |

## 8. Acceptance Criteria

1. **AC-01**: Normal ending triggers when time_units reaches 0 without Phase 1 conditions met. Rift creature siege animation plays. Player loops with all progress retained.
2. **AC-02**: Phase 1 unlocks at the Shrine only when all conditions are met: loop ≥ 3, 橘云 warmth 3, ≥2 NPCs warmth ≥2, ≥3 boss victories, ≥4 clues collected. Missing any condition: Shrine shows normal dialogue.
3. **AC-03**: Phase 1 revelation scene plays as a dialogue-driven sequence. 橘云's doubts and memory fragments converge on the truth. 银定亲王 falls into the village. Phase 1 completion flag is persisted.
4. **AC-04**: After Phase 1, 银定亲王 appears as a special NPC at Shrine (day) and Observatory (night). He has a unique warmth track — fish gifts give 0 affection; bringing warmth-3 NPCs to meet him gives +3 affection.
5. **AC-05**: 银定亲王's dialogue changes with his warmth tier: 0 = hostile, 1 = grudging respect, 2 = doubt, 3 = equality.
6. **AC-06**: Phase 2 (心魔 battle) unlocks at the Shrine at night when 银定亲王 warmth = 3 and loop ≥ 4. The 心魔's stats are reduced by 10% per warmth-3 NPC.
7. **AC-07**: 心魔 battle victory triggers the acknowledgment scene — 银定亲王 states the cats are equals. Phase 2 completion flag is persisted.
8. **AC-08**: After Phase 2, the Shrine offers "End the experiment." Selecting it triggers the True Ending: 箱庭 shatters, countdown breaks, credits roll. Save file is marked "True Ending Achieved."
9. **AC-09**: Post-True Ending, the player can reload to sandbox mode: no countdown, all NPCs and warmth preserved, rift creatures still present for battles.
10. **AC-10**: All progression flags (Phase 1/2 completion, clues, boss victory count, 银定亲王 warmth) persist correctly across loops via Save/Load.
