# ADR-0005: Relationship Data Model

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

The NPC Relationship System uses a two-layer model — per-loop affection (0-10, resets each loop) and cumulative warmth (0-3, never decays) — to create a design where the player must commit a full loop to advancing one relationship tier, while the accumulated bond persists permanently. This ADR defines the per-NPC data structure as a `RelationshipState` Resource containing `NPCData` arrays, the affection source registry and warmth conversion formula, the recruitment eligibility rules, and the memory fragment tier gating formula `min(warmth, floor(loop_count / 2) + 1)`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Resource`, integer math, and signal emission are stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/architecture/architecture.md`, `design/gdd/npc-relationship-system.md` |
| **Post-Cutoff APIs Used** | None — standard Resource serialization and integer arithmetic |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (EventBus — signal ordering for warmth conversion), ADR-0002 (Save/Load — persistence of warmth, affection, memory flags), ADR-0004 (Time/Loop — loop_start signal triggers affection reset and warmth conversion; loop count for memory fragments) |
| **Enables** | ADR-0006 (Combat — recruitment status, warmth combat bonus), ADR-0009 (Dialogue — warmth-gated dialogue and memory fragment delivery), ADR-0013 (Traces — warmth tier for trace saturation), ADR-0010 (Boss Encounter — warmth-gated access), ADR-0017 (True Ending — warmth thresholds for ending conditions) |
| **Blocks** | MVP stories for NPC interaction, recruitment, and relationship progression |
| **Ordering Note** | Must be Accepted before ADR-0006 (Combat — depends on recruitment) and ADR-0009 (Dialogue — depends on warmth-gated content) |

## Context

### Problem Statement

The NPC Relationship System is the emotional backbone of the game. It must model two distinct timeframes: what the player did for an NPC *this loop* (affection) and the *accumulated bond* across all loops (warmth). Affection resets to zero on reawakening — the player must commit again. Warmth never decays — once earned, it's permanent. Together they create the game's central emotional mechanic: "I remember everything; they remember fragments. But slowly, they begin to remember too."

Five downstream systems read relationship state (Combat, Dialogue, Traces, Boss, True Ending). Four upstream systems write to it (Combat, Economy, Dialogue, Time/Loop). The data model must support bidirectional read/write through EventBus without tight coupling.

### Constraints

- 3 NPCs (MVP) to 10 NPCs (full vision)
- Per-NPC data fits in a single Resource file per NPC
- Warmth conversion fires once per loop (during `loop_start` PRIORITY_PROCESS)
- Affection reset fires once per loop (during `loop_start` PRIORITY_RESET)
- Memory fragments delivered through Dialogue System, keyed to warmth + loop count
- Recruitment re-evaluated at loop start (affection-based recruits leave on reset)

### Requirements

- Per-loop affection: 0-10, resets to 0 at loop start, earned via 4 action types
- Cumulative warmth: 0-3, advances by 1 if affection=10 at loop end, never decays
- Memory fragment tier: formula-based, capped at 3
- Recruitment: warmth≥1 (permanent) OR affection>5 (current loop only)
- Warmth combat bonus: tier 2 → +10% stats, tier 3 → +20% + signature ability

## Decision

### Two-Layer Data Model

```
┌──────────────────────────────────────────────────────┐
│                  NPC Relationship                     │
│                                                      │
│  ┌─────────────────────┐  ┌──────────────────────┐   │
│  │  Per-Loop Affection  │  │  Cumulative Warmth    │   │
│  │  (0-10)              │  │  (0-3)                │   │
│  │  • Resets each loop  │  │  • Never decays       │   │
│  │  • Earned via actions│  │  • +1 if affect≥10    │   │
│  │  • Gates recruitment │  │  • Gates content       │   │
│  │    (current loop)    │  │  • Gates recruitment   │   │
│  │                      │  │    (permanent)         │   │
│  └─────────┬────────────┘  └──────────┬────────────┘   │
│            │ affection≥10             │                 │
│            └──────────→ warmth += 1   │                 │
│                     (loop end)        │                 │
└──────────────────────────────────────────────────────┘
```

### NPCData Resource

```gdscript
class_name NPCData extends Resource

## Unique NPC identifier (e.g., "old_tom", "juyun", "fisherman_wei")
@export var npc_id: String = ""

## Display name (e.g., "老汤姆", "橘云", "渔夫阿伟")
@export var display_name: String = ""

## Cumulative warmth tier (0-3, never decays)
@export var warmth: int = 0

## Per-loop affection (0-10, resets at loop start)
@export var affection: int = 0

## Recruitment state
@export var is_recruited: bool = false

## How this NPC was recruited (for loop-start re-evaluation)
@export_enum("none", "warmth", "affection") var recruitment_source: int = 0

## Memory fragments shown to this NPC (fragment IDs)
@export var memory_fragments_seen: Array[int] = []

## Gratitude fish given this loop (reset at loop start)
@export var gratitude_fish_given: bool = false

## Affection breakdown by source (for UI and debugging)
@export var affection_sources: Dictionary = {}  # { "fish": 4, "battle": 2, "dialogue": 3 }
```

### Affection Source Registry

Affection is earned through 4 source types, each with a fixed value:

```gdscript
const AFFECTION_SOURCE_FISH: int     = 2   # +2 per fish gifted
const AFFECTION_SOURCE_BATTLE: int   = 2   # +2 per battle alongside (on victory)
const AFFECTION_SOURCE_DIALOGUE: int = 1   # +1 per "good" dialogue choice
const AFFECTION_SOURCE_EVENT_MIN: int= 2   # +2 to +4 for special events
const AFFECTION_SOURCE_EVENT_MAX: int= 4
const AFFECTION_SOURCE_VISIT: int    = 0   # Visiting enables other actions, no direct gain
```

### Affection Accumulation

```gdscript
func add_affection(npc_id: String, amount: int, source: String) -> void:
    var npc: NPCData = _get_npc(npc_id)
    var old_affection := npc.affection
    npc.affection = min(10, npc.affection + amount)
    var actual_gain := npc.affection - old_affection
    npc.affection_sources[source] = npc.affection_sources.get(source, 0) + actual_gain
    EventBus.emit("affection_changed", npc_id, actual_gain, source)
    if npc.affection >= 10:
        EventBus.emit("affection_maxed", npc_id)
```

### Warmth Conversion (Loop End)

Fires during `loop_start` at PRIORITY_PROCESS (100), BEFORE affection reset:

```gdscript
# Called by EventBus "loop_start" at PRIORITY_PROCESS (100)
func _on_loop_start_convert(_loop_count: int) -> void:
    for npc in _npcs.values():
        if npc.affection >= 10:
            if npc.warmth < 3:
                npc.warmth += 1
                EventBus.emit("warmth_tier_up", npc.npc_id, npc.warmth)
            # If warmth already 3: no change, NPC acknowledges but no mechanical advance

# Called by EventBus "loop_start" at PRIORITY_RESET (80), AFTER conversion
func _on_loop_start_reset(_loop_count: int) -> void:
    for npc in _npcs.values():
        npc.affection = 0
        npc.affection_sources.clear()
        npc.gratitude_fish_given = false
        # Re-evaluate affection-based recruitment
        if npc.recruitment_source == 1:  # "affection"
            npc.is_recruited = false
            npc.recruitment_source = 0
            EventBus.emit("npc_unrecruited", npc.npc_id)
```

### Recruitment Eligibility

```gdscript
func is_recruitable(npc_id: String) -> bool:
    var npc := _get_npc(npc_id)
    if npc.is_recruited:
        return false  # Already in team
    return npc.warmth >= 1 or npc.affection > 5

func recruit(npc_id: String) -> bool:
    if not is_recruitable(npc_id):
        return false
    var npc := _get_npc(npc_id)
    npc.is_recruited = true
    npc.recruitment_source = 0 if npc.warmth >= 1 else 1  # 0=warmth, 1=affection
    EventBus.emit("npc_recruited", npc_id)
    return true

func dismiss(npc_id: String) -> void:
    var npc := _get_npc(npc_id)
    npc.is_recruited = false
    npc.recruitment_source = 0
    EventBus.emit("npc_dismissed", npc_id)
```

**Team full check**: CombatManager (C4) owns team size caps. RelationshipManager exposes recruitment eligibility; CombatManager calls `recruit()` and enforces the cap. If the team is full, CombatManager emits `team_full` — the UI shows the roster and asks the player to dismiss someone.

### Memory Fragment Tier

```gdscript
func get_memory_tier(npc_id: String) -> int:
    var npc := _get_npc(npc_id)
    var tier := min(npc.warmth, floor(TimeManager.get_loop_count() / 2.0) + 1)
    return clampi(tier, 0, 3)
```

| Fragment Tier | Requires | Behavior |
|--------------|----------|----------|
| 0 | warmth=0 | Basic idle lines only — NPC doesn't recognize player |
| 1 | warmth≥1, loop≥2 | Déjà vu lines from shared pool |
| 2 | warmth≥2, loop≥3 | Specific recall of past-loop events (hand-authored per NPC) |
| 3 | warmth=3, loop≥4 | Behavioral persistence — NPC acts on remembered knowledge |

### Warmth Combat Bonus

| Warmth | Label | Combat Bonus |
|--------|-------|-------------|
| 0 | Stranger | None |
| 1 | Acquaintance | Recruitable only — no stat bonus |
| 2 | Friend | +10% HP, ATK, DEF (applied in CombatManager) |
| 3 | Bonded | +20% HP, ATK, DEF + signature ability unlocked |

Warmth bonus does NOT affect SPD (per ADR-0006 formula: `effective_spd = base_spd − stat_bonus × 0.1`).

### Key Interfaces

```gdscript
# RelationshipManager — Autoload singleton
extends Node

## Query
func get_npc(npc_id: String) -> NPCData
func get_warmth(npc_id: String) -> int
func get_affection(npc_id: String) -> int
func get_memory_tier(npc_id: String) -> int
func get_all_npcs() -> Array[NPCData]
func get_recruited_npcs() -> Array[NPCData]
func is_recruited(npc_id: String) -> bool
func is_recruitable(npc_id: String) -> bool

## Mutation (called via EventBus consumers or direct by owner systems)
func add_affection(npc_id: String, amount: int, source: String) -> void
func recruit(npc_id: String) -> bool
func dismiss(npc_id: String) -> void

## Internal (called by EventBus loop_start consumers)
func _on_loop_start_convert(loop_count: int) -> void   # PRIORITY_PROCESS (100)
func _on_loop_start_reset(loop_count: int) -> void      # PRIORITY_RESET (80)

## Save/Load contract
func collect_save_state() -> RelationshipState
func restore_from_save(state: RelationshipState) -> void
```

### RelationshipState Resource

```gdscript
class_name RelationshipState extends Resource
@export var npcs: Array[NPCData] = []
```

### Event Wiring

```
UPSTREAM (other systems → RelationshipManager):
  C5: EventBus.emit("fish_gifted", npc_id, amount) → +2 affection
  C4: EventBus.emit("battle_victory") → +2 affection per team NPC
  F4: EventBus.emit("good_dialogue_choice", npc_id) → +1 affection
  C2: EventBus.emit("loop_start", loop_count) → warmth conversion + affection reset

DOWNSTREAM (RelationshipManager → other systems):
  EventBus.emit("affection_changed", npc_id, amount, source)
  EventBus.emit("affection_maxed", npc_id)
  EventBus.emit("warmth_tier_up", npc_id, new_tier)
  EventBus.emit("npc_recruited", npc_id)
  EventBus.emit("npc_dismissed", npc_id)
```

## Alternatives Considered

### Alternative 1: Single-Layer Warmth (No Affection)

- **Description**: Remove the per-loop affection layer. Warmth is the only metric. Actions add warmth directly (0→3 with enough gifts/battles/dialogue across any number of loops).
- **Pros**: Simpler data model. One number per NPC. No conversion logic. No reset logic.
- **Cons**: Violates the core design — "you cannot grind warmth through repetition alone." Without per-loop affection, a player could reach warmth 3 with all NPCs by mindlessly gifting fish across 12 loops. The "committed loop" tension is lost. The design pillar "Time Does Not Wait" is undermined.
- **Rejection Reason**: The two-layer model is the design's central innovation. Removing it removes the emotional core of the game.

### Alternative 2: Affection Persists (No Reset)

- **Description**: Affection accumulates across loops without resetting. No warmth tier. Affection IS the relationship metric. No conversion.
- **Pros**: Simpler — one number, no reset, no conversion.
- **Cons**: The player can reach max affection with everyone eventually without strategic choice. "Every Encounter Leaves a Mark" (P1) is satisfied but "Loops Are Growth" (P4) becomes "Loops Are Accumulation" — there's no moment of conversion, no payoff for a committed loop.
- **Rejection Reason**: The conversion moment (affection≥10 → warmth+1) is the emotional payoff of each loop. Removing it removes the moment the player feels "I earned that. It carries forward."

### Alternative 3: Warmth Decay

- **Description**: Warmth decays by 1 tier at loop start if the player didn't interact with the NPC that loop.
- **Pros**: Creates maintenance pressure — relationships need ongoing attention. Realistic (relationships fade without contact).
- **Cons**: Violates P4 (Loops Are Growth). Punishes the player for prioritizing other NPCs. Creates anxiety about "losing progress." The cross-GDD review identified this as a BLOCKER — it was explicitly rejected.
- **Rejection Reason**: Already resolved in the cross-GDD review. Warmth never decays. A cat who trusts you stays trusting. This is a design pillar commitment.

## Consequences

### Positive

- **Emotional pacing**: The player must plan each loop around 1-2 NPCs to max out affection. This creates strategic choice ("Who do I invest in this cycle?") and emotional payoff when warmth advances.
- **No grinding**: A player cannot reach warmth 3 through repetition alone. Three committed loops minimum per NPC. With 10 NPCs and 3-5 fish per loop, maxing everyone is a long-term goal.
- **Clear signal to other systems**: `warmth_tier_up` is a single, meaningful event that Dialogue, Traces, Audio, and Animation all react to. No polling, no checking "did warmth change by at least 1."
- **Bidirectional with loose coupling**: Upstream systems emit generic events (`fish_gifted`, `battle_victory`). RelationshipManager consumes them and converts to relationship changes. No system knows about any other system's internals.

### Negative

- **Two numbers to track per NPC**: Affection + warmth = 2 integers × 10 NPCs = 20 values. The HUD must show both (warmth tier icon + affection bar). Acceptable complexity for the core mechanic.
- **Conversion timing is critical**: If `convert_warmth` and `reset_affection` fire in the wrong order, warmth never advances. This is enforced by ADR-0001 priority bands, but the dependency is non-obvious to a new programmer.
- **Affection cap overflow is silently discarded**: Gifting a fish at affection 9 grants only +1 (capped at 10). The fish is still consumed. The UI should show the cap to prevent player frustration.

### Neutral

- The affection source breakdown (`affection_sources` Dictionary) is for debugging and UI only — not used in any formula. It can be removed if memory becomes a concern (it won't — 10 NPCs × 4 source entries = negligible).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Conversion/reset ordering inverted | Low | High — warmth never advances, all NPCs stuck at warmth 0 | ADR-0001 priority bands enforce CONVERT at 100, RESET at 80. Integration test verifies. |
| Affection double-counting | Medium | Medium — same action processed twice, affection reaches 10 too easily | Each source event is idempotent: `fish_gifted` fires once per gift, `battle_victory` fires once per battle. EventBus duplicate connection guard (ADR-0001) prevents double-subscription. |
| Warmth exceeds 3 | Low | Low — integer overflow, display weirdness | `add_affection` conversion step clamps: `npc.warmth = min(3, npc.warmth + 1)`. |
| Affection exceeds 10 | Medium | Low — player wastes actions | `add_affection` clamps: `npc.affection = min(10, npc.affection + amount)`. UI shows "MAX" when affection = 10. |
| NPC reset during mid-conversation | Low | Medium — affection from current dialogue block lost on reset | ADR-0004 edge case: dialogue block completes before collapse. Affection from completed dialogue is applied before loop end. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (add_affection) | N/A | <0.01ms (integer math + Dictionary update + signal emit) | Event-driven |
| CPU (loop start conversion) | N/A | <0.05ms (10 NPCs × warmth check + signal emits) | Once per loop |
| Memory (10 NPCs) | 0 KB | ~5KB (10 NPCData Resources × ~500 bytes) | Negligible |
| Load Time | N/A | <1ms (ResourceLoader for 10 .tres files or one combined .tres) | Acceptable at boot |

## Migration Plan

No existing relationship data to migrate — greenfield.

**Implementation steps:**
1. Create `NPCData` and `RelationshipState` Resource classes
2. Author NPC data files (3 for MVP, 10 for full vision) as .tres Resources
3. Implement RelationshipManager autoload with query and mutation API
4. Wire EventBus consumers: `fish_gifted` → +2 affection, `battle_victory` → +2/team NPC, `good_dialogue_choice` → +1 affection
5. Wire EventBus `loop_start` consumers at PRIORITY_PROCESS (100) and PRIORITY_RESET (80)
6. Implement recruitment eligibility, recruit, dismiss
7. Implement `get_memory_tier()` formula
8. Implement `RelationshipState` save/load contract (ADR-0002)
9. Register RelationshipManager as autoload index 5 (after EventBus, SaveManager, SceneManager, TimeManager)

**Rollback plan**: The two-layer model is fundamental to the design. Reverting to single-layer warmth would require removing affection tracking, conversion logic, and reset logic, and updating all downstream consumers (Combat, Dialogue, Traces, Boss, True Ending) — essentially a redesign. However, the `NPCData` Resource structure can absorb changes: adding a field is a no-op for existing saves; removing the `affection` field is a migration (`save_version` increment in ADR-0002).

## Validation Criteria

- [ ] **New game initialization**: Start new game. Assert all 3 NPCs have warmth=0, affection=0, is_recruited=false.
- [ ] **Affection accumulation**: Gift 3 fish to Old Tom (+6). Select 2 good dialogue choices (+2). Battle alongside once (+2). Assert affection = 10 (capped). Assert affection_sources = {"fish": 6, "dialogue": 2, "battle": 2}.
- [ ] **Affection cap**: Gift a fish at affection 9. Assert affection = 10 (not 11). Assert actual gain = 1. Fish consumed (Economy deducts).
- [ ] **Warmth conversion**: Set affection = 10 on 橘云. Emit `loop_start`. Assert warmth = 1, affection = 0 (reset after conversion).
- [ ] **Warmth no-decay**: Set warmth = 2, affection = 5 on Fisherman Wei. Emit `loop_start`. Assert warmth = 2 (unchanged, affection < 10). Assert affection = 0 (reset).
- [ ] **Warmth cap**: Set warmth = 3, affection = 10 on Old Tom. Emit `loop_start`. Assert warmth = 3 (capped). Warmth never exceeds 3.
- [ ] **Recruitment — warmth path**: Set warmth = 1 on 橘云. Assert `is_recruitable("juyun")` = true. Recruit. Assert persists across loop start.
- [ ] **Recruitment — affection path**: Set warmth = 0, affection = 6 on Fisherman Wei. Assert `is_recruitable("fisherman_wei")` = true. Recruit. Emit `loop_start`. Assert is_recruited = false (affection reset, warmth still 0).
- [ ] **Memory fragment tier**: warmth=1, loop=1 → tier=1. warmth=1, loop=3 → tier=2. warmth=3, loop=4 → tier=3. warmth=0, loop=5 → tier=0.
- [ ] **Save/load**: Set warmth=2, affection=7 on Old Tom. Save. Load. Assert both values restored.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Two-layer model: per-loop affection (0-10) + cumulative warmth (0-3, no decay) (AC-01, AC-07) | `NPCData.affection` + `NPCData.warmth` with conversion and reset logic |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Affection sources: fish=+2, battle=+2, good dialogue=+1, events=+2~4 (AC-02, AC-03) | Affection source constants + `add_affection()` with source tracking |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Affection capped at 10 (AC-04) | `min(10, affection + amount)` in `add_affection()` |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Warmth conversion: affection≥10 → warmth+1 at loop end (AC-05) | `_on_loop_start_convert()` at PRIORITY_PROCESS (100) |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Affection reset to 0 at loop start (AC-06) | `_on_loop_start_reset()` at PRIORITY_RESET (80) — after conversion |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Recruitment: warmth≥1 OR affection>5 (AC-08) | `is_recruitable()` with dual-path logic |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Affection-based recruits leave team on reset (AC-09) | `recruitment_source` enum; re-evaluated at loop start |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Dialogue queries correct warmth tier (AC-10) | `get_warmth()` and `get_memory_tier()` exposed to Dialogue System |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Warmth capped at 3 (AC-11) | `min(3, warmth + 1)` in conversion |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Multiple NPCs advance independently (AC-12) | Per-NPC iteration in conversion loop |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Memory fragments: 3 tiers, formula-based | `get_memory_tier()` = `min(warmth, floor(loop/2)+1)` |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Warmth combat bonus: +10% at tier 2, +20% at tier 3 | CombatManager reads `get_warmth()` and applies bonus in ADR-0006 |

## Related

- `docs/architecture/architecture.md` — RelationshipManager module ownership (Core layer), signal catalog
- ADR-0001: Event Bus Architecture — signal priority bands for `loop_start` ordering
- ADR-0002: Save/Load Serialization Format — `RelationshipState` sub-resource, `NPCData` persistence
- ADR-0004: Time/Loop State Machine — `loop_start` trigger, `loop_count` for memory fragments
- ADR-0006: Auto-Battler Resolution Engine — consumes recruitment status, warmth combat bonus
- ADR-0009: Dialogue Resource Format — consumes warmth tier for dialogue gating and memory fragments
