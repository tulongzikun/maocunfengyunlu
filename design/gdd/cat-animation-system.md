# Cat Animation System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Presentation*
*Dependency order: #15 (depends on C1 Movement)*

---

## 1. Overview

The Cat Animation System manages all visual animation states for the player cat, NPC cats, and team cats. It is 2D sprite-based — each cat has a set of animation frames for each state (idle, walk, leap, climb, squeeze, emotes) that play in response to movement events from the Movement System (C1) and interaction events from other systems. Animations are simple, readable, and feline — cats stretch before leaping, pause mid-step to observe, curl up when idle. The system handles the player cat (always visible), recruited team cats (visible in team panel and battle), and NPC cats (visible at their scheduled nodes). All cats share the same animation skeleton — visual differentiation comes from coat patterns, accessories, and size variants, not unique rigs.

## 2. Player Fantasy

Cats should move like cats — not like generic RPG sprites. The idle animation should make the player smile: a cat washing its paw, curling its tail, blinking slowly. The leap should feel like a real cat pounce — a crouch, a wiggle, then an arc through the air. Emotes should be minimal but expressive: a tail flick for annoyance, slow blink for trust, ears flat for fear. The animation's job is not to impress with technical complexity but to reinforce P2 (Cat's Perspective) — every movement feels feline, natural, and warm. The player should think "that's exactly what a cat would do" not "that's a well-animated sprite."

## 3. Detailed Rules

### 3.1 Animation States

Every cat supports these animation states:

| State | Trigger | Frames | Loop | Priority |
|-------|---------|--------|------|----------|
| **Idle** | Cat is stationary at a node | 4-6 frames @ 8fps | Yes | Lowest |
| **Walk** | Cat is traversing a walk edge (C1) | 4 frames @ 10fps | Yes | Overrides idle |
| **Leap** | Cat is traversing a leap edge (C1) | 5 frames @ 12fps | No (one-shot) | Overrides walk |
| **Climb** | Cat is traversing a climb edge (C1) | 4 frames @ 8fps | Yes | Overrides walk |
| **Squeeze** | Cat is traversing a squeeze edge (C1) | 3 frames @ 6fps | No (one-shot) | Overrides walk |
| **Interact** | Cat is in dialogue or gifting | 2 frames @ 4fps | Yes | Highest |
| **Battle Idle** | Cat is in battle, waiting | 3 frames @ 6fps | Yes | Battle-only |
| **Battle Attack** | Cat is attacking in battle | 3 frames @ 12fps | No (one-shot) | Battle-only |
| **Wounded** | Cat is Wounded (C4 defeat) | 2 frames @ 4fps | Yes | Overrides idle/walk |
| **Emote** | Specific interaction events | 2-3 frames @ 6fps | No (one-shot) | Highest |

### 3.2 Idle Variations

Idle animation cycles through a set of feline micro-behaviors:
- Paw lick (most common, 60% chance per idle cycle)
- Tail curl + slow blink (20%)
- Stretch + yawn (10%)
- Look around / ear twitch (10%)

Variations prevent all cats from looking synchronized. Each cat independently picks its idle variation.

### 3.3 Emotes

Emotes are brief one-shot animations triggered by specific events:

| Emote | Trigger | Visual |
|-------|---------|--------|
| Slow blink | NPC reaches warmth tier 2 | Cat closes eyes slowly, 1s — sign of trust |
| Tail flick | Player attempts action that fails (inventory full, etc.) | Single tail swish |
| Ears flat | Battle defeat, Wounded status applied | Ears flatten for 1s |
| Happy hop | Fish gift accepted, warmth tier up | Small vertical hop (4px) |
| Curious tilt | Discovering a new node or clue | Head tilt, 0.5s |
| Sleep | Night phase, cat at home node | Curled up, gentle breathing animation |

### 3.4 Traversal Animations

Traversal animations play during edge transitions (C1 Movement). The Movement System fires `traversal_start` and `traversal_end` events with the edge type. The Animation System plays the appropriate state for the edge duration.

Leap animation includes:
1. Crouch (1 frame) — cat lowers body
2. Launch (1 frame) — extended posture
3. Mid-air (1 frame) — stretched, paws forward
4. Landing (1 frame) — paws touch down
5. Settle (1 frame) — tail balances

### 3.5 Visual Differentiation

All cats share the same animation rig. Differentiation comes from:
- **Coat color/pattern** (per-NPC, hand-authored): tabby stripes, calico patches, solid colors, tuxedo
- **Size variant**: Small (kitten), medium (adult), large (elder)
- **Accessories** (Tier 1+): Ribbons, charms, collars — added at warmth 2+ per P1 (Traces)
- **Cerulean sheen** (warmth 2+): Subtle overlay per P1 §3.5

The player cat has a unique silhouette (slightly different tail shape or ear tuft) to stand out from NPCs.

### 3.6 Battle Animations

During auto-battler combat (C4):
- Cats use **Battle Idle** between attack intervals
- **Battle Attack** plays on each SPD-timed attack
- Attack animation differs by archetype: Hunter (pounce swipe), Guardian (defensive paw swipe), Trickster (feint + tail whip)
- Wounded cats use the **Wounded** state overlay (slower movement, slight limp in idle)

### 3.7 MVP Simplifications

- Idle: 1 variation only (paw lick loop)
- Emotes: slow blink and happy hop only
- Battle: 1 generic attack animation for all archetypes
- No accessories or cerulean sheen (deferred to Tier 1 with Traces P1)
- Walk/leap/climb/squeeze: full set (essential for P2 cat perspective)
- All cats share identical animation frames — differentiation is coat color only (static sprite swap)

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Idle animation framerate | 8 fps | Relaxed, natural feel |
| Walk animation framerate | 10 fps | Slightly faster for movement clarity |
| Leap animation framerate | 12 fps | Fastest — pounce is quick |
| Climb animation framerate | 8 fps | Deliberate, careful |
| Squeeze animation framerate | 6 fps | Slow, effortful |
| Emote duration | 0.5-1.5s | Varies by emote type |
| Battle attack animation speed | 12 fps | Quick, readable |
| Wounded animation speed | 4 fps | Slow, pained |
| Sprite sheet size per cat | ≤512×512px | 4 animation states × 4-6 frames |
| Total animation frames (MVP) | ~30 frames | 7 states × average 4 frames |
| Total animation memory | ≤5MB | All cat sprites combined |

## 5. Edge Cases

1. **Traversal interrupted mid-animation**: If the player taps a new node mid-traversal, the current animation completes its current frame, then transitions to the new edge's animation. No frame tearing.
2. **Two animations trigger simultaneously (e.g., interact + emote)**: Higher priority state wins. Interact overrides idle/walk; emote overrides everything. The lower-priority animation resumes after the emote completes.
3. **Battle attack animation overlaps SPD interval**: If a cat attacks every 2.0s but the attack animation is 0.25s (3 frames @ 12fps), there is a 1.75s gap. The cat uses Battle Idle during the gap. If SPD is faster than the animation, the animation is cut short — the cat completes at least 1 frame of the attack.
4. **Very long traversal (climb edge, 0.8s)**: Climb animation loops until the traversal completes. The last loop iteration may be cut mid-cycle — animation stops on the frame closest to the traversal end time.
5. **Cat at node boundary during day/night transition**: Cat is idle. Night transition does not interrupt idle animation. Sleeping emote begins on the next idle cycle after night falls (not instantly — cats don't all sleep at once).
6. **Player cat in Wounded state during traversal**: Wounded animation overrides the normal walk animation. The cat moves at visibly slower pace. Traversal duration is unchanged (Movement System controls speed) — the animation simply plays slower.

## 6. Dependencies

### Upstream

| System | What P3 Needs From It |
|--------|----------------------|
| **Movement System (C1)** | Traversal start/end events with edge type; traversal duration; cat position |
| **Scene/World Manager (F2)** | Node entry/exit for idle state activation |
| **Auto-Battler Combat System (C4)** | Battle start/end; cat attack events; Wounded status; archetype for attack variant |
| **NPC Relationship System (C3)** | Warmth tier up events → happy hop emote; warmth 2+ → slow blink |
| **NPC Scheduling System (F7)** | Day/night phase → sleep emote eligibility at night |
| **Economy/Inventory System (C5)** | Fish gift event → happy hop; inventory full → tail flick |
| **Traces Visual Feedback (P1)** | Warmth-based visual changes (coat sheen, accessories) applied as overlays |

### Downstream

P3 is a leaf system — no gameplay system depends on animation for mechanical data.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Idle fps | 8 | 6-10 | Relaxed vs. restless feel |
| Walk fps | 10 | 8-12 | Movement clarity |
| Leap fps | 12 | 10-15 | Pounce energy |
| Idle variation probabilities | 60/20/10/10 | Any distribution | Cat personality expression |
| Emote duration | 0.5-1.5s | 0.3-2.0s | Expressiveness vs. responsiveness |
| Sprite sheet resolution | 512×512px | 256-1024px | Visual quality vs. memory |

## 8. Acceptance Criteria

1. **AC-01**: Player cat plays idle animation when stationary at a node; idle cycles through feline micro-behaviors.
2. **AC-02**: Walk, leap, climb, and squeeze animations play correctly during their respective edge traversals, matching the traversal duration from C1.
3. **AC-03**: Interact animation plays during dialogue and fish gifting; overrides idle/walk.
4. **AC-04**: Slow blink emote triggers when an NPC reaches warmth tier 2. Happy hop emote triggers on fish gift and warmth tier up.
5. **AC-05**: Battle attack animation plays on each SPD-timed attack during combat. Battle idle plays between attacks.
6. **AC-06**: Wounded animation (slower, pained) overrides idle and walk when a cat has the Wounded status from C4 defeat.
7. **AC-07**: All cats share the same animation rig but are visually distinct via coat color/pattern (sprite swap).
8. **AC-08**: Animation state transitions are clean — no frame tearing, no stuck frames, no visual artifacts when switching between states.
9. **AC-09**: Player cat is visually distinguishable from NPC cats (unique silhouette element — tail shape or ear tuft).
10. **AC-10**: Total cat animation memory does not exceed 5MB for MVP (30 frames across 7 states).