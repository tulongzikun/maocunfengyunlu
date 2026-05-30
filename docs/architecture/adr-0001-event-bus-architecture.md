# ADR-0001: Event Bus Architecture

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer), Technical Director, Godot Specialist

## Summary

The architecture mandates signal-driven cross-module communication via an EventBus autoload, but standard Godot signals use implicit connection-order FIFO — fragile for signals like `loop_start` where `convert_warmth()` must read per-loop affection values before `reset_affection()` zeroes them. This ADR establishes a priority-based EventBus wrapper: each connection declares an optional priority integer; consumers execute in descending priority order with named priority bands preventing collisions.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — Godot `Callable`, `Object.connect()`, and Dictionary APIs stable since 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | Variadic arguments (`Variant...`) — Godot 4.5 feature. `Callable.callv()` — standard since 4.0. Both verified against `current-best-practices.md`. |
| **Verification Required** | Test `Callable.callv()` with Array unpacking for signals with 0–6 args to confirm no edge-case arg-count behavior in 4.6 |

> **Note**: If the project upgrades to Godot 4.7+, re-verify `Callable.callv()` behavior and variadic arg unpacking.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0004 (Time/Loop state machine — emits and consumes via EventBus), ADR-0005 (Relationship data model — reacts to loop_start, fish_gifted, battle_victory), ADR-0006 (Auto-battler — emits battle_* signals), ADR-0008 (Economy — emits fish_* signals), ADR-0009 (Dialogue — emits dialogue_* signals), ADR-0010 (Boss Encounter — extends C4 EventBus patterns), ADR-0012 (UI/HUD — consumes signals from all Core systems), ADR-0013 (Traces — consumes warmth_tier_up), ADR-0014 (Audio — consumes signals from nearly every system), ADR-0015 (Accessibility — consumes setting_change events), ADR-0017 (True Ending — consumes signals from C3, C4, F5) |
| **Blocks** | All Pre-MVP stories — no cross-system communication can be implemented until EventBus contract is defined |
| **Ordering Note** | Must be Accepted before any module implements signal connections. Must be Accepted before ADR-0007 (Autoload Init Order) since EventBus is the first autoload. |

## Context

### Problem Statement

The architecture mandates signal-driven communication: 18 modules communicate exclusively through an `EventBus` autoload singleton. Standard Godot signals fire consumers in connection order — the order `connect()` was called in `_ready()`. This is:

1. **Implicit**: The execution order of consumers is not visible in the signal declaration or emission code. A programmer reading `EventBus.loop_start.emit()` cannot see which systems react or in what order.

2. **Fragile**: Reordering `connect()` calls in one module's `_ready()` silently changes behavior in another module. There is no compiler or lint check.

3. **Insufficient for ordered dependencies**: The `loop_start` signal has consumers where execution order matters — `convert_warmth()` must read per-loop affection values before `reset_affection()` zeroes them. Without explicit ordering, warmth conversion would read zeroed affection and no NPC would ever advance in warmth (TR-c3-003 would fail).

Additional ordering dependencies exist or may arise:

| Signal | Must Execute First | Before | Reason |
|--------|-------------------|--------|--------|
| `loop_start` | C3.convert_warmth() | C3.reset_affection() | Convert reads affection values that reset zeroes |
| `loop_start` | C3.convert_warmth() | F1.auto_save() | Save must capture post-conversion state |
| `loop_start` | C5.clear_fish() | F1.auto_save() | Save must capture cleared inventory |
| `battle_victory` | C3.add_affection() | C4.distribute_xp() | Affection credited before XP (affection could affect XP in Tier 1+) |

### Current State

No EventBus exists yet. This is the first architectural decision for the project. The architecture blueprint (`architecture.md`) defines 40+ signals and mandates signal-driven communication, but does not specify how signal ordering is enforced.

### Constraints

- Must use only Godot 4.6 built-in APIs — no third-party event libraries
- Must support 18 modules with 40+ signals and 100+ total connections
- EventBus autoload loads first (before any state-owning module)
- Signal emission is event-driven, not per-frame — zero overhead during idle
- Pure GDScript — no C# or GDExtension dependency
- Solo developer — simplicity and debuggability are high priorities

### Requirements

- Programmers can declare and see execution order at the connection site
- Modules that don't care about order use the same, simple API
- Adding a new signal consumer does not risk silently breaking existing ordering
- All cross-system signals are discoverable in one file
- Handlers must not block the frame — EventBus emits synchronously (all handlers run before `emit()` returns)

## Decision

### Priority-Based Signal Bus

EventBus maintains its own subscriber lists (Dictionary keyed by signal name) with an optional **priority** integer per connection. When a signal is emitted, consumers execute in descending priority order (higher = earlier). Equal priority = connection order (standard FIFO).

**Default priority is 0.** Modules that don't specify priority get standard FIFO behavior — the priority system is opt-in. Only ordering-sensitive connections declare a priority.

This design uses `Callable.callv()` dispatch rather than Godot's native `Signal.emit()` because native signals use connection-order FIFO with no priority mechanism. The trade-off is the loss of editor integration (Signals dock, Connections tab) in exchange for explicit, enforced execution order.

### Priority Bands

Named constants prevent priority number collisions across modules:

```gdscript
const PRIORITY_PROCESS: int = 100  # Process old-loop state before it's cleared
const PRIORITY_RESET: int   = 80   # Clear per-loop state for new loop
const PRIORITY_PERSIST: int = 60   # Save/persist post-transition state
const PRIORITY_NORMAL: int  = 0    # Default — UI updates, audio, animation triggers
const PRIORITY_DEFER: int   = -50  # Non-urgent — analytics, achievement checks, logging
```

Using `loop_start` as the worked example — the correct execution order is **process old state → reset for new loop → persist**:

```
C3.convert_warmth()     → PRIORITY_PROCESS (100) — reads affection BEFORE reset zeroes it
C4.escalate_enemies()   → PRIORITY_PROCESS (100) — reads loop_count, independent of C3
C3.reset_affection()    → PRIORITY_RESET   (80)  — zeroes affection AFTER conversion
C5.clear_fish()         → PRIORITY_RESET   (80)  — independent of C3, same band OK
F1.auto_save()          → PRIORITY_PERSIST (60)  — captures all post-transition state
F3.update_countdown()   → PRIORITY_NORMAL  (0)   — UI refresh, order-irrelevant
```

`convert_warmth` and `escalate_enemies` share PRIORITY_PROCESS (100) because neither depends on the other — FIFO within the band is acceptable. Similarly, `reset_affection` and `clear_fish` share PRIORITY_RESET (80).

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      EventBus (Autoload #0)             │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Signal Registry                     │   │
│  │  "loop_start"       → Array[Subscriber] (sorted) │   │
│  │  "battle_victory"   → Array[Subscriber] (sorted) │   │
│  │  "affection_changed"→ Array[Subscriber] (sorted) │   │
│  │  ... 40+ signals                                 │   │
│  │                                                  │   │
│  │  Each Array sorted by priority desc,             │   │
│  │  then by connection order within same priority.  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  connect_to(signal, callable, priority)                  │
│  disconnect_from(signal, callable)                       │
│  emit(signal, ...args)                                   │
│  is_connected(signal, callable) → bool                   │
│  has_signal(signal) → bool                               │
└─────────────────────────────────────────────────────────┘
         ↑ emit()                  ↓ callv() in priority order
   ┌─────┴──────┐          ┌──────┴──────────────┐
   │  Producer   │          │  Consumers (sorted)  │
   │  C2.TimeMgr │          │  1. C3.convert_warmth│
   │  C3.RelMgr  │          │  2. C4.escalate      │
   │  C4.Combat  │          │  3. C3.reset_affect  │
   │  ...         │          │  4. C5.clear_fish    │
   └─────────────┘          │  5. F1.auto_save     │
                            │  6. F3.update_ui     │
                            └─────────────────────┘
```

### Key Interfaces

```gdscript
# event_bus.gd — Autoload singleton, registered first in project.godot
extends Node

## Priority bands — use these constants, not raw integers.
const PRIORITY_PROCESS: int = 100  # Process old-loop state before clearing
const PRIORITY_RESET: int   = 80   # Clear per-loop state
const PRIORITY_PERSIST: int = 60   # Save after all transitions
const PRIORITY_NORMAL: int  = 0    # Default — UI, audio, animation
const PRIORITY_DEFER: int   = -50  # Non-urgent work

## Internal subscriber record
class Subscriber:
    var callable: Callable
    var priority: int
    var source: String  # Module name for debug logging

## { "signal_name": Array[Subscriber] }
var _subscribers: Dictionary = {}

## Register a signal the bus will carry.
func register_signal(signal_name: String) -> void:
    if not _subscribers.has(signal_name):
        _subscribers[signal_name] = [] as Array[Subscriber]

## Check if a signal is registered.
func has_signal(signal_name: String) -> bool:
    return _subscribers.has(signal_name)

## Connect to a bus signal with optional priority.
func connect_to(signal_name: String, callable: Callable, priority: int = PRIORITY_NORMAL, source: String = "") -> void:
    if not _subscribers.has(signal_name):
        push_error("EventBus: signal '%s' not registered. Call register_signal() first." % signal_name)
        return
    # Guard against duplicate connections
    if _find_subscriber(signal_name, callable) != -1:
        push_warning("EventBus: callable already connected to '%s'. Skipping duplicate." % signal_name)
        return
    var sub := Subscriber.new()
    sub.callable = callable
    sub.priority = priority
    sub.source = source
    var arr: Array[Subscriber] = _subscribers[signal_name]
    arr.append(sub)
    arr.sort_custom(_sort_by_priority_desc)

## Disconnect a callable from a bus signal.
func disconnect_from(signal_name: String, callable: Callable) -> void:
    if not _subscribers.has(signal_name):
        return
    var arr: Array[Subscriber] = _subscribers[signal_name]
    var idx := _find_subscriber(signal_name, callable)
    if idx >= 0:
        arr.remove_at(idx)

## Check if a callable is connected to a signal.
func is_connected(signal_name: String, callable: Callable) -> bool:
    return _find_subscriber(signal_name, callable) >= 0

## Emit a signal, calling all subscribers in priority order.
## Uses variadic args (Godot 4.5+) for arbitrary argument counts.
func emit(signal_name: String, args: Variant...) -> void:
    if not _subscribers.has(signal_name):
        return
    var arr: Array[Subscriber] = _subscribers[signal_name]
    for sub in arr:
        # Skip freed subscribers (safety net; modules should disconnect in _exit_tree)
        if not sub.callable.is_valid():
            continue
        sub.callable.callv(args)

## Internal: find a subscriber index, or -1 if not found.
func _find_subscriber(signal_name: String, callable: Callable) -> int:
    var arr: Array[Subscriber] = _subscribers.get(signal_name, [])
    for i in arr.size():
        if arr[i].callable == callable:
            return i
    return -1

static func _sort_by_priority_desc(a: Subscriber, b: Subscriber) -> bool:
    return a.priority > b.priority
```

### Signal Naming Convention

All EventBus signals follow `.claude/docs/technical-preferences.md`:
- `snake_case` past tense for state changes: `health_changed`, `loop_start`
- `snake_case` noun_verb for events: `fish_gifted`, `npc_recruited`
- No Hungarian prefix, no system prefix — signals are named by what happened, not who fires them

The complete signal catalog (40+ signals) is defined in `docs/architecture/architecture.md` Phase 3 Data Flow and will be registered in `EventBus._ready()`.

### Implementation Guidelines

1. **Connection pattern** — each module connects in `_ready()` and disconnects in `_exit_tree()`:
   ```gdscript
   # In RelationshipManager.gd
   func _ready() -> void:
       EventBus.connect_to("loop_start", _on_loop_start_convert, EventBus.PRIORITY_PROCESS, "RelationshipManager")

   func _exit_tree() -> void:
       EventBus.disconnect_from("loop_start", _on_loop_start_convert)
   ```

2. **Emission pattern** — producer emits after committing its own state change:
   ```gdscript
   # In EconomyManager.gd
   func gift_fish(npc_id: String) -> void:
       if fish_count <= 0:
           return
       fish_count -= 1
       EventBus.emit("fish_gifted", npc_id, 1)
   ```

3. **Handler constraint** — handlers must not do heavy work. EventBus emits synchronously — all handlers complete before `emit()` returns. This is acceptable per architecture principle "Time Is a Resource, Not a Frame" but must be enforced in code review.

4. **Freed subscriber safety** — Godot's native signals auto-disconnect when the target object is freed. This custom bus does not. Every module that calls `connect_to()` MUST call `disconnect_from()` in `_exit_tree()`. As a safety net, `emit()` skips invalid callables, but this should not be relied upon — it produces garbage subscribers that accumulate over time.

5. **New priority bands** require an ADR amendment — do not add raw integer priorities. This prevents priority inflation.

## Alternatives Considered

### Alternative 1: Multi-Phase Signal Protocol

- **Description**: Split ordering-sensitive signals into phases. Instead of `loop_start` with priority bands, C2 fires `loop_process_phase` → `loop_reset_phase` → `loop_persist_phase` in sequence. Consumers connect to the appropriate phase signal.
- **Pros**: Zero bus complexity — uses standard Godot signals with no wrapper. Phase order visible in emission code. Easier to debug — each phase is a distinct signal.
- **Cons**: Signal count multiplies — each ordered signal becomes 2-3 signals. Phase discovery requires reading the emitter's code. Same-phase consumers that need internal ordering are back to the same problem. Adding a new phase requires modifying the emitter.
- **Estimated Effort**: Lower initial cost, higher maintenance cost as signal count grows.
- **Rejection Reason**: Currently only one signal (`loop_start`) needs ordering, making this the simpler choice. However, the priority system was chosen because: (a) ordering needs may grow as systems integrate (ADR-0006 combat, ADR-0010 boss encounters), (b) new ordered consumers can be added without modifying the emitter, and (c) same-priority FIFO provides intra-band ordering that phases cannot. If `loop_start` remains the only ordered signal after implementation, reconsider this alternative.

### Alternative 2: Explicit Sequencing in Emitter (Direct Calls)

- **Description**: Producer calls consumer methods directly in order, then fires a signal for non-order-sensitive consumers.
- **Pros**: Trivially ordered — the code IS the order. No bus abstraction. Fastest path.
- **Cons**: Violates Architecture Principle #1 (Signal-Driven, Not Call-Driven). Creates tight coupling — producer must know every consumer's method signature. Untestable — producer cannot be unit tested without mocking all consumers. Adding a consumer requires modifying the producer.
- **Estimated Effort**: Lowest initial cost, highest coupling cost.
- **Rejection Reason**: Directly violates the architecture's core principle. The signal-driven architecture was chosen specifically to avoid this kind of coupling.

### Alternative 3: Godot Native Signal Groups

- **Description**: Use built-in Godot signals with no wrapper. Document the required connection order in comments at the signal declaration site.
- **Pros**: Zero code. Editor-visible in Signals dock. Standard Godot pattern.
- **Cons**: Ordering is comment-based, not enforced. Reordering `_ready()` code silently breaks ordering. The Lead Programmer explicitly flagged this as insufficient (sign-off condition #1 in architecture.md).
- **Estimated Effort**: Zero implementation cost, highest risk cost.
- **Rejection Reason**: This is the status quo that the LP flagged as blocking. The ordering problem is real and needs an enforced solution.

## Consequences

### Positive

- **Explicit ordering**: Priority constants at the connection site make execution order visible and reviewable
- **Opt-in complexity**: 80%+ of signal connections use default PRIORITY_NORMAL. Only 5-10 connections declare a priority
- **Consumer-side declaration**: Each module declares its own ordering needs. Adding a new module doesn't require modifying existing modules
- **Debuggable**: EventBus can log `[signal_name] calling N subscribers: [ordered list]` with a debug flag
- **Testable**: Each handler is testable in isolation. Integration tests can verify ordering by emitting and checking call sequence

### Negative

- **Not editor-visible**: Godot's Signals dock won't show EventBus connections. Mitigation: debug logging; eventual debug panel showing all registered signals and subscribers
- **String-keyed signals**: Signal names are magic strings — `EventBus.emit("loop_strat")` is a silent no-op. Mitigation: `register_signal()` at startup catches typos via `push_error`; `has_signal()` available for defensive checks
- **Runtime arity errors**: `Callable.callv()` with wrong argument count errors at runtime, not compile time. Native signals with typed parameters would catch this. Mitigation: signal signatures documented in architecture.md; add typed wrapper methods if this becomes a frequent issue
- **Wrapper overhead**: ~0.01-0.05ms per emission (array iteration + callv). Negligible since emissions are event-driven (a few per player action, not per frame)
- **~120 lines of infrastructure**: `event_bus.gd` requires maintenance

### Neutral

- Modules connect to `EventBus` instead of using Godot's native signal connection syntax. The pattern is similar (`EventBus.connect_to("name", callable, priority)` vs `signal.connect(callable)`) but not identical.
- Signal discovery moves from the editor's Signals dock to `event_bus.gd`'s `_ready()` registration block and `architecture.md`'s signal catalog.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Priority inversion (wrong band chosen) | Medium | High — wrong execution order breaks game logic silently | Named bands with clear semantics. Validation criteria include ordering integration test. Code review checks priority assignments. |
| Freed subscriber crash | Medium | Medium — `callv()` on freed object | `_exit_tree()` disconnect mandate. `is_valid()` safety net in emit loop. |
| Duplicate connections | Low | Medium — handler fires twice, double-counting state changes | `is_connected()` guard in `connect_to()`. |
| Re-entrant emission (A emits X → B emits Y → A emits X…) | Low | High — infinite recursion, stack overflow | Not in v1. Add `max_emit_depth` guard (default 10) if this occurs. |
| Only one signal needs ordering — wrapper was premature | Medium | Low — unnecessary abstraction, harder onboarding | Accept risk. If `loop_start` remains the only ordered signal after MVP implementation, reconsider Alternative 1. Reversibility cost is low (~2-4 hours to revert). |
| Priority inflation — modules compete for higher numbers | Low | Medium — undermines the band system | New bands require ADR amendment. Raw integers discouraged by convention; constants are the documented API. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (per emission) | N/A (no bus) | ~0.02ms (10 consumers) | Event-driven, 0-5 emissions per player action |
| Memory | 0 KB | ~24 KB (40 signals × 3 avg consumers × ~200 bytes) | 500 MB ceiling |
| Load Time | 0 ms | Negligible (40 Dictionary inserts) | — |
| Network | N/A | N/A | N/A |

## Migration Plan

No existing code to migrate. This is the first architectural decision for the project.

**Implementation steps:**
1. Create `src/autoload/event_bus.gd` with the API defined above
2. Register EventBus as autoload index 0 in `project.godot` (must load before all state-owning modules)
3. Register all 40+ signals from `architecture.md` Phase 3 Data Flow in `EventBus._ready()`
4. Each module's `_ready()` connects to its consumed signals with appropriate priorities
5. Each module's `_exit_tree()` disconnects all its connections
6. Verify with boot smoke test: load game, emit `loop_start`, assert execution order

**Rollback plan**: Replace `EventBus.connect_to("name", callable, priority)` with native Godot `EventBus.named_signal.connect(callable)` across all modules. Estimated 2-4 hours for 100+ connections. If any logic depends on priority ordering, re-establish through multi-phase signals (Alternative 1) or internal method sequencing. Currently only `loop_start` has ordering dependencies, so the blast radius is small.

## Validation Criteria

- [ ] **Ordering test**: Emit `loop_start` with 6 consumers at three priority levels. Assert PRIORITY_PROCESS (100) consumers fire before PRIORITY_RESET (80), which fire before PRIORITY_PERSIST (60), which fire before PRIORITY_NORMAL (0)
- [ ] **Same-priority FIFO**: Two consumers at PRIORITY_NORMAL. Assert they fire in connection order
- [ ] **Unregistered signal**: `connect_to("nonexistent", callable)` produces `push_error`
- [ ] **Duplicate connection guard**: Connecting the same callable twice produces `push_warning` and only one subscription
- [ ] **Disconnect**: Connect, disconnect, emit — assert disconnected consumer is not called
- [ ] **Freed subscriber**: Connect a consumer on a Node, `queue_free()` the node without disconnecting, emit — assert `is_valid()` check skips the freed callable (no crash)
- [ ] **Integration test**: Simulate full loop transition: `loop_collapse_start` → `loop_collapse_whiteout` → `loop_start`. Assert `convert_warmth()` reads pre-reset affection values, `reset_affection()` zeroes them after, and `auto_save()` captures final post-transition state

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Loop start sequence: convert warmth → reset affection → auto-save, in order | Priority bands enforce PROCESS→RESET→PERSIST ordering |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Warmth conversion (affection≥10 → warmth+1) fires at loop end; affection reset fires at loop start | PRIORITY_PROCESS (100) for convert, PRIORITY_RESET (80) for reset — convert reads affection before reset zeroes it |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | battle_victory: add affection before distribute XP | PRIORITY_PROCESS for affection, PRIORITY_NORMAL for XP distribution |
| `design/gdd/economy-inventory-system.md` | C5 Economy | fish_gifted event notifies Relationship system of affection change | Producer emits post-deduction; consumer reacts via EventBus |
| `design/gdd/save-load-system.md` | F1 Save/Load | auto_save captures state AFTER all loop-start transitions | PRIORITY_PERSIST (60) runs after PROCESS (100) and RESET (80) |
| All 17 GDDs | All systems | Cross-system decoupling — no module directly calls another module's mutation methods | EventBus is the single communication backbone for all cross-module signals |

## Related

- `docs/architecture/architecture.md` — defines all 40+ signals this bus carries (Phase 3 Data Flow), module ownership map, and autoload boot sequence
- ADR-0007: Autoload Initialization Order — EventBus must be autoload index 0; this ADR is a prerequisite
- `.claude/docs/technical-preferences.md` — signal naming conventions (`snake_case` past tense/noun_verb)
