# NPC Scheduling System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Feature*
*Dependency order: #11 (depends on F2 Scene/World, C1 Movement)*

---

## 1. Overview

The NPC Scheduling System determines where every NPC cat is at any point during a loop. A single loop contains 7 day/night cycles — corresponding to the 7-year countdown — with each cycle advancing when the player spends time units (dialogue, battles). The system tracks the current day (1-7) and whether it is day or night. Each NPC has a hand-authored schedule: a primary node for each day-phase (e.g., "Day 3 — Market", "Night 5 — Shrine"), plus optional condition-triggered overrides (warmth tier, fish held, battle outcome). At loop start, all NPCs reset to their Day 1 Morning positions.

The day/night rhythm makes the village feel alive: cats are active and visible during the day, then retreat to homes, rooftops, or hidden corners at night. Day is for socializing, trading, and recruiting. Night is for quiet conversations, secrets, and encounters with loop-aware NPCs who stay awake. The transition between day and night is a diegetic visual shift — sky color changes, lanterns light up, certain nodes become accessible or restricted. This 7-day structure also creates natural narrative pacing: early days are introductory, middle days are for relationship-building, and the final day carries urgency as the countdown nears zero.

## 2. Player Fantasy

The player should feel like they live in a real village, not a quest hub. NPCs have lives of their own — they wake up, go to the market, visit friends, patrol territory, and sleep. The player learns these rhythms across loops: "The fisherman is at the pier at dawn, but at night he drinks alone at the courier station." This knowledge is a form of mastery — the player who knows NPC schedules can plan their loop more effectively, finding the right cat at the right time.

Day and night should feel like different games sharing the same village. Day is bright, social, and busy — NPCs are at work, market stalls are open, the village is alive. Night is intimate, quiet, and mysterious — most cats are asleep, but the ones who stay awake have different things to say. A conversation at night feels more personal. The player who visits an NPC during their night shift discovers a side of them the daytime never shows.

The 7-day structure creates urgency and rhythm. Early days feel spacious — time to explore. By day 5, the player feels the countdown tightening. On day 7, every visit counts. The player who knows that a specific NPC only appears at the Shrine on Night 6 feels the thrill of insider knowledge — "I know something this loop that I didn't know last loop." P1 (Every Encounter Leaves a Mark) and P4 (Loops Are Growth) extend to scheduling: learning the village's rhythm is growth.

## 3. Detailed Rules

### 3.1 Day/Night Cycle

A loop contains 7 days, each with a day phase and a night phase. The current day and phase are derived from remaining time units:

```
day_number = max(1, 7 − floor(time_units × 7 / 100))
```

| Day | Time Units Range | Approximate Duration |
|-----|-----------------|---------------------|
| 1 | 100 → 86 | ~14 units |
| 2 | 85 → 72 | ~14 units |
| 3 | 71 → 58 | ~14 units |
| 4 | 57 → 43 | ~14 units |
| 5 | 42 → 29 | ~14 units |
| 6 | 28 → 15 | ~14 units |
| 7 | 14 → 0 | ~14 units |

Day phase occupies the first ~60% of each day's time range (roughly 8 units). Night phase occupies the last ~40% (roughly 6 units). The exact boundary is:

```
is_night = (time_units mod 14.3) < 5.7   # mod returns values in (0, 14.3]; exact multiples return 14.3, not 0.0
```

### 3.2 Day/Night Transition

When the phase flips from day to night (or night to day of the next day):

1. A brief visual transition plays (1.5s sky color fade + lanterns on/off)
2. NPCs move to their new positions (teleport — no traversal animation for off-screen NPCs)
3. The UI countdown display reflects the new day number
4. Nodes tagged `night-only` or `day-only` become accessible/inaccessible

The transition occurs when the player's next action would cross the time threshold. The transition itself costs 0 time units — it is a consequence of time already spent.

### 3.3 NPC Schedule Data

Each NPC has a hand-authored schedule file containing:

```
npc_id: "fisherman"
schedule:
  day_1:  { day: "seaside_pier",        night: "seaside_market" }
  day_2:  { day: "seaside_pier",        night: "central_bonfire" }
  day_3:  { day: "seaside_market",      night: "seaside_pier" }
  day_4:  { day: "seaside_courier",     night: "seaside_pier" }
  day_5:  { day: "seaside_pier",        night: "seaside_market" }
  day_6:  { day: "seaside_market",      night: "central_shrine" }
  day_7:  { day: "central_bonfire",     night: "seaside_pier" }
overrides:
  - condition: "warmth >= 2 AND player_holds_fish"
    location: "seaside_courier_station"
```

**Schedule rules**:
- Every NPC must have a location for every day-phase (14 slots). No "off-screen" NPCs — cats are always somewhere in the village.
- A schedule slot specifies a node ID from the Scene/World Manager (F2).
- Conditional overrides are evaluated at the start of each day-phase. If an override condition is met, the NPC goes to the override location instead of their scheduled location.
- Multiple overrides: the one with the highest priority wins.
- Override conditions can reference: warmth tier, loop count, player inventory (holds fish), current team composition, battle outcomes, and dialogue flags.

### 3.4 Night-Specific Behavior

Night changes the village in several ways:

- **Visual**: Sky shifts to deep blue; lantern sprites activate at all nodes; cerulean trace marks glow faintly (more visible than during day).
- **NPC availability**: All NPCs are still present somewhere, but most are at their night locations — typically homes, rooftops, or quiet corners.
- **Dialogue tone**: Night dialogue variants are more intimate, reflective, or secretive. The Dialogue System (F4) can key dialogue to `is_night` flag.
- **Night-only nodes** (Tier 1+): Certain nodes tagged `time-gated:night` are only accessible during night phase. Examples: rooftop stargazing spot, shrine under moonlight, underground fissure (glowing at night).
- **Night-only NPCs** (Tier 1+): One or two NPCs only appear at night — the village elder meditating at the shrine, a mysterious cat at the pier.

### 3.5 Schedule Discovery

Players learn NPC schedules through:

- **Observation**: Visiting a node and finding an NPC there (or not finding them where they were last loop).
- **Dialogue hints**: NPCs mention their routines: "I'll be at the market tomorrow." "Come find me at night — I'll be watching the stars."
- **Cross-loop knowledge**: The player remembers that the fisherman was at the pier on Day 3 Night in the previous loop. Schedules do not change between loops (same NPC, same day, same phase = same location).

Schedules are fixed across loops — they never change. This rewards cross-loop knowledge (P4).

### 3.6 Loop Start Reset

At the start of each new loop (after reawakening), all NPC positions reset to their Day 1 Day-phase scheduled locations. This is triggered by the Time/Loop System (C2).

### 3.7 Node Interaction with Multiple NPCs

When two or more NPCs share the same node (scheduled or override), the player taps to choose which NPC to interact with, per the Dialogue System (F4) edge case §5.6. The other NPCs remain visible and can be spoken to afterwards. No simultaneous conversations.

### 3.8 MVP Simplifications

- 3 NPCs with full 7-day schedules (14 slots each = 42 schedule entries total)
- Day/night visual transition: sky color fade (1.5s) + lantern toggle
- No conditional overrides (all NPCs follow fixed schedules)
- No night-only nodes or night-only NPCs
- No night-specific dialogue variants (Dialogue System uses loop tier + warmth only)
- Schedule data stored as simple dictionaries in NPC resource files

## 4. Formulas

### Day Number from Time Units

```
day_number = max(1, 7 − floor(time_units × 7 / 100))
```

Clamped to 1-7. Examples:
- `time_units = 100` → day 1
- `time_units = 86` → day 1 (86 × 7 / 100 = 6.02, floor = 6, 7 − 6 = 1)
- `time_units = 50` → day 4 (50 × 7 / 100 = 3.5, floor = 3, 7 − 3 = 4)
- `time_units = 1` → day 7 (1 × 7 / 100 = 0.07, floor = 0, 7 − 0 = 7)

### Day/Night Phase Check

```
phase_progress = (time_units × 7 / 100) mod 1.0   # mod returns values in (0, 1.0]; exact multiples of 1.0 return 1.0, not 0.0
is_night = phase_progress < 0.4                     # phase_progress in (0.0, 0.4) = Night (last ~40%); [0.4, 1.0] = Day (first ~60%)
```

Day phase = first 60% of the day's time window (phase_progress ≥ 0.4). Night phase = last 40% (phase_progress < 0.4). The mod convention where exact multiples return 1.0 rather than 0.0 ensures `phase_progress` runs from just above 0 (end of night) up to 1.0 (start of day), making `phase_progress < 0.4` correctly identify the trailing night portion of each day cycle.

Examples for day 1 (time 100→86):
- `time = 100`: phase_progress = 1.0, `1.0 < 0.4` = false → Day
- `time = 92`: phase_progress ≈ 0.44, `0.44 < 0.4` = false → Day
- `time = 88`: phase_progress ≈ 0.16, `0.16 < 0.4` = true → Night

### NPC Location Resolution

```
location = npc.schedule[day_number][phase]
if npc.overrides:
    for override in npc.overrides sorted by priority desc:
        if override.condition.is_met():
            location = override.location
            break
```

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Days per loop | 7 | Fixed |
| Time units per loop | 100 | From Time/Loop System |
| Units per day (average) | ~14.3 | 100 / 7 |
| Day phase proportion | 60% (~8.6 units) | Social/active hours |
| Night phase proportion | 40% (~5.7 units) | Quiet/intimate hours |
| Day/night transition duration | 1.5s | Sky color fade + lantern toggle |
| Schedule slots per NPC (MVP) | 14 | 7 days × 2 phases |
| Schedule slots per NPC (Tier 1) | 14 + overrides | Plus conditional locations |

## 5. Edge Cases

1. **Day/night transition during dialogue**: Dialogue completes first (per Time/Loop System §5.1). The transition triggers after the dialogue box closes. If the transition flips the NPC's location, the NPC leaves after the conversation ends — the player got their conversation in just before the NPC moved.
2. **Day/night transition during battle**: Battle completes or interrupts first (per Time/Loop System §5.2). Transition triggers after battle resolution. If battle ends in victory during day and the phase shifts to night, the post-battle screen shows the night sky.
3. **Player is at a node that becomes night-only during the day**: If the player is already at a night-only node when day breaks, they are not forcibly moved. They can finish their interaction and leave, but cannot return until night falls again. The node's accessibility is checked on entry, not continuously.
4. **Two NPCs have the same schedule slot**: Both NPCs appear at the same node. The player sees both and taps to choose who to talk to. This is intentional for social gatherings (e.g., Bonfire Ground at night).
5. **NPC schedule file missing or corrupted**: System logs an error. The NPC defaults to their primary node (defined in Scene/World Manager as the NPC's home node) for all day-phases. The NPC is never missing from the village.
6. **Override condition references a state that just changed**: Override conditions are evaluated at the start of each day-phase. If the player gifts a fish mid-phase, the override does not trigger until the next phase transition. NPCs don't teleport mid-phase.
7. **Player rapidly triggers time-advancing actions crossing multiple day boundaries**: Each action subtracts time sequentially. If a single action's time cost crosses a day boundary, the transition triggers once after the action completes (not once per crossed boundary). The NPC schedule updates to the new day/phase.
8. **Loop 1 initial state**: On a fresh new game, all NPCs are at their Day 1 Day locations. No override conditions are met (no warmth, no battle history, no flags).
9. **Save/Load mid-phase**: Current day, phase, and all NPC positions are saved. On reload, NPCs are exactly where they were — no schedule re-evaluation occurs. The schedule only re-evaluates on phase transition or loop start.
10. **Night visibility/readability**: Night palette must keep NPCs clearly visible against dark backgrounds. Lanterns at every node provide ambient light. NPC sprites have a subtle rim light at night to separate them from dark environments.

## 6. Dependencies

### Upstream

| System | What F7 Needs From It |
|--------|----------------------|
| **Scene/World Manager (F2)** | Node graph and node IDs for all schedule locations; `night-only` / `day-only` node tags for accessibility gating |
| **Movement System (C1)** | NPC position data (where each NPC currently is); NPC visibility on node entry |
| **Time/Loop System (C2)** | Current time_units value (→ derive day number and phase); loop start signal (→ reset NPC positions to Day 1 Day) |
| **Save/Load System (F1)** | Persist current day, phase, and per-NPC position; restore on load |
| **NPC Relationship System (C3)** | Warmth tier per NPC (→ override condition evaluation) |
| **Economy/Inventory System (C5)** | Player fish inventory (→ "player_holds_fish" condition) |

### Downstream

| System | What It Needs From F7 |
|--------|----------------------|
| **Dialogue System (F4)** | Current NPC position (which NPCs are at the player's current node for interaction); `is_night` flag for night dialogue variants (Tier 1+) |
| **Scene/World Manager (F2)** | NPC placement at each node for rendering |
| **Movement System (C1)** | NPC collision/presence at nodes (NPCs block or coexist at nodes) |
| **UI/HUD Framework (F3)** | Day number display; day/night indicator; NPC presence indicator at current node |

### Design Note

F7 (Scheduling) and F2 (Scene/World) form a tight loop: F2 provides the node graph that schedules reference; F7 tells F2 where to place NPCs. This is resolved by F2 owning the node data (tags, IDs) and F7 owning the per-NPC position assignments, with F2 reading F7's output at node load time.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Days per loop | 7 | 5-10 | Loop pacing granularity; more days = finer schedule control |
| Day phase proportion | 60% | 50-70% | How much of each day is "daytime"; affects night availability |
| Day/night transition duration | 1.5s | 1.0-3.0s | Cinematic feel vs. pace interruption |
| Override condition count per NPC | 0 (MVP), 2-4 (Tier 1) | 0-5 | Schedule complexity; more overrides = more dynamic NPC behavior |
| Schedule slots per NPC | 14 | 10-20 | Authoring burden vs. NPC variety |

## 8. Acceptance Criteria

1. **AC-01**: At loop start (time_units = 100), the current day is 1, phase is Day, and all NPCs are at their Day 1 Day scheduled locations.
2. **AC-02**: As time_units decreases through gameplay, the day number correctly increments from 1 through 7. Day 7 begins when time_units drops to 14 or below.
3. **AC-03**: Within each day, the phase correctly flips from Day to Night when the time crosses the 40% threshold. Night begins in the latter portion of each day's time window.
4. **AC-04**: When the phase flips, the day/night visual transition plays (sky color fade + lantern toggle, 1.5s). NPCs move to their scheduled locations for the new phase.
5. **AC-05**: Each NPC has a valid location for all 14 day-phase slots (7 days × 2 phases). No NPC is ever missing or off-screen.
6. **AC-06**: At loop start (reawakening), all NPC positions reset to Day 1 Day locations regardless of where they were at the end of the previous loop.
7. **AC-07**: NPC schedules are identical across loops — the fisherman is at the same node on Day 3 Night in loop 1 and loop 5.
8. **AC-08**: When two NPCs share the same node, both are visible and the player can choose which to interact with.
9. **AC-09**: Day/night transition during dialogue: conversation completes first, then the transition triggers. The NPC the player was talking to stays for the conversation even if their schedule says they should be elsewhere in the new phase.
10. **AC-10**: Save/Load preserves current day, phase, and all NPC positions exactly. Reloading does not re-evaluate the schedule.
