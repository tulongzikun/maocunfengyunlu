# Accessibility — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Polish*
*Dependency order: #17 (depends on F3 UI/HUD)*

---

## 1. Overview

The Accessibility system defines the accessibility features available to players — text scaling, colorblind modes, input remapping, and readability options. It is not a separate system in the code sense but a set of requirements and configurations that all UI and gameplay systems must support. Accessibility features are accessed through the Settings menu (F3 — UI/HUD Framework §3.7). The guiding principle: every accessibility feature should make the game more playable without compromising the visual and emotional design. Accessibility is not an afterthought — it is a first-class design constraint.

## 2. Player Fantasy

Accessibility features should be invisible to players who don't need them and seamless for players who do. A colorblind player should never have to think "I can't tell which trace is which" — the game should already support their vision. A player who needs larger text should never squint at dialogue. Accessibility is not "easy mode" — it is equal access to the same emotional experience. The village, the countdown, the warmth mechanics, and the Traces marks should all be readable by as many players as possible, regardless of visual, auditory, or motor differences.

## 3. Detailed Rules

### 3.1 Text Scaling

- UI text scale: configurable 0.75x–2.0x (was 0.75x–1.5x in F3; expanded to 2.0x)
- Dialogue text scale: independently configurable (0.75x–2.5x) — dialogue is the primary reading surface
- All text must remain readable at maximum scale — no clipping, no overflow hidden
- Default: 1.0x (1280×720 baseline)
- Minimum supported resolution with 2.0x scale: 1280×720 (text reflows, does not truncate)

### 3.2 Colorblind Modes

Three modes, selectable in Settings:

| Mode | What It Changes | Implementation |
|------|----------------|----------------|
| **Protanopia** (red-blind) | Countdown (gold→white) shifts to blue→white; cerulean Traces shift to amber | Shader-based palette swap on UI + Traces layers only |
| **Deuteranopia** (green-blind) | Warm earth palette shifts slightly cooler; Traces cerulean stays (blue is distinguishable) | Shader-based palette swap on environment layer |
| **Tritanopia** (blue-blind) | Cerulean Traces shift to warm gold (inverted from normal); countdown stays gold→white | Shader-based palette swap on Traces layer only |

Colorblind modes do NOT affect gameplay screenshots, save file thumbnails, or the game's art assets on disk — only the runtime display.

### 3.3 High Contrast Mode

- Option: "High Contrast UI" toggle
- When enabled: UI backgrounds become fully opaque (was semi-transparent); text gains a 2px dark outline; warmth hearts gain a dark border; fish counter background darkens
- Does not affect village art — only UI elements

### 3.4 Input Remapping

- Keyboard controls remappable:
  - Advance dialogue: SPACE (default) → any key
  - Pause: ESC (default) → any key
  - Team panel: TAB (default) → any key
- Mouse-only mode: all keyboard actions available via on-screen buttons (dialogue advance = click dialogue box; pause = click pause button; team panel = click team button)
- No gamepad support for MVP (Tier 1+ consideration)
- Touch support: all hit targets ≥48px already (per F3 §3.8) — touch is future-proofed but not implemented in initial release

### 3.5 Text Readability

- Dialogue text speed: configurable 10-60 chars/sec (default 30, per F3)
- Font: sans-serif, clear legibility at small sizes. No decorative fonts for body text.
- Line spacing: 1.5× for dialogue text
- NPC name labels: high contrast against dialogue box background
- No text smaller than 12px at 1.0x scale (scales proportionally)

### 3.6 Audio Accessibility

- All audio cues have visual equivalents:
  - Countdown critical → UI pulse (already in F3)
  - Battle events → battle log text (hit/miss/damage numbers)
  - Fish pickup/gift → toast animation (already in C5)
  - Warmth tier up → warmth indicator animation
- Subtitles: not applicable (no voice acting — anti-pillar)
- Mono audio option: collapses stereo to mono for single-ear players

### 3.7 Motion Reduction

- Option: "Reduce Motion" toggle
- When enabled:
  - Screen shake disabled (loop collapse, battle impacts)
  - Parallax scrolling reduced by 50%
  - UI pulse animation slowed to 2.0s cycle (was 0.5-2.0s)
  - Fade-in animations halved in duration (0.5s instead of 1.0s)
- Does not affect: traversal animations (essential for P2 cat perspective), battle attack animations (essential for combat readability)

### 3.8 MVP Simplifications

- Text scaling: 0.75x–1.5x (2.0x deferred)
- Colorblind modes: None (deferred to Tier 1)
- High contrast mode: None (deferred to Tier 1)
- Input remapping: Keyboard only (mouse-only mode deferred)
- Audio accessibility: Mono option only
- Motion reduction: Disable screen shake only

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Text scale range | 0.75x–1.5x (MVP), 0.75x–2.0x (Tier 1) | UI and dialogue independently configurable |
| Minimum font size | 12px at 1.0x | Scales with text scale setting |
| Hit target minimum | 48×48px | Per F3 — already touch-friendly |
| Dialogue line spacing | 1.5× | Improves readability |
| Colorblind palette swap | Shader-based | Runtime only, no asset changes |
| Mono audio | Stereo → mono downmix | Single toggle |

## 5. Edge Cases

1. **Player sets text to 2.0x at 960×540 resolution**: Text reflows — some UI elements may stack vertically instead of horizontally. The UI layout is tested at this extreme to ensure no text is lost. Minimum guarantee: all text is readable; some cosmetic layout shifts are acceptable.
2. **Colorblind mode + High Contrast mode simultaneously**: Both apply — palette swap shader + opaque UI. They are designed to compose without visual conflict.
3. **Motion reduction + Battle**: Reduce Motion disables screen shake but keeps battle animations at full speed. The battle log provides text feedback for events that shake would communicate.
4. **All accessibility options enabled at once**: Game must remain playable and not visually broken. This is a required test case.
5. **Accessibility settings in screenshots/video capture**: Settings are per-save-file and do not affect external outputs (screenshots capture the rendered frame including accessibility modifications). This is intentional — accessibility is part of the experience, not hidden.

## 6. Dependencies

### Upstream

| System | What PL2 Needs From It |
|--------|----------------------|
| **UI/HUD Framework (F3)** | Settings menu panel; UI text scale hook; all UI element styling |
| **Save/Load System (F1)** | Persist all accessibility settings per save file |

### Downstream

PL2 defines requirements, not code interfaces. Systems that must comply:

| System | Accessibility Requirement |
|--------|--------------------------|
| **UI/HUD Framework (F3)** | Text scaling, high contrast mode, hit targets, font sizing |
| **Dialogue System (F4)** | Dialogue text scaling, line spacing, text speed |
| **Traces Visual Feedback (P1)** | Colorblind palette swap on Traces layer |
| **Audio System (P2)** | Mono audio option; visual equivalents for audio cues |
| **Cat Animation (P3)** | Motion reduction (screen shake, parallax, pulse) |

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| UI text scale | 1.0x | 0.75x–2.0x | All UI text size |
| Dialogue text scale | 1.0x | 0.75x–2.5x | Dialogue box text size |
| Dialogue text speed | 30 chars/sec | 10-60 | Reading pace |
| Minimum font size | 12px | 10-14px | Baseline readability |
| Hit target minimum | 48px | 44-64px | Click/tap accuracy |
| Line spacing | 1.5× | 1.2×–2.0× | Text density and readability |
| Motion reduction parallax | 50% | 25-75% | Background movement when reduced |
| Reduced motion fade duration | 0.5s | 0.3-0.8s | Animation speed when reduced |

## 8. Acceptance Criteria

1. **AC-01**: Text scale setting (0.75x–1.5x) changes all UI text size in real-time without requiring a restart.
2. **AC-02**: Dialogue text scale is independently configurable from UI text scale.
3. **AC-03**: All interactive UI elements maintain ≥48×48px hit targets regardless of text scale setting.
4. **AC-04**: Keyboard input remapping works — reassigned keys function correctly in gameplay.
5. **AC-05**: Mono audio option collapses stereo output to mono. Visual equivalents exist for all critical audio cues (countdown pulse, battle log, toast animations).
6. **AC-06**: Reduce Motion disables screen shake during combat and loop collapse. Pulse animation slows to 2.0s cycle.
7. **AC-07**: All accessibility settings persist across game sessions via Save/Load.
8. **AC-08**: No text is clipped, truncated, or unreadable at any combination of text scale (0.75x–1.5x) and resolution (1280×720 minimum).
9. **AC-09**: High contrast mode makes all UI backgrounds fully opaque and adds text outlines without affecting village art.
10. **AC-10**: Colorblind modes apply palette swaps correctly — cerulean Traces marks are visually distinct from warm earth backgrounds in all three modes.