# ADR-0006: Auto-Battler Resolution Engine

## Status

Proposed

## Date

2026-05-30

## Last Verified

2026-05-30

## Decision Makers

User (sole developer)

## Summary

The combat system is an autonomous real-time auto-battler where recruited cats fight on SPD-based attack intervals with archetype-driven AI (Hunter/Guardian/Trickster), while the player issues limited observer commands (retreat, focus-fire, reposition) on a shared cooldown. This ADR defines the battle resolution loop, the damage formula `max(1, ATK-DEF)`, the SPD-to-interval conversion `effective_spd = base_spd − stat_bonus × 0.1`, the diminishing-returns XP formula, the enemy escalation curve across loops, and the pre-battle 2×3 formation grid.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — `Timer`, integer/float math, and signal-driven state machines are stable since 4.0. No physics or rendering dependency in battle resolution. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/architecture/architecture.md`, `design/gdd/auto-battler-combat-system.md` |
| **Post-Cutoff APIs Used** | None — battle resolution is pure GDScript math + Timer nodes for SPD intervals |
| **Verification Required** | Test Timer-based attack loops with 6+ concurrent timers to confirm no drift or missed ticks in Godot 4.6. Verify `max(1, ATK-DEF)` handles edge cases (negative DEF, fractional stats). |

> **Note**: Battle resolution is pure math — no physics, no rendering dependency. The 2D Compatibility renderer and GodotPhysics2D are not involved. This is the most testable module in the project.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (EventBus — battle signal ordering), ADR-0002 (Save/Load — team cat persistence), ADR-0003 (Node Graph — battle-trigger and boss-trigger nodes), ADR-0004 (Time/Loop — time cost consumption, enemy escalation at loop start), ADR-0005 (Relationship — recruitment status, warmth combat bonus) |
| **Enables** | ADR-0010 (Boss Encounter — extends battle framework with multi-phase boss logic), ADR-0012 (UI/HUD — team panel, pre-battle screen, battle log), ADR-0017 (True Ending — boss victory count) |
| **Blocks** | MVP combat stories — no battles can occur until the resolution engine is implemented |
| **Ordering Note** | Must be Accepted before ADR-0010 (Boss Encounter extends this framework) |

## Context

### Problem Statement

The auto-battler is the strategic payoff for the relationship-building loop. Battles must resolve autonomously (cats fight based on their archetype AI and SPD intervals) while the player retains agency through limited commander commands. The math must produce satisfying results across the full progression arc: from a single cat vs. basic shadows in loop 1, to 6 cats with synergy abilities vs. multi-phase bosses in loop 4+. This requires a resolution engine that is deterministic, testable, and data-driven — every number in the battle must be traceable to a formula with no hidden modifiers.

### Constraints

- Autonomous real-time resolution — no turn-based or frame-by-frame player input
- 3 archetypes (2 MVP, 3 full vision), 6 team cats max
- 4 enemy types, escalating stats per loop
- Shared command cooldown — one command at a time
- Battle state is deterministic (same inputs = same outcome, given seeded RNG)
- No physics or rendering dependency — battle math is pure GDScript

### Requirements

- Damage: `max(1, ATK - DEF)`, minimum 1 damage per hit
- SPD controls attack interval (1.5-3.0s base)
- 3 observer commands on shared cooldown with per-battle use limits
- XP with diminishing returns: `≤3→×2, ≤7→6+(XP-3), >7→10+0.5×(XP-7)`
- Enemy escalation: loop 1=base, 2=+20%, 3=+35%, 4+=+50%
- Wounded: −20% stats for rest of loop, clears on reset
- Warmth combat bonus: tier 2 +10%, tier 3 +20% + signature

## Decision

### Battle State Machine

```
                    ┌─────────────┐
    battle-trigger →│  DEPLOYING  │ (pre-battle, no time limit)
                    └──────┬──────┘
                           │ player confirms "Begin"
                           ↓
                    ┌─────────────┐
                    │   ACTIVE    │ (autonomous resolution)
                    └──────┬──────┘
                           │ all enemies HP≤0 OR all team cats HP≤0
                           ↓
                    ┌─────────────┐
                    │  RESOLVING  │ (apply rewards/penalties)
                    └──────┬──────┘
                           │ signals emitted
                           ↓
                       RETURN (to exploration)
```

### Cat Stats

```gdscript
class_name CatStats extends Resource
@export var npc_id: String = ""
@export var archetype: int = 0  # 0=Hunter, 1=Guardian, 2=Trickster

## Base stats (set by NPC definition, not battle)
@export var base_hp: int = 100
@export var base_atk: int = 14
@export var base_def: int = 5
@export var base_spd: float = 2.0  # Attack interval in seconds

## Growth
@export var xp: int = 0
@export var stat_bonus: int = 0  # From XP (see XP formula)

## State
@export var is_wounded: bool = false
@export var warmth: int = 0  # Read from RelationshipManager each battle

## Computed (calculated at battle start, not serialized)
var effective_hp: int = 0
var effective_atk: int = 0
var effective_def: int = 0
var effective_spd: float = 0.0
```

### Effective Stats Calculation

```gdscript
func _calculate_effective_stats(cat: CatStats) -> void:
    # Base + stat bonus (from XP)
    var hp := cat.base_hp + cat.stat_bonus
    var atk := cat.base_atk + cat.stat_bonus
    var def := cat.base_def + cat.stat_bonus

    # Warmth bonus (multiplicative)
    var warmth_mult := 1.0
    if cat.warmth >= 3:
        warmth_mult = 1.20
    elif cat.warmth >= 2:
        warmth_mult = 1.10
    # warmth 0-1: no bonus

    cat.effective_hp = int(ceil(hp * warmth_mult))
    cat.effective_atk = int(ceil(atk * warmth_mult))
    cat.effective_def = int(ceil(def * warmth_mult))

    # SPD: warmth does NOT affect SPD. Only stat_bonus reduces interval.
    cat.effective_spd = cat.base_spd - cat.stat_bonus * 0.1
    cat.effective_spd = max(cat.effective_spd, 0.5)  # Hard floor: 0.5s

    # Wounded penalty (applied last, additive with warmth)
    if cat.is_wounded:
        cat.effective_hp = int(cat.effective_hp * 0.8)
        cat.effective_atk = int(cat.effective_atk * 0.8)
        cat.effective_def = int(cat.effective_def * 0.8)
```

### Damage Formula

```gdscript
func calculate_damage(attacker_atk: int, defender_def: int, archetype: int, target_hp_pct: float) -> int:
    var raw := attacker_atk - defender_def
    var damage := max(1, raw)

    # Hunter bonus: +30% damage to enemies below 50% HP
    if archetype == 0 and target_hp_pct < 0.5:
        damage = int(ceil(damage * 1.3))

    return damage
```

### Archetype AI

```gdscript
# Hunter: targets lowest HP% enemy
func _hunter_select_target(enemies: Array[BattleEnemy]) -> BattleEnemy:
    var target := enemies[0]
    var lowest_pct := 1.0
    for enemy in enemies:
        var pct := float(enemy.current_hp) / float(enemy.max_hp)
        if pct < lowest_pct:
            lowest_pct = pct
            target = enemy
    return target

# Guardian: intercepts attacks directed at most wounded ally
func _guardian_intercept(attacker_target: CatStats, allies: Array[CatStats]) -> bool:
    var most_wounded: CatStats = null
    var lowest_hp_pct := 1.0
    for ally in allies:
        if ally.npc_id == attacker_target.npc_id:
            continue
        var pct := float(ally.current_hp) / float(ally.effective_hp)
        if pct < lowest_hp_pct:
            lowest_hp_pct = pct
            most_wounded = ally
    # If the attacker is targeting the most wounded cat, Guardian intercepts
    return attacker_target == most_wounded
# Guardian reduces damage to adjacent allies by 25%

# Trickster: 40% evade chance, exposes attacker (+20% damage taken for 3s)
func _trickster_try_evade() -> bool:
    return randf() < 0.40
```

### Battle Resolution Loop

```gdscript
func _battle_loop() -> void:
    while state == STATE_ACTIVE:
        # Each cat attacks on its SPD interval
        for cat in team_cats:
            if cat.attack_timer >= cat.effective_spd:
                var target := _select_target(cat, enemies)
                var damage := calculate_damage(cat.effective_atk, target.def, cat.archetype, target.hp_pct())
                target.take_damage(damage)
                EventBus.emit("cat_attack", cat.npc_id, target.enemy_id, damage)
                cat.attack_timer = 0.0
                if target.is_dead():
                    enemies.erase(target)
                    EventBus.emit("enemy_defeated", target.enemy_id)

        # Enemies attack on their SPD interval
        for enemy in enemies:
            if enemy.attack_timer >= enemy.spd:
                var target := _enemy_select_target(enemy, team_cats)
                # Guardian intercept check
                for cat in team_cats:
                    if cat.archetype == 1 and _guardian_intercept(target, team_cats):
                        target = cat  # Guardian takes the hit
                        break
                var damage := calculate_damage(enemy.atk, target.effective_def, -1, 1.0)
                target.take_damage(damage)
                # Trickster evade check
                if target.archetype == 2:
                    if _trickster_try_evade():
                        target.heal(damage)  # Undo damage
                        enemy.apply_exposed(3.0)  # +20% damage taken
                enemy.attack_timer = 0.0

        # Advance timers
        var dt := _get_delta()  # Timer-based, not _process
        for cat in team_cats:
            cat.attack_timer += dt
        for enemy in enemies:
            enemy.attack_timer += dt

        # Check end conditions
        if enemies.is_empty():
            _resolve_victory()
            return
        if team_cats.all(func(c): return c.current_hp <= 0):
            _resolve_defeat()
            return

        await _wait_interval(0.1)  # 100ms tick resolution
```

### Observer Commands

```gdscript
const COMMAND_RETREAT: int    = 0
const COMMAND_FOCUS_FIRE: int = 1
const COMMAND_REPOSITION: int = 2

class CommandDef:
    var cooldown: float
    var uses_per_battle: int
    var remaining_uses: int

var _command_defs := {
    COMMAND_RETREAT:    CommandDef.new(15.0, 2),
    COMMAND_FOCUS_FIRE: CommandDef.new(20.0, 2),
    COMMAND_REPOSITION: CommandDef.new(10.0, 3),
}
var _shared_cooldown: float = 0.0  # All commands share this

func issue_command(command_type: int, target_id: String) -> bool:
    if _shared_cooldown > 0.0:
        return false  # Global cooldown active
    var def := _command_defs[command_type]
    if def.remaining_uses <= 0:
        return false
    def.remaining_uses -= 1
    _shared_cooldown = def.cooldown

    match command_type:
        COMMAND_RETREAT:
            _execute_retreat(target_id)
        COMMAND_FOCUS_FIRE:
            _execute_focus_fire(target_id)
        COMMAND_REPOSITION:
            _execute_reposition(target_id)

    EventBus.emit("command_issued", command_type, target_id)
    return true
```

### XP Formula (Diminishing Returns)

```gdscript
func calculate_stat_bonus(xp: int) -> int:
    if xp <= 3:
        return 2 * xp
    elif xp <= 7:
        return 6 + 1 * (xp - 3)
    else:
        return 10 + int(0.5 * float(xp - 7))
```

| XP | Bonus | Effective Growth Per XP |
|----|-------|------------------------|
| 0 | 0 | — |
| 1 | 2 | 2.0 |
| 2 | 4 | 2.0 |
| 3 | 6 | 2.0 |
| 4 | 7 | 1.0 |
| 5 | 8 | 1.0 |
| 6 | 9 | 1.0 |
| 7 | 10 | 1.0 |
| 8 | 10 | 0.5 (rounded down) |
| 9 | 11 | 0.5 |
| 10 | 11 | 0.5 |

### Enemy Escalation

```gdscript
func get_escalation_multiplier(loop_count: int) -> float:
    if loop_count >= 4:
        return 1.50
    elif loop_count >= 3:
        return 1.35
    elif loop_count >= 2:
        return 1.20
    else:
        return 1.0

func scale_enemy_for_loop(enemy: BattleEnemy, loop_count: int) -> void:
    var mult := get_escalation_multiplier(loop_count)
    enemy.max_hp = int(ceil(enemy.base_hp * mult))
    enemy.atk = int(ceil(enemy.base_atk * mult))
    enemy.def = int(ceil(enemy.base_def * mult))
    enemy.current_hp = enemy.max_hp
```

### Boss Escalation (Layered on Enemy Escalation)

```gdscript
func get_boss_escalation(gate: int) -> Dictionary:
    match gate:
        1: return {"hp_mult": 1.15, "atk_mult": 1.10}
        2: return {"hp_mult": 1.30, "atk_mult": 1.20}
        3: return {"hp_mult": 1.45, "atk_mult": 1.30}
        _: return {"hp_mult": 1.0, "atk_mult": 1.0}
```

### Key Interfaces

```gdscript
# CombatManager — Autoload singleton
extends Node

## Team management
func get_team_roster() -> Array[CatStats]
func add_team_cat(npc_id: String) -> bool
func remove_team_cat(npc_id: String) -> void
func get_cat_stats(npc_id: String) -> CatStats

## Battle lifecycle
func start_battle(encounter_data: EncounterData) -> void
func issue_command(command_type: int, target_id: String) -> bool
func get_battle_state() -> int

## Save/Load
func collect_save_state() -> CombatState
func restore_from_save(state: CombatState) -> void

## Internal EventBus consumers
func _on_loop_start(_loop_count: int) -> void  # Escalate enemies, clear wounded

## Signals (via EventBus)
# battle_started, battle_victory, battle_defeat, battle_abort
# cat_attack(cat_id, target_id, damage)
# cat_wounded(npc_id)
# command_issued(command_type, target_id)
# xp_gained(npc_id, amount)
# enemy_defeated(enemy_id)
```

### Pre-Battle Formation

The 2×3 grid is represented as:

```
Front row (index 0-2): higher risk, normal damage
Back row  (index 3-5): lower risk (enemies target front row first)
```

```gdscript
class_name FormationSlot extends Resource
@export var row: int = 0     # 0=front, 1=back
@export var column: int = 0  # 0=left, 1=center, 2=right
@export var cat_id: String = ""

## CombatState (save/load)
class_name CombatState extends Resource
@export var team_cats: Array[CatStats] = []
```

## Alternatives Considered

### Alternative 1: Turn-Based Combat

- **Description**: Cats and enemies take turns in initiative order. Player selects each cat's action manually. Standard JRPG or tactics game model.
- **Pros**: More player agency per action. Easier to balance. No real-time concerns. Well-understood genre.
- **Cons**: Violates the core design — the player is an observer-commander, not a squad commander. Per-action control makes battles strategic but slow. The auto-battler model reinforces "your cats are autonomous beings, not chess pieces."
- **Rejection Reason**: The auto-battler + observer-commander design is a core pillar (P5: Strategic Mastery). Turn-based combat would change the game's identity completely.

### Alternative 2: Frame-Based Real-Time (No Timers)

- **Description**: Attacks resolve on `_process(delta)` with attack-speed multipliers instead of discrete intervals. Continuous damage rather than discrete hits.
- **Pros**: Smoother visual presentation. No timer drift concerns. Easier to animate.
- **Cons**: Harder to balance — continuous damage makes it difficult to tune for "one more hit" tension. Timer-based discrete attacks create clear, readable combat feedback ("橘云 attacked for 12 damage"). Frame-based is harder to unit test because outcomes depend on frame rate.
- **Rejection Reason**: Discrete timer-based attacks are more readable (clear cause→effect per hit), more testable (deterministic given same timestamps), and create better combat feedback for the player. The 100ms tick resolution is sufficient for smooth animation.

### Alternative 3: No Observer Commands (Pure Auto-Battler)

- **Description**: Battles are fully autonomous. Player sets formation and watches. No commands during battle.
- **Pros**: Simpler implementation. Purer auto-battler genre. Less UI complexity.
- **Cons**: Player has no agency during battle. If the formation is wrong, the player watches helplessly for 30-60 seconds. The shared cooldown command system creates meaningful tactical moments — removing it removes moments of player impact.
- **Rejection Reason**: The limited command system (3 types, shared cooldown, per-battle uses) is what makes the auto-battler interactive. Without it, the player is purely a spectator. The commands create tension: "Do I retreat 橘云 now or save the retreat for later?"

## Consequences

### Positive

- **Testable**: Every formula is a pure function. Battle outcomes are deterministic given the same initial state and seeded RNG. This is the most testable module in the project.
- **Data-driven**: Archetype stats, enemy definitions, escalation multipliers, XP curves — all in Resource files, not code.
- **Engine-independent math**: Battle resolution is integer/float arithmetic with Timers. No physics, no rendering, no Godot-specific systems beyond `Timer.new()` and signals.
- **Warmth→combat integration**: The relationship system feeds directly into combat effectiveness. Warmth 3 cats are noticeably more powerful — mechanical reinforcement of the emotional bond.

### Negative

- **100ms tick resolution**: The battle loop polls at 100ms intervals. For SPD values of 1.5-3.0s, this is 15-30 ticks per attack — sufficient granularity. But very fast attacks (<0.5s) would lose precision. The SPD floor (0.5s) prevents this.
- **RNG in combat**: Evasion (Trickster 40%), Hunter target selection among equal-HP% targets. RNG makes outcomes non-deterministic for identical inputs. Mitigation: seeded RNG for replays/debugging.
- **Timer drift**: Multiple concurrent `Timer` nodes may accumulate sub-tick drift over long battles. Battles are 30-90 seconds — negligible cumulative drift at 100ms resolution.

### Neutral

- Battle visuals are handled by P3 (Animation) and F3 (UI) — CombatManager only emits signals. The resolution engine is presentation-agnostic.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Timer drift over long battles | Low | Low — attack timing slightly desynchronized | Reset timers at battle start. Use elapsed time counter rather than cumulative timer adds for drift correction. |
| RNG seed leakage (same seed, different outcomes) | Low | Medium — "unfair" feeling | Seed the RNG at battle start. Log the seed for debugging. Use `randfn()` consistently (not `randf()` mixed with `randi()`). |
| Guardian intercept + Trickster evade infinite loop | Very Low | Medium — battle never resolves | Guard clause: Guardian cannot intercept an attack already redirected from a Trickster evade. Attack always resolves on the second target. |
| Team size growth (1→3→6) makes battle loop O(n²) | Low | Low — 6v4 = 24 attack pairs, 10 ticks/sec | A 6v4 battle with 100ms ticks is 240 attack checks per second. Pure math, no rendering — <0.1ms per tick. |
| XP overflow (stat_bonus exceeds base stats) | Very Low | Low — cats become overpowered | XP diminishing returns caps stat_bonus growth. At XP=20, stat_bonus=16 — well within design range. |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (battle tick, 6v4) | N/A | <0.1ms per 100ms tick (pure math) | Well under frame budget |
| CPU (battle start) | N/A | <1ms (stat calculation for all combatants) | Acceptable |
| Memory (battle state) | 0 KB | ~10KB (6 cats + 4 enemies + timer nodes) | Negligible |
| Battle duration | N/A | 30-90 seconds (4-8 SPD cycles) | Acceptable pacing |

## Migration Plan

No existing combat system to migrate — greenfield.

**Implementation steps:**
1. Create `CatStats`, `BattleEnemy`, `EncounterData`, `ArchetypeDef`, `EnemyTypeDef`, `CombatState` Resource classes
2. Implement CombatManager autoload with battle state machine
3. Implement effective stats calculation (base + XP bonus + warmth × wounded)
4. Implement archetype AI (Hunter target selection, Guardian intercept, Trickster evade)
5. Implement battle resolution loop with Timer-based SPD intervals
6. Implement observer command system (shared cooldown, per-battle use limits)
7. Implement XP formula and stat_bonus calculation
8. Implement enemy escalation (loop-based multiplier)
9. Implement post-battle resolution (victory rewards, defeat wounded penalty)
10. Wire EventBus signals (battle_started, battle_victory, battle_defeat, cat_attack, etc.)
11. Implement `CombatState` save/load contract (ADR-0002)
12. Register CombatManager as autoload index 6
13. Greybox test: 1v1 battle, Hunter vs Shadow-ling, verify damage formula, verify victory rewards

**Rollback plan**: The combat formulas are defined as constants and pure functions. Changing the damage formula or XP curve is a one-line edit. Changing the archetype AI requires updating the target selection functions — contained within CombatManager.

## Validation Criteria

- [ ] **Damage formula**: ATK=14, DEF=5 → damage=9. ATK=3, DEF=10 → damage=1 (minimum). ATK=20, DEF=5, target HP<50%, Hunter → damage=19 (ceil(15×1.3)).
- [ ] **SPD conversion**: base_spd=2.5, stat_bonus=5 → effective_spd=2.0. stat_bonus=20 → effective_spd=0.5 (floor).
- [ ] **XP formula**: XP=0 → bonus=0. XP=3 → bonus=6. XP=5 → bonus=8. XP=8 → bonus=10. XP=10 → bonus=11.
- [ ] **Effective stats**: base_atk=14, stat_bonus=6, warmth=2 → effective_atk=ceil(20×1.1)=22. Same cat wounded → effective_atk=int(22×0.8)=17.
- [ ] **Enemy escalation**: loop=1 → mult=1.0. loop=2 → mult=1.20. loop=3 → mult=1.35. loop=4+ → mult=1.50.
- [ ] **Battle victory**: Team defeats all enemies. Assert `battle_victory` fires. Assert XP +1 per cat. Assert affection +2 per team cat (via C3 signal).
- [ ] **Battle defeat**: All team cats HP≤0. Assert `battle_defeat` fires. Assert all cats gain Wounded. Assert XP=0.
- [ ] **Observer command**: Issue Retreat on cooldown=0, uses=2. Assert Retreat triggers. Assert shared_cooldown=15.0. Issue Focus-fire immediately → assert rejected (cooldown active).
- [ ] **Deterministic replay**: Seed RNG with 42. Run battle. Record outcome. Repeat. Assert identical outcome.
- [ ] **Save/load team**: Add 2 cats to team with XP=5. Save. Load. Assert roster matches.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | 3 archetypes: Hunter (finish wounded), Guardian (intercept), Trickster (evade) | Archetype AI functions with typed behaviors |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Autonomous battle: each cat attacks on SPD interval (1.5-3.0s) | Timer-based attack loop with `effective_spd` interval |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | 3 observer commands: retreat (15s/2), focus-fire (20s/2), reposition (10s/3) | Command system with shared cooldown and per-battle use limits |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Damage formula: max(1, ATK-DEF) | `calculate_damage()` with Hunter bonus for <50% HP |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | SPD conversion: effective_spd = base_spd − stat_bonus × 0.1 | `_calculate_effective_stats()` with 0.5s floor |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | XP diminishing returns | `calculate_stat_bonus()` step function |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Enemy escalation: loop 1=base, 2=+20%, 3=+35%, 4+=+50% | `get_escalation_multiplier()` + `scale_enemy_for_loop()` |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Wounded: −20% stats for rest of loop | `is_wounded` flag × 0.8 multiplier in stat calc; clears on `loop_start` |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Warmth combat bonus: +10% tier 2, +20% tier 3 + signature | Warmth multiplier in `_calculate_effective_stats()` (does not affect SPD) |
| `design/gdd/auto-battler-combat-system.md` | C4 Combat | Pre-battle: 2×3 formation grid + target priority assignment | `FormationSlot` Resource + pre-battle DEPLOYING state |

## Related

- `docs/architecture/architecture.md` — CombatManager module ownership (Core layer), signal catalog
- ADR-0001: Event Bus Architecture — signal priority for `battle_victory`
- ADR-0002: Save/Load Serialization Format — `CombatState` sub-resource
- ADR-0004: Time/Loop State Machine — time cost consumption, enemy escalation trigger
- ADR-0005: Relationship Data Model — recruitment status, warmth combat bonus
- ADR-0010: Boss Encounter State Machine — extends this battle framework with multi-phase boss logic
