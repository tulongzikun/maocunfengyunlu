# NPC Relationship System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Core*
*Dependency order: #8 (depends on C2 Time/Loop, F1 Save/Load, F4 Dialogue, C5 Economy)*

---

## 1. Overview

The NPC Relationship System operates on two layers: **per-loop affection** and **cumulative warmth**.

**Per-loop affection** is a 0–10 score that resets each loop. The player earns affection points through actions within a single cycle — fighting alongside an NPC, gifting fish, or triggering special events. Affection is the loop-level effort gauge: "How much did I invest in this cat this cycle?"

**Cumulative warmth** is the persistent tier (0, 1, 2, 3…) that carries across loops via Save/Load. At the end of each loop, if per-loop affection has reached the maximum of 10, the NPC's overall warmth increases by 1. Warmth is the permanent bond — it gates dialogue depth, clue availability, memory fragment tier, recruitment eligibility, and ultimately story direction.

This two-layer design means the player cannot grind warmth through repetition alone — every tier increase requires a committed loop where the NPC was a priority. The per-loop affection reset enforces P3 (Time Does Not Wait): you cannot hoard affection across cycles. The cumulative warmth persistence enforces P1 (Every Encounter Leaves a Mark) and P4 (Loops Are Growth): every loop where you max out a relationship permanently advances it.

The system is per-NPC — every cat in the village has an independent affection value (ephemeral, loop-scoped) and warmth tier (persistent, cross-loop).

## 2. Player Fantasy

The player should feel the weight of choice in every interaction. Because per-loop affection resets, each loop the player must decide: "Which cats am I investing in this cycle?" The 0–10 affection bar creates a visible, session-length goal — the player can watch it fill and feel the tension as the countdown ticks toward zero: "I'm at 8 with the fisherman… I just need one more visit."

The moment of payoff comes at loop's end. When the sky cracks and the world collapses, the affection check fires — and if the player committed enough, the warmth tier rises permanently. The player should feel: "I earned that. It carries forward." Across multiple loops, a cat who started as a stranger becomes an ally, then a confidant, then family. The cumulative warmth tier is the ledger of this journey.

The emotional core is asymmetry: the player remembers everything; the NPC remembers fragments. At warmth 0–1, the NPC treats the player as a stranger. At warmth 2+, memory fragments surface — the NPC recalls a gift, a shared battle, a moment. At warmth 3+, the NPC begins to sense the loop itself. The player should feel the ache of being the only one who truly knows, and the hope of slowly making the NPCs see.

## 3. Detailed Rules

### 3.1 Per-Loop Affection (0-10)

Every NPC has a per-loop affection score, 0-10, that resets to 0 at the start of each loop. Affection represents the player's investment in that NPC during the current cycle.

Affection is earned through actions within the loop:

| Action | Affection Gained | Notes |
|--------|-----------------|-------|
| Visit NPC (arrive at node + interact) | 0 | Visiting enables dialogue and fish gifting, but does not itself build affection |
| Gift fish | +2 | Per fish gifted; limited by fish inventory (max 5 carried) |
| Battle alongside NPC | +2 | Applied after battle victory; NPC must be in the active party |
| "Good" dialogue choice | +1 | When the player selects a warmth-advancing dialogue option |
| Special events | +2 to +4 | Story-specific moments (e.g., saving an NPC, delivering a message) |

Affection cannot exceed 10. Overflow points are lost.

### 3.2 Cumulative Warmth (0-3)

Warmth is the persistent relationship tier that carries across loops. It ranges from 0 (stranger) to 3 (fully bonded).

**Advancement**: At the end of each loop, during the collapse sequence, the system checks every NPC's per-loop affection:
- If affection = 10 → warmth increases by 1 (max 3)
- If affection < 10 → warmth stays at its current value

**No decay**: Warmth never decreases. A cat who trusts you stays trusting. P4 (Loops Are Growth) means relationships only move forward.

**Per-loop cap**: Warmth can only increase by 1 per loop, even if the player overshoots 10 affection. This enforces multi-loop relationship arcs.

### 3.3 Warmth Tier Effects

| Warmth | Label | What Unlocks |
|--------|-------|-------------|
| 0 | Stranger | Basic idle dialogue only. NPC does not recognize the player. |
| 1 | Acquaintance | NPC recognizes the player. Loop-aware tier 1 dialogue. **Recruitable** to battle team. |
| 2 | Friend | Memory fragments begin (tier 2: specific recall of past events). NPC may share clues. Deeper dialogue. NPC may give fish once per loop (gratitude gift). |
| 3 | Bonded | Full trust. Memory fragments tier 3 (behavioral persistence — NPC acts on remembered knowledge). NPC shares deepest secrets. Traces marks fully saturated. Full dialogue depth. |

### 3.4 Recruitment

An NPC can join the player's battle team if either condition is met:
- **Warmth 1+** — the NPC has lasting trust (persists across loops), OR
- **Current-loop affection > 5** — the player has invested heavily this loop (ephemeral, resets next loop)

Once recruited, the NPC remains in the team until the player swaps them out. Recruitment status is re-evaluated at loop start: if the NPC was recruited via affection > 5 (and warmth is still 0), they leave the team on reset.

Team size caps (set by Combat System):
- MVP: 1 team cat
- Tier 1: 3 team cats
- Full vision: 6 team cats

### 3.5 Memory Fragment Delivery

Memory fragments are delivered through the Dialogue System (F4), keyed to warmth tier and loop count:

| Fragment Tier | Requires | Behavior |
|--------------|----------|----------|
| Tier 1 | Warmth 1+, Loop 2+ | Deja vu lines from shared pool: "Have we met?" "You feel familiar." |
| Tier 2 | Warmth 2+, Loop 3+ | Specific recall of past-loop events, hand-authored per NPC: "You gave me a fish last cycle. I don't know how I know that." |
| Tier 3 | Warmth 3, Loop 4+ | Behavioral persistence: NPC acts on remembered knowledge — leaves a fish for the player, warns of danger, confronts the player with the truth, opens a hidden path. |

The Relationship System provides warmth tier and affection score to the Dialogue System. The Dialogue System selects the appropriate dialogue node and delivers the fragment text.

### 3.6 Affection Reset

At the start of each new loop (after reawakening), all NPC per-loop affection scores are set to 0. This is triggered by the Time/Loop System and enforced by Save/Load.

Warmth tiers persist unchanged (no decay).

### 3.7 Multi-NPC Tracking

The player can earn affection with any number of NPCs per loop. There is no system-level cap on how many NPCs can reach 10 affection in one loop. The practical limit is set by:
- Time (100 units per loop — visits and battles cost time)
- Fish (max 5 carried, 2-5 available per loop)
- The player's strategic choice of who to prioritize

### 3.8 MVP Simplifications

- 3 NPCs in the village
- Affection sources active: visit (+0), fish gift (+2), battle-together (+2), "good" dialogue choice (+1)
- Special events (+2~4) deferred to Tier 1
- NPC gratitude fish at warmth 2+ deferred to Tier 1
- Recruitment via warmth 1+ OR affection > 5 — both paths active

## 4. Formulas

### Affection Accumulation

```
affection_npc = min(10, sum(affection_gains_this_loop))
```

Where `affection_gains_this_loop` is the sum of all affection-yielding actions with that NPC in the current loop.

### Warmth Advancement (Loop-End Check)

```
if affection_npc >= 10:
    warmth_npc = min(3, warmth_npc + 1)
else:
    warmth_npc = warmth_npc  # unchanged
```

This check fires once per loop, during the collapse sequence, for every NPC.

### Recruitment Eligibility

```
is_recruitable = (warmth_npc >= 1) OR (affection_npc > 5)
```

Re-evaluated at loop start for team membership: NPCs recruited via affection > 5 (with warmth still 0) leave the team on reset.

### Memory Fragment Tier

```
fragment_tier = min(warmth_npc, floor(loop_count / 2) + 1)
```

Capped at 3. Fragment content is selected by the Dialogue System using this tier value.

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Affection max per loop | 10 | Overflow lost |
| Affection per fish gift | +2 | Per fish consumed |
| Affection per battle alongside | +2 | On victory |
| Affection per "good" dialogue choice | +1 | Per choice |
| Affection per visit | 0 | Enables other actions |
| Affection per special event | +2 to +4 | Story-driven |
| Warmth max | 3 | Cannot exceed |
| Warmth advance threshold | 10 affection | Checked at loop end |
| Warmth advance per successful loop | +1 | Once per loop maximum |
| Warmth decay | 0 | Never decreases |
| Recruitment warmth threshold | ≥ 1 | Persistent eligibility |
| Recruitment affection threshold | > 5 | Current-loop eligibility |

### Example: One NPC Across 3 Loops

| Loop | Start Warmth | Actions This Loop | Affection | Loop-End Check |
|------|-------------|-------------------|-----------|----------------|
| 1 | 0 | 2 fish (+4), 3 good dialogue (+3), 1 battle (+2) | 9 | 9 < 10 → warmth stays 0 |
| 2 | 0 | 3 fish (+6), 2 good dialogue (+2), 1 battle (+2) | 10 | 10 ≥ 10 → warmth 0→1 |
| 3 | 1 | 2 fish (+4), 1 battle (+2), 2 good dialogue (+2), 1 event (+2) | 10 | 10 ≥ 10 → warmth 1→2 |

### Example: Fastest Possible 0→3

| Loop | Actions (Minimum to Reach 10) | Result |
|------|------------------------------|--------|
| 1 | 4 fish (+8) + 1 battle (+2) = 10 | 0→1 |
| 2 | 2 fish (+4) + 2 battles (+4) + 2 good dialogue (+2) = 10 | 1→2 |
| 3 | 2 fish (+4) + 2 battles (+4) + 2 good dialogue (+2) = 10 | 2→3 |

Minimum 3 loops to reach warmth 3 with any NPC. With 10 NPCs (full vision) and 3-5 typical fish per loop, the player can realistically max ~1-2 NPCs per loop, making full-village bonding a long-term goal.

## 5. Edge Cases

1. **Player reaches 10 affection but NPC is already at warmth 3**: Affection is tracked and capped at 10, but the loop-end check finds warmth already at maximum. No change. The NPC accepts gifts and dialogue warmly but no mechanical advancement occurs.
2. **NPC recruited via affection > 5 (warmth still 0), then loop resets**: On reawakening, affection resets to 0. Since warmth is still 0, the NPC leaves the team. The player must rebuild affection > 5 or raise warmth to 1+ in the new loop to re-recruit.
3. **Player gifts fish to warmth-3 NPC**: Fish is consumed (Economy System deducts it). +2 affection applied (capped at 10). No warmth advance since warmth is already 3. The fish is effectively "wasted" mechanically, but the NPC responds with a warm dialogue line — the gift is acknowledged.
4. **Player has 0 affection with all NPCs at loop end**: No warmth advances. All relationships stay at their current warmth values. Nothing is lost — P4 guarantees loops never penalize.
5. **Multiple NPCs reach 10 affection in the same loop**: Each advances warmth by 1 independently. No conflict. The player can advance multiple relationships simultaneously if they invest enough resources.
6. **Player avoids an NPC for many loops**: Warmth stays at its current value (no decay). When the player returns, the NPC is at the same warmth tier they left. Dialogue reflects the gap — the NPC may comment on the player's absence, but the bond is preserved.
7. **Player interacts with warmth-0 NPC in loop 4+**: The NPC is still at warmth 0 (stranger) — they do not recognize the player. However, if the Dialogue System's loop tier is high, the NPC may still deliver deja vu lines ("You feel familiar…") even though warmth-gated content remains locked. Warmth gates depth; loop count gates ambient awareness.
8. **Team full when player attempts to recruit**: The recruitment UI shows "Team is full" with the current team roster. The player must dismiss an existing team member before recruiting the new NPC. Dismissed NPCs return to their normal village location and retain their warmth tier.
9. **Affection-earning action interrupted by loop collapse**: Per Time/Loop System §5.1 (dialogue completes before collapse) and §5.2 (battle ends immediately on collapse), the affection from the action is applied if the action completes. An incomplete battle grants 0 affection. A completed dialogue choice grants its +1.
10. **Player gifts multiple fish to the same NPC in one visit**: Each fish gives +2 affection, capped at 10. The player can gift up to 5 fish (full inventory) in one interaction. Overflow beyond 10 is lost.
11. **NPC is both recruitable and already recruited**: Once recruited, the NPC remains in the team until dismissed. Recruitment status only changes at loop start (affection-based recruitment re-evaluated) or when the player manually dismisses.
12. **Save/Load mid-loop**: Per-loop affection is stored in the save file. On reload, it is restored exactly as it was — no reset. The loop-end affection check only fires during the collapse sequence, not on save/load.

## 6. Dependencies

### Upstream

| System | What C3 Needs From It |
|--------|----------------------|
| **Time/Loop System (C2)** | Loop start signal (reset affection to 0); loop end signal (run warmth advancement check); loop count (for memory fragment tier calculation) |
| **Save/Load System (F1)** | Persist warmth tier per NPC across loops; persist/clear per-loop affection; persist recruitment status |
| **Dialogue System (F4)** | Fires "good dialogue choice" events (→ +1 affection); delivers memory fragments keyed to warmth tier |
| **Economy/Inventory System (C5)** | Fires fish-gifted-to-NPC events (→ +2 affection); fish inventory queries for gift validation |

### Downstream

| System | What It Needs From C3 |
|--------|----------------------|
| **Dialogue System (F4)** | Current warmth tier per NPC (gates dialogue depth and choice visibility); current affection score (may influence dialogue tone); memory fragment tier |
| **Auto-Battler Combat System (C4)** | Recruitment status per NPC (is this NPC in the team?); warmth tier may affect combat performance (Tier 1+) |
| **Traces Visual Feedback System (P1)** | Warmth tier per NPC (determines visual mark saturation — tier 3 = fully saturated Traces) |
| **True Ending/Progression System (F6)** | Warmth tiers across key NPCs (gates story progression and true ending conditions) |
| **Boss Encounter System (F5)** | Recruitment status and warmth tiers (may trigger boss phases or unlocks) |
| **Economy/Inventory System (C5)** | Warmth ≥ 2 triggers NPC gratitude fish (once per loop, Tier 1+) |

### Bidirectional Note

The Dialogue System (F4) and Economy System (C5) are both upstream and downstream of C3. C3 provides warmth/affection data that gates dialogue and economy behavior; in return, dialogue choices and fish gifts feed affection values back into C3. This is intentional — C3 is the central hub that other systems read from and write to.

### Cross-GDD Inconsistency Flag

**Resolved 2026-05-30** — The Economy/Inventory System GDD (C5) has been updated to use the affection model (per-loop affection 0-10, fish = +2 affection at any warmth tier). This section retained for historical reference. C3 and C5 are now aligned.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Affection max | 10 | 8-12 | Actions required per loop to advance warmth; higher = more commitment needed |
| Affection per fish gift | +2 | +1 to +3 | Value of fish economy; higher = fish more impactful for relationships |
| Affection per battle alongside | +2 | +1 to +4 | Combat-relationship synergy; higher = battles more rewarding for bonding |
| Affection per "good" dialogue | +1 | +1 to +2 | Dialogue choice weight; higher = conversation choices more mechanically meaningful |
| Affection per special event | +2 to +4 | +1 to +5 | Story beat impact on relationships |
| Warmth max | 3 | 3-5 | Relationship depth granularity; more tiers = longer arcs, more writing |
| Warmth advance threshold | 10 | 8-12 | Must match affection max; determines "full commitment" bar |
| Recruitment warmth threshold | ≥ 1 | 1-2 | How much lasting bond is needed before NPC joins permanently |
| Recruitment affection threshold | > 5 | 3-7 | How much current-loop investment recruits without warmth; lower = easier ephemeral recruitment |

## 8. Acceptance Criteria

1. **AC-01**: Every NPC starts at warmth 0 and per-loop affection 0 at the beginning of a new game.
2. **AC-02**: Gifting a fish to an NPC adds exactly +2 affection to that NPC. The affection change is reflected in the UI before the next player action.
3. **AC-03**: Selecting a "good" dialogue choice adds exactly +1 affection to the NPC currently in conversation.
4. **AC-04**: Affection is capped at 10. When an NPC has 9 affection and the player gifts a fish (+2), the NPC's affection becomes 10 — not 11. Overflow is discarded.
5. **AC-05**: At loop end (during collapse sequence), every NPC with affection = 10 has their warmth increased by exactly 1. NPCs with affection < 10 have no warmth change.
6. **AC-06**: At loop start (after reawakening), all NPC per-loop affection scores are reset to 0.
7. **AC-07**: Warmth tiers persist across loops — an NPC at warmth 2 at loop end is still at warmth 2 at the start of the next loop. Warmth never decreases.
8. **AC-08**: An NPC with warmth ≥ 1 is recruitable (can be added to the player's battle team). An NPC with warmth 0 but affection > 5 is also recruitable.
9. **AC-09**: An NPC recruited via affection > 5 (with warmth 0) is removed from the team at loop start when affection resets to 0.
10. **AC-10**: Dialogue queries the correct warmth tier for an NPC — warmth 0 shows basic idle lines only, warmth 1+ shows tier-appropriate dialogue, warmth 2+ includes memory fragments, warmth 3 includes full dialogue depth.
11. **AC-11**: Warmth cannot exceed 3. An NPC at warmth 3 with 10 affection at loop end stays at warmth 3.
12. **AC-12**: Multiple NPCs can reach 10 affection and advance warmth in the same loop — they are processed independently.
