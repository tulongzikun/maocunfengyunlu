# Auto-Battler Combat System — GDD

*Created: 2026-05-30*
*Status: Complete — all 8 sections written*
*Layer: Core*
*Dependency order: #9 (depends on C2 Time/Loop, F3 UI/HUD, F1 Save/Load, C3 Relationship)*

---

## 1. Overview

The Auto-Battler Combat System manages all battle encounters — the pre-battle preparation phase, the autonomous battle resolution, the player's observer-commander interventions, and the post-battle outcome (victory rewards, defeat penalties, stat changes). Combat is the strategic payoff for relationship-building: the cats the player has befriended and recruited fight as a team, their behaviors driven by feline archetypes rather than generic RPG roles. The player's role is observer-commander — watching from an elevated perch, reading the flow of battle, and issuing limited commands on cooldown (retreat, focus-fire, reposition). Battles are won or lost based on preparation — team composition, positioning, and target priority set before the fight — not on reflexes. This preserves P5 (Strategic Mastery) and the anti-pillar of no button-timing combat. Enemies escalate in power each loop (+15-25% stats, new abilities at milestones), while team cat growth follows diminishing returns — early loops reward investment, later loops require strategic depth. No cat dies permanently — losing means wounded retreat and a temporary stat penalty for the rest of the loop (P4: Loops Are Growth).

## 2. Player Fantasy

The player should feel like a strategist on a hilltop, watching their cats carry out the plan. The dominant emotion is not adrenaline but satisfaction — the quiet confidence of preparation paying off. When the team wins, the player thinks: "I positioned them well. That synergy worked." When the team struggles, the player thinks: "I need a different formation," not "I didn't click fast enough."

The observer-commander perspective reinforces the cat fantasy (P2): the player cat is not a general barking orders but a fellow cat who has earned the trust of their team. The limited cooldown commands — retreat a wounded friend, focus-fire a threat, reposition one cat — feel like urgent feline signals, not tactical menus. Each command is precious because you only get a few.

The emotional stakes come from the relationship system: every cat on the battlefield is someone the player has befriended across loops. When a team cat takes damage, the player feels a genuine wince — "That's my friend." When a recruited cat lands the winning blow, the player feels pride — not in their own reflexes, but in the bond they built. Victory is shared. Defeat is temporary — cats retreat wounded, not dead — but it still stings because these cats trusted you and you let them down. The stat penalty for the rest of the loop is the mechanical echo of that emotional weight.

## 3. Detailed Rules

### 3.1 Battle Initiation

Battles trigger when the player enters a node tagged `battle-trigger` in the Scene/World Manager (F2). Battle triggers come in two types:

| Type | Time Cost | Trigger | Notes |
|------|-----------|---------|-------|
| Small encounter | 10 units | Fixed nodes, respawn each loop | Standard enemies; 1-3 enemies vs. player's team |
| Boss encounter | 30 units | Loop-milestone nodes | Major enemies; multi-phase; loop-gated |

On trigger: a brief transition plays (camera zoom, battlefield framing, team cats leap into position — ~1.5s). The pre-battle screen then opens.

### 3.2 Pre-Battle Preparation

Before the battle begins, the player sets up their team with no time pressure:

- **Formation**: Position each team cat on a 2×3 grid (front row / back row). Front row takes more attacks; back row deals more damage (elevated vantage).
- **Target priority**: For each team cat, select one:
  - Closest enemy (default)
  - Weakest enemy (lowest HP)
  - Strongest enemy (highest ATK)
  - Same target as [ally name] (focus-fire)
- **Confirm**: Player presses "Begin" to start the battle.

The pre-battle screen is not time-gated. The player can review enemy info (visible enemy types and rough strength) before committing.

### 3.3 Cat Archetypes

Each team cat belongs to one archetype, which determines its autonomous battle AI and stat profile:

| Archetype | Role | Stat Bias | Behavior | Synergy |
|-----------|------|-----------|----------|---------|
| **Hunter** (猎手) | Damage dealer | High SPD, medium ATK, low DEF | Stalks wounded enemies. Attacks the target with the lowest HP%. Deals +30% damage to enemies below 50% HP. | Guardian protects Hunter while Hunter finishes targets |
| **Guardian** (守卫) | Protector | High DEF, high HP, low SPD | Defends allies. Intercepts enemy attacks directed at the most wounded teammate. Reduces damage to adjacent allies by 25%. | Takes hits so Hunter and Trickster can operate |
| **Trickster** (诡猫) | Disruptor | High SPD, medium DEF, low ATK | Evades and distracts. Draws enemy attention then dodges. When targeted, has 40% chance to evade and expose the attacker (+20% damage taken for 3s). | Creates openings that Hunter exploits |

**MVP**: Hunter + Guardian only. Trickster added at Tier 1.

### 3.4 Cat Stats

Each team cat has four stats:

| Stat | Description | Base Range (Level 1) |
|------|-------------|----------------------|
| HP | Health points | 80-120 |
| ATK | Damage per attack | 10-18 |
| DEF | Flat damage reduction per hit | 3-8 |
| SPD | Attack interval in seconds | 1.5-3.0 (lower = faster) |

Stats are modified by:
- **Warmth tier** (§3.7): warmth 1 = base, warmth 2 = +10% all stats, warmth 3 = +20% all stats
- **Loop experience** (§3.8): diminishing returns from battles fought
- **Wounded penalty** (§3.6): −20% all stats for rest of loop after a defeat

### 3.5 Battle Resolution

Battles resolve autonomously in real-time:

1. Team cats deploy to their formation positions. Enemies deploy to opposing side.
2. Each combatant acts on its SPD interval — a cat with SPD 2.0 attacks every 2.0 seconds.
3. Damage calculation: `damage = max(1, attacker.ATK − defender.DEF)`
4. Archetype behaviors and target priorities determine who attacks whom.
5. The player watches from an elevated-perch camera angle — a wide view of the battlefield.
6. Battle ends when: all enemies HP ≤ 0 (victory) OR all team cats HP ≤ 0 (defeat).

### 3.6 Observer-Commander Commands

During battle, the player can issue limited commands on a shared cooldown:

| Command | Effect | Cooldown | Uses Per Battle |
|---------|--------|----------|-----------------|
| **Retreat** | Pull target team cat to back row. They recover 20% HP over 3s, then rejoin. Cat cannot attack while retreating. | 15s | 2 |
| **Focus-fire** | All team cats switch target to the specified enemy for 8 seconds, then revert to their priority settings. | 20s | 2 |
| **Reposition** | Move one team cat to a different grid cell (front↔back row, left↔center↔right). | 10s | 3 |

Commands share a global cooldown — using any command locks all commands for its cooldown duration. The player must choose which command to use and when.

Per-battle uses reset when the battle ends. Unused commands do not carry over.

### 3.7 Warmth Combat Bonus

A team cat's warmth tier with the player (from C3 — NPC Relationship System) provides combat bonuses:

| Warmth | Stat Bonus | Unlocks |
|--------|-----------|---------|
| 0 | — | Cannot be recruited |
| 1 | Base stats (100%) | Eligible for team |
| 2 | +10% all stats | Unlocks archetype synergy (e.g., Guardian intercept range +1 cell) |
| 3 | +20% all stats | Unlocks signature ability (archetype-specific special move, triggers once per battle) |

This makes relationship-building directly mechanically rewarding in combat (P1, P4, P5).

### 3.8 Team Cat Growth (Experience)

Team cats gain experience from battles they participate in:

- **Small encounter victory**: +1 XP per participating cat
- **Boss encounter victory**: +3 XP per participating cat
- **Defeat**: +0 XP (no growth from failure — but no loss either)

XP → stat growth follows diminishing returns:

| XP Total | Bonus Applied | Growth Curve |
|----------|--------------|--------------|
| 0-3 | +2 to all stats per XP | Linear (early investment pays off quickly) |
| 4-7 | +1 to all stats per XP | Slowing |
| 8+ | +0.5 to all stats per XP (rounded down) | Diminishing (strategic depth replaces stat growth) |

This ensures early battles feel rewarding and later battles require strategy over grinding.

### 3.9 Post-Battle Outcome

**Victory**:
- Team cats gain XP (see §3.8)
- +2 affection for each team cat who fought (per C3 — NPC Relationship System)
- Enemies may drop fish (per C5 — Economy/Inventory System)
- Battle results screen shows: damage dealt per cat, MVP cat, XP earned

**Defeat**:
- All team cats gain the **Wounded** status: −20% all stats for the rest of the current loop
- No XP, no affection, no drops
- Enemies retreat from the node — the battle trigger does not re-activate for the rest of the loop
- Wounded status clears automatically on loop reset (P4: Loops Are Growth)
- No permanent death — cats are never lost

### 3.10 Enemy Escalation

Enemies grow stronger each loop to match the player's growing team:

| Loop | Enemy Stat Scaling | New Abilities |
|------|-------------------|---------------|
| 1 | Base (100%) | Basic attacks only |
| 2 | +20% all stats | 1 new enemy type appears |
| 3 | +35% all stats | Enemies gain 1 special ability each |
| 4+ | +50% all stats (cap) | Bosses gain additional phases |

Enemy types (MVP: types 1-2 only):
1. **Shadow-ling** — basic enemy, balanced stats, attacks nearest cat
2. **Shade-claw** — high ATK, low DEF, targets the cat with highest ATK
3. **Rift-hound** — high HP, medium ATK, protects other enemies (Tier 1+)
4. **Rift-wraith** — boss enemy, multi-phase, unique abilities (Tier 1+)

### 3.11 Team Size

Team size caps by scope tier:

| Scope | Max Team Cats | Notes |
|-------|--------------|-------|
| MVP | 1 | One recruited cat fights alongside the player cat (observer) |
| Tier 1 | 3 | Full formation grid (2×3 with 3 cats) |
| Full vision | 6 | Larger battles, more synergies |

The player cat does not fight directly — it observes and issues commands (§3.6).

### 3.12 MVP Simplifications

- 2 archetypes: Hunter + Guardian (no Trickster)
- 1 team cat slot
- 1 enemy type: Shadow-ling only
- Small encounters only (no boss encounters)
- No archetype synergies or signature abilities (these unlock at warmth 2-3, which is Tier 1 content)
- No enemy drops (fish from battles deferred to Tier 1)
- Battle results screen: simplified — shows win/loss and XP earned only

## 4. Formulas

### Damage Calculation

```
raw_damage = attacker.ATK - defender.DEF
damage = max(1, raw_damage)
```

Minimum 1 damage per hit — no zero-damage attacks.

### Archetype Modifiers

**Hunter — Pounce**:
```
if target.current_HP / target.max_HP < 0.5:
    damage = damage × 1.3
```

**Guardian — Intercept**:
```
if guardian_is_adjacent_to_ally AND ally_is_targeted:
    damage_to_ally = damage × 0.75
```
Guardian takes the original (unreduced) damage if the enemy was targeting the Guardian directly.

**Trickster — Evade**:
```
if enemy_targets_trickster:
    if random() < 0.4:
        damage = 0  # evaded
        enemy.exposed = true  # enemy takes +20% damage for 3 seconds
```

### Retreat Recovery

```
HP_recovered = cat.max_HP × 0.2
recovery_duration = 3.0 seconds
```

### Warmth Combat Bonus

```
effective_stat = base_stat × (1.0 + warmth_bonus)
```

| Warmth | warmth_bonus |
|--------|-------------|
| 0 | — (cannot fight) |
| 1 | 0.00 |
| 2 | 0.10 |
| 3 | 0.20 |

### Team Cat Experience Growth

```
if XP ≤ 3:     stat_bonus = 2 × XP
elif XP ≤ 7:   stat_bonus = 6 + 1 × (XP − 3)
else:          stat_bonus = 10 + 0.5 × (XP − 7)
```

Stat bonus is applied to HP, ATK, DEF, and SPD independently:
- HP, ATK, DEF: `effective_stat = base_stat × (1 + warmth_bonus_pct) + stat_bonus`
- SPD: `effective_spd = base_spd − stat_bonus × 0.1` (SPD conversion rate: 0.1s per stat_bonus point; warmth bonus does not affect SPD)

Example (Hunter, 3 XP, stat_bonus = 6): `effective_spd = 2.0 − 6 × 0.1 = 1.4s`

### Wounded Penalty

```
wounded_stat = stat × 0.80
```

Applied to all four stats for the rest of the current loop. Clears on loop reset.

### Enemy Escalation

```
enemy_stat = base_stat × escalation_multiplier
```

| Loop | escalation_multiplier |
|------|----------------------|
| 1 | 1.00 |
| 2 | 1.20 |
| 3 | 1.35 |
| 4+ | 1.50 |

### Summary Table

| Formula | Value | Notes |
|---------|-------|-------|
| Base damage | `max(1, ATK − DEF)` | Minimum 1 per hit |
| Hunter pounce bonus | ×1.3 vs. targets <50% HP | Applies after DEF reduction |
| Guardian intercept reduction | ×0.75 to adjacent ally damage | Guardian takes full damage if targeted directly |
| Trickster evade chance | 40% | Dodged attack deals 0; attacker exposed (+20% damage taken, 3s) |
| Retreat recovery | 20% max HP over 3s | Cat cannot attack during recovery |
| Command cooldown (global) | 10-20s per command | Shared across all commands |
| Warmth stat bonus | +0% / +10% / +20% | Tiers 1 / 2 / 3 |
| XP per small encounter (win) | +1 XP per cat | Defeat: 0 XP |
| XP per boss encounter (win) | +3 XP per cat | Defeat: 0 XP |
| XP growth: early (0-3 XP) | +2 all stats per XP | Linear |
| XP growth: mid (4-7 XP) | +1 all stats per XP | Slowing |
| XP growth: late (8+ XP) | +0.5 all stats per XP | Diminishing |
| Wounded penalty | −20% all stats | Rest of loop, clears on reset |
| Enemy escalation | +0% / +20% / +35% / +50% | Loops 1 / 2 / 3 / 4+ |
| Battle time cost (small) | 10 time units | Per Time/Loop System |
| Battle time cost (boss) | 30 time units | Per Time/Loop System |

### Combat Example

**Setup**: Loop 2. Player has 1 team cat — a Hunter (warmth 2, XP 3).

| Stat | Base | Warmth (+10%) | XP (+6) | Effective |
|------|------|--------------|---------|-----------|
| HP | 100 | 110 | 116 | 116 |
| ATK | 14 | 15.4 | 21.4 | 21 |
| DEF | 5 | 5.5 | 11.5 | 11 |
| SPD | 2.0s | 2.0s | 1.4s | 1.4s |

**Enemy**: Shadow-ling, loop 2 escalation (+20%).

| Stat | Base | Escalated |
|------|------|-----------|
| HP | 80 | 96 |
| ATK | 12 | 14 |
| DEF | 4 | 5 |
| SPD | 2.5s | 2.5s |

**Battle**: Hunter attacks every 1.4s for `max(1, 21 − 5) = 16` damage. Shadow-ling attacks every 2.5s for `max(1, 14 − 11) = 3` damage. Shadow-ling HP 96 → Hunter needs 6 hits (9.0s including first hit at t=0). Shadow-ling deals `3 × floor(9.0/2.5) = 3 × 3 = 9` damage to Hunter. Hunter wins with 107/116 HP remaining.

## 5. Edge Cases

1. **Player enters battle with 0 team cats**: Cannot occur under normal flow — battle-trigger nodes should require at least 1 recruited cat to activate. If triggered via debug or edge case: battle auto-ends with "No team to fight." No time cost, no rewards, no penalty.
2. **All team cats already Wounded before battle**: Wounded is a binary status — it does not stack. Cats fight with the −20% penalty. The player may still win but the risk is higher. Defeat while already Wounded does not double the penalty.
3. **Battle in progress when time hits zero**: Per Time/Loop System §5.2: battle ends immediately. Enemies retreat (not defeated). No XP, no affection, no drops. All team cats who hit 0 HP before the interruption are Wounded. The collapse sequence begins.
4. **Player exhausts all command uses early**: No commands remain. The player watches passively for the rest of the battle — the team fights on their own. Unused commands do not carry over to the next battle.
5. **Mutual kill (last enemy and last team cat die on same tick)**: Counts as a defeat. Enemies retreat, all team cats are Wounded. No rewards. Rationale: the player's team was wiped — the outcome is loss.
6. **Single team cat (MVP)**: The formation grid reduces to 1 cell. All enemies target this cat. Guardian intercept has no adjacent ally to protect — Guardian fights as a basic attacker with its stat profile. Hunter pounce functions normally.
7. **NPC recruited via affection > 5 fights, then loop resets**: The cat gained XP from battles fought. XP persists on the NPC even if they leave the team on reset (warmth 0 → affection resets → recruitment lost). If the player re-recruits the same cat in a future loop, their XP is restored. XP is tied to the NPC, not team membership.
8. **Command issued mid-attack**: The command interrupts the cat's current action. The cat immediately begins the commanded action (retreat, reposition, or focus-fire retarget). No animation lockout — commands take priority.
9. **All enemies focus-fire one team cat**: All attacks resolve independently. If a Guardian is adjacent to the targeted cat, the Guardian intercepts for that cat — reducing each incoming attack by 25%. The targeted cat still takes significant damage through intercept. Without a Guardian, the targeted cat takes full damage from all sources.
10. **Team cat reaches 0 HP mid-battle but allies win**: The cat that hit 0 HP is Wounded for the rest of the loop — even though the battle was won. Surviving cats receive XP and affection normally. This creates tension: winning is good, but losing a teammate mid-fight has consequences.
11. **No valid target priority (only one enemy type)**: "Closest" is always valid. Other priorities (weakest, strongest) resolve to the single enemy. "Same target as ally" requires at least one ally; with MVP's 1 team cat, this option is hidden.
12. **Save/Load outside battle only**: The game does not allow saving during an active battle. The save option is greyed out in the pause menu. Battle state is not serialized — if a battle is in progress and the game crashes, on reload the player is at the node before the battle trigger.

## 6. Dependencies

### Upstream

| System | What C4 Needs From It |
|--------|----------------------|
| **Time/Loop System (C2)** | Enemy escalation triggered at loop start; battle time cost (10/30 units); mid-collapse battle interruption signal; loop count for enemy scaling |
| **UI/HUD Framework (F3)** | Team panel display (cat name, stats, affinity ❤); battle results screen (damage dealt, MVP, XP earned); command buttons during battle; pre-battle formation grid UI |
| **Save/Load System (F1)** | Persist team roster, per-cat XP, per-cat stat bonuses, Wounded status per cat; clear Wounded on loop reset |
| **NPC Relationship System (C3)** | Recruitment status (who is in the team); warmth tier per team cat (→ combat bonus); fires affection events on battle victory |
| **Scene/World Manager (F2)** | `battle-trigger` tagged nodes for battle initiation |
| **Economy/Inventory System (C5)** | Enemy fish drops on victory (Tier 1+); fish inventory availability for post-battle loot |

### Downstream

| System | What It Needs From C4 |
|--------|----------------------|
| **NPC Relationship System (C3)** | Battle victory events → +2 affection per participating team cat; battle-together flag for relationship tracking |
| **Boss Encounter System (F5)** | Battle framework (initiation, resolution, commands, outcomes); extends with boss-specific phases, abilities, and rewards |
| **True Ending/Progression System (F6)** | Battle outcome flags (specific boss victories may be required for progression) |
| **Traces Visual Feedback System (P1)** | Battle outcome events (victory/defeat may deposit visual marks at battle locations) |

### Bidirectional Note

C3 (Relationship) and C4 (Combat) form a tight loop: C3 provides recruited cats and warmth bonuses that determine combat effectiveness; C4 returns battle outcomes that grow affection and advance relationships. This is the core gameplay synergy — social investment pays off in combat, and combat deepens social bonds.

## 7. Tuning Knobs

| Knob | Default | Safe Range | What It Affects |
|------|---------|------------|-----------------|
| Hunter pounce bonus | ×1.3 | ×1.2 to ×1.5 | Finisher incentive; higher = more burst |
| Guardian intercept reduction | ×0.75 | ×0.60 to ×0.85 | Protection strength; lower = more damage reduction for allies |
| Trickster evade chance | 40% | 30-50% | Evasion reliability; higher = more frustrating for enemies |
| Trickster expose duration | 3s | 2-5s | Window for allies to capitalize |
| Retreat HP recovery | 20% | 15-30% | Survival value of retreat command |
| Command cooldown (global) | 10-20s | 8-30s | Frequency of player intervention; lower = more active |
| Retreat uses per battle | 2 | 1-3 | How often the player can save a wounded cat |
| Focus-fire uses per battle | 2 | 1-3 | How often the player can override target priorities |
| Reposition uses per battle | 3 | 2-4 | How much formation flexibility |
| Warmth tier 2 stat bonus | +10% | +5% to +15% | Mid-relationship combat payoff |
| Warmth tier 3 stat bonus | +20% | +15% to +30% | Full-bond combat payoff |
| XP per small encounter | +1 | +1 to +2 | Growth pacing per battle |
| XP per boss encounter | +3 | +2 to +5 | Boss reward weight |
| XP growth: early (per XP) | +2 stats | +1 to +3 | Early-game power curve steepness |
| XP growth: mid (per XP) | +1 stats | +0.5 to +1.5 | Mid-game growth rate |
| XP growth: late (per XP) | +0.5 stats | +0 to +1 | Late-game growth floor (0 = no growth after 7 XP) |
| Wounded penalty | −20% | −15% to −30% | Defeat consequence weight |
| Enemy escalation loop 2 | +20% | +15% to +25% | Difficulty jump after first loop |
| Enemy escalation loop 3 | +35% | +25% to +45% | Mid-game enemy threat |
| Enemy escalation loop 4+ | +50% | +40% to +60% | End-game enemy threat (soft cap) |
| Battle transition duration | 1.5s | 1.0-2.5s | Cinematic feel vs. pace |
| Retreat recovery duration | 3.0s | 2.0-5.0s | How long a cat is out of the fight |

## 8. Acceptance Criteria

1. **AC-01**: Entering a `battle-trigger` node with at least 1 recruited team cat initiates the pre-battle screen. The player can set formation (front/back row) and target priority before pressing "Begin."
2. **AC-02**: Pre-battle screen has no time limit. The countdown does not advance during pre-battle setup.
3. **AC-03**: During battle, team cats fight autonomously — attacking on their SPD interval, following their archetype AI and target priority settings.
4. **AC-04**: Damage is calculated as `max(1, ATK − DEF)`. A cat with 10 ATK hitting a target with 8 DEF deals 2 damage per hit.
5. **AC-05**: Hunter deals ×1.3 damage to targets below 50% HP. Guardian reduces damage to adjacent allies by 25%. Trickster has a 40% chance to evade and expose the attacker (+20% damage taken for 3s).
6. **AC-06**: Observer commands function correctly — Retreat (heals 20% HP over 3s, cat cannot attack), Focus-fire (all cats retarget for 8s), Reposition (move one cat on the grid). Commands share a global cooldown and are limited to their per-battle use counts.
7. **AC-07**: Victory awards +1 XP per participating cat (small encounter) or +3 XP (boss). XP stat bonuses apply according to the diminishing returns curve (§4). Defeat awards 0 XP and applies Wounded (−20% all stats for the rest of the loop).
8. **AC-08**: Warmth tier correctly modifies team cat stats — tier 1 = base, tier 2 = +10%, tier 3 = +20% all stats.
9. **AC-09**: Enemy stats escalate per loop — loop 1 (base), loop 2 (+20%), loop 3 (+35%), loop 4+ (+50%).
10. **AC-10**: Wounded status clears on loop reset. A cat Wounded in loop 2 starts loop 3 at full stats.
11. **AC-11**: Mid-battle time-zero: battle ends immediately, enemies retreat, no rewards, collapse sequence begins. Battle is not resumable.
12. **AC-12**: Team cat XP persists across loops via Save/Load. A cat with 5 XP at the end of loop 2 still has 5 XP at the start of loop 3.
