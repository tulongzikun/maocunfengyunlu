# Time/Loop System — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Core*
*Dependency order: #5 (depends on F1 Save/Load, F3 UI/HUD)*

---

## 1. Overview

The Time/Loop System owns the countdown clock and the diegetic loop transition. It defines when time advances, what happens when time runs out, and what triggers the loop reset. Time is action-gated — it advances when the player completes dialogue exchanges or finishes battles, not during traversal or idle exploration. The countdown is always visible via the UI/HUD Framework. When time reaches zero, the diegetic collapse sequence plays and the Save/Load System triggers auto-save before the player reawakens. This system is the mechanical heart of P3 (Time Does Not Wait).

## 2. Player Fantasy

The countdown should feel like a genuine, inescapable presence — not a stressful timer. The player should feel the weight of limited time without feeling rushed. Because traversal is free, the player can explore at their own pace; time only advances when they choose to engage. This creates a rhythm: explore freely → decide who to talk to → commit time → explore more. The countdown's visual presence (pale gold, always there) should be beautiful, not anxiety-inducing. The collapse sequence should feel like a genuine death-and-rebirth — beautiful, sad, and hopeful all at once. When the player reawakens, they should feel: "I lost something, but I gained something too."

## 3. Detailed Rules

### 3.1 Time Advancement

Time advances only through player actions. Traversal, idle standing, and menu navigation are free.

| Action | Time Cost | Notes |
|--------|-----------|-------|
| Dialogue block (one text advance/click) | 1 unit | Each click-through of a dialogue line |
| Small battle encounter | 10 units | Standard enemy engagement |
| Boss encounter | 30 units | Major battle at loop milestones |

Time does NOT advance during: node traversal, idle at a node, pause menu, viewing team panel, or any UI interaction.

### 3.2 Countdown Budget

- Total budget per loop: **100 time units**
- Displayed diegetically as "7 years" (100 units → ~14.3 units per in-game year)
- The countdown is always visible via the UI/HUD countdown display
- Years remaining shown as whole numbers: `ceil(time_units / 14.3)` → 7, 6, 5, 4, 3, 2, 1, 0
- At ≤10 units (critical threshold), the UI countdown begins pulsing

### 3.3 Diegetic Loop Transition

When time reaches zero (or player triggers early reset), the following sequence plays:

1. **Sky cracks** (2.0s) — the sky fractures, cerulean blue light spills through
2. **World collapse** (2.0s) — the village dissolves, screen shakes, audio swells
3. **Whiteout** (1.0s) — screen fades to pure white
4. **Auto-save** (≤100ms) — Save/Load System persists loop state
5. **Reawakening** — player cat opens eyes at Bonfire Ground, Central District. New loop begins.

Total transition duration: ~5 seconds. The player cannot skip or interrupt it.

### 3.4 Per-Loop State Changes

Triggered automatically by the Time/Loop System at the start of each new loop:

| Change | System Responsible |
|--------|-------------------|
| Loop counter +1 | Save/Load System |
| Warmth decay (−1 per NPC, tier 1 stays) | Relationship System |
| Fish inventory emptied | Economy System |
| Team cats persist (identity, stats, affinity) | Combat System |
| Traces marks persist (cumulative) | Traces System |
| Enemies escalate (+15-25% stats, new abilities at milestones) | Combat System |
| NPC positions reset to loop-start defaults | NPC Scheduling System |
| Player spawns at Bonfire Ground | Movement System |

### 3.5 Early Loop Reset

- Available from **loop 2 onward** at the Shrine/Altar node in Central District.
- Interacting with the Shrine offers: "Accept the cycle's end?" → Yes/No confirmation.
- If Yes: the diegetic collapse sequence plays immediately, regardless of remaining time.
- Any unspent time is lost. Fish inventory is still emptied. Warmth decay still applies.
- Early reset allows players who have accomplished their goals to move on without waiting.

### 3.6 Time Cost Design Intent

With a 100-unit budget:
- The player can complete ~70-80 dialogue exchanges per loop (allowing for battle costs)
- With 10 NPCs, that's ~7-8 exchanges per NPC if evenly distributed
- A single battle (10-30 units) represents a significant commitment
- A boss fight (30 units) is nearly a third of the loop — a major decision
- The player who avoids battles has more time for relationships; the player who fights heavily sacrifices social depth

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Time budget per loop | 100 units | Constant across all loops |
| Years display conversion | `years = ceil(time_units / 14.3)` | 100 / 7 ≈ 14.3 units per diegetic year |
| Critical threshold | `time_units ≤ 10` | Triggers UI pulse animation |
| Dialogue cost | 1 unit per text advance | Player controls pace |
| Small battle cost | 10 units | Per encounter |
| Boss battle cost | 30 units | Per encounter |
| Collapse sequence total | ~5.0 seconds | Sky cracks (2s) + collapse (2s) + whiteout (1s) |

## 5. Edge Cases

1. **Dialogue in progress when time hits zero**: The current dialogue block completes fully. The collapse sequence begins immediately after the last line is displayed. No dialogue is cut off mid-sentence.
2. **Battle in progress when time hits zero**: The battle ends immediately — enemies retreat (not defeated). The collapse sequence begins. The player does not receive battle rewards for an incomplete fight.
3. **Early reset with confirmation**: The Shrine dialog asks for confirmation. Selecting "No" returns to gameplay with no time cost. Selecting "Yes" triggers the full collapse sequence.
4. **Loop 1 Shrine inaccessible**: The Shrine node has a `loop-gated:2` tag. The player cannot trigger an early reset on their first loop — they must experience the full countdown at least once.
5. **Time cannot advance without player action**: If no dialogue or battle is active, time is frozen. There is no passive countdown — P3 tension comes from the player knowing every conversation costs time, not from a ticking clock.
6. **Multiple simultaneous time triggers**: If a dialogue completes and a battle-trigger is on the same node, dialogue resolves first, then the battle-trigger becomes active. Time costs are sequential, not simultaneous.

## 6. Dependencies

### Upstream
- **Save/Load System (F1)** — triggers auto-save during collapse sequence; reads loop count on reawakening
- **UI/HUD Framework (F3)** — updates countdown display every time unit; shows loop counter

### Downstream

| System | Trigger |
|--------|---------|
| NPC Relationship System (C3) | Loop-reset event for per-loop affection reset; loop count for memory fragment tier gating |
| Auto-Battler Combat System (C4) | Enemy escalation applied at loop start; team persistence |
| Economy/Inventory System (C5) | Fish inventory cleared at loop start |
| Traces Visual Feedback (P1) | Mark persistence across loops |
| Boss Encounter System (F5) | Boss phase escalation at loop milestones |
| NPC Scheduling System (F7) | NPC position reset at loop start |
| Dialogue System (F4) | Time cost per text advance (1 unit); loop-aware dialogue tiers (C2 provides loop count) |
| Tutorial/Onboarding (PL1) | Loop count for Old Tom's loop-aware dialogue; collapse sequence trigger |

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| Time units per loop | 60-150 | Loop length; relationship depth vs. urgency |
| Dialogue cost (per block) | 1-2 units | Conversation pacing |
| Small battle cost | 5-20 units | Combat opportunity cost |
| Boss battle cost | 20-50 units | Boss commitment weight |
| Critical threshold (pulse start) | 5-20 units | Urgency ramp timing |
| Sky cracks duration | 1.0-3.0s | Dramatic weight of collapse |
| World collapse duration | 1.0-3.0s | Emotional impact of loss |
| Early reset available from loop | 2-4 | Player agency timing |

## 8. Acceptance Criteria

1. **AC-01**: Countdown displays "7" at loop start and decreases as dialogue blocks are advanced. Each dialogue click reduces the countdown display by the appropriate fraction.
2. **AC-02**: Traversal between nodes does not reduce the countdown. Idle time does not reduce the countdown.
3. **AC-03**: A small battle encounter reduces the countdown by 10 units. A boss encounter reduces it by 30 units.
4. **AC-04**: When time reaches zero, the full collapse sequence plays in order: sky cracks (2s) → world collapse (2s) → whiteout (1s) → reawakening at Bonfire Ground.
5. **AC-05**: After reawakening, loop counter is incremented by 1, all NPC warmth tiers are reduced by 1 (tier 1 unchanged), fish inventory is empty, and team cats are present with correct stats.
6. **AC-06**: Mid-dialogue collapse: the current dialogue block completes before the collapse sequence begins. No text is cut off.
7. **AC-07**: Mid-battle collapse: enemies retreat immediately, battle ends without rewards, collapse sequence begins.
8. **AC-08**: Early reset at Shrine shows a confirmation dialog. Selecting "No" returns to gameplay. Selecting "Yes" triggers the collapse sequence with all normal loop-end rules applied.
9. **AC-09**: Shrine is inaccessible (displays "not yet available") in loop 1. Accessible from loop 2 onward.
10. **AC-10**: Time does not advance passively. A player who leaves the game idle for 5 minutes at a node sees zero countdown change.
