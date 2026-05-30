# Audio System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Presentation*
*Dependency order: #14 (leaf system — no code-level downstream deps)*

---

## 1. Overview

The Audio System manages all sound in the game: ambient village atmosphere, UI feedback sounds, battle music, and loop transition audio. It is a data-driven playback system — other systems fire audio events ("battle_started", "fish_collected", "loop_collapse"), and the Audio System plays the appropriate sound from its audio resource library. It supports layered audio (ambient base layer + situational overlays), crossfade transitions between music states, and volume mixing (master, music, SFX). There is no voice acting — the anti-pillar is preserved. The audio design philosophy is warm, atmospheric, and emotionally responsive — sound reinforces the cozy-yet-heavy tone of the village and the weight of the countdown.

## 2. Player Fantasy

Sound should make the village feel alive without demanding attention. The ambient layer is a constant, gentle presence — wind through rooftops, distant cat chatter, the soft tick of the countdown clock. The player should feel immersed, not distracted. When the countdown nears zero, the audio subtly shifts — the clock tick becomes more prominent, the ambient warmth cools. The loop collapse sequence is the audio climax: sky-crack roar, world-collapse rumble, then silence before reawakening.

Battle music should feel like the stakes rising without becoming bombastic. Each boss has a distinct theme that reflects their relationship to the narrative — the 心魔 battle track is melancholy, not aggressive. UI sounds are minimal and satisfying: a soft chime for fish pickup, a gentle click for dialogue advance, a warm tone for warmth tier increase. No sound should ever feel harsh, digital, or out of place in a cat village.

## 3. Detailed Rules

### 3.1 Audio Layers

Audio plays in three priority layers:

| Layer | Priority | Content | Behavior |
|-------|----------|---------|----------|
| **Music** | Highest | Battle themes, boss themes, loop transition score | Crossfades between tracks; one track active at a time |
| **Ambient** | Medium | Village atmosphere (wind, chatter, clock tick, day/night ambience) | Loops continuously; layered with situational variations |
| **SFX** | Lowest | UI sounds, pickup sounds, dialogue clicks, battle hits | One-shot playback; multiple SFX can play simultaneously |

### 3.2 Audio Events

Other systems fire audio events. The Audio System listens and responds:

| Event | Source System | Audio Response |
|-------|--------------|----------------|
| `loop_start` | C2 — Time/Loop | Reawakening ambient swell (2s) |
| `day_phase_change` | F7 — NPC Scheduling | Day→Night: cricket ambience fades in; Night→Day: bird ambience fades in |
| `countdown_critical` | C2 — Time/Loop | Clock tick becomes louder, more prominent in ambient mix |
| `loop_collapse_start` | C2 — Time/Loop | Sky-crack sound (low roar + glass fracture), ambient fades out |
| `loop_collapse_whiteout` | C2 — Time/Loop | Silence (1s) |
| `dialogue_advance` | F4 — Dialogue | Soft click / page-turn sound |
| `dialogue_choice_good` | F4 — Dialogue | Warm chime |
| `fish_pickup` | C5 — Economy | Soft splash / chime |
| `fish_gift` | C5 — Economy | Warm tone, slightly longer |
| `warmth_tier_up` | C3 — Relationship | Rising warm tone (pitch increases with tier: 1 low, 3 high) |
| `battle_start` | C4 — Combat | Battle theme begins (crossfade from ambient) |
| `battle_victory` | C4 — Combat | Victory sting (3s), then ambient crossfades back |
| `battle_defeat` | C4 — Combat | Somber tone (2s), then ambient crossfades back |
| `boss_phase_transition` | F5 — Boss | Dramatic hit + new phase theme layer added |
| `command_used` | C4 — Combat | Sharp meow / signal sound |
| `trace_deposited` | P1 — Traces | Soft cerulean chime (very faint) |
| `ui_button_click` | F3 — UI/HUD | Soft click |
| `pause_open` | F3 — UI/HUD | Ambient ducks −6dB |
| `pause_close` | F3 — UI/HUD | Ambient restores |

### 3.3 Music Tracks

| Track | When It Plays | Duration | Notes |
|-------|--------------|----------|-------|
| Village Day | Day phase, no battle | Loop | Warm, gentle, acoustic |
| Village Night | Night phase, no battle | Loop | Quieter, strings/pads, lullaby-like |
| Battle (small encounter) | Small encounter active | Loop | Tense but not aggressive; percussion-driven |
| Boss 1 Theme | Boss 1 active | Loop | Intimidating, rhythmic |
| Boss 2 Theme | Boss 2 active | Loop | Mysterious, layered |
| 心魔 Theme | 心魔 battle | Loop | Melancholy, piano-driven, emotional |
| Collapse Sequence | Loop collapse | Linear (~5s) | Swelling roar → crack → silence |
| True Ending | True ending resolution | Linear (~30s) | Thematic resolution, full arrangement |

Tier 1: Village Day/Night, Battle, Boss 1-2, Collapse.
Full vision: Boss 3-4, 心魔, True Ending.

### 3.4 Volume Mixing

| Bus | Default Level | Range | Notes |
|-----|--------------|-------|-------|
| Master | 100% | 0-100% | User-configurable |
| Music | 80% | 0-100% | Lower than SFX by default |
| Ambient | 60% | 0-100% | Background presence |
| SFX | 100% | 0-100% | UI and gameplay sounds |

Settings persisted via Save/Load System (F1) — audio preferences are saved globally, not per-save-slot.

### 3.5 Crossfade Rules

- Music → Music: 2.0s crossfade
- Music → Ambient (battle end): 1.5s crossfade from music to ambient
- Ambient → Music (battle start): 0.8s crossfade (quicker — battle starts urgently)
- Day → Night ambient: 3.0s crossfade (gradual, atmospheric)
- Collapse sequence: ambient hard cut to collapse audio (0s crossfade — sudden, dramatic)

### 3.6 MVP Simplifications

- Village Day ambient only (no night variant)
- Battle music: 1 track for all encounters
- No boss themes (no bosses in MVP)
- No collapse sequence audio beyond a simple rumble
- UI sounds: click, fish pickup, fish gift only
- No warmth tier up sound
- Music uses placeholder/temp tracks or simple generated loops

## 4. Formulas

| Formula | Value | Notes |
|---------|-------|-------|
| Music crossfade (standard) | 2.0s | Between music tracks |
| Music crossfade (battle start) | 0.8s | Urgent transition |
| Music crossfade (battle end) | 1.5s | Return to ambient |
| Day/night ambient crossfade | 3.0s | Gradual atmosphere shift |
| Ambient duck (pause) | −6dB | While pause menu is open |
| Collapse audio duration | ~5s | Matches collapse sequence timing |
| Collapse silence | 1.0s | During whiteout |
| SFX max simultaneous voices | 8 | Prevent audio clutter |
| Audio file format | OGG Vorbis | Godot default; small file size |
| Target total audio memory | ≤50MB | All audio assets combined |

## 5. Edge Cases

1. **Multiple SFX triggered simultaneously**: SFX play concurrently up to the max voice limit (8). Beyond 8, the oldest/lowest priority SFX is cut. UI sounds have lowest SFX priority; battle sounds have highest.
2. **Battle starts during day/night transition**: Battle music takes priority. Ambient crossfade is interrupted — ambient resumes at the correct day/night state after battle ends.
3. **Audio file missing or corrupted**: System logs an error. That audio event is silently skipped — no crash, no pop, no silence burst. The game plays without that sound.
4. **Player sets all volumes to 0**: Game functions normally. Audio events still fire internally but produce no output. No performance impact from muted audio.
5. **Loop collapse audio interrupted (rare)**: The collapse sequence is ~5s linear audio. If the game is forced to skip (debug/testing), the audio hard-cuts to the reawakening ambient. No stuck audio.
6. **Rapid battle start/end**: If the player triggers and leaves a battle quickly, the battle music crossfades in and immediately back out. The crossfade handles interruption gracefully — it crossfades from current position, not from the start of the track.
7. **Platform with no audio device**: System detects no audio output and silently disables all playback. Game runs without audio. No error messages to the player.

## 6. Dependencies

### Upstream

Audio is a leaf system — it listens to events from many systems but has no upstream code dependencies. It requires:

| Source | What Audio Needs |
|--------|-----------------|
| **Time/Loop System (C2)** | Loop start, collapse phase, countdown critical events |
| **NPC Scheduling (F7)** | Day/night phase change events |
| **Dialogue System (F4)** | Dialogue advance, good choice events |
| **Economy/Inventory (C5)** | Fish pickup, fish gift events |
| **NPC Relationship (C3)** | Warmth tier up events |
| **Auto-Battler Combat (C4)** | Battle start, victory, defeat, command used events |
| **Boss Encounter (F5)** | Boss phase transition events |
| **Traces Visual Feedback (P1)** | Trace deposited events |
| **UI/HUD Framework (F3)** | UI button click, pause open/close events |
| **Save/Load System (F1)** | Audio volume settings persistence |
| **True Ending (F6)** | True ending sequence event |

### Downstream

None — Audio is a pure output system. No gameplay system depends on audio for mechanical data.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Master volume | 100% | 0-100% | Overall loudness |
| Music volume | 80% | 0-100% | Music relative to other layers |
| Ambient volume | 60% | 0-100% | Background atmosphere presence |
| SFX volume | 100% | 0-100% | UI and gameplay sound clarity |
| Music crossfade duration | 2.0s | 1.0-4.0s | Smoothness of music transitions |
| Ambient crossfade duration | 3.0s | 1.5-5.0s | Atmosphere shift subtlety |
| Ambient duck amount (pause) | −6dB | −3dB to −12dB | How much pause menu silences the world |
| Max SFX voices | 8 | 4-16 | Audio clutter vs. richness |
| Countdown critical tick volume boost | +3dB | +2dB to +6dB | Urgency perception |

## 8. Acceptance Criteria

1. **AC-01**: Village ambient audio loops continuously during gameplay and crossfades between day and night variants (3.0s transition).
2. **AC-02**: Battle music begins when a battle encounter starts (0.8s crossfade) and returns to ambient after victory or defeat (1.5s crossfade).
3. **AC-03**: UI sounds play on: fish pickup (soft chime), fish gift (warm tone), dialogue advance (soft click), and button press (soft click).
4. **AC-04**: Loop collapse sequence plays the full ~5s collapse audio (roar → crack → silence) synchronized with the visual collapse phases.
5. **AC-05**: Pause menu ducks ambient audio by −6dB while open and restores it when closed.
6. **AC-06**: Volume settings (master, music, ambient, SFX) are user-configurable in the Settings menu and persist across sessions via Save/Load.
7. **AC-07**: Missing audio files do not crash the game — the event is silently skipped with a logged error.
8. **AC-08**: Boss phase transitions play a dramatic hit + layer the new phase theme into the music mix.
9. **AC-09**: Multiple simultaneous SFX do not exceed the max voice count (8). Beyond the limit, oldest/lowest-priority sounds are cut.
10. **AC-10**: No voice acting anywhere — the anti-pillar is preserved.