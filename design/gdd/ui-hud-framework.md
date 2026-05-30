# UI/HUD Framework — GDD

*Created: 2026-05-29*
*Status: Complete — all 8 sections written*
*Layer: Foundation*
*Dependency order: #4 (no code-level upstream deps; depended on by C2, C3, C4, C5, F4, PL1, PL2)*

---

## 1. Overview

The UI/HUD Framework provides all player-facing interface elements. It owns the countdown display (always visible in the sky), the team panel (cat names, stats, affinity ❤), warmth tier indicators (shown during NPC interactions), the dialogue UI (text box with choices), the fish inventory display, the loop counter, and the pause menu. All UI is mouse-clickable with touch-friendly hit targets (≥48px for future mobile port). The framework is data-driven — other systems push data to UI components; the UI never owns game state. It is the last Foundation system — everything above it in the stack renders through it.

## 2. Player Fantasy

The UI should feel like part of the world, not a spreadsheet overlaid on it. The countdown is the dominant visual element — always there, always ticking, pale gold bleeding to white. The team panel is warm and personal — cat portraits, names, little ❤ indicators. UI elements should evoke a cat's journal or village scrapbook — cozy, handcrafted, never cold or technical. The UI's emotional job is to make the player feel informed and connected, not overwhelmed. If the player has to hunt for information, the UI is failing.

## 3. Detailed Rules

### 3.1 Countdown Display

- Always visible at top-center of screen during gameplay.
- Displays remaining time as pale gold numerals bleeding to white as time decreases.
- When time is critically low (≤10% remaining), numerals pulse gently (0.5-2.0s cycle).
- At zero: fully white, rapid pulse, then collapse sequence begins.
- The countdown is the dominant visual element — P3 made manifest.

### 3.2 Team Panel

- Toggleable via hotkey (TAB) or button in the UI chrome.
- Shows each recruited team cat with: name, portrait, stats (atk/def/spd/hp), and affinity level (❤ 1-3).
- Empty state: "No team cats yet. Explore the village to find recruits."
- Default state (MVP): closed. Player opens it to check their team.

### 3.3 Warmth Indicator

- Appears above the dialogue box during NPC interactions.
- Displays: NPC name + warmth tier as filled hearts (0-3 ❤).
- Heart fills are cumulative — tier 1 = 1 filled heart, tier 3 = 3 filled hearts.
- Indicator fades in when interaction starts, fades out when it ends.

### 3.4 Dialogue UI

- Occupies the bottom third of the screen during conversations.
- Layout: NPC name (top-left of box), NPC portrait (left side), dialogue text (center), choice buttons (bottom, 2-4 options).
- Click anywhere or press SPACE to advance text to next line.
- Choice buttons are large (≥48px tall), mouse-clickable.
- Dialogue box has a warm, semi-transparent background — readable over village art.

### 3.5 Fish Inventory

- Small icon (fish silhouette) + count number in top-right corner.
- Updates instantly on fish pickup or gift.
- Shows zero with a dimmed icon when empty (most of each loop).

### 3.6 Loop Counter

- Small indicator in top-left corner: "Loop 1", "Loop 2", etc.
- Increments at the moment of reawakening after loop transition.
- Subtle, not prominent — secondary information.

### 3.7 Pause Menu

- Triggered by ESC key or pause button in UI chrome.
- Overlays the full screen with a semi-transparent dark background.
- Options: Resume, Save, Load, Settings, Quit to Menu.
- Settings submenu: UI scale slider, text speed slider, audio volume sliders (master/music/SFX).

### 3.8 Screen Layout

Non-overlapping zones at 1280×720 minimum resolution:

| Zone | Position | Element |
|------|----------|---------|
| Top-left | 16px margin | Loop counter |
| Top-center | Centered | Countdown display |
| Top-right | 16px margin | Fish inventory |
| Right edge | Toggleable overlay | Team panel |
| Bottom third | Centered, conditional | Dialogue UI |
| Full screen | Conditional overlay | Pause menu |

## 4. Formulas

| Parameter | Value | Notes |
|-----------|-------|-------|
| UI base scale | 1.0x | Configurable 0.75x-1.5x |
| Dialogue text speed | 30 chars/sec | Instant reveal on click/SPACE |
| Minimum hit target | 48×48px | Touch-friendly future-proofing |
| Dialogue choice max | 4 options | If more choices exist, scroll |
| Countdown pulse threshold | ≤10% time remaining | Triggers pulse animation |

## 5. Edge Cases

1. **Countdown at zero**: Numerals fully white, rapid pulse (0.3s cycle) for 2 seconds, then collapse sequence triggers. UI fades out during collapse.
2. **Empty team panel**: Shows placeholder text "No team cats yet. Explore the village to find recruits." with a pawprint icon.
3. **Dialogue triggered during combat warning**: Dialogue does not open during active combat. If an NPC attempts dialogue while battle is ongoing, it queues until combat ends.
4. **UI element overlap**: The dialogue box (bottom third) takes priority over other elements. Team panel auto-closes when dialogue opens. Countdown and fish counter remain visible during dialogue.
5. **Very long NPC names**: Truncated with ellipsis after 12 characters in dialogue UI and warmth indicator.
6. **Resolution below 1280×720**: UI scales down proportionally to fit. Minimum supported: 960×540 (UI scale floor of 0.75x).

## 6. Dependencies

### Upstream
None. Foundation-level system. No code dependencies on other GDDs.

### Downstream

| System | UI Elements Used |
|--------|-----------------|
| Time/Loop System (C2) | Countdown display, loop counter |
| Auto-Battler Combat System (C4) | Team panel (stats, affinity) |
| NPC Relationship System (C3) | Warmth indicator |
| Economy/Inventory System (C5) | Fish inventory display |
| Dialogue System (F4) | Dialogue UI (text box, choices, NPC portrait) |
| Tutorial/Onboarding (PL1) | All UI elements (guided highlights) |
| Accessibility (PL2) | UI scale, text speed settings |

## 7. Tuning Knobs

| Knob | Safe Range | What It Affects |
|------|------------|-----------------|
| UI scale | 0.75x-1.5x | Overall interface size, accessibility |
| Dialogue text speed | 10-60 chars/sec | Reading comfort |
| Minimum hit target size | 44-64px | Click/tap accuracy |
| Team panel default state | open/closed | Screen clutter on game start |
| Countdown pulse speed (low time) | 0.5-2.0s per cycle | Urgency feel |
| Dialogue box opacity | 60-90% | Village visibility behind text |
| Warmth indicator fade duration | 0.2-0.5s | Transition smoothness |

## 8. Acceptance Criteria

1. **AC-01**: Countdown display is always visible during gameplay and updates in real-time as the Time/Loop System pushes time values.
2. **AC-02**: Team panel opens/closes with TAB and shows each recruited cat with correct name, portrait, stats, and affinity ❤ count.
3. **AC-03**: Warmth indicator appears above dialogue during NPC interaction with correct tier (0-3 filled hearts) matching the Relationship System's current warmth value.
4. **AC-04**: Dialogue UI displays NPC name, portrait, dialogue text, and choice buttons (when available). Click or SPACE advances text.
5. **AC-05**: Fish inventory count updates immediately (≤1 frame) when Economy System fires a fish-changed event.
6. **AC-06**: Loop counter displays correct loop number and increments on reawakening after loop transition.
7. **AC-07**: Pause menu opens with ESC, all buttons perform their labeled actions, and gameplay is suspended while paused.
8. **AC-08**: All interactive UI elements (buttons, choices, toggles) have hit targets ≥48×48px.
9. **AC-09**: No UI elements overlap or clip at 1280×720 resolution. At 960×540, UI scales proportionally without breaking layout.
10. **AC-10**: Full UI (countdown, team panel closed, fish, loop counter) renders within 50 draw calls, leaving ≥150 for the village scene.
