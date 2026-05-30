# Economy/Inventory System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Core*
*Dependency order: #7 (depends on C2 Time/Loop, F3 UI/HUD, F1 Save/Load)*

---

## 1. Overview

The Economy/Inventory System manages the fish gift economy — the single resource type for MVP. It tracks fish acquisition (spawn locations, NPC gifts), fish inventory (player's carried fish), and fish expenditure (gifting to NPCs). The system enforces the core economic rules: fish grants +2 per-loop affection (0-10 scale) regardless of warmth tier — no binary gates. At loop end, if per-loop affection reaches 10, the NPC's cumulative warmth increases by 1 (max +1 per loop). Fish does NOT carry over between loops — use-or-lose per P3. A guaranteed per-loop baseline of fish spawns ensures the player can always engage with relationships each cycle. Every fish source is visible and understandable to the player — no hidden economy.

## 2. Player Fantasy

Fish should feel precious but not hoarded. The player should think: "I found a fish — who do I give it to?" not "I found a fish — I'll save it for later." Because fish expire at loop's end, every fish creates a small moment of decision. The visible source rule (every fish comes from somewhere the player can see — a market stall, a fishing NPC, a shoreline spawn) makes the economy feel grounded in the village, not an abstract currency counter. Giving a fish grants +2 affection — a genuine gesture that moves the NPC closer to the next warmth tier. At loop end, if affection reaches 10, warmth increases permanently by 1. The player should feel: "Each fish matters, even if the warmth increase only comes at the end."

## 3. Detailed Rules

### 3.1 Fish as a Resource

- Fish is the sole gift currency for MVP (single-typed).
- Fish occupies one inventory slot per unit.
- Maximum fish carried at once: 5 (prevents stockpiling; use-or-lose makes this a soft cap anyway).
- Fish is visible in the UI/HUD fish inventory counter at all times.

### 3.2 Fish Sources

| Source | Fish per Loop | Location | Notes |
|--------|--------------|----------|-------|
| Old Tom (tutorial gift) | 1 (loop 1 only) | Central District — Village Chief's Residence | One-time introduction to the gift mechanic |
| Fish Market stall | 2 per loop | Seaside District — Fish Market nodes | Always available, reliable baseline |
| Shoreline spawn | 1 per loop | Seaside District — Pier end node | Random appearance (70% chance per loop) |
| NPC gratitude gift | 1 (conditional) | Varies | An NPC at warmth 2+ may give the player a fish once per loop |
| Hunting Grounds (rare) | 0-1 per loop | Forest District — Deep Woods node | 30% chance per loop; alternative to market fish |

- **Guaranteed minimum per loop**: 2 fish (from Fish Market — always reachable, no combat gate).
- **Maximum per loop**: 5 fish (if all sources proc).
- **Typical per loop**: 3 fish.

### 3.3 Fish Expenditure

| Use | Effect | Notes |
|-----|--------|-------|
| Gift to any NPC (any warmth tier) | +2 per-loop affection | Always +2 regardless of warmth 0, 1, 2, or 3 |

- Fish is consumed on use (single-use item).
- The +2 affection is capped at 10 per-loop (the maximum). Excess affection beyond 10 is lost.
- Gifting fish triggers a dialogue response from the NPC appropriate to their warmth tier.
- The player selects which fish to gift (only 1 type in MVP, so this is a simple confirm action).
- Per-loop affection converts to warmth at loop end: if affection ≥ 10 → warmth +1 (max +1/loop per NPC). Per C3 §3.7.

### 3.4 Carry-Over Rule

Fish does **NOT** carry over between loops. Unspent fish are lost when the loop resets. This is enforced by the Save/Load System (§3.2: "Fish inventory — Emptied completely").

This rule exists to:
- Prevent hoarding and degenerate recon runs in early loops (P3)
- Create use-or-lose urgency each loop
- Make every fish pick-up a meaningful decision

### 3.5 Affection Model

The relationship system (NPC Relationship System, C3) uses per-loop affection (0-10 scale) and cumulative warmth (0-3). The Economy System contributes:

- Fish gift to any NPC at any warmth tier: +2 affection (per-loop, capped at 10)

At loop end, if per-loop affection reaches 10, the NPC's cumulative warmth increases by 1 (max +1 per loop per NPC). Warmth never decays. Full details in C3 §3.7.

### 3.6 Fish Spawn Rules

- Fish spawns refresh at the start of each loop.
- Spawn locations are fixed per district (see sources table).
- The player sees a visual indicator at spawn locations when fish is present (small fish silhouette).
- Once collected, the spawn location is empty for the rest of the loop.
- The Shoreline and Hunting Grounds spawns use probability checks — the player may or may not find a fish there each loop.

### 3.7 Inventory Display

- Fish count shown in top-right corner of UI/HUD (F3).
- On pickup: brief "+1 Fish" toast animation.
- On gift: brief "-1 Fish" toast animation.
- When at 0: icon is dimmed, count shows "0".

### 3.8 MVP Simplifications

- Single fish type (no preferred fish varieties).
- No fish trading between NPCs.
- No fish price economy (no buying/selling).
- No crafting using fish.

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Fish cap (inventory) | 5 | Soft cap; use-or-lose makes this rarely binding |
| Guaranteed fish per loop | 2 | From Fish Market (Seaside, no combat gate) |
| Max fish per loop | 5 | All sources including probability-based |
| Typical fish per loop | 3 | Expected value with 70% Shoreline and 30% Hunting Grounds |
| Fish gift affection | +2 | Per fish, any warmth tier, capped at 10 per-loop |
| Affection → warmth conversion | ≥10 affection → warmth +1 | At loop end, max +1/loop per NPC; per C3 §3.7 |
| Shoreline spawn probability | 70% | Per loop |
| Hunting Grounds spawn probability | 30% | Per loop |
| NPC gratitude fish probability | Once if warmth ≥ 2 | First visit per loop |

## 5. Edge Cases

1. **Player has 5 fish and tries to pick up another**: The fish remains at the spawn location. A toast shows: "Can't carry more fish." The player can return after spending one.
2. **Player gifts fish to an NPC already at 10 per-loop affection**: Fish is consumed (gift accepted) but grants 0 affection (capped at 10). NPC responds warmly but the gift has no mechanical effect. The +2 excess is lost.
3. **Player finds 0 fish in a loop (below guaranteed minimum)**: Cannot happen — the 2 Fish Market fish are always available and not behind combat gates. The player would have to actively avoid the Seaside District to miss them.
4. **Player gifts fish to warmth-0 NPC**: Fish is consumed, +2 affection applied. NPC now has affection 2/10. The affection bar appears in UI. All NPCs are giftable — every NPC can reach warmth 3 through sustained interaction across loops.
5. **Old Tom's tutorial fish in loop 2+**: Old Tom still gives a tutorial fish in loop 2+ if the player hasn't received a fish from him before. This covers the case where a player avoids Tom in loop 1. The flag `received_tom_fish` persists across loops via Save/Load.
6. **Save/Load mid-loop with fish inventory**: Manual save stores current fish count. On reload, fish count is restored. On loop auto-save, fish count is zeroed.

## 6. Dependencies

### Upstream
- **Time/Loop System (C2)** — triggers fish reset (inventory emptied) at loop start
- **UI/HUD Framework (F3)** — displays fish count, toast animations
- **Save/Load System (F1)** — persists/clears fish inventory; persists `received_tom_fish` flag
- **Scene/World Manager (F2)** — provides `fish-spawn` tagged node locations

### Downstream
- **NPC Relationship System (C3)** — receives +2 affection from fish gifts; queries per-loop affection for warmth conversion at loop end
- **Dialogue System (F4)** — triggers gift dialogue responses

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Fish carry capacity | 3-10 | Inventory management friction |
| Guaranteed fish per loop | 1-3 | Minimum relationship initiations per loop |
| Max fish per loop | 3-8 | Maximum relationship acceleration |
| Fish gift affection value | +1 to +3 | How much affection per fish gift (affects relationship pacing) |
| Shoreline spawn probability | 50-90% | Bonus fish availability |
| Hunting Grounds spawn probability | 20-50% | Risk/reward fish in combat zone |

## 8. Acceptance Criteria

1. **AC-01**: Player can collect fish from Fish Market nodes (2 fish available per loop, always present).
2. **AC-02**: Fish inventory count is displayed in the UI and updates on pickup and gift.
3. **AC-03**: Gifting a fish to any NPC (any warmth tier) adds exactly +2 per-loop affection, capped at 10.
4. **AC-04**: Gifting a fish triggers the appropriate NPC dialogue response for their current warmth tier.
5. **AC-05**: At loop end, if an NPC's per-loop affection reaches 10, their cumulative warmth increases by exactly 1 (max +1 per loop).
6. **AC-06**: Fish inventory is emptied (set to 0) at the start of each new loop.
7. **AC-07**: Fish spawns refresh at loop start — previously collected fish locations are replenished.
8. **AC-08**: Player cannot carry more than 5 fish. Attempting to pick up a 6th shows a toast message and the fish remains at the spawn point.
9. **AC-09**: Old Tom gives a tutorial fish in the player's first interaction with him, regardless of which loop that occurs in.
10. **AC-10**: Shoreline spawn (~70%) and Hunting Grounds spawn (~30%) trigger correctly with documented probabilities across multiple loops.
