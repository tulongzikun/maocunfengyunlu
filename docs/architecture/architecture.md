# 猫村物语 (Cat Village Story) — Master Architecture

## Document Status
- **Version**: 1.0
- **Last Updated**: 2026-05-30
- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: 2D (Compatibility renderer)
- **Physics**: GodotPhysics2D
- **GDDs Covered**: 17 systems (F1-F3, C1-C5, F4-F7, P1-P3, PL1-PL2)
- **ADRs Referenced**: None yet (22 planned, 0 written)
- **Technical Director Sign-Off**: 2026-05-30 — APPROVED WITH CONCERNS
- **Lead Programmer Feasibility**: FEASIBLE WITH CONCERNS — 5 conditions (see below)

### Sign-Off Conditions

1. **Signal ordering** (ADR-0001): Add signal priority or multi-phase protocol to EventBus. `loop_start` consumers need ordered execution: `reset_affection()` before `convert_warmth()`. Resolve in ADR-0001.
2. **Autoloads vs DI** (ADR-0007): Clarify that autoloads expose their state via signals (not direct mutation calls), satisfying the spirit of DI. Update coding standards to explicitly allow autoload singletons for game state managers. Resolve in ADR-0007.
3. **Scene loading strategy** (ADR-0003): Add district scene lifecycle — how nodes are instantiated, pooled, and freed. Should specify `PackedScene` loading pattern for district transitions. Resolve in ADR-0003.
4. **Localization architecture** (new ADR): Add string externalization strategy. Dialogue stored as resource keys with locale-specific text files. Defer implementation to Tier 1, but architect the hook now. Add to ADR-0009 (Dialogue Resource Format).
5. **HIGH RISK engine verification** (ADR-0013, ADR-0015): Before implementing Traces or Accessibility, run a spike to verify ShaderMaterial glow API and AccessKit node properties in Godot 4.6. Flagged in QQ-01 and QQ-02.

## Engine Knowledge Gap Summary
- **HIGH RISK**: Shader materials (P1 Traces), AccessKit API (PL2 Accessibility)
- **MEDIUM RISK**: FileAccess return types (F1 Save/Load), AudioServer API (P2 Audio)
- **LOW RISK**: 2D Scene/Node, Signals, Resources, Input, AnimationPlayer

---

## Module Ownership

### Foundation Layer

#### F2 — Scene/World Manager
- **Autoload**: `SceneManager` (singleton)
- **Owns**: Node graph data (all nodes, edges, tags, positions, vertical layers), district definitions, camera state, discovered node list, district transition state
- **Exposes**: `get_adjacent_nodes(node_id)`, `get_node_tags(node_id)`, `get_edge_type(from, to)`, `is_node_accessible(node_id, player)`, `get_district(node_id)`, `get_camera_bounds(district)`, `discover_node(node_id)`, `node_entered(node_id)` signal, `district_changed(from, to)` signal
- **Consumes**: Nothing (leaf in dependency graph — no upstream systems)
- **Engine APIs**: Node2D (positioning), Camera2D (smoothing, zoom, bounds), Resource (node graph data stored as .tres), Tween (camera transitions) — all LOW RISK
- **Data format**: Node graph stored as `NodeGraphData` Resource (.tres) with arrays of `NodeData` and `EdgeData` resources

#### F1 — Save/Load System
- **Autoload**: `SaveManager` (singleton)
- **Owns**: Save file I/O, serialization/deserialization of all persistent state, auto-save trigger at loop transition, save slot management
- **Exposes**: `save_game(slot)`, `load_game(slot)`, `auto_save()`, `delete_save(slot)`, `get_save_slots()`, `save_completed` signal, `load_completed` signal
- **Consumes**: All persistence-relevant state from C3 (warmth, affection, memory flags), C4 (team cats, XP), C5 (fish inventory), C2 (loop count), F2 (discovered nodes), P1 (traces marks), F6 (phase flags, clue flags), PL1 (tutorial flags), PL2 (accessibility settings), F3 (volume settings from P2)
- **Engine APIs**: FileAccess (MEDIUM RISK — return types changed in 4.4), ResourceSaver/ResourceLoader, ConfigFile (.ini for settings), DirAccess — verify `FileAccess.get_open_error()` vs `FileAccess.file_exists()` pattern in 4.4+
- **Save format**: Single `.sav` Resource file per slot containing serialized `GameState` Resource with sub-resources per system

#### Event Bus
- **Autoload**: `EventBus` (singleton — architectural infrastructure, not a GDD system)
- **Owns**: Signal registry, event routing between modules
- **Exposes**: Named signals for all cross-system events (see Phase 3 Data Flow for complete list)
- **Consumes**: Nothing
- **Engine APIs**: Node (signals only) — LOW RISK

### Core Layer

#### C1 — Movement System
- **Autoload**: `MovementManager` (singleton)
- **Owns**: Player position (current node), traversal state (idle/moving/transition), pathfinding on node graph
- **Exposes**: `move_to_node(node_id)`, `get_current_node()`, `get_current_district()`, `can_reach_node(node_id)`, `traversal_started(from, to, edge_type)` signal, `traversal_completed(node_id)` signal, `node_reached(node_id)` signal
- **Consumes**: F2 (node graph, edge types, visibility, accessibility), P3 (triggers animation states)
- **Engine APIs**: Tween (traversal animation along edge path), Node2D (position) — LOW RISK
- **Traversal logic**: Free movement (no time cost). Edge type determines animation: walk (linear), leap (arc), climb (vertical linear with pause), squeeze (narrow path). Duration per edge: walk 0.4s, leap 0.3s, climb 0.8s, squeeze 0.5s

#### C2 — Time/Loop System
- **Autoload**: `TimeManager` (singleton)
- **Owns**: Current time units (100 → 0), loop count, countdown critical threshold (≤10), day/night cycle delegation, loop transition (collapse → reawaken sequence), time-cost registry
- **Exposes**: `get_time_remaining()`, `get_loop_count()`, `get_years_display()`, `consume_time(units)`, `is_critical()`, `time_advanced(units)` signal, `countdown_critical` signal, `loop_collapse_start` signal, `loop_collapse_whiteout` signal, `loop_start` signal, `loop_count_changed(count)` signal
- **Consumes**: F3 (updates countdown display on time_advanced), F7 (day/night phase calculation), F1 (triggers auto-save at loop_end), C3 (triggers warmth conversion and affection reset at loop end), C4 (triggers enemy escalation at loop start), C5 (triggers fish clear at loop start), P1 (accumulates traces at loop end), F5 (triggers boss escalation), F6 (checks phase conditions at loop milestones)
- **Engine APIs**: Timer (internal tick), Tween (collapse animation timing) — LOW RISK

#### C3 — NPC Relationship System
- **Autoload**: `RelationshipManager` (singleton)
- **Owns**: Per-NPC data: cumulative warmth (0-3), per-loop affection (0-10), recruitment state, memory fragment tier, NPC gratitude fish flag
- **Exposes**: `get_warmth(npc_id)`, `get_affection(npc_id)`, `add_affection(npc_id, amount, source)`, `is_recruited(npc_id)`, `get_memory_tier(npc_id)`, `get_npc_affection_sources(npc_id)`, `affection_changed(npc_id, amount, source)` signal, `warmth_tier_up(npc_id, new_tier)` signal, `warmth_tier_down(npc_id, new_tier)` signal, `npc_recruited(npc_id)` signal, `loop_end_warmth_conversion()` (called by C2)
- **Consumes**: C2 (loop count for memory fragment tier, loop-end trigger), F1 (persistence), F4 (good dialogue choice → +1 affection), C5 (fish gift → +2 affection), C4 (battle alongside → +2 affection), F6 (银定亲王 special affection sources)
- **Engine APIs**: Resource (.tres per NPC for warmth/affection data) — LOW RISK

#### C4 — Auto-Battler Combat System
- **Autoload**: `CombatManager` (singleton)
- **Owns**: Team cat roster (identity, archetype, base stats, XP, stat bonuses, Wounded status), battle state (active enemies, formation, phase, command cooldowns), enemy type definitions, archetype definitions, XP curves, enemy escalation multipliers
- **Exposes**: `start_battle(encounter_data)`, `get_team_roster()`, `add_team_cat(npc_id)`, `remove_team_cat(npc_id)`, `get_cat_stats(npc_id)`, `issue_command(command_type, target)`, `battle_started` signal, `battle_victory` signal, `battle_defeat` signal, `cat_wounded(npc_id)` signal, `cat_attack(cat_id, target_id, damage)` signal, `xp_gained(npc_id, amount)` signal
- **Consumes**: C2 (time cost: 10 units small / 20 large / 30 boss), C3 (recruitment status, warmth tier → stat bonus), F2 (battle-trigger nodes), F3 (team panel, pre-battle screen), P3 (battle animations), F5 (boss battle data)
- **Engine APIs**: Timer (SPD-based attack intervals, shared command cooldown) — LOW RISK
- **Battle resolution**: Autonomous — each cat attacks on its SPD interval. Commands (retreat/focus-fire/reposition) are on shared cooldown. Math is pure GDScript, no physics/rendering dependency.

#### C5 — Economy/Inventory System
- **Autoload**: `EconomyManager` (singleton)
- **Owns**: Fish inventory (current count, max 5), fish spawn state per node per loop, tutorial fish flag (`received_tom_fish`), NPC gratitude fish state
- **Exposes**: `get_fish_count()`, `add_fish(amount, source)`, `gift_fish(npc_id)`, `can_gift_fish(npc_id)`, `fish_picked_up(amount, source)` signal, `fish_gifted(npc_id, amount)` signal, `inventory_full` signal
- **Consumes**: C2 (fish clear at loop start), F1 (persistence), F2 (fish-spawn nodes), F3 (fish counter display), C3 (receives +2 affection on gift, warmth≥2 gratitude fish), PL1 (tutorial fish grant)
- **Engine APIs**: None (data-only) — LOW RISK

...(Core continued)...

### Feature Layer

#### F4 — Dialogue System
- **Scene-attached**: `DialogueBox` (CanvasLayer node, instantiated per conversation)
- **Owns**: Dialogue resource files per NPC (.tres), dialogue selection logic (loop tier + warmth tier + condition filters), active conversation state (current node, history stack)
- **Exposes**: `start_dialogue(npc_id)`, `advance_dialogue()`, `select_choice(choice_index)`, `get_available_choices()`, `dialogue_started(npc_id)` signal, `dialogue_ended(npc_id)` signal, `dialogue_advanced(line_index)` signal, `choice_selected(choice_id)` signal
- **Consumes**: C2 (loop tier: 1/2-3/4+, time cost 1 unit/advance), C3 (warmth tier, affection score), F3 (dialogue box UI rendering), PL1 (tutorial dialogue override)
- **Engine APIs**: Resource (.tres per NPC dialogue file), RichTextLabel (text rendering) — LOW RISK

#### F5 — Boss Encounter System
- **Scene-attached**: Extends C4 battle with boss-specific logic
- **Owns**: Boss definitions (stats, phases, abilities, HP thresholds, telegraph timing), boss defeat flags (persistent), unique drop tracking (once-ever), boss escalation multipliers (per gate)
- **Exposes**: `start_boss_encounter(boss_id)` (extends C4's start_battle with boss data), `get_boss_phase(boss_id)`, `boss_phase_transition(boss_id, new_phase)` signal, `boss_defeated(boss_id)` signal
- **Consumes**: C4 (battle framework, team management, commands), C2 (loop gate, time cost 30 units), C3 (warmth 2+ NPC access for Boss 2), F6 (boss victory flags for true ending), F2 (boss-trigger nodes)
- **Engine APIs**: Timer (phase transition timing, telegraph visibility) — LOW RISK

#### F6 — True Ending/Progression System
- **Autoload**: `ProgressionManager` (singleton)
- **Owns**: Phase 1/2 unlock state, clue fragment inventory, boss victory count, ending state (normal/phase1/true), 银定亲王 special affection track, 心魔 battle state
- **Exposes**: `get_ending_state()`, `get_clue_count()`, `add_clue(clue_id)`, `check_phase1_conditions()`, `check_phase2_conditions()`, `get_yingding_affection()`, `clue_discovered(clue_id)` signal, `phase1_unlocked` signal, `phase2_unlocked` signal, `true_ending_triggered` signal
- **Consumes**: C3 (橘云 warmth=3, key NPCs warmth≥2), C4 (boss victories ≥3), F5 (boss defeat flags), C2 (loop count ≥3), F4 (银定亲王 dialogue)
- **Engine APIs**: None (data-only condition checking) — LOW RISK

#### F7 — NPC Scheduling System
- **Autoload**: `ScheduleManager` (singleton)
- **Owns**: Day/night cycle calculation (day_number, is_night), NPC schedule tables (14 slots per NPC), NPC position resolution per time, conditional overrides
- **Exposes**: `get_current_day()`, `is_night()`, `get_npc_position(npc_id)`, `get_npcs_at_node(node_id)`, `day_changed(day_number)` signal, `phase_changed(is_night)` signal, `npc_moved(npc_id, new_node)` signal
- **Consumes**: C2 (time units for day/phase calculation), F2 (npc-present nodes)
- **Engine APIs**: None (pure calculation on C2's time_units) — LOW RISK

### Presentation Layer

#### F3 — UI/HUD Framework
- **Autoload**: `UIManager` (CanvasLayer root)
- **Owns**: HUD layout (countdown display, loop counter, fish counter, team panel toggle), dialogue box, settings menu, pause menu, toast notifications, warmth indicator, team panel, pre-battle screen
- **Exposes**: `update_countdown(years)`, `update_fish_count(count)`, `update_loop_count(count)`, `show_dialogue_box(npc_id, text)`, `hide_dialogue_box()`, `show_toast(message)`, `open_pause_menu()`, `open_settings()`, `open_team_panel()`, `update_warmth_indicator(npc_id, warmth, affection)`, `ui_button_click` signal, `pause_opened` signal, `pause_closed` signal
- **Consumes**: C2 (countdown display, loop count), C5 (fish counter), C3 (warmth indicator), F4 (dialogue box content), C4 (team panel, pre-battle screen), PL1 (tutorial tooltips), PL2 (text scaling, high contrast, font sizing)
- **Engine APIs**: CanvasLayer, Control nodes (VBoxContainer/HBoxContainer/GridContainer/Panel/MarginContainer), Label, RichTextLabel, Button, TextureRect (icons), ColorRect (backgrounds), Theme (styling) — LOW RISK. ⚠️ PL2 AccessKit integration is HIGH RISK (new in 4.5)

#### P1 — Traces Visual Feedback System
- **Scene-attached**: `TracesRenderer` (Node2D, renders trace marks on village nodes)
- **Owns**: Trace data per node (type, warmth tier at deposit, saturation, timestamp), cerulean (#2B7FB0) shader material, trace visual assets (5 types), fade-in animation state
- **Exposes**: `deposit_trace(node_id, trace_type, warmth_tier)`, `get_traces_at(node_id)`, `get_all_traces()`, `trace_deposited(node_id, trace_type)` signal
- **Consumes**: C3 (warmth tier for saturation), C2 (loop context for milestone traces), F6 (ending-related trace types), F1 (persistence — traces never reset)
- **Engine APIs**: ⚠️ HIGH RISK — ShaderMaterial (glow rework in 4.6, shader texture type changes in 4.4). Use `shader_type canvas_item;` for 2D. Verify `hint_color` and `uniform` declarations unchanged in 4.4+. Node2D (positioning sprites at node locations), AnimationPlayer (fade-in) — LOW RISK.

#### P2 — Audio System
- **Autoload**: `AudioManager` (singleton)
- **Owns**: Audio bus configuration (Master/Music/Ambient/SFX), audio resource library (.ogg files), playback state, volume settings, crossfade state, music track queue
- **Exposes**: `play_music(track_id)`, `play_sfx(sfx_id)`, `set_volume(bus, level)`, `crossfade_music(to_track, duration)`, `duck_ambient(dB)`, `restore_ambient()`, `set_mono_mode(enabled)`
- **Consumes**: Events from C2, C3, C4, C5, F3, F4, F5, F6, P1, F7 (see Phase 3 data flow), F1 (volume persistence), PL2 (mono audio option)
- **Engine APIs**: ⚠️ MEDIUM RISK — AudioStreamPlayer (verify OGG Vorbis unchanged), AudioServer (bus management). `AudioServer.get_bus_index()`, `AudioServer.set_bus_volume_db()` — verify API in 4.6. AudioStreamPlayer2D for positional SFX at nodes.

#### P3 — Cat Animation System
- **Scene-attached**: `CatAnimator` (AnimatedSprite2D, one per visible cat)
- **Owns**: Animation frames (10 states × 4-6 frames), animation state machine, idle variation selection, coat pattern sprites, accessories overlay
- **Exposes**: `play_state(cat_id, state)`, `play_emote(cat_id, emote)`, `set_coat_pattern(cat_id, pattern)`, `set_accessory(cat_id, accessory_id)`, `set_wounded(cat_id, enabled)`, `animation_completed(cat_id, state)` signal
- **Consumes**: C1 (traversal events → walk/leap/climb/squeeze), C4 (battle events → battle_idle/battle_attack/wounded), C3 (warmth tier up → happy_hop emote, warmth 2+ → slow_blink, warmth 2+ → cerulean sheen overlay), C5 (fish gift → happy_hop), F7 (day/night → sleep emote at night)
- **Engine APIs**: AnimatedSprite2D, SpriteFrames resource, AnimationPlayer — LOW RISK

#### PL1 — Tutorial/Onboarding
- **Autoload**: `TutorialManager` (singleton)
- **Owns**: Tutorial flag state (7 flags), Old Tom dialogue triggers, discovery tooltip triggers, tutorial fish grant state
- **Exposes**: `is_tutorial_complete(flag)`, `set_tutorial_flag(flag)`, `trigger_tutorial_moment(moment_id)`, `tutorial_moment_triggered(moment_id)` signal
- **Consumes**: C1 (first traversal completion), C2 (loop count, collapse sequence), F3 (tooltip display, team panel flash), F4 (Old Tom dialogue trees), C5 (tutorial fish grant), C3 (first recruitment event), C4 (first battle trigger), F1 (flag persistence)
- **Engine APIs**: None (triggers other systems) — LOW RISK

#### PL2 — Accessibility
- **Autoload**: `AccessibilityManager` (singleton)
- **Owns**: Accessibility settings (text scale, dialogue text scale, colorblind mode, high contrast, input remapping, mono audio, reduce motion), per-save persistence
- **Exposes**: `get_text_scale()`, `get_dialogue_text_scale()`, `get_colorblind_mode()`, `is_high_contrast()`, `is_motion_reduced()`, `is_mono_audio()`, `get_remapped_key(action)`, `accessibility_setting_changed(setting, value)` signal
- **Consumes**: F1 (settings persistence), F3 (applies text scaling, high contrast, colorblind shader, hit targets, font sizing), F4 (dialogue text scaling), P1 (colorblind palette swap on Traces layer), P2 (mono audio), P3 (motion reduction), InputMap (key remapping)
- **Engine APIs**: ⚠️ HIGH RISK — AccessKit integration (new in Godot 4.5). Verify `AccessibleNode` and `Accessible.canvas_item_set_accessibility()` API. Standard Control node properties (theme override, minimum size) — LOW RISK.

```
┌──────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                          │
│  F3 UI/HUD  │  P1 Traces  │  P2 Audio  │  P3 Animation      │
│  PL1 Tutorial  │  PL2 Accessibility                         │
├──────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                               │
│  F4 Dialogue  │  F5 Boss  │  F6 True Ending  │  F7 Schedule │
├──────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                  │
│  C1 Movement  │  C2 Time/Loop  │  C3 Relationship           │
│  C4 Combat    │  C5 Economy                                  │
├──────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                            │
│  F2 Scene/World  │  F1 Save/Load  │  Event Bus              │
├──────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                              │
│  Godot 4.6 Engine API  │  Windows D3D12  │  Input/File I/O  │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. Frame Update Path

```
Each Frame:
  Input.check()           → Mouse click on adjacent node?
    ↓ (if yes)
  C1.move_to_node(id)     → Start traversal tween (free, no time cost)
    ↓
  P3.play_state(cat,walk) → AnimatedSprite2D plays walk frames
    ↓
  F2.Camera2D.position    → Smooth follow player cat position
    ↓
  Render                  → Godot draws scene tree (≤200 draw calls)
```

Time advances only on player action (dialogue, battle, gifting) — not on frames. The frame loop is purely visual during idle and traversal.

### 2. Event/Signal Path

All cross-system communication flows through `EventBus` signals. Direct method calls only for synchronous queries (getters).

#### Time/Loop Events (C2)
```
C2.time_advanced(units)           → F3.update_countdown(), F7.recalc_phase()
C2.countdown_critical             → F3.pulse_animation(), P2.boost_tick_volume(+3dB)
C2.loop_collapse_start            → P2.play_collapse_audio(5s), F3.collapse_effects()
C2.loop_collapse_whiteout         → P2.silence(1s), F3.whiteout()
C2.loop_start                     → C3.reset_affection(), C3.convert_warmth(),
                                    C4.escalate_enemies(), C5.clear_fish(),
                                    P2.reawakening_ambient(), F1.auto_save()
C2.loop_count_changed(count)      → F6.check_phase_conditions(), PL1.update_loop_tone()
```

#### Relationship Events (C3)
```
C3.affection_changed(npc,amt,src) → F3.update_warmth_indicator()
C3.warmth_tier_up(npc_id, tier)   → P1.deposit_trace(), P3.happy_hop(),
                                    F4.unlock_dialogue(), P2.warmth_tone(tier),
                                    C4.recalc_team_stats()
C3.npc_recruited(npc_id)          → C4.add_team_cat(), F3.flash_team_panel(),
                                    P1.deposit_sigil(), PL1.check_recruitment()
```

#### Combat Events (C4)
```
C4.battle_started                 → C2.consume_time(10|20|30), P2.battle_music(0.8s),
                                    F3.pre_battle_screen(), PL1.check_battle()
C4.cat_attack(cat,tgt,dmg)        → P3.attack_anim(), F3.battle_log()
C4.cat_wounded(npc_id)            → P3.set_wounded(true), F3.update_team_panel()
C4.battle_victory                 → C3.add_affection(team,+2), C4.distribute_xp(),
                                    P2.ambient(1.5s), F3.victory_screen(),
                                    F6.check_boss_count()
C4.battle_defeat                  → C4.apply_wounded(), P2.defeat_tone(2s),
                                    P2.ambient(1.5s)
```

#### Economy Events (C5)
```
C5.fish_picked_up(amt,src)        → F3.update_fish(), F3.toast("+1 Fish"), P2.chime()
C5.fish_gifted(npc_id,amt)        → C3.add_affection(npc,+2,gift), F3.update_fish(),
                                    F3.toast("-1 Fish"), P2.warm_tone(),
                                    P3.happy_hop(), F4.gift_dialogue(),
                                    PL1.check_first_gift()
C5.inventory_full                 → F3.toast("Can't carry more"), P3.tail_flick()
```

#### Scheduling Events (F7)
```
F7.day_changed(day)               → F3.update_day_display()
F7.phase_changed(is_night)        → F2.update_accessibility(), P3.sleep_eligible(),
                                    P2.ambient_crossfade(day/night, 3.0s)
F7.npc_moved(npc_id, node)        → F2.update_npc_position()
```

### 3. Save/Load Path

```
SAVE (auto-save at loop transition, or manual from pause menu):
  1. SaveManager.collect_game_state():
     a. Query each manager for serializable state
     b. Package into GameState Resource
     c. ResourceSaver.save("user://save_slot_%d.sav" % slot, game_state)
  2. Fire save_completed signal

LOAD (main menu or auto-load on start):
  1. SaveManager.load_game_state(slot):
     a. ResourceLoader.load(path) → GameState Resource
     b. Distribute to each manager via their load_state(dict) method
     c. Managers rebuild runtime state from loaded data
     d. Fire load_completed signal
  2. SceneManager: restore camera to player's last node
  3. UIManager: rebuild HUD from all managers' current state
```

### 4. Initialization Order (Boot Sequence)

```
  1. Godot autoloads registered (project.godot):
     EventBus → SaveManager → SceneManager → TimeManager →
     MovementManager → RelationshipManager → CombatManager →
     EconomyManager → ScheduleManager → UIManager →
     AudioManager → TutorialManager → AccessibilityManager →
     ProgressionManager

  2. EventBus._ready()          → Register all known signals
  3. SceneManager._ready()      → Load node graph from NodeGraphData.tres
  4. SaveManager._ready()       → Scan user:// for save files
  5. UIManager._ready()         → Build HUD CanvasLayer shell
  6. AudioManager._ready()      → Configure buses, load .ogg library

  7. IF save exists:  SaveManager.load(slot) → distribute → rebuild
  8. ELSE (new game): TimeManager=100 units, TutorialManager=all false,
                       SceneManager=BonfireGround, loop_count=1

  9. CatAnimator (lazy)         → Load player sprite, play idle
  10. ScheduleManager._ready()  → Resolve NPC positions for time=100
  11. EventBus.fire(loop_start) → Reawakening ambient, countdown begins
  12. READY
```

---

## Technical Requirements Baseline

Extracted from 17 GDDs | 62 total requirements

### Foundation Layer

| Req ID | System | Requirement | Domain |
|--------|--------|-------------|--------|
| TR-f2-001 | Scene/World | Node graph data structure: nodes (2D pos, layer, tags) + edges (type, visibility conditions) | Data |
| TR-f2-002 | Scene/World | 44-66 total nodes across 3 districts, 2 vertical layers per district | Rendering |
| TR-f2-003 | Scene/World | Camera: 2D smooth follow, zoom out at high-level nodes, bounded to current district | Rendering |
| TR-f2-004 | Scene/World | 10 interaction zone tags queryable by downstream systems at runtime | Query |
| TR-f2-005 | Scene/World | District transition: camera pan + path traversal animation, ≤1.5s | Rendering |
| TR-f2-006 | Scene/World | Node visibility: adjacent only, hidden-until-discovered, loop-gated, warmth-gated | Query |
| TR-f2-007 | Scene/World | Performance: ≤200 draw calls per frame in current district | Performance |
| TR-f1-001 | Save/Load | Single .sav Resource file per slot, all persistent state serialized | Data |
| TR-f1-002 | Save/Load | Auto-save fires at loop transition, completes before reawakening cutscene | Timing |
| TR-f1-003 | Save/Load | FileAccess API — MEDIUM RISK (return types changed in Godot 4.4) | Engine |
| TR-f1-004 | Save/Load | Save slot management: create, load, delete, list slots | Data |

### Core Layer

| Req ID | System | Requirement | Domain |
|--------|--------|-------------|--------|
| TR-c1-001 | Movement | Traversal along edges: walk (0.4s), leap (0.3s arc), climb (0.8s), squeeze (0.5s) | Timing |
| TR-c1-002 | Movement | Movement is free — no time unit cost; triggers P3 animation states | Core |
| TR-c1-003 | Movement | Tween-based traversal along node graph edge paths | Engine |
| TR-c2-001 | Time/Loop | 100 time units per loop, displayed as "7 years" via `ceil(time_units / 14.3)` | Core |
| TR-c2-002 | Time/Loop | Time cost registry: dialogue=1/advance, small battle=10, large=20, boss=30 | Core |
| TR-c2-003 | Time/Loop | Critical threshold at ≤10 units triggers UI pulse + audio boost | Core |
| TR-c2-004 | Time/Loop | Loop transition: collapse audio (5s) → whiteout silence (1s) → reawaken | Timing |
| TR-c2-005 | Time/Loop | Loop start: reset affection, convert warmth, escalate enemies, clear fish, auto-save | Core |
| TR-c3-001 | Relationship | Two-layer model: per-loop affection (0-10) + cumulative warmth (0-3, no decay) | Data |
| TR-c3-002 | Relationship | Affection sources: fish=+2, battle=+2, good dialogue=+1, special events=+2~4 | Core |
| TR-c3-003 | Relationship | Warmth conversion: at loop end, if affection≥10 → warmth+1 (max 1/loop/NPC) | Core |
| TR-c3-004 | Relationship | Memory fragments: 3 tiers gated by loop count + warmth tier | Data |
| TR-c3-005 | Relationship | Recruitment: warmth≥1 OR current-loop affection>5 | Core |
| TR-c3-006 | Relationship | NPC data per NPC stored as .tres Resource files | Data |
| TR-c4-001 | Combat | 3 feline archetypes: Hunter (finish wounded×1.3), Guardian (intercept×0.75), Trickster (40% evade) | Core |
| TR-c4-002 | Combat | Autonomous battle: each cat attacks on SPD interval (1.5-3.0s base) | Timing |
| TR-c4-003 | Combat | 3 observer commands: retreat (15s CD, 2 uses), focus-fire (20s CD, 2 uses), reposition (10s CD, 3 uses) | Core |
| TR-c4-004 | Combat | Damage formula: max(1, ATK-DEF). HP, ATK, DEF, SPD stats per cat | Core |
| TR-c4-005 | Combat | SPD conversion: effective_spd = base_spd − stat_bonus × 0.1 | Core |
| TR-c4-006 | Combat | XP diminishing returns: ≤3 XP→×2, ≤7 XP→6+(XP-3), >7→10+0.5×(XP-7) | Core |
| TR-c4-007 | Combat | Enemy escalation: loop 1=base, 2=+20%, 3=+35%, 4+=+50% | Core |
| TR-c4-008 | Combat | Wounded status: −20% stats for rest of loop, clears on reset | Core |
| TR-c4-009 | Combat | Warmth combat bonus: tier 2 +10% stats, tier 3 +20% + signature ability | Core |
| TR-c4-010 | Combat | Pre-battle: 2×3 formation grid + target priority assignment | UI |
| TR-c5-001 | Economy | Single fish resource type, max 5 carried, use-or-lose (clear at loop start) | Data |
| TR-c5-002 | Economy | 5 fish sources: tutorial(1), market(2/loop), shoreline(70%), gratitude(warmth2+), hunting(30%) | Core |
| TR-c5-003 | Economy | Fish gift = +2 affection to any NPC at any warmth tier, consumed immediately | Core |
| TR-c5-004 | Economy | Guaranteed minimum 2 fish per loop via Fish Market (non-combat path) | Core |

### Feature Layer

| Req ID | System | Requirement | Domain |
|--------|--------|-------------|--------|
| TR-f4-001 | Dialogue | Dialogue selection: filter by loop tier (1/2-3/4+) + warmth_min + condition flags | Query |
| TR-f4-002 | Dialogue | Memory fragment delivery: Tier 1 procedural, Tier 2 hand-authored, Tier 3 behavioral | Data |
| TR-f4-003 | Dialogue | Content budget: 5-8 lines/tier for tiers 1-2, 3-5 lines for tier 3; 45-200 total | Data |
| TR-f4-004 | Dialogue | Dialogue stored as Godot Resource files (.tres) per NPC | Data |
| TR-f5-001 | Boss | Multi-phase bosses: 2-3 phases at 60%/25% HP thresholds, unique per-phase abilities | Core |
| TR-f5-002 | Boss | Boss escalation layered on enemy escalation: gate+1=+15%HP/+10%ATK, gate+2=+30%HP/+20%ATK, gate+3=+45%HP/+30%ATK | Core |
| TR-f5-003 | Boss | 1.0s telegraph before boss abilities; double-confirm before triggering (30 unit cost) | Timing |
| TR-f5-004 | Boss | Unique drops once ever; boss defeat flags persist across loops | Data |
| TR-f5-005 | Boss | 4 bosses total: MVP=0, Tier 1=2, Full vision=4 | Scope |
| TR-f6-001 | True Ending | Phase 1 conditions: loop≥3, 橘云 warmth=3, ≥2 NPCs warmth≥2, ≥3 boss victories, ≥4 clues | Core |
| TR-f6-002 | True Ending | Phase 2: 银定亲王 as special NPC (fish=0 affection, unique sources), 心魔 battle | Core |
| TR-f6-003 | True Ending | 心魔 battle: 30 time units, warmth-3 NPCs reduce 心魔 stats by 10% each | Core |
| TR-f6-004 | True Ending | Three endings: Normal (time out), Phase 1 (conspiracy exposed), True (full resolution) | Core |
| TR-f6-005 | True Ending | Post-game sandbox mode after true ending | Feature |
| TR-f7-001 | Scheduling | 7-day day/night cycle: day_number = max(1, 7 − floor(time_units × 7 / 100)) | Core |
| TR-f7-002 | Scheduling | night check: phase_progress < 0.4 (mod returns values in (0, 1.0]) | Core |
| TR-f7-003 | Scheduling | 14 schedule slots per NPC (7 days × 2 phases), fixed across loops | Data |
| TR-f7-004 | Scheduling | Day/night transition: 1.5s sky color fade + lantern toggle, costs 0 time | Rendering |

### Presentation Layer

| Req ID | System | Requirement | Domain |
|--------|--------|-------------|--------|
| TR-f3-001 | UI/HUD | 7 HUD elements: countdown, loop counter, fish counter, team panel toggle, dialogue box, warmth indicator, pause button | UI |
| TR-f3-002 | UI/HUD | Dialogue box: NPC name + portrait + text + 2-4 choices, bottom-third of screen | UI |
| TR-f3-003 | UI/HUD | Toast notifications for fish pickup/gift, inventory full, warmth tier up | UI |
| TR-f3-004 | UI/HUD | Settings menu: volume sliders, accessibility toggles, input remapping | UI |
| TR-f3-005 | UI/HUD | Hit targets ≥48px for all interactive UI elements | UI |
| TR-f3-006 | UI/HUD | 1280×720 baseline resolution, text reflows at 0.75x–2.0x scaling | UI |
| TR-p1-001 | Traces | 5 trace types: warmth mark, battle scar, gift echo, recruitment sigil, loop milestone | Rendering |
| TR-p1-002 | Traces | Cerulean blue (#2B7FB0) permanence color, saturation by warmth: 25%/60%/100% | Rendering |
| TR-p1-003 | Traces | ⚠️ HIGH RISK — ShaderMaterial glow rework in 4.6, shader texture changes in 4.4 | Engine |
| TR-p1-004 | Traces | Trace data per node persisted in save, never reset across loops | Data |
| TR-p2-001 | Audio | 3-layer audio: Music (top), Ambient (middle), SFX (bottom) | Audio |
| TR-p2-002 | Audio | ⚠️ MEDIUM RISK — AudioServer bus API, verify OGG Vorbis unchanged in 4.6 | Engine |
| TR-p2-003 | Audio | 16 audio events mapped to gameplay systems; max 8 simultaneous SFX voices | Audio |
| TR-p2-004 | Audio | Crossfade: music→music 2.0s, ambient→music 0.8s, music→ambient 1.5s, day/night 3.0s | Timing |
| TR-p2-005 | Audio | ≤50MB total audio assets, OGG Vorbis format | Performance |
| TR-p3-001 | Animation | 10 animation states per cat, 6 emotes; sprite sheet ≤512×512px, total ≤5MB | Rendering |
| TR-p3-002 | Animation | Idle variations: paw lick(60%), tail curl(20%), stretch(10%), look(10%) | Rendering |
| TR-p3-003 | Animation | Traversal animations mapped to edge types; battle animations by archetype | Rendering |
| TR-pl1-001 | Tutorial | 7 tutorial flags persisted across loops via Save/Load | Data |
| TR-pl1-002 | Tutorial | Loop 1 semi-structured 7-step intro with Old Tom, ~12 dialogue lines, ~6 time units | Core |
| TR-pl1-003 | Tutorial | Loop-aware Old Tom dialogue: welcoming→curious→knowing across loops 1/2/3+ | Data |
| TR-pl2-001 | Accessibility | Text scaling: UI 0.75x–2.0x, dialogue 0.75x–2.5x, independently configurable | UI |
| TR-pl2-002 | Accessibility | ⚠️ HIGH RISK — AccessKit integration new in Godot 4.5 | Engine |
| TR-pl2-003 | Accessibility | 3 colorblind modes: shader-based palette swaps (runtime only, no asset changes) | Rendering |
| TR-pl2-004 | Accessibility | Input remapping: keyboard controls remappable via InputMap | Input |
| TR-pl2-005 | Accessibility | Reduce motion: disable screen shake, parallax 50%, pulse slowed to 2.0s, fade 0.5s | Rendering |

---

## ADR Audit

### Existing ADRs
**None found** — no ADRs exist in `docs/architecture/`. This is the first architecture pass.

### Traceability Coverage
All 62 technical requirements are currently **uncovered by ADRs** (0/62). Every requirement needs an architectural decision recorded.

### Required New ADRs

#### Must Have Before Coding Starts (Foundation & Core — 8 ADRs)

1. **ADR-0001: Event Bus Architecture** — Signal-based cross-module communication pattern, signal naming conventions, EventBus singleton lifecycle. Covers: TR-c2-001~005, TR-c3-002~003, TR-c4-002~003, TR-c5-003
2. **ADR-0002: Save/Load Serialization Format** — GameState Resource structure, per-manager save/load contract, FileAccess strategy for Godot 4.6. Covers: TR-f1-001~004
3. **ADR-0003: Node Graph Data Model** — NodeData and EdgeData Resource format, tag system, district definitions, camera bounds. Covers: TR-f2-001~007
4. **ADR-0004: Time/Loop State Machine** — Time unit tracking, countdown display formula, critical threshold, loop transition sequence, initialization. Covers: TR-c2-001~005, TR-f7-001~002
5. **ADR-0005: Relationship Data Model** — Two-layer affection/warmth model, affection sources, warmth conversion, memory fragment tiers, recruitment rules, NPC data resources. Covers: TR-c3-001~006
6. **ADR-0006: Auto-Battler Resolution Engine** — Autonomous combat loop, SPD-based attack timing, damage formula, archetype AI, command cooldowns, XP curves. Covers: TR-c4-001~010
7. **ADR-0007: Autoload Initialization Order** — Boot sequence, dependency resolution, lazy vs eager loading, new game vs load game branching. Covers: all autoload modules
8. **ADR-0008: Economy Resource Model** — Fish inventory management, spawn sources per loop, use-or-lose clear, gratitude fish, tutorial fish flag. Covers: TR-c5-001~004

#### Should Have Before Relevant System Is Built (Feature & Presentation — 7 ADRs)

9. **ADR-0009: Dialogue Resource Format** — .tres dialogue trees, selection algorithm (loop+warmth+conditions), memory fragment delivery. Covers: TR-f4-001~004
10. **ADR-0010: Boss Encounter State Machine** — Multi-phase boss framework, HP thresholds, telegraph timing, boss escalation layering, unique drops. Covers: TR-f5-001~005
11. **ADR-0011: Day/Night Cycle Implementation** — Time-to-day formula, mod convention, day/night transition visuals, NPC schedule resolution. Covers: TR-f7-001~004
12. **ADR-0012: UI/HUD Layout & Scaling** — 7-element HUD layout, 1280×720 baseline, text scaling, dialogue box, toast system. Covers: TR-f3-001~006
13. **ADR-0013: Traces Visual Rendering (HIGH RISK)** — ShaderMaterial for cerulean marks in Godot 4.6, glow rework verification, colorblind palette swaps. Covers: TR-p1-001~004, TR-pl2-003
14. **ADR-0014: Audio System Architecture (MEDIUM RISK)** — 3-layer audio bus config, crossfade engine, OGG Vorbis playback, AudioServer API verification for 4.6. Covers: TR-p2-001~005
15. **ADR-0015: Accessibility Integration (HIGH RISK)** — AccessKit API for Godot 4.5+, text scaling implementation, input remapping, motion reduction. Covers: TR-pl2-001~005

#### Can Defer to Implementation (6 ADRs)

16. **ADR-0016**: Cat Animation State Machine — 10 states, 6 emotes, idle variations. Covers: TR-p3-001~003
17. **ADR-0017**: True Ending Condition Tracker — Phase 1/2 unlock, clue assembly, 银定亲王 track. Covers: TR-f6-001~005
18. **ADR-0018**: Tutorial Flag Persistence — 7 flags, loop-aware Old Tom dialogue, skip mechanics. Covers: TR-pl1-001~003
19. **ADR-0019**: Movement & Traversal System — Tween-based edge traversal, edge type mapping, camera integration. Covers: TR-c1-001~003
20. **ADR-0020**: NPC Scheduling Data Model — 14-slot schedule tables, conditional overrides. Covers: TR-f7-003~004
21. **ADR-0021**: Pre-Battle Formation UI — 2×3 grid, target priority UI, team panel. Covers: TR-c4-010
22. **ADR-0022**: Post-Game Sandbox Mode — State after true ending, continued play rules. Covers: TR-f6-005

---

## Architecture Principles

1. **Signal-Driven, Not Call-Driven** — Modules never call each other's mutation methods directly. State changes fire EventBus signals; interested modules listen and react. This keeps modules independently testable and prevents tight coupling.

2. **Autoloads Own State, Scenes Own Presentation** — All game state lives in autoload singletons (Foundation + Core layers). Scene-attached nodes (Feature + Presentation) are stateless renderers that read from autoloads and fire signals for input. If the scene tree is cleared, game state survives.

3. **Time Is a Resource, Not a Frame** — The game does not advance on `_process(delta)`. Time units are spent by player actions (dialogue click, battle trigger, fish gift). The frame loop renders visuals only. This decouples game logic from rendering and makes the game naturally pause-able.

4. **Data-Driven, Not Code-Driven** — All design data (node graphs, NPC schedules, dialogue trees, enemy stats, animation frames) lives in Godot Resource files (.tres). Designers can tune values without touching code. Code reads Resources; Resources never contain logic.

5. **Verify at Engine Boundary, Not Internally** — The only input validation happens at engine API boundaries (FileAccess for save, ShaderMaterial for traces, AccessKit for accessibility). Internal module boundaries trust each other — no defensive checks on internal calls.

---

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | Godot 4.6 ShaderMaterial glow API — does `canvas_item` shader type still use `hint_color` uniformly? | HIGH | ADR-0013 (Traces) must verify against 4.6 docs before implementation |
| QQ-02 | AccessKit API surface in Godot 4.5/4.6 — what nodes support `Accessible` properties? | HIGH | ADR-0015 (Accessibility) must verify before implementation |
| QQ-03 | FileAccess return types in 4.4+ — `get_open_error()` vs `file_exists()` pattern to use? | MEDIUM | ADR-0002 (Save/Load) must verify before implementation |
| QQ-04 | AudioServer bus API in 4.6 — `get_bus_index()` and `set_bus_volume_db()` signatures unchanged? | MEDIUM | ADR-0014 (Audio) must verify before implementation |
| QQ-05 | OGG Vorbis loop seamless playback — does `AudioStreamPlayer` looping handle OGG gaps in 4.6? | LOW | ADR-0014 (Audio) — test with ambient and music tracks |
| QQ-06 | D3D12 default on Windows in 4.6 — any impact on 2D Compatibility renderer? | LOW | Verify 2D Compatibility renderer is unaffected by D3D12 default |
