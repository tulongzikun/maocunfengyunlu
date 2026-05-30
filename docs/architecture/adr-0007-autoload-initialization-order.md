# ADR-0007: Autoload Initialization Order

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

The project uses 13+ Godot autoload singletons for all game state management. The boot sequence must load them in dependency order (leaf-first: EventBus → data owners → query systems → UI), distinguish new game from loaded game initialization, and resolve the LP's concern about autoloads vs. dependency injection: autoloads expose state read-only through getters and mutations through EventBus signals, satisfying the testability intent of DI without the indirection cost for a solo developer.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — autoload registration (`project.godot` `[autoload]` section) and `_ready()` initialization order are stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/architecture/architecture.md`, `.claude/docs/coding-standards.md` |
| **Post-Cutoff APIs Used** | None — standard autoload configuration and `_ready()` lifecycle |
| **Verification Required** | Verify autoload `_ready()` order matches `project.godot` registration order in Godot 4.6 — confirm no engine-level reordering was introduced |

> **Note**: Godot calls autoload `_ready()` in the order they appear in `project.godot`. This ADR's boot sequence depends on that guarantee. If Godot ever changes this (unlikely), the boot sequence would need explicit dependency checks.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (EventBus — must load first), ADR-0002 (Save/Load — SaveManager position), ADR-0003 (Node Graph — SceneManager position), ADR-0004 (Time/Loop — TimeManager position), ADR-0005 (Relationship — RelationshipManager position), ADR-0006 (Combat — CombatManager position) |
| **Enables** | All MVP stories — no module can start until its dependencies are loaded |
| **Blocks** | Project configuration — `project.godot` cannot be finalized until the autoload order is Accepted |
| **Ordering Note** | This is the last Must-Have ADR before implementation can begin. Accept it, configure `project.godot`, and the greybox build is unblocked. |

## Context

### Problem Statement

The architecture defines 13+ autoload singletons that must load in a specific dependency order. EventBus must exist before any module connects to it. SceneManager must load the node graph before MovementManager queries adjacency. SaveManager must scan for save files before TimeManager decides whether to start a new game or load. If any autoload's `_ready()` accesses another autoload that hasn't loaded yet, the result is a null reference and a silent or crashing boot failure.

Additionally, the LP flagged a concern (sign-off condition #2): "Autoloads vs DI — Clarify that autoloads expose their state via signals (not direct mutation calls), satisfying the spirit of DI. Update coding standards to explicitly allow autoload singletons for game state managers."

### Current State

No autoloads are registered. The architecture blueprint (architecture.md §4) lists a proposed boot sequence but it has not been formalized as an ADR.

### Constraints

- Godot 4.6 calls autoload `_ready()` in `project.godot` registration order
- Autoloads registered in the editor's Project Settings → Autoload tab (or `project.godot` directly)
- No lazy loading — all autoloads load at boot (the total is 13+ singletons, <2MB)
- Solo developer — simplicity justified; enterprise DI patterns are overhead

### Requirements

- EventBus is the first autoload (index 0) — all modules depend on it for signal connections
- Data-owning modules load before query modules (Foundation before Core, Core before Feature)
- New game and loaded game are handled as distinct initialization paths
- No module accesses another module's `_ready()` before that module is initialized
- The autoload pattern is explicitly permitted for this project's architecture

## Decision

### Autoload Registration Order

```
Index  Module                  Layer       Rationale
─────  ──────────────────────  ──────────  ──────────────────────────────────
  0    EventBus                Foundation  Must exist before any signal connection
  1    SaveManager             Foundation  Must scan for saves before modules ask
  2    SceneManager            Foundation  Must load node graph before queries
  3    TimeManager             Core        Must init time before action systems
  4    MovementManager         Core        No dependencies beyond SceneManager
  5    RelationshipManager     Core        Depends on EventBus, SaveManager
  6    CombatManager           Core        Depends on Relationship, Time
  7    EconomyManager          Core        Depends on Time, EventBus
  8    ScheduleManager         Feature     Depends on Time, SceneManager
  9    UIManager               Presentation Depends on all Core systems for HUD state
 10    AudioManager            Presentation Depends on EventBus for audio events
 11    TutorialManager         Polish      Depends on multiple Core + UI
 12    AccessibilityManager    Polish      Depends on UI for text scaling
 13    ProgressionManager      Feature     Depends on Relationship, Combat, Time
```

### Dependency Graph

```
EventBus (0)
    ↓
SaveManager (1) ←── depends on EventBus for save_completed/load_completed signals
    ↓
SceneManager (2) ←── depends on EventBus for node_entered/district_changed signals
    ↓
TimeManager (3) ←── depends on EventBus, SaveManager (load check)
    ↓
MovementManager (4) ←── depends on SceneManager (node graph queries)
    ↓
RelationshipManager (5) ←── depends on EventBus, SaveManager, TimeManager
    ↓
CombatManager (6) ←── depends on EventBus, Relationship, TimeManager
    ↓
EconomyManager (7) ←── depends on EventBus, TimeManager
    ↓
ScheduleManager (8) ←── depends on TimeManager, SceneManager
    ↓
UIManager (9) ←── depends on all Core (reads state for HUD)
    ↓
AudioManager (10) ←── depends on EventBus (reacts to all game events)
    ↓
TutorialManager (11) ←── depends on EventBus, Movement, Combat, Economy, UI
    ↓
AccessibilityManager (12) ←── depends on UIManager (applies text/contrast settings)
    ↓
ProgressionManager (13) ←── depends on Relationship, Combat, TimeManager
```

### Boot Sequence

```
Phase 1 — GODOT AUTOLOAD (engine-driven):
  Godot engine registers all autoloads in project.godot order
  Each autoload's Node._ready() is called in registration order

Phase 2 — INFRASTRUCTURE INIT (indices 0-2):
  EventBus._ready():
    - Register all 40+ signals via register_signal()
    - Log: "EventBus: [N] signals registered"
  SaveManager._ready():
    - Scan user:// for .tres save files via DirAccess
    - Populate save slot list
    - Load settings from user://settings.cfg (ConfigFile)
    - Connect to loop_collapse_whiteout for auto-save trigger
  SceneManager._ready():
    - Load node_graph.tres via ResourceLoader
    - Build _adjacency and _node_index dictionaries
    - Instantiate all node visuals (set visible=false)
    - Activate Central district (default start)

Phase 3 — CORE INIT (indices 3-7):
  TimeManager._ready():
    - Query SaveManager: has_existing_save()
    - Connect to time_cost_requested signal
  MovementManager._ready():
    - No state to load; queries SceneManager for node graph
  RelationshipManager._ready():
    - Load NPC data files from res://data/npcs/
    - Connect to fish_gifted, battle_victory, good_dialogue_choice signals
    - Connect to loop_start at PRIORITY_PROCESS and PRIORITY_RESET
  CombatManager._ready():
    - Load archetype definitions from res://data/archetypes/
    - Load enemy type definitions
    - Connect to battle-trigger events
  EconomyManager._ready():
    - Connect to fish-spawn events
    - Connect to loop_start for fish clear

Phase 4 — FEATURE + PRESENTATION INIT (indices 8-12):
  ScheduleManager, UIManager, AudioManager, TutorialManager, AccessibilityManager:
    - Connect to their respective EventBus signals
    - Build their runtime state (UI shell, audio buses, etc.)

Phase 5 — GAME STATE RESOLUTION (indices 13):
  ProgressionManager._ready():
    - Connect to clue_discovered, phase_unlock signals

Phase 6 — GAME START:
  IF SaveManager.has_existing_save():
    - SaveManager.load_game(most_recent_slot)
    - Each manager restores state via restore_from_save()
    - TimeManager checks save's loop_count and time_remaining
    - SceneManager moves camera to saved player position
    - UIManager rebuilds HUD from loaded state
    - EventBus.emit("load_completed")
  ELSE (new game):
    - TimeManager: loop_count=1, time_remaining=100
    - SceneManager: activate Central district, camera to Bonfire Ground
    - TutorialManager: all flags=false
    - All managers at initial defaults
    - EventBus.emit("loop_start", 1)  # First reawakening
```

### New Game vs Loaded Game

The branching point is in Phase 6, after all autoloads are initialized. By this point:
- All signal connections are established
- All Resource files are loaded (node graph, NPC data, archetypes, enemy types)
- Save files are scanned

The only difference is state population:
- **New game**: managers use their default values (loop=1, warmth=0, affection=0, fish=0)
- **Loaded game**: SaveManager distributes saved state to each manager via `restore_from_save()`

No autoload's `_ready()` needs to know whether this is a new game or a loaded game. The branching happens after `_ready()` completes.

### Autoload Architecture: Resolving the DI Concern

The LP's concern was: "Autoloads vs DI — Clarify that autoloads expose their state via signals (not direct mutation calls), satisfying the spirit of DI."

This ADR codifies the following rule:

**Autoload Communication Rules:**
1. **State is exposed read-only**: Other modules read state through getter methods (`get_warmth()`, `get_time_remaining()`, `get_adjacent_nodes()`). These are pure queries with no side effects.
2. **Mutations go through EventBus**: No module calls another module's mutation method directly. To change relationship state, emit `EventBus.emit("fish_gifted", npc_id, amount)`. The owning module listens and updates its own state.
3. **Autoloads own their state exclusively**: Only RelationshipManager writes to `NPCData.warmth`. Only TimeManager writes to `time_remaining`. No cross-module state writes.
4. **Testing is still possible**: Each autoload can be tested in isolation by:
   - Injecting fake data via `restore_from_save(state)` (bypassing the EventBus load path)
   - Calling handler methods directly (e.g., `_on_loop_start_convert(3)`)
   - Asserting getter outputs
   - Asserting EventBus emissions (spy on EventBus.emit)

This satisfies the intent of DI (testable modules, no tight coupling) while embracing Godot's autoload pattern (simpler for a solo developer than a full DI framework).

### Coding Standards Amendment

Add to `.claude/docs/coding-standards.md`:

```markdown
## Autoload Communication

- Autoloads are the standard pattern for game state managers in this project
- **READ**: Use getter methods on autoloads (`TimeManager.get_loop_count()`)
- **WRITE**: Emit an EventBus signal; the owning autoload handles the mutation
- Never call another autoload's mutation method directly
- Every autoload must implement `collect_save_state() -> Resource` and `restore_from_save(Resource) -> void`
```

### project.godot Configuration

```ini
[autoload]

EventBus="*res://src/autoload/event_bus.gd"
SaveManager="*res://src/autoload/save_manager.gd"
SceneManager="*res://src/autoload/scene_manager.gd"
TimeManager="*res://src/autoload/time_manager.gd"
MovementManager="*res://src/autoload/movement_manager.gd"
RelationshipManager="*res://src/autoload/relationship_manager.gd"
CombatManager="*res://src/autoload/combat_manager.gd"
EconomyManager="*res://src/autoload/economy_manager.gd"
ScheduleManager="*res://src/autoload/schedule_manager.gd"
UIManager="*res://src/autoload/ui_manager.gd"
AudioManager="*res://src/autoload/audio_manager.gd"
TutorialManager="*res://src/autoload/tutorial_manager.gd"
AccessibilityManager="*res://src/autoload/accessibility_manager.gd"
ProgressionManager="*res://src/autoload/progression_manager.gd"
```

The `*` prefix enables the autoload as a singleton (Godot's convention).

## Alternatives Considered

### Alternative 1: Pure Dependency Injection (No Autoloads)

- **Description**: No autoloads. Each module is a regular class instantiated by a `GameBootstrap` scene. Dependencies are passed via constructor or setter injection. Modules don't reference each other globally.
- **Pros**: Maximum testability. No global state. Modules are completely decoupled. Industry-standard OOP.
- **Cons**: Significant boilerplate — every module that needs `get_warmth()` must receive a `RelationshipManager` reference. Passing 5+ dependencies to every module. Bootstrap scene becomes a complex dependency graph resolver. For a solo developer, this is pure overhead with no benefit — the coupling is "solved" by the autoload rules (read-only getters + EventBus mutations) without the DI framework cost.
- **Rejection Reason**: Godot's autoload system is designed for this exact use case. The communication rules (read via getters, write via signals) provide the same decoupling as DI without the boilerplate. For a solo developer on a 12-week timeline, DI framework overhead is unjustified.

### Alternative 2: Lazy-Loaded Autoloads

- **Description**: Core autoloads load at boot. Feature and Presentation autoloads load on first access (lazy init pattern).
- **Pros**: Faster boot time. Modules that aren't needed immediately (Boss, True Ending) don't consume memory at startup.
- **Cons**: First access causes a hitch (loading resources mid-gameplay). Signal connections may be missed if the module hasn't loaded yet when a signal fires. Godot doesn't natively support lazy autoloads — requires manual implementation.
- **Rejection Reason**: The total autoload set is 13+ singletons consuming <2MB. The complexity of lazy loading (missed signals, mid-game hitches) outweighs the 50ms boot time savings. All autoloads load eagerly at boot.

### Alternative 3: Scene-Based Initialization (No Autoloads)

- **Description**: Game state lives in a persistent "Game" scene that is never unloaded. Other scenes (district, battle, dialogue) are loaded additively. State passes via scene references.
- **Pros**: Godot-native scene tree approach. Visual debugging via Remote scene tree.
- **Cons**: Scene references are fragile (reparenting breaks paths). Harder to test in isolation (tests need a partial scene tree). Multiple scenes sharing state through a root scene is functionally identical to autoloads but with more boilerplate.
- **Rejection Reason**: Autoloads are Godot's intended pattern for persistent game state. Scene-based state management adds complexity (additive loading, cross-scene references, re-parenting) with no benefit over the well-understood autoload pattern.

## Consequences

### Positive

- **Explicit dependency order**: The autoload registration order IS the dependency graph. A programmer can read `project.godot` from top to bottom and understand which modules depend on which.
- **LP concern resolved**: The communication rules (read via getters, write via signals) satisfy the testability intent of DI. Autoloads are explicitly permitted and their constraints are codified.
- **Single initialization path**: The new-game/load-game branch happens at exactly one point (Phase 6), after all autoloads are initialized. No module's `_ready()` needs conditional logic for save state.
- **Eager loading = no mid-game hitches**: All 13+ autoloads and their resources (<2MB, <100ms) load at boot. No lazy-load hitches during gameplay.

### Negative

- **13+ singletons**: For a programmer unfamiliar with the project, seeing 13+ autoloads in `project.godot` may look excessive. Mitigation: each autoload's `.gd` file has a header comment explaining its purpose. The architecture.md module ownership map provides the full context.
- **Boot time**: Loading the node graph, NPC data, archetypes, enemy types, and audio resource index takes <100ms at boot. Acceptable for a PC target.
- **All modules in memory always**: Total autoload memory footprint is <2MB (mostly data, not code). Not a concern for a 500MB budget.

### Neutral

- The `*res://` prefix in `project.godot` means Godot enables these as singletons. The `*` is Godot's convention — not a glob. Every autoload is explicitly listed.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Autoload added mid-order breaks dependency | Medium | High — null reference on boot | New autoloads append to the END of the list. Never insert between existing entries. If a new autoload must load earlier, add it at the end and document that it initializes lazily. |
| Godot engine reorders autoload _ready() | Very Low | High — entire boot breaks | Godot guarantees registration-order `_ready()`. This has been stable since 4.0. Monitor release notes when upgrading. |
| Circular dependency (A needs B which needs A) | Low | High — boot hangs | This ADR's dependency graph is a DAG by construction. New ADRs must verify they don't create a cycle. `/architecture-review` Phase 4 checks for cycles. |
| Missing autoload in project.godot | Low | High — module not found at runtime | Validate at boot: each autoload checks that its required peers exist in the tree. Log errors for missing dependencies. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Boot time (cold start) | N/A | <200ms (Resource loads + autoload _ready chains) | Acceptable for PC |
| Boot time (warm start / loaded save) | N/A | <300ms (adds GameState.tres load + restore distribution) | Acceptable |
| Memory (all autoloads) | 0 MB | <2MB (13+ singletons + loaded data) | 500 MB ceiling |

## Migration Plan

No existing autoload configuration to migrate — greenfield.

**Implementation steps:**
1. Create `src/autoload/` directory
2. Implement each autoload `.gd` file (skeleton with stub methods)
3. Register autoloads in `project.godot` in the specified order
4. Implement `_ready()` for each per the boot sequence
5. Implement Phase 6 branching (new game vs loaded game)
6. Add autoload communication rules to `.claude/docs/coding-standards.md`
7. Boot smoke test: launch game, verify all autoloads initialize without errors
8. Load smoke test: save game, relaunch, load, verify state restored

**Rollback plan**: Autoload registration order is a `project.godot` edit. Reordering autoloads requires understanding the dependency graph — reorder cautiously. If an autoload needs to be removed, delete its `[autoload]` entry and its `.gd` file. Module removal does not affect other autoloads' initialization (they may log warnings about missing dependencies, but Godot doesn't crash on missing autoload references — it returns `null` for `get_node("/root/MissingAutoload")`).

## Validation Criteria

- [ ] **Boot order**: Instrument each autoload's `_ready()` with a log statement. Boot the game. Assert log order matches the specified order (EventBus first, ProgressionManager last).
- [ ] **EventBus available**: In SceneManager._ready(), assert `EventBus != null` and `EventBus.has_signal("loop_start")`.
- [ ] **Node graph loaded**: In MovementManager._ready(), assert `SceneManager.get_node("central_bonfire_ground") != null`.
- [ ] **New game path**: Delete all save files. Launch game. Assert `loop_count = 1`, `time_remaining = 100`, `loop_start` signal fires.
- [ ] **Loaded game path**: Save game at loop 3 with 42 time remaining. Relaunch. Load save. Assert `loop_count = 3`, `time_remaining = 42`.
- [ ] **No cross-mutation**: Assert that no module calls another module's mutation method directly (enforced by code review, not automated).
- [ ] **All autoloads reachable**: From a test script, assert `get_node("/root/EventBus")` through `get_node("/root/ProgressionManager")` all return non-null.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| All 17 GDDs | All systems | Each system must initialize before systems that depend on it | Registration-order boot sequence with explicit dependency graph |
| Architecture Sign-Off | LP Condition #2 | Clarify autoloads vs DI — state exposed via signals, not direct mutation | Autoload Communication Rules codified; coding standards amended |
| Architecture Sign-Off | LP Condition #3 | Scene loading strategy | SceneManager loads node graph (ADR-0003) during Phase 2; no PackedScene district loading |
| `docs/architecture/architecture.md` | Boot Sequence | 12-step boot from EventBus to READY | Phases 1-6 formalized with new-game/load-game branching |

## Related

- `docs/architecture/architecture.md` — boot sequence (step 1-12), module ownership map
- ADR-0001: Event Bus Architecture — EventBus must load first; autoload communication rules
- ADR-0002: Save/Load Serialization Format — SaveManager position, save/load distribution
- ADR-0003: Node Graph Data Model — SceneManager position, node graph loading
- `.claude/docs/coding-standards.md` — Autoload Communication section to be added
