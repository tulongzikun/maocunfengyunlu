# Tutorial/Onboarding — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Polish*
*Dependency order: #16 (depends on C1 Movement, F3 UI/HUD, C2 Time/Loop)*

---

## 1. Overview

The Tutorial/Onboarding system manages the first-time player experience — the initial 10-15 minutes of gameplay that introduce movement, the countdown, NPC interaction, fish gifting, warmth, and the loop reset. The tutorial is diegetic: it is delivered through gameplay and NPC dialogue, not through pop-up text boxes or separate tutorial levels. Old Tom (the village elder) serves as the guide in loop 1 — he greets the player cat, explains the countdown in the sky, gives the first fish, and points toward the first NPC. Subsequent mechanics (recruitment, combat, boss encounters) are introduced naturally as they become available. The tutorial respects player intelligence — it teaches by letting the player do, not by telling them what to do.

## 2. Player Fantasy

The player should feel welcomed into the village, not instructed. Old Tom's guidance should feel like a wise cat showing a newcomer around — warm, patient, occasionally cryptic. The tutorial's emotional job is to establish the village as a place worth saving before the countdown becomes urgent. When the first loop ends and the player reawakens at the Bonfire Ground, the tutorial is done — but Old Tom's dialogue in loop 2 acknowledges the shared experience ("You look like you've done this before…"). The player who already knows the mechanics should not feel condescended to — advanced actions (leaping, climbing, focus-fire commands) are discovered, not taught.

## 3. Detailed Rules

### 3.1 Loop 1 — Guided Introduction

Loop 1 unfolds as a semi-structured introduction:

| Step | Trigger | What Happens | Time Cost |
|------|---------|-------------|-----------|
| 1. Awakening | Game start | Player cat opens eyes at Bonfire Ground. Countdown visible in sky. Old Tom is at the node. | 0 |
| 2. First conversation | Player taps Old Tom | Old Tom introduces himself, explains the countdown ("7 years until the sky breaks"), gives 1 fish (tutorial fish). Dialogue: 3-4 lines. | 3-4 units |
| 3. First movement | Old Tom suggests visiting the market | Player must tap a connected node to move. First traversal: walk edge (0.5s). | 0 |
| 4. First NPC meeting | Player reaches Fish Market node | Fisherman NPC is present. Old Tom (if followed) or fisherman initiates dialogue: "You can give fish to cats you want to know better." | 1 unit |
| 5. First fish gift | Player gifts the tutorial fish to fisherman | Fisherman accepts. +2 affection (C3). Warmth 0 → not enough to advance yet, but player sees the affection bar appear. Old Tom comments: "That's how bonds begin." | 0 (gifting costs 0 time; the dialogue after costs 1) |
| 6. Countdown awareness | Player has spent ~10 time units | Old Tom: "The sky counts down. Every word you speak, every fight you join — they cost time. Choose wisely." | 1 unit |
| 7. First loop end | Time reaches 0 (or player reaches ~50 units and Old Tom says farewell) | Collapse sequence plays. Player reawakens at Bonfire Ground. Loop 2 begins. | 0 (collapse) |

### 3.2 Loop 2+ — Discovery

After loop 1, tutorials are discovery-driven:
- **First battle**: When the player first enters a `battle-trigger` node, the pre-battle screen opens. A brief tooltip shows formation controls — but no NPC explains it. The player learns by doing.
- **First recruitment**: When an NPC reaches warmth 1 or affection > 5, a notification appears: "[NPC name] is willing to join you." The Team Panel button flashes.
- **First boss**: The boss node's descriptive text hints at the danger ("A heavy presence lingers…"). The double-confirm prompt warns about the 30-unit cost.
- **Shrine (early reset)**: Loop 2+: Old Tom mentions it if visited: "If you ever want to end the cycle early… the shrine accepts those who are ready."

### 3.3 Tutorial States

The tutorial tracks which mechanics have been introduced:

```
tutorial_flags:
  movement_learned: false       # First traversal completed
  countdown_explained: false    # Old Tom's countdown dialogue seen
  fish_gifted_first: false      # First fish gifted
  battle_first: false           # First battle triggered
  recruitment_first: false      # First NPC recruited
  loop_reset_experienced: false # First collapse sequence watched
  shrine_mentioned: false       # Old Tom mentions early reset
```

Flags persist across loops via Save/Load (F1). Once a flag is true, the associated tutorial content never plays again — even in future loops.

### 3.4 Old Tom's Loop-Aware Dialogue

Old Tom's dialogue changes across loops:

| Loop | Old Tom's Tone | Key Lines |
|------|---------------|-----------|
| 1 | Welcoming guide | "You're awake. Do you see the sky? It's been counting down for as long as anyone remembers." |
| 2 | Curious | "You're back. You look… different. Like you've walked this path before." |
| 3+ | Knowing | "I don't understand it, but I remember you. The fish you gave. The cats you helped. Something is happening." |

### 3.5 Skip and Accessibility

- All tutorial dialogue is skippable: each line advances with a click (standard dialogue mechanic).
- There is no forced slow-walk or locked camera during tutorial.
- A player who already knows the mechanics can ignore Old Tom entirely in loop 1 — he stays at Bonfire Ground but is not required.
- Tutorial flags can be set via debug/cheat for testing: "Skip Tutorial" option in Settings (dev mode only).

### 3.6 MVP Simplifications

- Loop 1 guided introduction only (steps 1-7 above)
- Old Tom dialogue: loop 1 only (no loop 2+ variants)
- Discovery tutorials (battle, recruitment, boss): basic tooltip only
- No tutorial flags persistence (tutorial replays each new game)
- Shrine early reset: no NPC mention — player discovers it

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Tutorial fish given | 1 | Loop 1 only; per Economy System C5 |
| Tutorial dialogue lines | ~12 total | Across all loop 1 steps |
| Tutorial time cost (total) | ~6 units | ~12 dialogue lines at 1 unit per 2 lines (some lines are paired) |
| First loop target time | ~50-60 units remaining | Tutorial completes well before urgency |
| Tutorial flag count | 7 | One per mechanic introduced |

## 5. Edge Cases

1. **Player ignores Old Tom entirely in loop 1**: Tutorial flags remain false. The player discovers mechanics organically (or not). No penalty. The game does not force tutorial completion.
2. **Player gifts tutorial fish to Old Tom himself**: Old Tom accepts but gently redirects: "A kind gesture. But I am not the one who needs it. Find a cat who doesn't know you yet."
3. **Player reaches 0 time during tutorial steps**: Tutorial dialogue completes first (per C2 edge case). Collapse triggers. On reawakening in loop 2, incomplete tutorial steps are skipped — Old Tom says: "You've seen the sky crack now. You know what's at stake."
4. **Player already knows mechanics from previous playthrough**: Tutorial can be ignored. Old Tom is not on the critical path — the player can leave Bonfire Ground immediately.
5. **Old Tom's tutorial fish in loop 2+ (player never received it)**: Per Economy System C5 §5.5: Old Tom still offers the tutorial fish in loop 2+ if the `received_tom_fish` flag is false.

## 6. Dependencies

### Upstream

| System | What PL1 Needs From It |
|--------|----------------------|
| **Movement System (C1)** | First traversal completion event |
| **UI/HUD Framework (F3)** | Tooltip display; team panel flash; countdown display |
| **Time/Loop System (C2)** | Loop count; collapse sequence; loop start event |
| **Dialogue System (F4)** | Old Tom dialogue delivery; tutorial dialogue trees |
| **Economy/Inventory System (C5)** | Tutorial fish grant; first fish gift event |
| **NPC Relationship System (C3)** | First recruitment event; warmth bar display |
| **Auto-Battler Combat System (C4)** | First battle trigger; pre-battle screen |
| **Save/Load System (F1)** | Tutorial flag persistence |

### Downstream

None — PL1 is a leaf system.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Tutorial fish count | 1 | 0-2 | First-loop economy head start |
| Tutorial dialogue lines | ~12 | 8-20 | Tutorial length and pacing |
| Tutorial time cost (total) | ~6 units | 4-10 | How much of loop 1 the tutorial consumes |
| Old Tom persistence in loop 2+ | Yes | Yes/No | Whether Old Tom is tutorial-only or an ongoing guide |

## 8. Acceptance Criteria

1. **AC-01**: On new game start, player cat awakens at Bonfire Ground. Countdown is visible. Old Tom is present.
2. **AC-02**: Old Tom's loop 1 dialogue explains the countdown, gives 1 fish, and suggests visiting the market — all within ~12 dialogue lines.
3. **AC-03**: Player can skip or ignore all tutorial content. Old Tom is not required for progression.
4. **AC-04**: First fish gift triggers the affection bar display and Old Tom's acknowledgment.
5. **AC-05**: Tutorial fish is given only once per save file (received_tom_fish flag). If not received in loop 1, Old Tom offers it in loop 2+.
6. **AC-06**: First battle, first recruitment, and first boss trigger appropriate discovery tooltips.
7. **AC-07**: Tutorial flags persist across loops — a learned mechanic is never re-explained.
8. **AC-08**: Old Tom's dialogue acknowledges the loop in loop 2+ ("You look like you've done this before").
9. **AC-09**: Loop 1 tutorial completes within ~6 time units, leaving ample time for free exploration.
10. **AC-10**: No forced camera locks, slow-walk segments, or unskippable sequences during tutorial.