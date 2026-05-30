# Dialogue System — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Feature*
*Dependency order: #6 (depends on F3 UI/HUD)*

---

## 1. Overview

The Dialogue System manages all NPC conversations — the text the player reads, the choices they make, and the branches those choices produce. It delivers the narrative through text-only interactions (anti-pillar: no voice acting). Every conversation is keyed to the current loop, the NPC's warmth tier, and the player's history with that NPC. The system queries the UI/HUD Framework's dialogue box to render text and choices. It is a data-driven pipeline: dialogue content lives in structured data files; the system selects the right content based on game state.

## 2. Player Fantasy

Dialogue should feel like discovering secrets from someone who might remember you — or might not. The player should feel the weight of being the only one who truly knows what's happening. In loop 1, conversations are warm introductions. In loop 2, NPCs sense something different — deja vu, unease. In loop 3+, they remember fragments, and the player feels the thrill of recognition: "You remember me." The dialogue system's emotional job is to make every conversation feel alive and responsive to context — never a static script repeated verbatim.

## 3. Detailed Rules

### 3.1 Dialogue Data Structure

Each NPC has a dialogue resource file containing conversation nodes keyed by:

```
dialogue_id: "NPC_name.conversation_key"
loop_tier: 1 | 2 | 3+        # Loop tier for this dialogue variant
warmth_min: 0-3               # Minimum warmth tier required
conditions: []                 # Optional flags (has_fish, fought_together, clue_known)
text: "Dialogue text here."
choices: []                    # 2-4 options, each with conditions and next dialogue_id
```

### 3.2 Dialogue Selection

When the player interacts with an NPC (arrives at same node, taps NPC):

1. Query the NPC's dialogue resource file
2. Filter by current loop tier: loop 1 = tier 1 only; loops 2-3 = tier 2; loop 4+ = tier 3+
3. Filter by current warmth tier: only show dialogue nodes where `warmth_min ≤ current_warmth`
4. Filter by conditions: only show nodes where all flags are met
5. Select the highest-priority matching node (highest warmth_min first, then most conditions met)
6. Fallback: if no node matches, use the NPC's generic idle line for the current loop tier

### 3.3 Dialogue Flow

- NPC dialogue text displays in the UI dialogue box (F3).
- Player clicks or presses SPACE to advance to the next line.
- When the text block ends, if the node has choices, they appear as buttons.
- Player selects a choice → system loads the next dialogue node by `dialogue_id`.
- If the node has no choices, the conversation ends and the dialogue box closes.
- Each text advance costs 1 time unit (per Time/Loop System §3.1).

### 3.4 Loop-Aware Dialogue Tiers

| Loop Tier | Loops | Dialogue Behavior |
|-----------|-------|-------------------|
| Tier 1 | Loop 1 | Normal introductions. NPCs do not recognize the player. Warm, curious, village-life topics. |
| Tier 2 | Loops 2-3 | Deja vu. NPCs sense something different: "Have we met?" "You feel familiar." Subtle hints that the world is not normal. |
| Tier 3 | Loop 4+ | Memory fragments. Specific NPCs recall past interactions: "You gave me a fish last time. I don't know how I know that." |

### 3.5 Memory Fragment Delivery

Memory fragments (defined in game-concept.md) are delivered through dialogue:

- **Fragment Tier 1 (Loop 2, all NPCs)**: Procedural deja vu lines — pulled from a shared pool per NPC personality type. Not hand-authored per NPC.
- **Fragment Tier 2 (Loop 3+, warmth 2+)**: Specific recall lines — hand-authored per NPC, referencing past-loop events. Example: "You stood at the pier for a long time last cycle. I watched you."
- **Fragment Tier 3 (Loop 4+, warmth 3)**: Behavioral persistence — the NPC acts on remembered knowledge. This is a dialogue flag that also triggers gameplay changes (NPC leaves a fish, warns of danger, opens a hidden path).

### 3.6 Choices

- 2-4 choices per dialogue node where branching occurs.
- Choices can have conditions (warmth_min, has_item, loop_count, clue_known).
- Choices can set flags on the player or NPC ("clue_known = true", "gifted_fish = true").
- Choices can advance warmth (a particularly good response grants +1 affection point toward next tier).
- If no choices are available/valid, the conversation follows a linear path.

### 3.7 Dialogue Content Budget

Per NPC, per loop tier, per warmth tier:

| Tier | Min Lines | Notes |
|------|-----------|-------|
| Tier 1 (loop 1, warmth 0-1) | 5-8 lines | Introduction + 1-2 topics |
| Tier 2 (loops 2-3, warmth 1-2) | 5-8 lines | Deja vu + 1-2 clue fragments |
| Tier 3 (loop 4+, warmth 2-3) | 3-5 lines | Memory fragments + 箱庭 lore |
| Generic idle (fallback) | 1-2 lines | "The cat watches you quietly." |

**MVP total (3 NPCs × 3 tiers)**: ~45-60 lines of dialogue
**Tier 1 total (5 NPCs × 3 tiers)**: ~75-100 lines
**Tier 2 total (10 NPCs × 3 tiers)**: ~150-200 lines

### 3.8 Dialogue Resource Format

Dialogue is stored as Godot Resource files (.tres) — one per NPC — for editor-friendliness during authoring. JSON export for debugging and bulk editing.

## 4. Formulas

| Parameter | Value | Notes |
|-----------|-------|-------|
| Dialogue lines per NPC per tier | 5-8 (tiers 1-2), 3-5 (tier 3) | See content budget §3.7 |
| Max choices per node | 4 | UI constraint |
| Time cost per text advance | 1 unit | Per Time/Loop System |
| Affection per "good" choice | +1 affection point | Toward per-loop affection (0-10) per Relationship System (C3) |
| Dialogue file size target | ≤50KB per NPC | Well within .tres limits |

## 5. Edge Cases

1. **Player interacts with same NPC twice in one loop**: System checks for already-viewed dialogue nodes and avoids repeats. If all nodes for the current tier have been seen, the NPC uses generic idle lines.
2. **Player has zero warmth with an NPC but is in loop 3**: Dialogue defaults to loop tier 2-appropriate content ("You feel familiar…") but warmth-gated choices are hidden.
3. **NPC has no dialogue written for the current loop tier**: Fallback to the highest available tier below the current one. If nothing exists, use the NPC's generic idle line.
4. **Player rapidly clicks through dialogue**: Each click still costs 1 time unit. There is no "skip all" button — the time cost is intentional (P3).
5. **Dialogue triggers at exact moment countdown hits zero**: Current text block completes, then collapse sequence begins — per Time/Loop System §5.1.
6. **Two NPCs on same node**: Player taps to choose which NPC to speak with. The other NPC waits. No simultaneous conversations.
7. **Dialogue file missing or corrupted**: System logs an error, displays NPC's generic idle line, and does not crash. The NPC says: "..." with a confused expression.

## 6. Dependencies

### Upstream
- **UI/HUD Framework (F3)** — renders dialogue text, choices, NPC name, and portrait
- **Time/Loop System (C2)** — loop count for dialogue tier selection (loop 1 / 2-3 / 4+); time unit cost per text advance
- **NPC Relationship System (C3)** — warmth tier per NPC (gates dialogue depth and choice visibility); memory fragment tier

### Downstream
- **NPC Relationship System (C3)** — receives affection point increments from "good" choices (+1 affection)
- **Time/Loop System (C2)** — notified of each text advance for time unit consumption

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Dialogue lines per NPC per tier | 3-12 | Writing burden, narrative depth |
| Max choices per node | 2-4 | Player agency vs. writing complexity |
| Affection per good choice | 0-3 | How much dialogue accelerates relationships |
| Time cost per text advance | 1-2 units | Conversation pacing, time pressure |
| Idle line repetition tolerance | 1-3 times before variation | NPC realism |

## 8. Acceptance Criteria

1. **AC-01**: Player approaches an NPC at the same node and taps them → dialogue box opens with correct NPC name and portrait.
2. **AC-02**: In loop 1, NPCs use tier 1 dialogue (normal introductions, no deja vu).
3. **AC-03**: In loops 2-3, NPCs use tier 2 dialogue (deja vu lines from shared pool per personality type).
4. **AC-04**: In loop 4+, NPCs at warmth 2+ use tier 3 dialogue (hand-authored memory fragments).
5. **AC-05**: Warmth-gated dialogue choices are hidden when the player's warmth tier is below the minimum.
6. **AC-06**: Selecting a dialogue choice advances to the correct next dialogue node by dialogue_id.
7. **AC-07**: Each text advance (click/SPACE) costs exactly 1 time unit from the Time/Loop System.
8. **AC-08**: A "good" dialogue choice increments the NPC's warmth interaction counter by +1.
9. **AC-09**: Repeated interactions with the same NPC in one loop show different lines (no immediate repetition).
10. **AC-10**: A missing or corrupted dialogue file does not crash the game — NPC displays a fallback generic idle line.
