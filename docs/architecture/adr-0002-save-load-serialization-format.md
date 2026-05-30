# ADR-0002: Save/Load Serialization Format

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

The Save/Load System must persist 10+ subsystems' state across loop transitions and game sessions within a 5MB budget. This ADR establishes Godot's typed Resource format (`.tres`) as the save file format with a `GameState` root Resource containing per-system sub-resources, a `save_state()/load_state()` contract for each manager autoload, and updated FileAccess patterns for Godot 4.6 where `store_*` methods now return `bool`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | MEDIUM — `FileAccess.store_*` return types changed in Godot 4.4 (was `void`, now `bool`). `ResourceSaver`/`ResourceLoader` APIs are stable since 4.0 but verify Resource UID handling in 4.6. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` (§4.3→4.4), `docs/engine-reference/godot/deprecated-apis.md`, `docs/architecture/architecture.md`, `design/gdd/save-load-system.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_buffer()` returning `bool` (4.4+), `ResourceSaver.save()` flags parameter (4.0+), `duplicate_deep()` for nested Resource copying (4.5+) |
| **Verification Required** | Test `FileAccess.store_buffer()` return value in Godot 4.6 — confirm it returns `false` on disk-full or permission-denied. Verify `ResourceSaver.save()` with `ResourceSaver.FLAG_COMPRESS` produces files under 5MB for full-vision content volume. Test `ResourceLoader.load()` on corrupted `.tres` — confirm error handling catches parse failures. |

> **Note**: If the project upgrades Godot versions, re-verify FileAccess return type behavior and ResourceSaver flags. The FileAccess change (4.4) means pre-4.4 training data examples of `store_buffer()` without return-value checking are silently wrong.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Event Bus Architecture) — `loop_start` signal triggers auto-save; `load_completed` signal notifies modules to rebuild |
| **Enables** | ADR-0004 (Time/Loop — loop count persistence), ADR-0005 (Relationship — warmth/affection persistence), ADR-0006 (Combat — team cat persistence), ADR-0008 (Economy — fish persistence), ADR-0012 (UI/HUD — settings persistence), ADR-0013 (Traces — trace mark persistence), ADR-0017 (True Ending — clue/phase persistence), ADR-0018 (Tutorial — flag persistence), ADR-0015 (Accessibility — settings persistence) |
| **Blocks** | All Pre-MVP stories requiring persistence — no state can survive loop transitions until Save/Load is implemented |
| **Ordering Note** | Must be Accepted before ADR-0007 (Autoload Init Order) since SaveManager's position in the boot sequence depends on this format |

## Context

### Problem Statement

The game's 17-system architecture requires 10+ subsystems to persist state across loop transitions and game sessions. Each system owns its own state (architecture principle #2), so the save format must be a federation of per-system dictionaries — not a monolithic blob. The GDD specifies Godot `.tres` Resource format with a top-level dictionary keyed by system name; the architecture blueprint refines this to a `GameState` Resource. But neither fully specifies:

1. The per-manager serialization contract (what each manager must implement)
2. The Godot 4.6 FileAccess strategy (post-4.4 `store_*` return `bool`, not `void`)
3. The distinction between auto-save state scope (loop-persistent only) and manual save state scope (all mid-loop state)
4. The error handling and recovery strategy for corrupted saves

### Current State

No save infrastructure exists. This is the second architectural decision. The SaveManager autoload is specified in architecture.md as owning "Save file I/O, serialization/deserialization of all persistent state, auto-save trigger at loop transition, save slot management."

### Constraints

- Save file ≤5 MB at full Tier 2 content volume (10 NPCs, 6 team cats, 4 districts, all Traces marks)
- Auto-save ≤100ms (must not cause perceptible hitch during collapse sequence)
- Godot 4.6 built-in APIs only — no third-party serialization libraries
- Single save slot for MVP, expandable to 3 slots in Tier 1
- Must survive corrupted files gracefully (no crash, no unrecoverable state)

### Requirements

- All persistent state survives loop transition (auto-save → reawaken → load)
- Mid-loop manual save captures exact state including player position, NPC positions, dialogue state
- First-ever launch with no save file starts a fresh game with no error
- Save files are debuggable during development (human-readable format)
- Each manager adds/removes persistence data independently without changing the save format

## Decision

### Format: Godot `.tres` Resource with GameState Root

Save files use Godot's text-based Resource format (`.tres` extension) with a `GameState` Resource as the root serialization object. The `.tres` format is chosen over binary `.res` because:

- Text-based: openable in any text editor during development for debugging
- Native: uses Godot's built-in `ResourceSaver`/`ResourceLoader` — no manual serialization code
- Typed: Resource properties are type-checked by Godot on load
- Migration-friendly: adding a new system adds a new sub-resource property; old saves load with default values for missing properties

The GDD's dictionary-per-system structure is implemented as typed sub-resources in `GameState`.

### GameState Resource Structure

```gdscript
# game_state.gd
class_name GameState extends Resource

## Loop-persistent state (written on auto-save AND manual save)
@export var loop_count: int = 1
@export var save_version: int = 1  # For future migration
@export var timestamp: int = 0     # OS.get_unix_time() at save

## Per-system state (each system owns its sub-resource)
@export var relationship_state: RelationshipState
@export var combat_state: CombatState
@export var world_state: WorldState
@export var traces_state: TracesState
@export var progression_state: ProgressionState
@export var tutorial_state: TutorialState

## Mid-loop state (written on manual save ONLY, null on auto-save)
@export var economy_state: EconomyState       # Fish inventory (cleared on loop reset)
@export var schedule_state: ScheduleState     # NPC positions at save time
@export var player_position: String           # Current node ID (auto-save: "bonfire_ground")
@export var time_remaining: int = 100          # Current time units
```

### Per-System Sub-Resources

Each system that persists state defines its own Resource type:

```gdscript
# In RelationshipManager's domain
class_name RelationshipState extends Resource
@export var npcs: Array[NPCData] = []

class_name NPCData extends Resource
@export var npc_id: String = ""
@export var warmth: int = 0          # 0-3, persistent
@export var affection: int = 0        # 0-10, per-loop (manual save only)
@export var is_recruited: bool = false
@export var memory_fragments_seen: Array[int] = []
@export var gratitude_fish_given: bool = false

# In CombatManager's domain
class_name CombatState extends Resource
@export var team_cats: Array[TeamCatData] = []
@export var xp_total: int = 0

class_name TeamCatData extends Resource
@export var npc_id: String = ""
@export var archetype: int = 0       # 0=Hunter, 1=Guardian, 2=Trickster
@export var base_hp: int = 0
@export var base_atk: int = 0
@export var base_def: int = 0
@export var base_spd: float = 0.0
@export var stat_bonus: int = 0      # Per-loop growth points
@export var is_wounded: bool = false
```

### Per-Manager Save/Load Contract

Every autoload that owns persistent state implements two methods:

```gdscript
## Called by SaveManager during save collection.
## Returns a Resource with this system's persistent state.
## Return null if this system has no state to persist.
func collect_save_state() -> Resource:
    pass

## Called by SaveManager during load distribution.
## Receives the Resource this system wrote during collect_save_state().
## For auto-save loads, mid-loop fields will be at their defaults.
func restore_from_save(state: Resource) -> void:
    pass
```

The SaveManager orchestrates:

```
SAVE (auto-save at loop transition):
  1. Create new GameState Resource
  2. For each registered manager, call collect_save_state() → assign to GameState property
  3. For auto-save: set mid-loop fields (economy_state, player_position, etc.) to null
  4. ResourceSaver.save(game_state, "user://save_slot_%d.tres" % slot, ResourceSaver.FLAG_COMPRESS)
  5. Verify: store_buffer return value check
  6. EventBus.emit("save_completed", slot)

LOAD (main menu or game start):
  1. ResourceLoader.load("user://save_slot_%d.tres" % slot) → GameState
  2. If load fails: invoke error recovery (see below)
  3. For each registered manager, call restore_from_save(manager_state)
  4. EventBus.emit("load_completed", slot)
```

### FileAccess Strategy for Godot 4.6

Godot 4.4 changed `FileAccess.store_*` methods from `void` to `bool`. The SaveManager uses `ResourceSaver` as the primary API (which abstracts FileAccess), but manual verification uses FileAccess directly:

```gdscript
func verify_save_file(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var fa := FileAccess.open(path, FileAccess.READ)
    if fa == null:
        return false
    # Godot 4.6: get_open_error() available, use instead of null check pattern
    var error := FileAccess.get_open_error()
    if error != OK:
        push_error("SaveManager: failed to open save file for verification: %d" % error)
        return false
    var size := fa.get_length()
    fa.close()
    return size > 0
```

Key FileAccess notes for Godot 4.6:
- `FileAccess.open()` returns `null` on failure — check the return value AND `FileAccess.get_open_error()`
- `ResourceSaver.save()` internally handles the FileAccess `bool` return — we rely on it for writing
- Use `FileAccess.file_exists(path)` for existence checks (static method, no open needed)
- `DirAccess` for directory operations (create save directory on first launch, list save slots)

### Settings Persistence: ConfigFile

Settings (volume, accessibility, input remapping) use Godot's `ConfigFile` API (`.ini` format):

```gdscript
# Separate from game state — settings survive save deletion
var _config := ConfigFile.new()
var _config_path := "user://settings.cfg"

func save_settings() -> void:
    _config.set_value("audio", "master_volume", master_volume)
    _config.set_value("audio", "music_volume", music_volume)
    _config.set_value("accessibility", "text_scale", text_scale)
    _config.save(_config_path)

func load_settings() -> void:
    if _config.load(_config_path) == OK:
        master_volume = _config.get_value("audio", "master_volume", 1.0)
        text_scale = _config.get_value("accessibility", "text_scale", 1.0)
```

Settings are NOT stored in the GameState `.tres` file. This means deleting a save slot does not reset settings.

### JSON Debug Export

Development-only dumping of save state to JSON for inspection:

```gdscript
func debug_dump_save(slot: int) -> void:
    var game_state: GameState = ResourceLoader.load("user://save_slot_%d.tres" % slot)
    if game_state == null:
        print("No save file at slot %d" % slot)
        return
    # Manual JSON serialization of key fields for debugging
    var dump := {
        "loop_count": game_state.loop_count,
        "save_version": game_state.save_version,
        "timestamp": game_state.timestamp,
        "relationship_npcs": _serialize_relationships(game_state.relationship_state),
        "team_cats_count": game_state.combat_state.team_cats.size() if game_state.combat_state else 0,
    }
    var fa := FileAccess.open("user://debug_save_%d.json" % slot, FileAccess.WRITE)
    fa.store_string(JSON.stringify(dump, "\t"))
    fa.close()
```

Not called in production builds — triggered via dev console command `dump_save`.

### Error Handling

```
CORRUPTED SAVE (.tres parse failure or ResourceLoader returns null):
  1. Catch the error (ResourceLoader.load returns null, check for it)
  2. Log the error with full path for debugging
  3. Present UI: "Save data could not be read." with options:
     - [Retry] → re-attempt load
     - [New Game] → overwrite corrupted file with fresh GameState
     - [Return to Menu] → go to main menu, no file modification
  4. Do NOT crash. Do NOT enter unrecoverable state.

FIRST LAUNCH (no save file exists):
  1. FileAccess.file_exists(path) returns false
  2. This is normal — show the main menu with only "New Game" available
  3. No error dialog. No warning.

SAVE FAILURE (disk full, permission denied):
  1. ResourceSaver.save() returns a non-OK error code
  2. Retry once
  3. If retry fails: show error "Save failed — [reason]. Try again?"
     Options: [Retry] / [Continue without saving] / [Return to Menu]
```

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                  SaveManager (Autoload #1)           │
│                                                     │
│  save_game(slot)          load_game(slot)            │
│  auto_save()              delete_save(slot)          │
│  get_save_slots()         verify_save(slot)          │
│  debug_dump_save(slot)                               │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │  GameState Resource (.tres per slot)         │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐     │    │
│  │  │RelState  │ │CombatSt  │ │WorldSt   │ ... │    │
│  │  │.npcs[]   │ │.cats[]   │ │.nodes[]  │     │    │
│  │  └──────────┘ └──────────┘ └──────────┘     │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
│  collect_save_state() ← from each manager           │
│  restore_from_save()  → to each manager             │
│                                                     │
│  FileAccess (verify)  ResourceSaver (write)          │
│  ResourceLoader (read)  ConfigFile (settings)        │
└─────────────────────────────────────────────────────┘
     ↑ collect       ↓ restore         ↑↓ .tres file
  ┌──┴──────────┐    ┌──┴──────────┐   user://save_slot_01.tres
  │ C3.RelMgr   │    │ C3.RelMgr   │   user://save_slot_02.tres
  │ C4.Combat   │    │ C4.Combat   │   user://save_slot_03.tres
  │ F2.World    │    │ F2.World    │   user://settings.cfg
  │ P1.Traces   │    │ P1.Traces   │
  │ F6.Prog     │    │ F6.Prog     │
  │ PL1.Tut     │    │ PL1.Tut     │
  └─────────────┘    └─────────────┘
```

### Implementation Guidelines

1. **Save directory creation**: On first launch, create `user://` directory if it doesn't exist (Godot usually handles this, but verify).

2. **Save version migration**: The `save_version` field in GameState enables forward-compatibility. When a new system is added or a field changes type:
   ```gdscript
   func restore_from_save(state: GameState) -> void:
       if state.save_version < 2:
           # Migration: warmth used to be stored as float, now int
           _migrate_warmth_float_to_int(state)
       if state.save_version < 3:
           # Migration: added accessibility_state in v3
           state.accessibility_state = AccessibilityState.new()
       # Apply current state
       _apply_state(state)
   ```

3. **Auto-save signal flow**: `C2.loop_collapse_start` → VFX plays → `C2.loop_collapse_whiteout` → `SaveManager.auto_save()` → `EventBus.emit("save_completed")` → `C2.loop_start` → reawakening.

4. **Thread safety**: All save/load operations are synchronous on the main thread. The ≤100ms auto-save budget makes this acceptable. If saves ever exceed 100ms, consider `ResourceSaver.save_threaded()` but this adds complexity — avoid unless needed.

5. **No mid-loop autosave**: Autosave only fires at loop transition. There is no "autosave every N minutes" — the player must use manual save for mid-session breaks. This keeps the save model simple and the auto-save scope well-defined.

## Alternatives Considered

### Alternative 1: JSON-Only Serialization

- **Description**: All game state serialized to JSON using `JSON.stringify()` and written via `FileAccess.store_string()`. Settings also in JSON.
- **Pros**: Fully portable, human-readable in any text editor, no Godot Resource dependency, trivial to diff in version control, smallest file size.
- **Cons**: No typed deserialization — all values become `Variant`, requiring manual type casting. Nested Resource objects require manual recursive serialization. Adding a new field to a manager requires updating both the serialize and deserialize paths. No Godot editor integration.
- **Estimated Effort**: Higher — manual serialization for 10+ systems with 30+ data types.
- **Rejection Reason**: For a solo developer, the manual serialization maintenance burden (two code paths per data type: serialize + deserialize) outweighs the portability benefit. Godot's Resource system handles this automatically.

### Alternative 2: Binary Resource (.res) with .sav Extension

- **Description**: Use Godot's binary Resource format with a custom `.sav` extension. Same GameState structure, but binary encoding.
- **Pros**: Smaller files (~50% smaller than .tres), faster load/save, architecture.md-native approach.
- **Cons**: Not human-readable — debugging a save file requires a hex editor or writing a dump tool. Harder to diagnose save corruption. Extension is non-standard (`.sav` vs `.res`).
- **Estimated Effort**: Same as chosen approach (only the file extension and Saver flag differ).
- **Rejection Reason**: The debuggability loss during development is significant for a solo developer. The 5MB budget is easily met with text-based `.tres` files (the "full vision" content estimate is ~500KB-1MB of text). The `.tres` format can be swapped to `.res` at release with a one-line change if file size becomes an issue.

### Alternative 3: Per-System Separate Files

- **Description**: Each system writes its own `.tres` file (e.g., `user://save_01_relationship.tres`, `user://save_01_combat.tres`). SaveManager coordinates but doesn't package into a single file.
- **Pros**: Atomic per-system saves — corruption in one file doesn't affect others. Systems can be loaded lazily.
- **Cons**: Multiple FileAccess opens on load (5-10 files). Save slot management requires listing a directory and grouping by prefix. No transactional guarantee — some files could save and others fail, producing an inconsistent overall state.
- **Estimated Effort**: Similar to chosen approach.
- **Rejection Reason**: Single-file packaging provides transactional safety (the file either saves completely or not at all). The 5MB budget makes single-file I/O fast enough (≤100ms). Per-system corruption isolation isn't needed — if the save file is corrupted at the file level (disk error), it's corrupted regardless of how many files were written.

## Consequences

### Positive

- **Zero manual serialization**: Godot's `ResourceSaver`/`ResourceLoader` handle nested Resource trees automatically. Adding a new field to `NPCData` requires zero save/load code changes — just add the `@export var`.
- **Debuggable**: `.tres` files are plain text. Open in any editor during development to inspect warmth tiers, team stats, loop count. JSON debug export for programmatic inspection.
- **Type-safe**: Deserialized values are the declared types — no `Variant` casting or type-guard code.
- **Extensible**: New systems add sub-resources to `GameState`. Old saves load with defaults for new properties. `save_version` field enables explicit migration logic.
- **Editor-compatible**: Resource types appear in Godot's inspector and can be created/tested in-editor before integrating with save/load.

### Negative

- **Resource boilerplate**: Each system must define a `class_name` Resource for its persistent state. ~10 extra `.gd` files with `@export var` declarations. For a solo developer, this is acceptable overhead.
- **Godot-specific**: Save files are not portable to other engines or tools without the JSON debug export.
- **ResourceLoader.load() is synchronous**: Blocks the main thread during load. For 5MB files this is <100ms; for larger files consider `ResourceLoader.load_threaded_request()`.

### Neutral

- Settings use `ConfigFile` (`.ini`) while game state uses `.tres` — two formats to understand. The separation is intentional: settings survive save deletion.
- Auto-save and manual save write the same format but with different state scopes (auto-save excludes mid-loop fields). This is enforced by SaveManager, not by the format itself.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `.tres` file exceeds 5MB at full content volume | Low | Medium — violates AC-10, may slow load | Monitor file size during Tier 1/Tier 2 content pushes. Switch to `.res` (binary) at release if needed — one-line flag change. |
| ResourceLoader.load() returns null on corrupted file | Medium | High — game cannot continue | Explicit null check after load. Error recovery UI with Retry/New Game/Return to Menu. Do not crash. |
| Resource type mismatch on load (class renamed or removed) | Low | High — load fails with obscure Godot error | Use `save_version` for migration. Never rename Resource classes without incrementing version. Keep old class stubs as migration shims. |
| Auto-save exceeds 100ms during collapse sequence | Low | Medium — perceptible hitch | Profile save time during Tier 2 content testing. If >100ms, use `ResourceSaver.save_threaded()` with a loading screen during whiteout. |
| Concurrent file access (crash during save) | Low | Medium — partially written file | `ResourceSaver.save()` writes atomically to a temp file then renames. Godot handles this internally. Verify behavior on Windows in 4.6. |
| FileAccess return type pattern inconsistency | Medium | Low — wrong error handling | All FileAccess calls check `get_open_error()` and return value. Enforced via code review checklist item. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (auto-save) | N/A | ≤100ms for ResourceSaver.save() | No perceptible hitch during collapse |
| CPU (load) | N/A | ≤200ms for ResourceLoader.load() + restore | Acceptable for menu→game transition |
| Memory | 0 MB | ~1-3 MB during save/load (Resource in memory) | 500 MB ceiling |
| Disk | 0 MB | ≤5 MB per slot × 3 slots = 15 MB | Acceptable for PC target |
| Load Time | N/A | ≤200ms (single synchronous load) | — |

## Migration Plan

No existing save files to migrate — this is a greenfield decision.

**Implementation steps:**
1. Create `GameState` Resource class with properties for all persistent systems
2. Create per-system Resource classes (`RelationshipState`, `CombatState`, `WorldState`, `TracesState`, `ProgressionState`, `TutorialState`, `EconomyState`, `ScheduleState`)
3. Implement `SaveManager` autoload with the orchestration API
4. Implement `collect_save_state()` and `restore_from_save()` on each state-owning manager
5. Implement `ConfigFile`-based settings persistence
6. Wire auto-save to `loop_collapse_whiteout` signal and manual save to pause menu
7. Implement error handling (corrupted file, first launch, save failure)
8. Add JSON debug export via dev console command
9. Register SaveManager as autoload index 1 (after EventBus at index 0)

**Rollback plan**: Save format changes require migrating existing save files. Always increment `save_version` when changing the format. Write a migration function for the old→new version transition. Keep old Resource class definitions as migration shims (never delete them — mark them `@deprecated`). If the format must be completely replaced, write a standalone migration tool that loads old `.tres` files and writes new-format files.

**Version migration protocol**:
```
save_version: 1 → initial format (2026-05-30)
save_version: 2 → (future) add migration in GameState._validate_property()
```

## Validation Criteria

- [ ] **Save/load round-trip**: Save game state with all 10 systems populated. Load it. Assert every field matches (loop_count, warmth tiers, team cats, discovered nodes, traces marks, tutorial flags).
- [ ] **Auto-save excludes mid-loop state**: Trigger auto-save during loop transition. Load the save. Assert economy_state is null, player_position is "bonfire_ground", fish count is 0 (reset).
- [ ] **Manual save includes mid-loop state**: Manual save mid-loop with 3 fish and player at node "market_square". Load the save. Assert fish count = 3, player_position = "market_square".
- [ ] **Auto-save completes within 100ms**: Measure `ResourceSaver.save()` duration for a GameState with full Tier 2 content (10 NPCs, 6 cats, 4 districts, all traces). Assert ≤100ms.
- [ ] **Corrupted file recovery**: Create a text file with invalid content at the save path. Call `load_game(1)`. Assert null is returned, error recovery UI triggers, game does not crash.
- [ ] **First launch**: Delete all save files. Launch game. Assert no error shown, "New Game" is available, save slots list is empty.
- [ ] **Save file under 5MB**: Save a game with full Tier 2 content volume. Assert file size ≤5,242,880 bytes.
- [ ] **Settings survive save deletion**: Save settings (volume=0.5). Delete all `.tres` save files. Reload settings. Assert volume is still 0.5.
- [ ] **Save version migration**: Create a v1 save file. Increment `save_version` to 2 and add a new required field. Load the v1 save. Assert migration runs, new field has default value, game loads successfully.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-load-system.md` | F1 Save/Load | Auto-save fires at loop transition, completes before reawakening (AC-01) | Auto-save wired to `loop_collapse_whiteout` signal; ≤100ms budget |
| `design/gdd/save-load-system.md` | F1 Save/Load | Warmth tiers persist with no decay across loops (AC-02) | `NPCData.warmth` stored in `RelationshipState` sub-resource; restored on load |
| `design/gdd/save-load-system.md` | F1 Save/Load | Team cats persist with correct stats across loops (AC-03) | `TeamCatData` stored in `CombatState` sub-resource with all stats |
| `design/gdd/save-load-system.md` | F1 Save/Load | Fish inventory empty at loop start (AC-04) | Auto-save excludes `EconomyState` → loads as default (0 fish) |
| `design/gdd/save-load-system.md` | F1 Save/Load | Discovered nodes visible across loops (AC-05) | `WorldState.discovered_nodes` persisted in auto-save |
| `design/gdd/save-load-system.md` | F1 Save/Load | Traces marks accumulate across loops (AC-06) | `TracesState` persisted, never cleared on loop reset |
| `design/gdd/save-load-system.md` | F1 Save/Load | Manual save captures mid-loop state (AC-07) | Manual save includes `EconomyState`, `ScheduleState`, `player_position`, `time_remaining` |
| `design/gdd/save-load-system.md` | F1 Save/Load | Corrupted file shows error, no crash (AC-08) | Null check on load + error recovery UI |
| `design/gdd/save-load-system.md` | F1 Save/Load | First launch starts fresh loop 1 (AC-09) | `FileAccess.file_exists()` guard; no file = fresh state |
| `design/gdd/save-load-system.md` | F1 Save/Load | Save file under 5MB (AC-10) | `.tres` text format with compression flag; monitor and switch to `.res` if needed |
| `design/gdd/npc-relationship-system.md` | C3 Relationship | Warmth persistent, affection per-loop | `NPCData.warmth` always saved; `NPCData.affection` saved in manual, reset in auto |
| `design/gdd/time-loop-system.md` | C2 Time/Loop | Loop count persists across sessions | `GameState.loop_count` persisted |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Team cat roster persists across loops | `CombatState.team_cats` persisted in auto-save |

## Related

- `docs/architecture/architecture.md` — SaveManager module ownership (Foundation layer), save/load data flow, boot sequence
- ADR-0001: Event Bus Architecture — `save_completed` and `load_completed` signals use EventBus
- `docs/engine-reference/godot/breaking-changes.md` — FileAccess return type changes in 4.4
- `docs/engine-reference/godot/deprecated-apis.md` — `duplicate()` → `duplicate_deep()` for nested Resources (4.5+)
