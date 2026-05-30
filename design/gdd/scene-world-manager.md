# Scene/World Manager — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Foundation*
*Dependency order: #1 (no upstream system dependencies)*

---

## 1. Overview

The Scene/World Manager owns the cat village as a hand-crafted node graph across three distinct districts connected by traversable paths. The village is finite, dense, and vertical — density over sprawl (anti-pillar).

**Central District (中心区域)**: The heart of village life. Contains the Village Chief's residence (quest hub, clue source), residential houses (NPC homes), the Bonfire Ground (night gathering, story-sharing events, warmth-building opportunities), shops (item acquisition, fish trade), and the Shrine/Altar (pact-lore site, key to the true ending mystery).

**Seaside District (海边)**: The village's connection to the wider world. Contains the Pier/Dock (arrival point, visual anchor), the Fish Market (primary fish source, NPC merchants), and the Courier Station/驿站 (message delivery, cross-district NPC scheduling ties).

**Forest & Mountain District (森林和山地)**: The wild edge where the pact's cost is visible. Contains the Hunting Grounds (battle encounters, fish alternatives), the Workshop/Factory (crafting, item production), the Observatory (star-reading, countdown lore, elder NPC location), and the Underground Fissure (地底裂缝) — the source of the pact's manifestations. Creatures (魔物) emerge from the fissure, and the player's combat encounters are concentrated here. The fissure's state changes across loops (widening, new creature types) as the pact's debt escalates.

The three districts are connected by defined traversal paths: Central ↔ Seaside (coastal path), Central ↔ Forest (mountain trail). The Seaside and Forest districts are not directly connected — all routes pass through Central, making it the player's natural hub and ensuring NPC encounters compound there.

## 2. Player Fantasy

The player should feel the village is a **real, lived-in place** — not a game level. Moving through it should feel naturally feline: leaping between rooftops, slipping through narrow gaps, perching on high points to survey the district below. Each district has a distinct identity (bustling Central, breezy Seaside, wild Forest-Mountain), and traversal between them should feel like crossing genuine terrain, not clicking a fast-travel map. The village rewards curiosity — hidden shortcuts, secret perches, and environmental details that only reveal meaning on repeat visits across loops. Most importantly, the village should feel like **home** by loop 3 — familiar enough that changes (a new Traces mark, a missing NPC, a widened fissure) land emotionally.

## 3. Detailed Rules

### 3.1 Node Graph Structure

The village is a graph where **nodes** are locations the player can stand at and **edges** are traversable paths between them.

- Each node has: a 2D position, a vertical layer (ground/high), one or more connected edges, and optional tags.
- Each edge has: a movement animation type (walk/leap/climb/squeeze) and optional visibility conditions (hidden until discovered, blocked until loop N, blocked until warmth tier met).
- The player sees adjacent nodes as highlighted interactive targets. Tapping an adjacent node initiates traversal along the edge. Traversal is **free** — it does not consume countdown time. The player explores the village at their own pace without time pressure from movement.

### 3.2 Three Districts

**Central District (中心区域)**: Largest node count (~40-50% of village). Locations: Village Chief's Residence (2 nodes: exterior, interior), Residential Houses (4-6 nodes, one per NPC home), Bonfire Ground (1 large central node, night gathering events), Shops (2-3 nodes: general store, specialty merchant), Shrine/Altar (1 node, pact-lore interactions). Central is the player's natural hub — all inter-district routes pass through it.

**Seaside District (海边)**: Medium node count (~25-30%). Locations: Pier/Dock (2 nodes: dock entrance, pier end — visual arrival point), Fish Market (2-3 nodes: market stalls, fishmonger NPC), Courier Station (1 node: message board, cross-district NPC connections). Connected to Central via coastal path.

**Forest & Mountain District (森林和山地)**: Medium-large node count (~25-30%). Locations: Hunting Grounds (3-4 nodes: forest edge, deep woods, hunting blind), Workshop/Factory (1 node: crafting, item production), Observatory (1 node: perched high, star-reading, elder NPC), Underground Fissure (2-3 nodes: fissure entrance, upper ledge, deep approach — battle encounters concentrate here). Connected to Central via mountain trail. The Fissure's state escalates across loops (wider opening, new creature spawn points, new node connections).

**Inter-district connections**: Central ↔ Seaside (coastal path), Central ↔ Forest (mountain trail). Seaside and Forest are not directly connected — all routes pass through Central.

### 3.3 Vertical Layers

Each district supports up to 2 vertical layers:

- **Ground level** (default): streets, paths, market floors, bonfire circle, dock, workshop floor
- **High level**: rooftops, wall ledges, tree branches, observatory platform, shrine roof, canopy bridges

Nodes at different layers in the same vicinity are connected by vertical edges (climb up, leap down). The player moves between layers at specific transition nodes. High-level nodes provide a wider camera view and may reveal hidden ground-level nodes.

### 3.4 District Loading

The game loads the current district plus adjacent connected districts. At most 2 districts are in memory at any time (current + one connected). Traversal between districts triggers a short transition (camera pan, path traversal animation). In the 2D renderer, "loading" means node graph activation and NPC state transitions — not heavy scene streaming. Performance budget: ≤200 draw calls.

### 3.5 Camera

A single 2D camera follows the player cat with soft smoothing. Camera bounds are per-district. When the player reaches a high-level node, the camera zooms out slightly for a wider view. Ground-level nodes use the standard zoom. The camera is bounded to the current district — it does not scroll into adjacent districts until the player begins inter-district traversal.

### 3.6 Interaction Zone Tags

Each node can carry tags that other systems query:

| Tag | Effect | Queried By |
|-----|--------|------------|
| `npc-present` | An NPC can occupy this node | NPC Scheduling System |
| `fish-spawn` | A fish may appear here each loop | Economy System |
| `battle-trigger` | Small enemy encounters can initiate here | Combat System (C4) |
| `boss-trigger` | Boss encounters can initiate here (requires `loop-gated:N` on same node) | Boss Encounter System (F5) |
| `safe-zone` | No combat, no time pressure while present | Time/Loop System (C2) |
| `hidden` | Not visible on map until discovered (player proximity or NPC hint) | Movement System (C1) |
| `loop-gated:N` | Only accessible from loop N onward | Time/Loop System (C2) |
| `warmth-gated:NPC:N` | Only accessible at warmth tier N+ with a specific NPC | Relationship System (C3) |
| `night-only` | Only accessible during night phase | NPC Scheduling System (F7) |
| `day-only` | Only accessible during day phase | NPC Scheduling System (F7) |

## 4. Formulas

The Scene/World Manager is primarily structural, not mathematical. Key formulas:

### 4.1 Traversal

Traversal does NOT consume countdown time. The player moves freely between nodes without time pressure. Time advances only when the player engages in dialogue or triggers specific events — see Time/Loop System GDD for the time-advancement model.

### 4.2 Adjacent Node Visibility

```
is_visible(node, player) = true IF (
    node is connected to player.current_node by an edge
    AND (node.tag ≠ "hidden" OR node.discovered == true)
    AND (node.tag ≠ "loop-gated:N" OR current_loop ≥ N)
    AND (node.tag ≠ "warmth-gated:NPC:N" OR warmth(NPC) ≥ N)
)
```

### 4.3 District Node Budget

| District | Ground Nodes | High Nodes | Total |
|----------|-------------|------------|-------|
| Central | 14-20 | 6-10 | 20-30 |
| Seaside | 8-12 | 4-6 | 12-18 |
| Forest & Mountain | 8-12 | 4-6 | 12-18 |
| **Village Total** | **30-44** | **14-22** | **44-66** |

All well within the 200 draw-call performance budget.

## 5. Edge Cases

1. **Player at loop-gated node when loop resets**: Player is relocated to the nearest non-gated safe node (Bonfire Ground, Central). They do not retain access to the gated node — must re-qualify in the new loop.

2. **Warmth-gated node access after warmth decay**: If an NPC's warmth drops below the gate threshold at loop reset, the player loses access to any warmth-gated nodes tied to that NPC. Nodes already visited remain on the map but display as inaccessible until the player re-qualifies.

3. **NPC present at battle-trigger node**: Battle cannot trigger on a node where an NPC is currently present. The node is treated as `safe-zone` while occupied by an NPC. NPCs flee from battle-trigger nodes when combat starts at an adjacent node.

4. **Hidden node discovery persistence**: Discovered hidden nodes remain visible on the player's map across loops (knowledge persists — P4: Loops Are Growth). Only the `hidden` tag is removed upon discovery; the node itself remains in the graph and is accessible in future loops.

5. **Fissure node changes across loops**: The Underground Fissure gains new nodes each loop as it widens. These new nodes appear on the map as unexplored regardless of previous loop exploration. The player must re-approach to discover them. Previously discovered Fissure nodes remain visible.

6. **District boundary cancellation**: If the player initiates inter-district traversal and then cancels mid-transition, they return to the last ground-level node in the originating district. No time is consumed (traversal is free).

## 6. Dependencies

### Upstream
None. This is the first system in authoring order. No other GDDs must exist before this one can be implemented.

### Downstream
| System | What It Queries |
|--------|-----------------|
| Movement System (C1) | Node graph for valid adjacent nodes, edge types, vertical transitions |
| NPC Scheduling System (F7) | `npc-present` tags for NPC routine placement |
| Combat System (C4) | `battle-trigger` tags for encounter initialization |
| Economy System (C5) | `fish-spawn` tags for item placement per loop |
| Time/Loop System (C2) | `safe-zone` tags; enforces `loop-gated:N` access rules |
| Relationship System (C3) | `warmth-gated:NPC:N` tags; queries node graph for NPC proximity |

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Central District node count | 20-30 nodes | Village density, exploration time |
| Seaside District node count | 12-18 nodes | Seaside pacing, fish market accessibility |
| Forest District node count | 12-18 nodes | Fissure approach tension, hunting ground spread |
| Camera zoom (ground level) | 1.0x-1.5x | Standard gameplay view |
| Camera zoom (high level) | 0.7x-1.0x | Wider view from elevated perches |
| Edge animation duration | 0.3-0.8s per edge | Traversal feel — faster = snappier, slower = more deliberate |
| Hidden node reveal radius | 1-2 nodes distance | How close the player must be to discover hidden paths |
| Fissure new nodes per loop | 1-2 per loop (loop 2+) | Escalation pacing |
| District transition duration | 0.5-1.5s | Feel of crossing between districts |

## 8. Acceptance Criteria

1. **AC-01**: Player can tap any adjacent node and their cat traverses to it with the correct animation (walk for ground-ground, leap for horizontal gaps, climb/squeeze for vertical transitions).
2. **AC-02**: Player can move between ground and high layers at designated transition nodes in all three districts.
3. **AC-03**: Camera smoothly follows the player and zooms out at high-level nodes, returns to standard zoom at ground level.
4. **AC-04**: Camera is bounded to the current district — does not scroll into an adjacent district until inter-district traversal begins.
5. **AC-05**: Hidden nodes are not visible on the map until the player moves within 1-2 nodes of them or receives an NPC hint.
6. **AC-06**: Loop-gated nodes are inaccessible until the required loop. Tapping them shows a "not yet available" indicator.
7. **AC-07**: Warmth-gated nodes display which NPC and tier is required. Tapping an unmet warmth-gated node shows the requirement.
8. **AC-08**: Inter-district traversal shows a transition animation and loads the target district's node graph.
9. **AC-09**: All interaction zone tags (`npc-present`, `fish-spawn`, `battle-trigger`, `boss-trigger`, `safe-zone`, `hidden`, `loop-gated`, `warmth-gated`, `night-only`, `day-only`) can be queried by their respective downstream systems.
10. **AC-10**: Village renders within the 200 draw-call performance budget with all node graphics visible in the current district.
