# Movement System — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Core*
*Dependency order: #2 (depends on F2 — Scene/World Manager)*

---

## 1. Overview

The Movement System translates player taps into cat traversal across the village node graph. It queries the Scene/World Manager for adjacent nodes and edge types, plays the appropriate movement animation (walk, leap, climb, squeeze), and updates the player's current position for all other systems. Movement is entirely node-based — no free-form physics, no real-time input during traversal. Traversal is free (no countdown time consumed). The system makes getting around feel satisfying and feline: the cat flows from rooftop to alleyway with grace, each edge transition a small moment of embodied cat-ness.

## 2. Player Fantasy

Moving through the village should feel like **being a cat**. Not a human-shaped character walking on rooftops — a cat. Leaps should feel effortless and precise, landing silently on the next perch. Climbing should feel deliberate — claws finding purchase on wooden beams. Squeezing through narrow gaps should feel intimate and secret. Walking on ground level should be a relaxed stride, tail high. The movement system's primary emotional job is to make the player feel graceful, nimble, and curious — the way a cat exploring its territory feels. If the player ever thinks about the movement system, it's failing. If they just *move* and it feels right, it's working.

## 3. Detailed Rules

### 3.1 Tap-to-Move Input

- Player taps an adjacent node (visible and accessible per Scene/World Manager visibility rules).
- The movement system locks input during traversal — no queuing, no interrupting mid-traversal.
- If the tapped node is inaccessible (gated, blocked), the cat does not move. A brief visual indicator shows the reason (lock icon for loop-gated, heart icon for warmth-gated).

### 3.2 Edge Traversal by Type

| Edge Type | Animation | Duration | Use Case |
|-----------|-----------|----------|----------|
| `walk` | Cat strides along ground or wide ledge | 0.4-0.6s | Streets, paths, market floor |
| `leap` | Cat crouches, springs, lands silently | 0.3-0.5s | Rooftop gaps, branch jumps |
| `climb` | Cat scales vertical surface, claws visible | 0.5-0.8s | Wall to rooftop, tree trunk |
| `squeeze` | Cat flattens, slips through narrow gap | 0.6-0.8s | Alleyway cracks, fence gaps |

### 3.3 Vertical Transitions

- Vertical edges connect ground nodes to high nodes at the same vicinity.
- Climbing up uses the `climb` animation. Leaping down uses a shortened `leap` (0.2-0.3s).
- The cat cannot be interrupted mid-vertical-traversal.

### 3.4 Movement State Machine

Three states:
- **Idle**: Cat stands at current node. Adjacent nodes are highlighted. Input accepted.
- **Traversing**: Cat is in motion along an edge. Input locked. Other systems query current interpolated position.
- **Blocked**: Cat attempted to traverse to an inaccessible node. Brief shake animation (0.2s). Returns to Idle.

### 3.5 Interaction Proximity

- The player is considered "at" a node once traversal completes (cat arrives at target, state = Idle).
- NPC interaction, item pickup, and battle triggers all require the player to be at the relevant node.
- Other systems query `player.current_node` to determine interaction eligibility.

### 3.6 Gated Node Behavior

- `loop-gated:N`: Tapping shows a closed-lock indicator + loop number required. No traversal.
- `warmth-gated:NPC:N`: Tapping shows a heart indicator + NPC name + tier required. No traversal.
- `hidden`: Not shown as a tap target until discovered.

## 4. Formulas

### 4.1 Traversal Duration

```
traversal_duration = edge.animation_duration × speed_modifier
```

- `edge.animation_duration`: per-type base value from table in §3.2
- `speed_modifier`: 1.0 by default; configurable for accessibility (0.5-2.0 range)
- No countdown time is consumed by traversal

### 4.2 Visual Interpolation

```
interpolated_position(t) = lerp(start_node.position, end_node.position, t / traversal_duration)
```

- `t`: elapsed time since traversal start
- Linear interpolation between node positions
- For `leap` edges: parabolic arc added, peak height = 20px
- Visual only — no physics simulation

## 5. Edge Cases

1. **Rapid tapping during traversal**: Input is locked. No queuing. Player must wait for traversal completion before tapping the next node.
2. **Tap on non-adjacent node**: No response. Only nodes connected by a single edge are tappable.
3. **Tap on gated node**: Cat does not move. Appropriate indicator shown (lock/heart/loop number). Returns to Idle after 0.2s shake animation.
4. **Arrival at battle-trigger node with enemies present**: Traversal completes, then combat initiates immediately.
5. **Traversal during loop reset**: If the loop ends mid-traversal, traversal completes (max 0.8s remaining), then the diegetic transition triggers.
6. **District transition edge**: Inter-district edges use a special extended animation (1.0-1.5s). Camera pans during traversal. Target district loads before arrival.

## 6. Dependencies

### Upstream
- **Scene/World Manager (F2)** — queries node graph for adjacent nodes, edge types, visibility rules, and gating tags

### Downstream

| System | What It Queries |
|--------|-----------------|
| NPC Scheduling System (F7) | `player.current_node` for NPC proximity |
| Dialogue System (F4) | `player.current_node` for conversation triggers |
| Combat System (C4) | Arrival at `battle-trigger` nodes |
| Economy System (C5) | Arrival at `fish-spawn` nodes |
| Cat Animation System (P3) | Current movement animation and interpolation |

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Walk duration | 0.3-0.8s | Ground traversal feel |
| Leap duration | 0.2-0.6s | Rooftop agility feel |
| Climb duration | 0.4-1.0s | Vertical effort feel |
| Squeeze duration | 0.4-1.0s | Narrow passage feel |
| Leap arc height | 10-40px | Visual drama of jumps |
| Speed modifier (accessibility) | 0.5-2.0x | Player comfort |
| Blocked shake duration | 0.1-0.4s | Feedback clarity |
| District transition duration | 0.8-2.0s | Inter-district travel feel |

## 8. Acceptance Criteria

1. **AC-01**: Tapping an adjacent walkable node causes the cat to walk to it at the configured duration. Interpolated position updates every frame.
2. **AC-02**: Tapping a node connected by a `leap` edge plays the leap animation with a visible parabolic arc.
3. **AC-03**: Tapping a node connected by a `climb` edge plays the climb animation (vertical ascent with clawing motion).
4. **AC-04**: Tapping a node connected by a `squeeze` edge plays the squeeze animation (flattened, narrow passage).
5. **AC-05**: Input is locked during traversal — tapping other nodes during movement has no effect.
6. **AC-06**: Tapping a loop-gated node displays the required loop number and does not move the cat.
7. **AC-07**: Tapping a warmth-gated node displays the required NPC name and tier. Cat does not move.
8. **AC-08**: Hidden (undiscovered) nodes are not tappable and not visible on the map.
9. **AC-09**: Inter-district edge triggers the extended transition animation and loads the target district before arrival.
10. **AC-10**: `player.current_node` is accurately updated on traversal completion and is queryable by all downstream systems.
