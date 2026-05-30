# Boss Encounter System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Feature*
*Dependency order: #12 (depends on C4 Combat, C2 Time/Loop, C3 Relationship)*

---

## 1. Overview

The Boss Encounter System extends the Auto-Battler Combat System (C4) with multi-phase boss fights that serve as the loop's narrative and mechanical climaxes. Bosses are powerful 裂界生物 (rift-realm creatures) that have breached the walls of the 箱庭, each loop-gated, appearing only at specific loop milestones. A boss fight uses the same pre-battle preparation, autonomous battle resolution, and observer-commander framework as regular combat, but adds: multiple phases triggered at HP thresholds, unique per-phase abilities, phase-transition cinematic moments, and higher stakes (30 time units, greater rewards, narrative progression). Bosses escalate across loops — gaining new phases, abilities, and stat boosts — ensuring that the same boss fought in loop 3 is a different challenge than in loop 5. Boss victories are required for the true ending (F6). Bosses are the game's set-piece moments — the combat system's strategic depth pays off here.

## 2. Player Fantasy

A boss fight should feel like the culmination of everything the player has built across loops. When the boss appears, the player should think: "This is why I recruited these cats. This is why I built these bonds." The pre-battle screen becomes a moment of reckoning — the player surveys their team, remembers the loops spent earning each cat's trust, and commits to the fight knowing the stakes.

The multi-phase structure creates a narrative arc within the battle itself. Phase 1: "I can handle this." The boss reveals a new ability. Phase 2: "This is harder than I thought." A team cat drops to low HP — the player burns a Retreat command. Phase 3: "One last push." The boss is at 10% HP, the team is battered, and the player has no commands left. The cats fight on their own. When they win, the victory feels earned — not by a single clever move, but by everything: the team composition, the warmth bonds, the stat growth across loops, the command usage, and a little bit of luck.

Losing to a boss should not feel like failure — it should feel like reconnaissance. "Now I know its second phase. Next loop I'll be ready." The boss's loop escalation means the player can't simply grind past it — they must learn its patterns, adapt their team, and try again with better preparation. The boss that walled them in loop 3 becomes beatable in loop 4 not because they got stronger, but because they got smarter.

## 3. Detailed Rules

### 3.1 Boss Triggering

Bosses are encountered at nodes tagged `boss-trigger` in the Scene/World Manager (F2). Each boss has a `loop-gated:N` requirement — the boss node is inactive (inaccessible or displays "A heavy presence lingers here…") until the player reaches the required loop.

| Boss | Loop Gate | District | 裂界 Role |
|------|-----------|----------|-----------|
| Boss 1 (Tier 1) | Loop 2+ | TBD | Minor rift creature — tests the player's team |
| Boss 2 (Tier 1) | Loop 3+ | TBD | Rift guardian — requires warmth 2+ with a specific NPC to access |
| Boss 3 (Full vision) | Loop 4+ | TBD | Memory-keeper — drops a critical clue |
| Boss 4 (Full vision) | Loop 5+ | TBD | Final enforcer — gatekeeper to true ending |

MVP has 0 bosses. Tier 1 has bosses 1-2. Full vision adds bosses 3-4.

### 3.2 Boss Phases

Every boss has 2-3 phases. A phase transition triggers when the boss's HP drops below a threshold:

- **Phase 1**: 100% → 60% HP. Boss uses basic abilities.
- **Phase 2**: 60% → 25% HP. Boss gains 1-2 new abilities. Behavior changes (more aggressive, new target priority).
- **Phase 3**: 25% → 0% HP. Boss gains a desperation ability. Some bosses enrage (increased ATK, decreased DEF).

Phase transitions are cinematic moments:

1. Boss becomes briefly invulnerable (1.0s)
2. Boss plays a phase transition animation (roar, form shift, arena change)
3. Boss gains new abilities as defined per phase
4. Team cats hold position — no actions during the transition
5. Battle resumes with the boss at the new phase's starting HP

Phase transitions do not cost additional time units — the 30-unit boss cost covers the full fight.

### 3.3 Boss Abilities

Bosses have unique abilities beyond basic attacks. Examples:

| Ability Type | Example | Effect |
|-------------|---------|--------|
| **AOE attack** | Shadow-swipe | Damages all cats in front row |
| **Targeted burst** | Debt-collector's Gaze | Heavy damage to the cat with highest affection (❤) |
| **Summon** | Call Shadows | Spawns 1-2 shadow-lings to assist |
| **Debuff** | Weakening Wail | −20% ATK to all team cats for 8 seconds |
| **Heal** | Consume Memory | Boss recovers 10% HP, gains +10% ATK permanently |
| **Phase-specific** | Rift-claim | At 10% HP, boss targets the lowest-HP cat for a finishing blow |

Each boss has a unique ability set. Abilities are telegraphed with a brief visual cue (boss flashes, text warning appears) 1.0s before the ability fires, giving the player time to use a command if available.

### 3.4 Boss Escalation Across Loops

Bosses scale with the loop count, layered on top of the standard enemy escalation (C4 §3.10):

| Loop | Boss Scaling (cumulative) | New Elements |
|------|--------------------------|-------------|
| Gate loop (first appearance) | Base stats | Base phases and abilities |
| Gate + 1 | +15% HP, +10% ATK | Phase 2 gains 1 new ability |
| Gate + 2 | +30% HP, +20% ATK | Phase 3 unlocks (if boss was 2-phase); 1 additional summon per summon ability |
| Gate + 3+ | +45% HP, +30% ATK (cap) | All abilities have reduced telegraph time (0.7s instead of 1.0s) |

This ensures the boss remains challenging even as the player's team grows stronger across loops.

### 3.5 Boss Rewards

Victory against a boss grants:

- **XP**: +3 XP per participating team cat (per C4 §3.8)
- **Affection**: +2 affection per team cat (per C3 §3.1)
- **Boss drop**: A unique item or clue fragment (Tier 1+)
  - Boss 1: Fish charm (permanent +1 fish capacity, persists across loops)
  - Boss 2: 箱庭 fragment (clue for true ending, F6)
  - Boss 3: Memory shard (unlocks hidden dialogue with a specific NPC)
  - Boss 4: Key of Release (required for true ending)
- **Battle scar**: A unique cerulean boss-mark at the boss node (per P1 §3.1)

Boss rewards are once per loop — defeating the same boss again in the same loop grants XP and affection but not the unique drop.

### 3.6 Boss Defeat

Defeat against a boss follows the standard combat defeat rules (C4 §3.9):

- All team cats gain Wounded status (−20% stats for rest of loop)
- No XP, no affection, no boss drop
- The boss node remains accessible — the player can retry in the same loop (but with Wounded cats)

Boss HP does not persist between attempts — each attempt starts the boss at full HP.

### 3.7 Pre-Boss Preparation

Boss encounters use the same pre-battle screen as regular combat (C4 §3.2) with additions:

- **Boss info panel**: Shows boss name, loop gate, known abilities (abilities discovered in previous fights are revealed), and phase count.
- **Warning**: "This is a boss encounter. It will cost 30 time units. Your team cannot retreat once the battle begins."
- **Confirm**: Player must confirm twice — "Prepare for battle?" → "Begin" — to prevent accidental boss triggers.

### 3.8 Boss Node State

After a boss is defeated in a loop:
- The boss node becomes a `safe-zone` for the rest of the loop
- The cerulean boss-mark (P1) is deposited
- The node resets to `boss-trigger` at the start of the next loop (boss respawns)

After a boss is defeated AND the player has claimed the unique drop:
- In future loops, the boss still respawns but the unique drop does not drop again
- The player can farm the boss for XP and affection but not for duplicate unique items

### 3.9 MVP / Tier 1 Simplifications

**MVP**: No bosses. Small encounters only.

**Tier 1**: Bosses 1 and 2.
- 2 phases each (no phase 3)
- 2 unique abilities per boss
- Boss drops: Fish charm (boss 1), 箱庭 fragment (boss 2)
- Boss escalation: base + gate+1 tiers only

**Full vision**: All 4 bosses, 3 phases, full ability sets, all drops.

## 4. Formulas

### Phase Transition Thresholds

```
if boss.current_HP / boss.max_HP ≤ 0.60 AND current_phase == 1:
    transition_to_phase(2)
elif boss.current_HP / boss.max_HP ≤ 0.25 AND current_phase == 2:
    transition_to_phase(3)
```

For 2-phase bosses, the phase 2 threshold is 50% HP.

### Boss Escalation

```
boss_stat = base_stat × (1.0 + standard_enemy_escalation[loop]) × boss_escalation_multiplier
```

Where `standard_enemy_escalation` is from C4 §3.10 and:

| Loop (relative to gate) | boss_escalation_multiplier | New Abilities |
|------------------------|---------------------------|---------------|
| Gate (first appearance) | 1.00 | Base set |
| Gate + 1 | 1.15 HP, 1.10 ATK | +1 phase-2 ability |
| Gate + 2 | 1.30 HP, 1.20 ATK | Unlock phase 3 |
| Gate + 3+ | 1.45 HP, 1.30 ATK | Reduced telegraph (0.7s) |

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Boss time cost | 30 time units | From Time/Loop System |
| Phase 2 HP threshold | ≤60% max HP | 2-phase bosses use ≤50% |
| Phase 3 HP threshold | ≤25% max HP | Not present on 2-phase bosses |
| Phase transition invulnerability | 1.0s | Cats hold position during transition |
| Ability telegraph duration | 1.0s (0.7s at gate+3) | Visual cue before ability fires |
| Boss XP reward | +3 XP per cat | Same as standard encounter C4 formula |
| Boss drop: once per loop | Yes | Unique item only on first kill per loop |
| Boss respawn | Every loop | Boss node resets at loop start |
| Double confirm for boss trigger | 2 confirms | "Prepare?" → "Begin" |

### Boss Stat Example

Boss 1 (loop 2 gate), fought in loop 4 (gate + 2):

| Stat | Base | C4 Escalation (×1.35) | Boss Escalation (×1.30 HP, ×1.20 ATK) | Final |
|------|------|----------------------|--------------------------------------|-------|
| HP | 300 | 405 | 526 | **526** |
| ATK | 25 | 33.7 | 40.5 | **40** |
| DEF | 10 | 13.5 | 13.5 | **13** |
| SPD | 3.0s | 3.0s | 3.0s | **3.0s** |

## 5. Edge Cases

1. **Boss triggered with all team cats Wounded**: Boss fight proceeds normally — Wounded penalty applies. The player may still win but at significant disadvantage. The double-confirm gives them a chance to reconsider.
2. **Boss killed during phase transition**: If an attack lands that would push the boss below 0% HP AND below the next phase threshold simultaneously, the boss transitions first (becomes briefly invulnerable), then immediately enters the death animation at 0% HP. No skipped phases.
3. **Player defeats boss on first attempt in a loop**: Full rewards granted. The boss node becomes a safe-zone. The player cannot re-fight the boss until the next loop.
4. **Player loses to boss, retries, loses again**: Each attempt costs 30 time units. After 2 failed attempts (60 units), the player has very little time remaining. The strategic choice becomes: try again with Wounded cats, or accept the loss and prepare better next loop.
5. **Boss ability targets a cat already at 0 HP**: Ability retargets to the nearest living cat. Bosses do not attack downed cats.
6. **Player issues Retreat on the only remaining cat**: Retreat still works — cat recovers 20% HP. But while retreating, the boss attacks nothing and recovers no HP (bosses don't heal during combat lulls). The cat rejoins and continues fighting.
7. **Boss escalation makes boss stronger than the player can handle**: The player always has the option to skip the boss this loop and fight it in a future loop with a stronger team. Boss nodes are optional, not mandatory. P4 guarantees alternatives.
8. **Boss fight interrupted by loop collapse (time hits zero)**: Per Time/Loop System §5.2 and C4 §5.3: battle ends immediately, boss retreats to its node (not defeated), no rewards, all team cats who hit 0 HP are Wounded. The boss does not count as defeated.
9. **Player defeats boss, loop resets, boss respawns, player already has the unique drop**: Boss drops the unique item only once ever (per boss). On subsequent victories, the player receives XP and affection but not the duplicate unique item. The post-battle screen shows "Unique item already claimed" instead of the drop.

## 6. Dependencies

### Upstream

| System | What F5 Needs From It |
|--------|----------------------|
| **Auto-Battler Combat System (C4)** | Battle framework: pre-battle screen, formation grid, battle resolution, observer commands, post-battle outcomes, stat calculations, XP system |
| **Time/Loop System (C2)** | Loop count (→ boss gate check, boss escalation); 30-unit time cost; mid-collapse battle interruption |
| **NPC Relationship System (C3)** | Warmth tiers for boss access conditions; affection rewards on victory; team composition |
| **Scene/World Manager (F2)** | `boss-trigger` tagged nodes; loop-gated node accessibility |
| **UI/HUD Framework (F3)** | Boss info panel on pre-battle screen; phase transition animations; boss HP bar with phase indicators |
| **Save/Load System (F1)** | Persist boss defeat status per loop; persist unique boss drop claimed status |
| **Traces Visual Feedback (P1)** | Boss-mark trace deposition on victory |

### Downstream

| System | What It Needs From F5 |
|--------|----------------------|
| **True Ending/Progression System (F6)** | Boss victory flags; unique boss drops (箱庭 fragment, Key of Release); boss defeat status for progression gating |
| **Dialogue System (F4)** | Boss encounter triggers; post-boss victory dialogue from related NPCs |

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Phase 2 HP threshold | 60% (50% for 2-phase) | 50-70% | When the fight changes; higher = more time in phase 2 |
| Phase 3 HP threshold | 25% | 15-30% | Desperation phase length |
| Phase transition invulnerability | 1.0s | 0.5-1.5s | Cinematic weight vs. flow interruption |
| Ability telegraph duration | 1.0s (0.7s at cap) | 0.5-1.5s | Player reaction window |
| Boss HP escalation (gate + N) | +15% per loop | +10-20% | Boss durability growth |
| Boss ATK escalation (gate + N) | +10% per loop | +5-15% | Boss threat growth |
| Bosses per scope tier | 0/2/4 | MVP/Tier 1/Full | Content volume |
| Boss phases per scope tier | 0/2/3 | MVP/Tier 1/Full | Encounter complexity |
| Double-confirm requirement | Yes | Yes/No | Accidental trigger protection |

## 8. Acceptance Criteria

1. **AC-01**: Boss-trigger nodes with `loop-gated:N` are inaccessible until the player reaches loop N. The node displays a descriptive message ("A heavy presence lingers here…") when approached below the gate.
2. **AC-02**: Boss pre-battle screen shows the boss info panel with name, known abilities, and phase count, plus a double-confirm prompt before the battle begins.
3. **AC-03**: Boss transitions to phase 2 when HP drops to or below 60% (or 50% for 2-phase bosses). Phase transition includes 1.0s invulnerability + animation + new ability unlock.
4. **AC-04**: Boss abilities are telegraphed with a 1.0s visual cue before firing. The player can issue commands during the telegraph window to respond.
5. **AC-05**: Boss victory grants +3 XP per participating cat, +2 affection per cat, and the boss's unique drop (first kill per loop). The boss node becomes a safe-zone for the rest of the loop.
6. **AC-06**: Boss defeat follows C4 defeat rules: all team cats Wounded, no XP, no drops. The boss node remains accessible for retry.
7. **AC-07**: Boss stats escalate correctly across loops according to the boss escalation formula (§4), layered on top of standard enemy escalation.
8. **AC-08**: Unique boss drops are only granted once ever per boss. Subsequent victories show "Unique item already claimed" instead.
9. **AC-09**: Mid-boss time-zero: battle ends immediately, boss retreats (not defeated), no rewards, collapse sequence begins.
10. **AC-10**: Boss respawns at loop start — the boss-trigger node reactivates regardless of whether the boss was defeated in the previous loop.
