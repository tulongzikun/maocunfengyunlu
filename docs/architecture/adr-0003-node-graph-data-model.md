# ADR-0003: Node Graph Data Model

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

The village map is a hand-crafted node graph of 44-66 nodes across 3 districts with 2 vertical layers, 10 interaction zone tags, and 4 edge traversal types. This ADR defines a single `NodeGraphData` Resource (.tres) containing all nodes and edges, a runtime activation/deactivation model per district (no PackedScene loading or unloading — the entire graph is in memory, only the current district's nodes are rendered and interactive), and a StringName-based tag system queried by 6 downstream systems.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Resource`, `Node2D`, `Camera2D`, `Tween` APIs stable since 4.0. No post-cutoff changes affecting 2D scene graph, node positioning, or Resource serialization. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/architecture/architecture.md`, `design/gdd/scene-world-manager.md` |
| **Post-Cutoff APIs Used** | `duplicate_deep()` for node template cloning (Godot 4.5+) |
| **Verification Required** | Test `Node2D.add_child()` performance when activating 20-30 nodes with Sprite2D children — verify under 2ms to stay within frame budget during district transitions |

> **Note**: The 2D Compatibility renderer and GodotPhysics2D (both defaults) are unaffected by the 4.6 D3D12 default (which affects 3D Vulkan→D3D12 transition only). No engine risk for 2D node rendering.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Event Bus Architecture) — `node_entered`, `district_changed` signals via EventBus; ADR-0002 (Save/Load Serialization Format) — discovered nodes persist via `WorldState` sub-resource |
| **Enables** | ADR-0004 (Time/Loop — safe-zone and loop-gated query), ADR-0005 (Relationship — warmth-gated query), ADR-0006 (Combat — battle-trigger query), ADR-0008 (Economy — fish-spawn query), ADR-0011 (Day/Night Cycle — night-only/day-only query), ADR-0019 (Movement — graph traversal) |
| **Blocks** | All Pre-MVP stories — no village exists until the node graph is loaded |
| **Ordering Note** | Must be Accepted before ADR-0007 (Autoload Init Order) since SceneManager loads in step 3 of the boot sequence |

## Context

### Problem Statement

The village is a graph of 44-66 nodes connected by typed edges across 3 districts. Six downstream systems (Movement, Scheduling, Combat, Economy, Time/Loop, Relationship) query the graph at runtime — they need node positions, edge connectivity, interaction zone tags, and vertical layer information. The LP flagged a gap: "Add district scene lifecycle — how nodes are instantiated, pooled, and freed. Should specify PackedScene loading pattern for district transitions."

This ADR must define: the data format for nodes and edges, the tag system's implementation, the district transition lifecycle, and how the node graph integrates with the rendering budget (≤200 draw calls).

### Current State

No node graph exists. The SceneManager autoload is specified in architecture.md as owning "Node graph data (all nodes, edges, tags, positions, vertical layers), district definitions, camera state, discovered node list, district transition state."

### Constraints

- 44-66 nodes, 3 districts, 2 vertical layers per district
- ≤200 draw calls per frame (2D Compatibility renderer)
- 6 downstream systems query node properties at runtime
- Hand-crafted graph (designed in-editor, not procedurally generated)
- Must support node discovery persistence across loops (hidden nodes stay revealed)
- Fissure nodes can be added per loop (escalation mechanic)
- Godot 4.6 2D scene tree — no 3D, no tilemap-based layout

### Requirements

- Node graph data is editable without code changes (designer-friendly)
- All nodes and edges are in a single loadable unit (fast startup, no mid-game file I/O)
- Districts activate/deactivate without scene reloading (seamless transitions)
- Tags are queryable by multiple systems with O(1) or O(log n) lookup
- Node discovery state persists across loops via Save/Load
- Camera bounds are per-district with zoom variation by vertical layer

## Decision

### Single NodeGraphData Resource

The entire village graph (all 44-66 nodes, all edges, all districts) lives in a single `NodeGraphData` Resource (.tres file). At boot, SceneManager loads this file once. At runtime, nodes are activated or deactivated based on the player's current district — no PackedScene loading or unloading during gameplay.

This is chosen over per-district files because:
- 44-66 nodes is small (a single .tres file is <50KB)
- District transitions are instant — just activate/deactivate Node2D children
- No file I/O or ResourceLoader calls during gameplay
- Simpler save/load — the entire graph state is in memory

### NodeData Resource

```gdscript
# node_data.gd
class_name NodeData extends Resource

## Unique identifier for this node (e.g., "central_bonfire_ground")
@export var node_id: String = ""

## Display name shown on the map and in UI
@export var display_name: String = ""

## 2D position in world coordinates
@export var position: Vector2 = Vector2.ZERO

## Which district this node belongs to
@export_enum("Central", "Seaside", "Forest") var district: int = 0

## Vertical layer: 0 = ground, 1 = high
@export var layer: int = 0

## Interaction zone tags (see Tag System below)
@export var tags: Array[StringName] = []

## Scene template for visual representation (PackedScene or null for default)
## If null, SceneManager uses a default placeholder (colored Circle2D during greybox)
@export var scene_template: PackedScene

## Custom data dictionary for future expansion (e.g., {"npc_count": 3, "event_id": "bonfire_night_1"})
@export var custom_data: Dictionary = {}

## Runtime state (not serialized in .tres, managed by SceneManager at runtime)
## Populated on game start / load
var is_discovered: bool = false   # hidden nodes become discovered
var is_active: bool = false       # currently in active district
var instance: Node2D              # runtime visual instance
```

### EdgeData Resource

```gdscript
# edge_data.gd
class_name EdgeData extends Resource

## Unique identifier (e.g., "edge_central_bonfire_to_market")
@export var edge_id: String = ""

## Source and target node IDs
@export var from_node: String = ""
@export var to_node: String = ""

## Traversal animation: 0=walk, 1=leap, 2=climb, 3=squeeze
@export_enum("walk", "leap", "climb", "squeeze") var edge_type: int = 0

## Travel duration in seconds
@export var duration: float = 0.4

## Visibility conditions (optional)
@export var is_hidden: bool = false               # invisible until discovered
@export var loop_gate: int = 0                    # 0 = always accessible, N = loop N+
@export var warmth_gate_npc: String = ""          # NPC ID for warmth gate (empty = none)
@export var warmth_gate_tier: int = 0             # minimum warmth tier (0 = none)
@export var night_only: bool = false              # only traversable at night
@export var day_only: bool = false                # only traversable during day
```

### NodeGraphData Resource (Root)

```gdscript
# node_graph_data.gd
class_name NodeGraphData extends Resource

## Graph version for migration
@export var version: int = 1

## All nodes in the village
@export var nodes: Array[NodeData] = []

## All edges in the village
@export var edges: Array[EdgeData] = []

## Per-district camera settings
@export var district_cameras: Array[DistrictCameraData] = []

## Adjacency lookup built at load time (not serialized)
var _adjacency: Dictionary = {}  # { "node_id": Array[String] } — adjacent node IDs
var _node_index: Dictionary = {} # { "node_id": NodeData } — O(1) lookup by ID
```

### DistrictCameraData Resource

```gdscript
# district_camera_data.gd
class_name DistrictCameraData extends Resource

@export var district: int = 0
@export var bounds: Rect2 = Rect2(0, 0, 1920, 1080)  # Camera limit rect
@export var ground_zoom: Vector2 = Vector2(1.0, 1.0)  # Default zoom
@export var high_zoom: Vector2 = Vector2(0.85, 0.85)  # Zoomed-out view from high nodes
@export var default_spawn_node: String = ""            # Where player starts in this district
```

### Tag System

Tags use Godot's `StringName` type — an optimized, interned string with O(1) equality comparison. Each node carries a `tags: Array[StringName]` array. Downstream systems query by tag name.

Tags are defined as constants on SceneManager for discoverability:

```gdscript
# Tag constants — use these, not raw strings
const TAG_NPC_PRESENT   := &"npc-present"
const TAG_FISH_SPAWN    := &"fish-spawn"
const TAG_BATTLE_TRIGGER:= &"battle-trigger"
const TAG_BOSS_TRIGGER  := &"boss-trigger"
const TAG_SAFE_ZONE     := &"safe-zone"
const TAG_HIDDEN        := &"hidden"
const TAG_LOOP_GATED    := &"loop-gated"     # Format: "loop-gated:N"
const TAG_WARMTH_GATED  := &"warmth-gated"   # Format: "warmth-gated:NPC:N"
const TAG_NIGHT_ONLY    := &"night-only"
const TAG_DAY_ONLY      := &"day-only"
```

Compound tags (`loop-gated:N`, `warmth-gated:NPC:N`) use a tag + data pattern. The tag marks the node as gated; the edge's `loop_gate` or `warmth_gate_*` fields carry the numeric threshold. Redundant encoding (both tag and typed field) ensures systems can query by tag presence (fast) OR by typed field (precise).

### SceneManager API

```gdscript
# SceneManager — Autoload singleton
extends Node

## Load the node graph at boot
func load_graph(path: String = "res://data/node_graph.tres") -> void

## Query
func get_node(node_id: String) -> NodeData
func get_adjacent_nodes(node_id: String) -> Array[String]
func get_edge(from_id: String, to_id: String) -> EdgeData
func get_nodes_with_tag(tag: StringName) -> Array[NodeData]
func get_nodes_in_district(district: int) -> Array[NodeData]
func is_node_accessible(node_id: String) -> bool
func get_camera_settings(district: int) -> DistrictCameraData
func get_current_district() -> int

## Discovery
func discover_node(node_id: String) -> void
func is_node_discovered(node_id: String) -> bool
func get_discovered_node_ids() -> Array[String]

## District transitions
func transition_to_district(district: int) -> void

## Runtime activation
func activate_district(district: int) -> void
func deactivate_district(district: int) -> void

## Save/Load contract
func collect_save_state() -> WorldState
func restore_from_save(state: WorldState) -> void

## Signals (via EventBus)
# node_entered(node_id: String)
# district_changed(from: int, to: int)
```

### District Transition Lifecycle

The LP's concern about PackedScene loading is resolved by the single-graph model — no PackedScene loading occurs during gameplay. The transition sequence:

```
1. Player reaches an inter-district edge (edge connects nodes in different districts)
2. MovementManager calls SceneManager.transition_to_district(target_district)
3. SceneManager:
   a. Deactivate current district:
      - Set is_active = false on all nodes in current district
      - Hide all Node2D instances in current district (visible = false)
      - Disable input processing on current district nodes
   b. Activate target district:
      - Set is_active = true on all nodes in target district
      - Show Node2D instances (visible = true)
      - Enable input processing
      - Move camera to target district bounds
   c. Play transition animation:
      - Camera pans from current to target district (Tween, 1.0-1.5s)
      - Player cat traverses the inter-district edge during the pan
   d. Fire EventBus.emit("district_changed", from_district, to_district)
4. Downstream systems react:
   - F7 (Scheduling): resolve NPC positions in new district
   - P2 (Audio): crossfade ambient for new district
   - P3 (Animation): play traversal animation for the edge type
```

No PackedScene loading. No node pooling. For 44-66 nodes, creating all instances at boot and toggling visibility is simpler and faster than any load/free strategy.

### Node Instance Management

Each node's visual representation is instantiated at boot from its `scene_template` PackedScene (or a default placeholder during greybox). Instances are created once and reused:

```gdscript
func _instantiate_nodes() -> void:
    for node_data in _graph.nodes:
        var template: PackedScene = node_data.scene_template
        var instance: Node2D
        if template:
            instance = template.instantiate()
        else:
            instance = _create_default_placeholder(node_data)
        instance.position = node_data.position
        instance.visible = false  # hidden until district activated
        instance.process_mode = Node.PROCESS_MODE_DISABLED
        node_data.instance = instance
        add_child(instance)
```

For 44-66 nodes with a Sprite2D child each, this is 88-132 nodes total — well within Godot's scene tree performance limits.

### Save/Load Integration

The `WorldState` sub-resource (defined in ADR-0002) stores discovered state:

```gdscript
class_name WorldState extends Resource
@export var discovered_node_ids: Array[String] = []
@export var fissure_nodes_added: int = 0  # How many new fissure nodes have been added
```

On load, SceneManager iterates `discovered_node_ids` and marks those nodes as discovered, making previously-hidden nodes visible. Fissure escalation adds new `NodeData` entries to the graph at loop start — these persist as part of the graph, not the save file (since the fissure state is deterministic per loop count).

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│              SceneManager (Autoload #2)                   │
│                                                          │
│  NodeGraphData (.tres) ─ loaded once at boot              │
│  ┌──────────────────────────────────────────────────┐    │
│  │  nodes: Array[NodeData]    (44-66 entries)        │    │
│  │  edges: Array[EdgeData]    (~2× node count)       │    │
│  │  district_cameras: Array[DistrictCameraData] (3)  │    │
│  │                                                   │    │
│  │  _adjacency: Dictionary   (built at load time)    │    │
│  │  _node_index: Dictionary  (O(1) lookup by ID)     │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Per-node runtime state:                                  │
│    is_discovered, is_active, instance (Node2D)            │
│                                                          │
│  Query API → C1 Movement, F7 Schedule, C4 Combat,         │
│              C5 Economy, C2 Time/Loop, C3 Relationship    │
│                                                          │
│  Camera: Camera2D with smoothing, per-district bounds     │
└──────────────────────────────────────────────────────────┘

         ┌──────────────┬──────────────┬──────────────┐
         │   Central    │   Seaside    │   Forest     │
         │   20-30 nodes│   12-18 nodes│   12-18 nodes│
         │   (active)   │  (inactive)  │  (inactive)  │
         └──────────────┴──────────────┴──────────────┘
              ↑ visible     ↑ hidden       ↑ hidden
```

## Alternatives Considered

### Alternative 1: Per-District .tres Files with On-Demand Loading

- **Description**: Each district has its own `district_central.tres`, `district_seaside.tres`, `district_forest.tres`. On district transition, load the target file via `ResourceLoader.load()` and free the previous district's instances.
- **Pros**: Lower memory footprint (only 1/3 of the graph in memory). More scalable if district count grows.
- **Cons**: File I/O during gameplay (ResourceLoader.load() on every district crossing). Free/instantiate cycle on every transition. More files to maintain. 44-66 nodes doesn't justify the complexity.
- **Estimated Effort**: Higher — load/unload lifecycle, error handling for missing files, transition state management.
- **Rejection Reason**: 44-66 nodes is a trivially small data set. A single .tres file is <50KB. The memory saved by per-district loading is negligible (<1MB). The complexity cost (file I/O during gameplay, load error handling, instance pool management) is not justified.

### Alternative 2: .tscn Scenes Per District (Godot Scene System)

- **Description**: Each district is a Godot `.tscn` scene file with nodes placed visually in the editor. Districts are loaded via `PackedScene.instantiate()` and freed via `queue_free()` on transition.
- **Pros**: Full visual editing in Godot's 2D editor. Drag-and-drop node placement. Designer-friendly.
- **Cons**: Tight coupling between visual representation and graph data. Tags must be set via node properties (harder to query programmatically). Adding a node requires editing a .tscn file AND updating downstream references. The data-driven principle (Architecture Principle #4) prefers Resources over scenes for data.
- **Estimated Effort**: Lower initial creation, higher maintenance.
- **Rejection Reason**: Violates Architecture Principle #4 (Data-Driven, Not Code-Driven). Graph data should be a Resource file, not a scene file. The node graph is queried by 6 systems — they need data, not visual nodes. Using .tscn files mixes data and presentation.

### Alternative 3: JSON or CSV Node Data

- **Description**: Store node graph in JSON or CSV text files. Parse at boot. No Godot Resource dependency.
- **Pros**: Portable, diffable in version control, editable in any text editor.
- **Cons**: No type safety. Manual parsing code. No editor integration. `StringName` tags must be manually converted. Adding a field requires updating both the format spec and the parser.
- **Estimated Effort**: Higher maintenance.
- **Rejection Reason**: Godot Resources provide the same benefits (text-based .tres is diffable) with type safety and zero parsing code. No advantage to JSON for this use case.

## Consequences

### Positive

- **Single file, single load**: The entire village graph is one `node_graph.tres` file. Debugging is trivial — open it in a text editor and read node positions, tags, edges.
- **Zero file I/O during gameplay**: District transitions are visibility toggles + camera pan. No ResourceLoader calls, no disk access.
- **O(1) tag queries**: `StringName` comparison is O(1). `_node_index` Dictionary gives O(1) node lookup by ID. Six downstream systems can query without performance concern.
- **Data-driven**: Node positions, tags, edge types, and camera bounds are all editable in Godot's Inspector via Resource files. Designers can tune the graph without touching code.
- **LP concern resolved**: The scene lifecycle is explicit — all instances created at boot, toggled on district change, never freed during gameplay.

### Negative

- **All nodes in memory always**: 44-66 Node2D instances + Sprite2D children = ~200 scene tree nodes. For the 2D Compatibility renderer with ≤200 draw calls, this is fine. The memory cost is <2MB.
- **Fissure escalation modifies the graph at runtime**: Adding new nodes mid-game mutates the `nodes` array. This is acceptable for the fissure mechanic (1-2 nodes per loop, loops 2+), but must be done before downstream systems query — add nodes during `loop_start` PRIORITY_PROCESS (100).
- **Node positions in pixels**: Hand-authoring coordinates for 44-66 nodes is tedious without a visual editor. Mitigation: build a simple in-editor placement tool later, or use a spreadsheet → .tres converter. For MVP, placing 44-66 Vector2 values manually is acceptable (a few hours of level design work).

### Neutral

- Nodes have both a `tags` array AND typed edge fields for gated access. This redundancy is intentional — tags enable fast filtering ("find all battle-trigger nodes"), typed fields enable precise gating logic ("loop ≥ 3 AND warmth ≥ 2").

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Node ID collisions or typos | Medium | Medium — edges reference non-existent nodes, systems query wrong node | Validate all edge references at load time. Log errors for any `from_node` or `to_node` not found in `_node_index`. Reject graph files with unresolved references. |
| Fissure node escalation breaks adjacency | Low | Medium — new nodes added at incorrect positions or with wrong edges | Fissure nodes are pre-authored with positions and edges for each loop; they are revealed, not randomly generated. Validate new node edges reference existing nodes. |
| Camera bounds mismatch with node positions | Low | Low — camera clips nodes at district edges | Bounds are authored alongside nodes. Validate at load time: warn if any node position falls outside its district's camera bounds. |
| 200 draw call budget exceeded | Low | High — visual glitches, frame drops | All nodes share a small set of sprite textures (atlas). Use `visible = false` for inactive districts to exclude them from draw. Profile with full Tier 2 content. |
| StringName tag typo in query | Medium | Low — system queries wrong tag, feature silently breaks | Tag constants defined on SceneManager. Downstream systems use `SceneManager.TAG_BATTLE_TRIGGER`, not `&"battle-trigger"`. Code review enforces this. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (graph load) | N/A | ≤5ms for ResourceLoader.load() + adjacency build | Acceptable at boot |
| CPU (district transition) | N/A | ≤2ms for visibility toggle + camera tween start | Well under 16.6ms |
| Memory (graph data) | 0 MB | ~2MB (44-66 Node2D + Sprite2D instances) | 500 MB ceiling |
| Memory (graph .tres file) | 0 KB | <50KB text file | Trivial |
| Draw Calls | 0 | ≤200 (one district active at a time) | 200 budget |

## Migration Plan

No existing graph to migrate — greenfield.

**Implementation steps:**
1. Create Resource classes: `NodeData`, `EdgeData`, `DistrictCameraData`, `NodeGraphData`
2. Author `node_graph.tres` with all 44-66 nodes, edges, and camera data
3. Implement SceneManager autoload with query API, activation/deactivation, and camera management
4. Register SceneManager as autoload index 2 (after EventBus, SaveManager)
5. Implement `WorldState` save/load for discovered nodes
6. Implement district transition lifecycle (visibility toggle + camera pan)
7. Wire `node_entered` and `district_changed` signals via EventBus
8. Greybox test: load graph, activate Central district, verify all nodes render at correct positions

**Rollback plan**: The node graph is a single Resource file. If the format needs to change, increment `NodeGraphData.version` and add a migration function. Old `.tres` files can be opened in a text editor and manually updated if needed (text-based format). If per-district loading becomes necessary later (e.g., if the village expands beyond 150 nodes), add `ResourceLoader.load()` per district without changing the NodeData/EdgeData format — only the load orchestration changes.

## Validation Criteria

- [ ] **Graph load**: Load `node_graph.tres`. Assert all 44-66 nodes are parsed, `_adjacency` is built, `_node_index` has O(1) lookup for every node ID.
- [ ] **District activation**: Activate Central district. Assert all Central nodes have `is_active = true` and `instance.visible = true`. Assert all Seaside and Forest nodes have `is_active = false` and `instance.visible = false`.
- [ ] **District transition**: Transition from Central to Seaside. Assert Central deactivates, Seaside activates, camera pans, `district_changed` signal fires.
- [ ] **Adjacency query**: Call `get_adjacent_nodes("central_bonfire_ground")`. Assert returned array matches expected adjacent node IDs from the authored graph.
- [ ] **Tag query**: Call `get_nodes_with_tag(TAG_BATTLE_TRIGGER)`. Assert returned array includes all and only battle-trigger nodes.
- [ ] **Hidden node discovery**: Node tagged `hidden` with `is_discovered = false`. Assert `is_node_accessible` returns false. Call `discover_node(id)`. Assert `is_node_accessible` returns true, `is_discovered = true`.
- [ ] **Loop gate**: Edge with `loop_gate = 3` when `current_loop = 2`. Assert `is_node_accessible` on the target node returns false.
- [ ] **Save/load discovered nodes**: Save game with 5 discovered hidden nodes. Load game. Assert all 5 are `is_discovered = true`.
- [ ] **Draw call budget**: Activate Central district (largest, 20-30 nodes). Profile with Godot's debugger → Monitors → Draw Calls. Assert ≤200.
- [ ] **Camera bounds**: Move camera to Seaside district edge. Assert camera does not scroll beyond `DistrictCameraData.bounds` for Seaside.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Node graph data structure: nodes (2D pos, layer, tags) + edges (type, visibility conditions) (AC-01 through AC-09) | `NodeData` + `EdgeData` Resource classes with typed fields for all properties |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | 44-66 total nodes across 3 districts, 2 vertical layers per district | Single `NodeGraphData` .tres with `district` enum and `layer` int per node |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Camera: 2D smooth follow, zoom out at high-level nodes, bounded to current district (AC-03, AC-04) | `DistrictCameraData` per district with `ground_zoom`/`high_zoom` + `Rect2` bounds |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | 10 interaction zone tags queryable by downstream systems (AC-09) | `StringName` tag system with constants; `get_nodes_with_tag()` O(n) query |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | District transition: camera pan + path traversal animation, ≤1.5s | Activation toggle + Tween-based camera pan, 1.0-1.5s |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Node visibility: adjacent only, hidden-until-discovered, loop-gated, warmth-gated (AC-05, AC-06, AC-07) | `is_node_accessible()` combines adjacency + discovery + gate checks |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Performance: ≤200 draw calls per frame (AC-10) | Single district active at a time; inactive nodes set `visible = false` |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Fissure escalation: new nodes added per loop (Edge Case #5) | Runtime node addition to `NodeGraphData.nodes` during `loop_start` |
| `design/gdd/scene-world-manager.md` | F2 Scene/World | Discovered nodes persist across loops (Edge Case #4) | `WorldState.discovered_node_ids` persisted via Save/Load (ADR-0002) |
| `design/gdd/movement-system.md` | C1 Movement | Traversal along edges with typed animations | `EdgeData.edge_type` (walk/leap/climb/squeeze) + `duration` |
| `design/gdd/npc-scheduling-system.md` | F7 Scheduling | NPC placement at `npc-present` tagged nodes | Tag query via `get_nodes_with_tag(TAG_NPC_PRESENT)` |

## Related

- `docs/architecture/architecture.md` — SceneManager module ownership (Foundation layer), node graph overview
- ADR-0001: Event Bus Architecture — `node_entered`, `district_changed` signals
- ADR-0002: Save/Load Serialization Format — `WorldState` sub-resource for discovered nodes
- ADR-0019: Movement System — consumes node graph for traversal
- `.claude/docs/technical-preferences.md` — snake_case naming, 200 draw call budget, 2D Compatibility renderer
