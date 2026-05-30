# Save/Load System — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Foundation*
*Dependency order: #3 (no upstream dependencies; depended on by C2, C3, C4, C5, P1)*

---

## 1. Overview

The Save/Load System manages all persistent state across loop resets and game sessions. It defines a clear boundary: what carries forward (warmth tiers with decay, team cats, discovered nodes, Traces marks, loop count) and what resets (fish inventory, player position, NPC positions, battle state). The system auto-saves at the moment of loop transition (diegetic collapse → save → reawaken) and supports manual save for mid-session breaks. Serialization uses Godot's Resource system (.tres) for structured data with JSON fallback for debugging. The system is the single source of truth for "what survives the loop" — every other system queries it for their persistence rules.

## 2. Player Fantasy

The save system is invisible. The player should never think about it. Its emotional job is to make the reawakening moment real — when the world collapses and the cat opens their eyes again, everything they fought for is there: their team, their relationships (even if a little faded), their discovered secrets, their Traces marks on the village. The save system is the mechanical backbone of P4 (Loops Are Growth). If it works, the player feels continuity and accumulated meaning across resets. If it fails, the player feels betrayed. This system must never fail.

## 3. Detailed Rules

### 3.1 What Persists Across Loops

The following state survives loop reset and is written during auto-save:

| Data | Persistence Rule |
|------|-----------------|
| Loop count | Increments by 1 each loop |
| Warmth tiers | Persist with no decay — warmth never decreases across loops |
| Team cats | Identity, base stats, per-loop stat growth, affinity level |
| Discovered nodes | All `hidden`-tagged nodes the player has revealed |
| Traces marks | All permanent visual marks deposited in the world |
| NPC memory fragment flags | Which fragments each NPC has shown the player |
| True ending clue progress | Which pact-lore clues the player has assembled |

### 3.2 What Resets Each Loop

The following state is discarded at loop transition and reinitialized:

| Data | Reset Behavior |
|------|---------------|
| Fish inventory | Emptied completely (use-or-lose rule) |
| Player position | Returns to Bonfire Ground, Central District |
| NPC positions | Return to loop-start defaults per NPC Scheduling System |
| Battle/enemy state | All enemies reset to loop-appropriate configuration |
| Temporary stat penalties | Cleared (wounded cats recovered on reset) |
| Current dialogue state | Reset (no mid-conversation carry-over) |

### 3.3 Auto-Save Timing

Auto-save fires at the moment of loop transition — after the diegetic collapse sequence begins (sky cracks) but before the reawakening scene plays. The sequence is: collapse VFX → auto-save write → reawakening cutscene. The player cannot interrupt the save step. If the save fails, the game retries once, then shows an error with option to retry or return to menu.

### 3.4 Manual Save

Manual save is available from the pause menu at any time during gameplay. It captures the current loop state (mid-loop, all systems). Loading a manual save restores the exact state at save time — player position, fish inventory, NPC positions, current dialogue state. Manual save is distinct from auto-save: it preserves mid-loop state that auto-save intentionally discards.

### 3.5 Save File Structure

- Format: Godot Resource (.tres) — typed, fast, native serialization
- Path: `user://save_slot_01.tres` (single slot for MVP; expandable to 3 slots in Tier 1)
- Structure: A top-level dictionary keyed by system name. Each system writes and reads its own sub-dictionary.
- Example: `{"loop": {...}, "relationship": {...}, "economy": {...}, "combat": {...}, "traces": {...}, "world": {...}}`
- JSON debug export: available via dev console command `dump_save` for debugging only

### 3.6 Load Sequencing

1. Scene/World Manager loads the base village
2. Save/Load System reads the .tres file into memory
3. Each registered system receives its sub-dictionary and restores state
4. Player is placed at the appropriate spawn point (Bonfire Ground for loop start, saved position for manual load)
5. UI/HUD initializes with restored values (loop count, team panel, warmth indicators)

## 4. Formulas

| Constraint | Value | Reason |
|------------|-------|--------|
| Save file size target | ≤5 MB | Well within Godot .tres practical limits; allows future expansion |
| Auto-save duration target | ≤100 ms | No perceptible hitch during collapse sequence |
| Max save slots (MVP) | 1 | Single save file; adds a confirmation dialog for New Game |
| Max save slots (Tier 1) | 3 | Enables multiple playthroughs |

No complex formulas. This system's correctness is structural, not mathematical.

## 5. Edge Cases

1. **Corrupted save file**: Show error message: "Save data could not be read." Offer options: Retry, New Game (overwrites), Return to Menu. Do not crash.
2. **First ever launch**: No save file exists. Game starts fresh at loop 1, Bonfire Ground, with all systems at initial state. No error shown — this is the normal new player path.
3. **Save initiated during battle**: Battle state is discarded from the save. On load, player is placed at the last safe node before the battle-trigger node. Combat System handles re-initialization.
4. **Save initiated during dialogue**: Dialogue state is not persisted. On load, the NPC returns to their idle state at their current node. The player must re-initiate conversation. A warning toast is shown if the player attempts to save mid-dialogue.

## 6. Dependencies

### Upstream
None. This system is third in authoring order but has no code-level dependencies on other GDDs. It provides the persistence API that other systems consume.

### Downstream

| System | What Save/Load Provides |
|--------|------------------------|
| Time/Loop System (C2) | Triggers auto-save at loop transition; reads loop count |
| NPC Relationship System (C3) | Saves/loads warmth tiers, memory fragment flags, recruitment state |
| Auto-Battler Combat System (C4) | Saves/loads team cat data; discards battle state on reset |
| Economy/Inventory System (C5) | Saves/loads fish inventory (triggers clear on loop reset) |
| Traces Visual Feedback (P1) | Saves/loads all permanent Traces marks |
| Scene/World Manager (F2) | Saves/loads discovered node list |

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Max save slots | 1-3 | Multiple playthrough support |
| Save file size limit | 1-10 MB | Future-proofing for content expansion |
| Auto-save retry count | 1-3 | Resilience to transient write failures |

## 8. Acceptance Criteria

1. **AC-01**: Auto-save fires automatically during loop transition and completes before the reawakening cutscene begins.
2. **AC-02**: After loop reset, all NPC warmth tiers persist unchanged — warmth never decays. Tier 3 stays tier 3.
3. **AC-03**: Team cats persist with correct identity, base stats, per-loop growth, and affinity level across loop resets.
4. **AC-04**: Fish inventory is empty at the start of every loop regardless of previous-loop fish count.
5. **AC-05**: Discovered hidden nodes remain visible on the map across loop resets.
6. **AC-06**: Traces visual marks accumulate across loops — marks from loop 1 are visible in loop 2, new marks add to them.
7. **AC-07**: Manual save captures and restores mid-loop state (position, inventory, NPC positions, dialogue state).
8. **AC-08**: Corrupted save file displays an error message with options. Game does not crash or enter an unrecoverable state.
9. **AC-09**: First launch with no save file starts a fresh loop 1 at Bonfire Ground with all systems at initial defaults.
10. **AC-10**: Save file remains under 5MB with full Tier 2 content volume (10 NPCs, 6 team cats, all Traces marks, 4 districts).
