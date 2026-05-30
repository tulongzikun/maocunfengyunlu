# Traces Visual Feedback System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Presentation*
*Dependency order: #10 (depends on C3 Relationship, C2 Time/Loop, F1 Save/Load)*

---

## 1. Overview

The Traces Visual Feedback System is the visual manifestation of P1 (Every Encounter Leaves a Mark). It manages the permanent visual marks that accumulate in the village across loops — pawprint scars on walls, gifted ribbons tied to posts, a cat's coat changing color after a significant conversation. These marks use a single accent hue — cerulean blue — that grows in saturation each loop. Blue = permanence. The system ensures that nothing resets clean: every interaction that matters deposits evidence, and the village becomes a visual scrapbook of the player's journey. Traces answers the question: "How does the world show the player that they matter?" The system queries the NPC Relationship System for warmth tiers (determining mark saturation), the Time/Loop System for loop count (determining mark density), and the Save/Load System for persistence (marks never reset).

## 2. Player Fantasy

The player should feel like their existence matters to this world. Every loop, they return to a village that is physically different because of what they did. In loop 1, the village is clean — warm earth tones, no blue. By loop 3, cerulean marks are everywhere: a ribbon on the fisherman's stall from the fish the player gifted, a pawprint scar on the shrine wall from the battle they fought there, a subtle glow in a recruited cat's coat. The player should think: "I did that. That's from loop 2."

The cerulean blue accent should feel like memory made visible. It is never on things that reset — the fish inventory counter, the countdown display, the pause menu. Blue only appears on things that persist. This creates an intuitive visual language: if you see blue, it's permanent. The player learns to scan the village for blue marks as a way of tracking their own history.

The fantasy is not about decoration — it's about proof. Proof that the loops are real. Proof that the relationships matter. Proof that the player is not alone in remembering. When an NPC at warmth 2 says "I don't know how I know this, but you gave me a fish," and the player sees the cerulean fish-bone mark behind that NPC — the visual and the narrative reinforce each other. The mark was there before the NPC remembered. The player knew. The world knew.

## 3. Detailed Rules

### 3.1 Trace Types

Traces are permanent visual marks deposited at specific locations (nodes) or on specific entities (NPCs, team cats). Each trace type has a trigger condition and a visual form.

| Trace Type | Trigger | Location | Visual Form |
|------------|---------|----------|-------------|
| **Warmth mark** | NPC reaches warmth tier 2 and again at tier 3 | At the NPC's primary node | Cerulean mark unique to that NPC (e.g., fish-bone, ribbon, pawprint pattern) |
| **Battle scar** | Player wins a battle at a `battle-trigger` node | At the battle node | Cerulean scratch or claw-mark on the environment |
| **Gift echo** | Player gifts a fish to an NPC | At the NPC's current location | Small cerulean fish silhouette, faint |
| **Recruitment sigil** | NPC joins the player's team | At the node where recruitment dialogue occurred | Cerulean circle/pawprint — the NPC's "signature" |
| **Loop milestone** | Loop count reaches 2, 3, 4+ | Key village locations (Bonfire Ground, Shrine, Pier) | Environmental transformation — cerulean cracks in stone, glowing vine, water reflection |

### 3.2 Visual Language Rules

All traces follow strict visual rules:

1. **Color**: Only cerulean blue (#2B7FB0 or equivalent) is used for trace marks. No other game element uses this exact hue.
2. **Saturation by warmth**: Marks tied to NPC warmth scale in opacity/saturation:
   - Warmth 1: 25% opacity (barely visible — "something is starting")
   - Warmth 2: 60% opacity (clearly visible — "this matters now")
   - Warmth 3: 100% opacity (fully saturated — "this is permanent")
3. **No blue on ephemera**: Cerulean blue never appears on: countdown display, fish inventory counter, pause menu, dialogue box, or any UI element that resets.
4. **Layering**: New marks appear on top of older marks. The visual history is readable — the player can tell which marks are older by their position in the layer stack.
5. **Fade-in animation**: New marks fade in over 1.0-1.5 seconds when deposited. Existing marks are already there when the player enters a node.

### 3.3 Mark Accumulation

- Marks accumulate per node, per loop.
- There is no hard cap on marks per node, but each trace type triggers at most once per node per trigger condition (e.g., one battle scar per battle node per loop, one warmth mark per NPC per warmth tier).
- Marks never despawn, fade, or reset — they are cumulative forever.
- The Save/Load System persists all deposited marks across loops.

### 3.4 Trace Triggers

Traces are triggered by events from other systems:

| Event Source | Event | Trace Deposited |
|-------------|-------|-----------------|
| C3 — Relationship | NPC warmth reaches tier 2 | Warmth mark at NPC node (60% opacity) |
| C3 — Relationship | NPC warmth reaches tier 3 | Warmth mark at NPC node upgraded to 100% opacity |
| C4 — Combat | Battle victory at a node (first time per loop) | Battle scar at battle node |
| C5 — Economy | Fish gifted to NPC | Gift echo at NPC location |
| C3 — Relationship | NPC recruited to team | Recruitment sigil at recruitment node |
| C2 — Time/Loop | Loop count increments to 2, 3, 4+ | Loop milestone at key locations |

### 3.5 Team Cat Visual Changes

Team cats change visually as their warmth tier increases (Tier 1+ content):

| Warmth | Visual Change |
|--------|--------------|
| 1 | Base appearance — no trace marks |
| 2 | Coat gains subtle cerulean sheen; small accessory appears (ribbon, charm) |
| 3 | Coat fully enriched with cerulean highlights; accessory is prominent; cat leaves faint cerulean pawprints when moving |

These changes are applied to the team cat's sprite via overlay layers — not separate sprite sheets.

### 3.6 Node Trace Data

Each node in the Scene/World Manager (F2) can hold trace data:

```
node_id: "seaside_pier"
traces:
  - type: battle_scar
    loop_deposited: 2
    position: [x, y]  # local offset within node
  - type: gift_echo
    npc_id: "fisherman"
    loop_deposited: 1
    position: [x, y]
```

The Traces system reads this data on node entry and renders the appropriate sprites/overlays.

### 3.7 MVP Simplifications

- Trace types active: warmth mark, gift echo (battle scar, recruitment sigil, and loop milestone deferred)
- Team cat visual changes deferred to Tier 1
- Marks use placeholder cerulean sprites (colored circles/pawprints) — final art deferred
- Node trace data stored in a simple dictionary per node (no spatial partitioning)
- Fade-in animation: 1.0 second, fixed

## 4. Formulas

Traces is primarily an event-driven visual system rather than a calculation-heavy one. Key values:

### Warmth Saturation Mapping

```
trace_opacity = warmth_based_opacity[warmth_tier]
```

| Warmth Tier | Opacity | Visual Read |
|------------|---------|-------------|
| 1 | 0.25 | Faint — "something is starting" |
| 2 | 0.60 | Visible — "this matters" |
| 3 | 1.00 | Full — "this is permanent" |

### Fade-In Animation

```
opacity(t) = t / fade_duration × target_opacity
```

Linear fade from 0 to target opacity over `fade_duration` seconds.

### Mark Accumulation

```
node_mark_count = count(traces at node)
```

No cap. Cumulative forever.

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Warmth 1 trace opacity | 0.25 | Barely visible |
| Warmth 2 trace opacity | 0.60 | Clearly visible |
| Warmth 3 trace opacity | 1.00 | Fully saturated |
| Fade-in duration | 1.0-1.5s | Linear interpolation |
| Trace color (cerulean blue) | #2B7FB0 | Must not appear on any UI element |
| Max marks per node | No cap | Cumulative across all loops |
| Team cat warmth 2 visual | + sheen + small accessory | Tier 1+ |
| Team cat warmth 3 visual | + highlights + pawprint trail | Tier 1+ |

## 5. Edge Cases

1. **Node accumulates many marks (visual clutter)**: Marks layer with oldest at the bottom, newest on top. After 5+ marks at a single node, the oldest marks shrink to 50% size and reduce to 30% opacity — becoming background texture rather than competing for attention. They are never removed, only softened. The player can still see them if they look closely.
2. **Same trigger fires multiple times (e.g., 3 fish gifted to same NPC)**: Each gift creates its own gift echo. They stack at slightly offset positions (random ±5px horizontal, 0px vertical) so they read as separate marks without overlapping perfectly.
3. **NPC moves to different node after trace deposited**: Traces are permanently bound to the node where the event occurred. If the fisherman was at the Pier when the player gifted a fish, the gift echo stays at the Pier even if the fisherman's schedule moves them to the Market in future loops.
4. **Warmth mark upgrade (tier 2 → 3)**: The existing warmth mark at 60% opacity is upgraded in-place to 100% opacity. No duplicate mark is created. The transition animates over the standard fade duration.
5. **Player rapidly enters and exits a node**: All existing traces at the node render immediately on node load. No fade-in for existing marks — they are persistent scenery. Fade-in animation only applies to a new mark being deposited right now.
6. **Trace triggered on a loop-gated node the player cannot access yet**: The trace data is written to the node's trace list immediately when triggered. The player sees it when they first access the node in a future loop. Trace data is independent of node accessibility.
7. **Performance — many traces across many nodes**: Only traces for the currently active node (and adjacent visible nodes) are instantiated in the scene. Traces are lightweight sprites with no scripts attached. A village-wide trace count of 200+ marks should stay within the 50 draw call UI budget (marks batch-render on a dedicated Traces canvas layer).
8. **Save/Load mid-loop with traces**: All deposited traces are included in the save file. On reload, all previously deposited traces render correctly. Traces triggered between the save point and loop end are lost if the game is reloaded before the next save — the same as any other mid-loop progress.
9. **Trace position conflict (two marks at same offset)**: Each new mark at the same node is assigned a unique local offset (round-robin from a small offset table, e.g., [(0,0), (+8,−4), (−6,+5), (+4,+8), (−8,−2)]). Marks never overlap exactly.

## 6. Dependencies

### Upstream

| System | What P1 Needs From It |
|--------|----------------------|
| **NPC Relationship System (C3)** | Warmth tier per NPC (→ trace opacity); warmth change events (→ deposit/upgrade warmth marks); recruitment events (→ recruitment sigil) |
| **Time/Loop System (C2)** | Loop count (→ loop milestone traces); loop start signal (→ no action — marks persist) |
| **Save/Load System (F1)** | Persist all deposited trace data per node; serialize/deserialize node trace lists |
| **Scene/World Manager (F2)** | Node trace data container on each node; node enter/exit signals (→ load/unload trace sprites) |
| **Economy/Inventory System (C5)** | Fish-gifted events (→ gift echo) |
| **Auto-Battler Combat System (C4)** | Battle victory events (→ battle scar) |

### Downstream

Traces is a leaf system — no other system depends on it for mechanical data. It is purely output. However:

| System | What P1 Provides To It |
|--------|----------------------|
| **UI/HUD Framework (F3)** | Traces render on a dedicated canvas layer; must coexist with UI draw call budget |
| **Dialogue System (F4)** | Visual context — dialogue may reference visible traces ("That mark on the wall… where did it come from?") |

### Design Note

The Traces system is intentionally downstream-only in terms of gameplay data — it reads from other systems but never writes mechanics back. This keeps the visual layer cleanly separated: Traces can be modified, replaced, or disabled without affecting any gameplay logic.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Warmth 1 trace opacity | 0.25 | 0.15-0.35 | How subtle the earliest marks are |
| Warmth 2 trace opacity | 0.60 | 0.45-0.75 | Visibility of mid-tier relationship marks |
| Warmth 3 trace opacity | 1.00 | 0.85-1.00 | Full saturation intensity |
| Fade-in duration (new marks) | 1.0-1.5s | 0.5-2.5s | How quickly new marks appear when deposited |
| Mark soft-cap per node (before shrinking) | 5 | 3-8 | When old marks begin to shrink/soften |
| Old mark shrink scale | 0.50 | 0.30-0.70 | Size reduction for background marks |
| Old mark shrink opacity | 0.30 | 0.15-0.40 | Opacity reduction for background marks |
| Position offset range | ±5px | ±3-10px | How much new marks offset to avoid overlap |
| Team cat warmth 2 sheen strength | 20% | 10-30% | How visible the cerulean coat sheen is |
| Team cat warmth 3 highlight strength | 40% | 25-50% | How prominent the cerulean highlights are |
| Cerulean blue hex | #2B7FB0 | Adjacent blue range | The specific permanence color — must be unique in the palette |

## 8. Acceptance Criteria

1. **AC-01**: When an NPC reaches warmth tier 2, a cerulean warmth mark is deposited at that NPC's primary node at 60% opacity. When the NPC reaches warmth tier 3, the same mark upgrades to 100% opacity.
2. **AC-02**: When the player gifts a fish to an NPC, a faint cerulean gift echo appears at the NPC's current location with a 1.0-1.5s fade-in animation.
3. **AC-03**: All deposited traces persist across loops via Save/Load. A trace deposited in loop 1 is visible in loop 3 at the same node, with the same opacity.
4. **AC-04**: Cerulean blue (#2B7FB0) appears only on trace marks — never on the countdown display, fish inventory counter, dialogue box, pause menu, or any ephemeral UI element.
5. **AC-05**: When the player enters a node, all existing traces at that node are rendered immediately (no fade-in delay for existing marks). Traces at non-visible nodes are not rendered.
6. **AC-06**: Traces at the same node with the same trigger type layer correctly — newer marks appear above older marks. After 5+ marks, oldest marks shrink to 50% size and 30% opacity.
7. **AC-07**: Trace rendering does not exceed the UI draw call budget when 200+ marks exist across the village. Only marks at the current node (and adjacent visible nodes) are in the scene tree.
8. **AC-08**: Warmth marks are per-NPC — each NPC's warmth mark is visually distinct (different shape/pattern) so the player can identify whose mark is whose.
9. **AC-09**: Traces have no effect on gameplay mechanics — disabling or removing all trace rendering does not change relationship scores, battle outcomes, or any game state.
10. **AC-10**: When an NPC moves (NPC Scheduling, F7), their existing traces remain at the nodes where they were deposited. Traces are location-bound, not NPC-bound.
