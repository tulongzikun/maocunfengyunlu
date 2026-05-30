# ADR-0004: Time/Loop State Machine

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

Time is the game's central resource — action-gated, not frame-gated — with a 100-unit budget displayed diegetically as "7 years." This ADR defines the TimeManager state machine: a request/validate/deduct/notify cycle for time consumption, a 5-phase loop transition sequence (sky cracks → collapse → whiteout → auto-save → reawaken) with explicit signal ordering per ADR-0001 priority bands, an early reset path from loop 2+, and the `ceil(time_units / 14.3)` countdown formula.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Timer`, `Tween`, and integer arithmetic are stable since 4.0. No post-cutoff changes affecting signal-driven state machines or scene tree timers. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/architecture/architecture.md`, `design/gdd/time-loop-system.md` |
| **Post-Cutoff APIs Used** | None — standard `Timer`, `Tween`, `await`, and signal emission |
| **Verification Required** | Test `Tween` sequencing for the 5-second collapse animation — verify `tween.finished` signal reliably fires after chained animations in Godot 4.6 |

> **Note**: The 4.6 Tween system (`.tween_property()`, `.tween_callback()`, chaining) is stable. The collapse sequence uses `await tween.finished` between phases — verify this pattern still works correctly with 4.6's Tween refactors.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Event Bus Architecture) — signal ordering for loop transition cascade; ADR-0002 (Save/Load Serialization Format) — auto-save trigger during collapse; ADR-0003 (Node Graph Data Model) — Shrine node for early reset, safe-zone query |
| **Enables** | ADR-0005 (Relationship — loop count for memory fragments, loop-start trigger for warmth conversion and affection reset), ADR-0006 (Combat — enemy escalation at loop start, team persistence), ADR-0008 (Economy — fish clear at loop start), ADR-0011 (Day/Night Cycle — raw time_units input), ADR-0010 (Boss Encounter — boss escalation at loop milestones), ADR-0017 (True Ending — phase condition checks at loop milestones) |
| **Blocks** | All MVP stories — no game loop exists until time tracking is implemented |
| **Ordering Note** | Must be Accepted before ADR-0007 (Autoload Init Order) since TimeManager is autoload index 3 |

## Context

### Problem Statement

The game's core tension comes from limited time: 100 units per loop, consumed by player actions (dialogue, battles). When time reaches zero — or the player triggers an early reset — a 5-second diegetic collapse sequence plays, auto-save fires, and the player reawakens in a new loop. Seven downstream systems react to loop transitions (reset affection, convert warmth, escalate enemies, clear fish, reset NPC positions, accumulate traces, update tutorial tone).

The architecture signals (`time_advanced`, `countdown_critical`, `loop_collapse_start`, `loop_collapse_whiteout`, `loop_start`) must fire in a specific order to prevent data races (ADR-0001 defines priority bands for `loop_start`). This ADR defines the TimeManager state machine that sequences these signals correctly.

### Current State

No time tracking exists. The TimeManager autoload is specified in architecture.md as owning "Current time units, loop count, countdown critical threshold, loop transition, time-cost registry."

### Constraints

- Time is action-gated, not frame-gated — `_process(delta)` is NOT used for countdown
- 100 time units per loop, displayed as "7 years" via `ceil(time_units / 14.3)`
- Collapse sequence is ~5 seconds, unskippable
- 7 downstream systems react to loop transition signals
- Early reset available from loop 2+ only
- Loop count persists across game sessions via Save/Load

### Requirements

- Time only advances when the player commits to an action (dialogue advance, battle start)
- Countdown display updates immediately on time consumption
- Critical threshold (≤10 units) triggers visual + audio urgency
- Collapse sequence plays in order, auto-save completes before reawakening
- Mid-dialogue collapse: dialogue block completes before collapse begins
- Mid-battle collapse: battle ends immediately, no rewards, collapse begins
- Early reset requires explicit confirmation at Shrine node

## Decision

### TimeManager State Machine

TimeManager is an autoload singleton with three runtime states:

```
                    ┌──────────┐
        new game →  │  ACTIVE  │ ← loop start
                    └─────┬────┘
                          │ time reaches 0 OR early reset triggered
                          ↓
                    ┌──────────┐
                    │COLLAPSING│ (5s, unskippable)
                    └─────┬────┘
                          │ sequence completes → auto-save
                          ↓
                    ┌──────────┐
                    │REAWAKEN  │ → loop_start signal cascade
                    └─────┬────┘
                          │ all consumers complete
                          ↓
                    ┌──────────┐
                    │  ACTIVE  │ (new loop)
                    └──────────┘
```

States:
- **ACTIVE**: Time can be consumed. All gameplay systems operational.
- **COLLAPSING**: Time frozen. Gameplay input blocked. Collapse VFX/audio playing.
- **REAWAKEN**: Transitional — `loop_start` signal cascade in progress. Lasts until all consumers complete (synchronous, <1 frame).

### Time Consumption Protocol

Time advances through a request/validate/deduct/notify protocol via EventBus:

```
1. Action system (e.g., Dialogue) emits:
   EventBus.emit("time_cost_requested", 1)  # 1 unit for dialogue advance

2. TimeManager._on_time_cost_requested(units):
   a. Validate: is state == ACTIVE?
   b. Validate: time_remaining >= units? (if not, handle edge case — see below)
   c. Deduct: time_remaining -= units
   d. Notify: EventBus.emit("time_advanced", units, time_remaining)
   e. Check: if time_remaining <= 10 and not critical_triggered:
        EventBus.emit("countdown_critical")
        critical_triggered = true
   f. Check: if time_remaining <= 0:
        _begin_collapse_sequence()

3. Consumers of time_advanced:
   - F3 (UI): update countdown display
   - F7 (Scheduling): recalculate day/phase
```

### Time-Cost Registry

```gdscript
# Time costs — registered at boot, queryable by action systems
const COST_DIALOGUE_ADVANCE: int = 1
const COST_SMALL_BATTLE: int    = 10
const COST_LARGE_BATTLE: int    = 20
const COST_BOSS_BATTLE: int     = 30
```

Action systems emit `time_cost_requested` with the appropriate constant. TimeManager does not know what the action is — it only validates and deducts. Adding a new time-consuming action requires adding a constant here (no TimeManager code change).

### Loop Transition Sequence

```
Phase 1 — SKY CRACKS (2.0s):
  State → COLLAPSING
  EventBus.emit("loop_collapse_start")
  Consumers: P2.play_collapse_audio(5s), F3.collapse_effects()
  2.0s Tween: sky_cracks animation

Phase 2 — WORLD COLLAPSE (2.0s):
  2.0s Tween: world_collapse animation
  EventBus.emit("loop_collapse_progress", 0.5)  # midpoint

Phase 3 — WHITEOUT (1.0s):
  1.0s Tween: whiteout animation
  EventBus.emit("loop_collapse_whiteout")
  Consumer: F1.auto_save()  # ≤100ms, synchronous
  Consumer: P2.silence(1s)

Phase 4 — AUTO-SAVE:
  SaveManager.auto_save()  # Called directly (must complete before loop_start)
  EventBus.emit("save_completed", current_slot)

Phase 5 — REAWAKENING:
  loop_count += 1
  time_remaining = 100
  critical_triggered = false
  State → REAWAKEN
  EventBus.emit("loop_count_changed", loop_count)
  EventBus.emit("loop_start", loop_count)
  # loop_start consumers execute in ADR-0001 priority order:
  #   PRIORITY_PROCESS (100): C3.convert_warmth(), C4.escalate_enemies()
  #   PRIORITY_RESET   (80):  C3.reset_affection(), C5.clear_fish()
  #   PRIORITY_PERSIST (60):  F1.auto_save()
  #   PRIORITY_NORMAL  (0):   F3.update_countdown(), F6.check_phase(), etc.
  State → ACTIVE
```

### Early Reset

From loop 2+, the player can interact with the Shrine node (Central District). The interaction triggers:

```
1. Dialogue: "Accept the cycle's end?" → [Yes] / [No]
2. If [No]: return to gameplay, no time cost
3. If [Yes]: _begin_collapse_sequence() — identical to natural time-out
```

The Shrine node is tagged `loop-gated:2` in the node graph (ADR-0003). SceneManager enforces the gate — the node is not accessible in loop 1.

### Collapse Sequence Implementation

```gdscript
func _begin_collapse_sequence() -> void:
    state = STATE_COLLAPSING

    # Phase 1: Sky cracks
    EventBus.emit("loop_collapse_start")
    var tween := create_tween()
    tween.tween_property(sky_layer, "modulate:a", 1.0, 2.0)
    await tween.finished

    # Phase 2: World collapse
    EventBus.emit("loop_collapse_progress", 0.5)
    tween = create_tween()
    tween.tween_property(world_layer, "modulate:a", 0.0, 2.0)
    await tween.finished

    # Phase 3: Whiteout
    EventBus.emit("loop_collapse_whiteout")
    tween = create_tween()
    tween.tween_property(whiteout_rect, "modulate:a", 1.0, 1.0)
    await tween.finished

    # Phase 4: Auto-save (synchronous, ≤100ms)
    SaveManager.auto_save()

    # Phase 5: Reawaken
    _begin_new_loop()

func _begin_new_loop() -> void:
    loop_count += 1
    time_remaining = 100
    critical_triggered = false
    state = STATE_REAWAKEN
    EventBus.emit("loop_count_changed", loop_count)
    EventBus.emit("loop_start", loop_count)
    state = STATE_ACTIVE
```

### Edge Cases

**Dialogue in progress when time hits zero**: `time_cost_requested` for the current dialogue block is validated BEFORE the block plays. If the block's cost (1 unit) would reduce time to ≤0, the cost is still applied — the dialogue block completes, then time hits zero. The `_begin_collapse_sequence()` call happens AFTER the dialogue block's completion callback, not during the block. No dialogue is cut off.

**Battle in progress when time hits zero**: Battles request their cost (10/20/30) at battle START, not end. If a battle is in progress when time naturally reaches zero (from dialogue costs during the battle), the battle ends immediately via `EventBus.emit("battle_abort")`. Enemies retreat. No rewards. Collapse begins.

**Multiple simultaneous cost requests**: EventBus signals are synchronous — `time_cost_requested` for action A completes (including its `time_advanced` emission) before action B's `time_cost_requested` is processed. No race condition.

**Time cost requested during COLLAPSING state**: `_on_time_cost_requested()` returns immediately without deducting. The action system receives no `time_advanced` signal — it should guard against this by checking TimeManager state before requesting.

### Key Interfaces

```gdscript
# TimeManager — Autoload singleton
extends Node

enum State { ACTIVE, COLLAPSING, REAWAKEN }

var state: int = State.ACTIVE
var time_remaining: int = 100
var loop_count: int = 1
var critical_triggered: bool = false

## Query
func get_time_remaining() -> int
func get_loop_count() -> int
func get_years_display() -> int: return ceil(time_remaining / 14.3)
func is_critical() -> bool: return time_remaining <= 10
func get_state() -> int

## Time cost validation (called by action systems before committing)
func can_afford(units: int) -> bool: return state == State.ACTIVE and time_remaining >= units

## Early reset trigger (called by Shrine interaction)
func trigger_early_reset() -> void

## Save/Load contract
func collect_save_state() -> TimeState
func restore_from_save(state: TimeState) -> void
```

### TimeState Resource (Save/Load)

```gdscript
class_name TimeState extends Resource
@export var time_remaining: int = 100
@export var loop_count: int = 1
@export var critical_triggered: bool = false
```

## Alternatives Considered

### Alternative 1: Frame-Gated Passive Countdown

- **Description**: Time decreases on `_process(delta)` in real-time. 100 units = 100 seconds of real time. Player feels a ticking clock.
- **Pros**: Simpler implementation. Creates genuine time pressure. Common in games like Majora's Mask.
- **Cons**: Violates the design intent — "Time Does Not Wait" means actions cost time, not that real time is the pressure. Penalizes exploration and reading speed. Makes dialogue feel rushed. Punishes players who read slowly or explore thoroughly.
- **Rejection Reason**: The GDD explicitly states "Time does not advance during node traversal, idle standing, or menu navigation." Frame-gated time would advance during all of these. The action-gated model is a core design pillar, not an implementation preference.

### Alternative 2: Event-Driven Without Validation (Fire-and-Forget)

- **Description**: Action systems emit `time_advanced(units)` directly without requesting. TimeManager just decrements and checks for zero. No validation phase.
- **Pros**: Fewer signals. Action systems have more control. Slightly less latency (one signal instead of two).
- **Cons**: No centralized validation. Action system could advance time during COLLAPSING state. Time could go negative. No guard against double-counting (two systems advancing time for the same action).
- **Rejection Reason**: The request/validate pattern provides a single choke point for time validation. Every time-advancing action goes through `can_afford()` — if this check is removed, time bugs scatter across every action system.

### Alternative 3: Coroutine-Based Collapse (Single Long Async Function)

- **Description**: The collapse sequence is one `async func` with `await` between phases. No state enum. Collapse is just a function call.
- **Pros**: Simpler code. Sequential logic is easy to read.
- **Cons**: No explicit state that other systems can query. A system checking "is the game currently in collapse?" has no answer. If a signal consumer throws, the coroutine dies silently (Godot async error handling is limited). Harder to test phase-by-phase.
- **Rejection Reason**: The state enum (`ACTIVE | COLLAPSING | REAWAKEN`) is the single source of truth for "can time advance right now?" Six action systems check this before requesting time costs. A coroutine cannot replace explicit state without every system calling `is_collapsing()` differently.

## Consequences

### Positive

- **Single choke point**: All time validation goes through `can_afford()`. Bugs in time consumption are centralized and debuggable.
- **Explicit state**: Three states clearly define what operations are valid at each moment. No system can accidentally consume time during collapse.
- **Signal ordering is enforced**: The `loop_start` priority bands (ADR-0001) guarantee convert→reset→persist ordering. The collapse sequence explicitly fires signals in order.
- **Action-gated time serves the design**: Players explore freely, then commit time intentionally. No rushing through dialogue.

### Negative

- **Two signals per time cost**: `time_cost_requested` → `time_advanced` adds latency compared to a single signal. For event-driven (not per-frame) time consumption, this is negligible (<0.01ms per emission).
- **5-second collapse is unskippable**: Players who have seen the collapse 10+ times may find it tedious. Mitigation: add a "hold to skip" option in Tier 1 (not MVP) — but the first collapse each session must play fully per the design.
- **No passive urgency**: Players who are not paying attention to the countdown may forget time is limited. Mitigation: the countdown is always visible; critical threshold pulse (<10 units) is hard to ignore.

### Neutral

- TimeManager does not know which action consumed time — it only knows the unit cost. This is intentional: adding a new time-consuming action requires only a constant and an EventBus emit, not a TimeManager code change.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Collapse sequence hangs (Tween.finished never fires) | Low | High — game stuck in COLLAPSING state, player must force-quit | Add a safety timeout: if collapse exceeds 10s, force-complete and log error. |
| time_remaining goes negative | Low | Medium — display shows "-1 years" | `can_afford()` checks before deducting. Action systems must call it before emitting `time_cost_requested`. Debug assertion in `_on_time_cost_requested` that `time_remaining >= units`. |
| loop_count overflow | Very Low | Low — after 2^31 loops, integer overflows | Not applicable — the game is designed for ~10-20 loops before true ending. |
| Early reset in loop 1 via bug | Low | High — player could skip the tutorial loop | Shrine node uses `loop-gated:2` tag enforced by SceneManager (ADR-0003). TimeManager additionally checks `loop_count >= 2` in `trigger_early_reset()`. |
| Save during COLLAPSING state | Low | High — save captures half-collapsed state, load restores broken visual state | COLLAPSING state blocks manual save. Auto-save fires at a specific point in the sequence (after whiteout), not during active collapse animation. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (time cost request → notify) | N/A | <0.01ms (two EventBus emissions) | Event-driven, a few per player action |
| CPU (collapse sequence) | N/A | 5.0s total, no per-frame processing | Visual/animation budget |
| Memory | 0 KB | <1KB (3 ints + 1 enum) | Negligible |
| Load Time | N/A | No impact | — |

## Migration Plan

No existing time system to migrate — greenfield.

**Implementation steps:**
1. Create `TimeManager` autoload with state enum, time_remaining, loop_count, and query API
2. Implement `_on_time_cost_requested()` handler with validation and deduction
3. Implement `_begin_collapse_sequence()` with 5-phase Tween chain
4. Implement `_begin_new_loop()` with signal cascade
5. Implement `trigger_early_reset()` with confirmation dialogue
6. Register TimeManager as autoload index 3 (after EventBus, SaveManager, SceneManager)
7. Wire `time_cost_requested` → `time_advanced` → `countdown_critical` → `loop_collapse_start` → `loop_collapse_whiteout` → `loop_start` signal chain via EventBus
8. Implement `TimeState` Resource and save/load contract
9. Greybox test: emit time_cost_requested(1) 100 times, verify collapse plays and loop_count increments

**Rollback plan**: The TimeManager state machine is self-contained. If the collapse sequence timing needs adjustment, the Tween durations are tuning knobs. If the signal ordering needs revision, the `loop_start` priority bands in ADR-0001 control execution order without changing TimeManager code.

## Validation Criteria

- [ ] **Time consumption**: Emit `time_cost_requested(1)`. Assert `time_remaining` decrements from 100 to 99. Assert `time_advanced` signal fires with args (1, 99).
- [ ] **Validation guard**: Set `time_remaining = 0`. Emit `time_cost_requested(1)`. Assert `time_remaining` stays at 0, `time_advanced` does NOT fire.
- [ ] **Critical threshold**: Reduce `time_remaining` from 11 to 10. Assert `countdown_critical` signal fires. Reduce from 10 to 9. Assert `countdown_critical` does NOT fire again (already triggered).
- [ ] **Full collapse sequence**: Set `time_remaining = 1`. Emit `time_cost_requested(1)`. Assert: `loop_collapse_start` fires → Tween chain plays → `loop_collapse_whiteout` fires → `loop_start` fires → state returns to ACTIVE → `loop_count` = 2 → `time_remaining` = 100.
- [ ] **Loop start signal ordering**: Connect 6 test consumers to `loop_start` at PRIORITY_PROCESS (100), PRIORITY_RESET (80), PRIORITY_PERSIST (60), PRIORITY_NORMAL (0). Assert execution order matches priority bands.
- [ ] **Early reset**: Set `loop_count = 3`. Call `trigger_early_reset()`. Assert collapse sequence plays. Assert `loop_count` = 4. Set `loop_count = 1`. Call `trigger_early_reset()`. Assert function returns early (no reset).
- [ ] **COLLAPSING state blocks time**: Set state = COLLAPSING. Emit `time_cost_requested(1)`. Assert `time_remaining` unchanged. Assert `time_advanced` not emitted.
- [ ] **Countdown display**: Assert `get_years_display()` returns 7 at `time_remaining = 100`, 4 at `time_remaining = 57`, 1 at `time_remaining = 14`, 0 at `time_remaining = 0`.
- [ ] **Save/load**: Set `time_remaining = 42`, `loop_count = 5`. Save. Load. Assert both values restored.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/time-loop-system.md` | C2 Time/Loop | 100 time units per loop, displayed as "7 years" via `ceil(time_units / 14.3)` (AC-01) | `time_remaining` int + `get_years_display()` formula |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Time advances only through player actions, not traversal or idle (AC-02, AC-10) | Action-gated request/validate/deduct protocol; no `_process()` involvement |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Small battle = 10 units, boss = 30 units (AC-03) | `COST_SMALL_BATTLE`, `COST_LARGE_BATTLE`, `COST_BOSS_BATTLE` constants |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Collapse sequence: sky cracks (2s) → collapse (2s) → whiteout (1s) → reawakening (AC-04) | 5-phase Tween chain with `await tween.finished` between phases |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Loop start: counter +1, warmth persists (no decay), fish clear, team persists, enemies escalate (AC-05) | `loop_start` signal cascade with ADR-0001 priority bands |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Mid-dialogue collapse: dialogue block completes first (AC-06) | Cost validated before dialogue block; collapse begins after completion callback |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Mid-battle collapse: enemies retreat, no rewards (AC-07) | `battle_abort` signal on collapse during active battle |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Early reset via Shrine with confirmation, loop 2+ only (AC-08, AC-09) | `trigger_early_reset()` with `loop_count >= 2` guard + confirmation dialogue |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Critical threshold at ≤10 units triggers UI pulse | `countdown_critical` signal at `time_remaining <= 10` |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Loop count for memory fragment tier, dialogue tiers, enemy escalation | `loop_count` exposed via `get_loop_count()`; `loop_count_changed` signal |

## Related

- `docs/architecture/architecture.md` — TimeManager module ownership (Core layer), signal catalog, boot sequence
- ADR-0001: Event Bus Architecture — signal priority bands for `loop_start` cascade
- ADR-0002: Save/Load Serialization Format — `TimeState` sub-resource, auto-save trigger
- ADR-0003: Node Graph Data Model — Shrine node (`loop-gated:2`), safe-zone tags
- ADR-0011: Day/Night Cycle Implementation — consumes `time_remaining` for day/phase calculation
