# Systems Index

*Generated: 2026-05-29 — from approved game concept*
*Design order: Foundation → Core → Feature → Presentation → Polish*

---

## System Map

### Foundation (Infrastructure — must ship first)

| # | System | File | Status | MVP Tier | Key Dependencies |
|---|--------|------|--------|----------|------------------|
| F1 | Save/Load System | save-load-system.md | Complete | Pre-MVP | — |
| F2 | Scene/World Manager | scene-world-manager.md | Complete | Pre-MVP | — |
| F3 | UI/HUD Framework | ui-hud-framework.md | Complete | MVP | — |

### Core (The game IS these — cannot ship without)

| # | System | File | Status | MVP Tier | Key Dependencies |
|---|--------|------|--------|----------|------------------|
| C1 | Movement System | movement-system.md | Complete | Pre-MVP | F2 (Scene/World) |
| C2 | Time/Loop System | time-loop-system.md | Complete | MVP | F3 (UI/HUD), F1 (Save/Load) |
| C3 | NPC Relationship System | npc-relationship-system.md | Complete | MVP | C2 (Time/Loop), F1 (Save/Load), F4 (Dialogue), C5 (Economy) |
| C4 | Auto-Battler Combat System | auto-battler-combat-system.md | Complete | MVP | C2 (Time/Loop), F3 (UI/HUD), F1 (Save/Load), C3 (Relationship) |
| C5 | Economy/Inventory System | economy-inventory-system.md | Complete | MVP | C2 (Time/Loop), F3 (UI/HUD), F1 (Save/Load) |

### Feature (Specific gameplay built on Core)

| # | System | File | Status | MVP Tier | Key Dependencies |
|---|--------|------|--------|----------|------------------|
| F4 | Dialogue System | dialogue-system.md | Complete | MVP | F3 (UI/HUD) |
| F5 | Boss Encounter System | boss-encounter-system.md | Complete | Tier 1 | C4 (Combat), C2 (Time/Loop), C3 (Relationship) |
| F6 | True Ending/Progression System | true-ending-progression-system.md | Complete | Tier 2 | C3 (Relationship), C4 (Combat), F5 (Boss) |
| F7 | NPC Scheduling System | npc-scheduling-system.md | Complete | Tier 1 | F2 (Scene/World), C1 (Movement), C2 (Time/Loop) |

### Presentation (Visual/Audio polish)

| # | System | File | Status | MVP Tier | Key Dependencies |
|---|--------|------|--------|----------|------------------|
| P1 | Traces Visual Feedback System | traces-visual-feedback-system.md | Complete | MVP | C3 (Relationship), C2 (Time/Loop), F1 (Save/Load) |
| P2 | Audio System | audio-system.md | Complete | Tier 1 | — |
| P3 | Cat Animation System | cat-animation-system.md | Complete | Tier 1 | C1 (Movement) |

### Polish (Post-MVP quality)

| # | System | File | Status | MVP Tier | Key Dependencies |
|---|--------|------|--------|----------|------------------|
| PL1 | Tutorial/Onboarding | tutorial-onboarding.md | Complete | Tier 1 | C1 (Movement), F3 (UI/HUD), C2 (Time/Loop) |
| PL2 | Accessibility | accessibility.md | Complete | Tier 1 | F3 (UI/HUD) |

---

## Dependency Graph (Bidirectional)

### Foundation → Core
- **F1 (Save/Load)** → depended on by: C2, C3, C4, C5, P1
- **F2 (Scene/World)** → depended on by: C1, F7
- **F3 (UI/HUD)** → depended on by: C2, C4, C3, C5, F4, PL1, PL2

### Core → Core
- **C1 (Movement)** → depended on by: F7, P3, PL1
- **C2 (Time/Loop)** → depended on by: C3, C4, C5, F5, P1, PL1
- **C3 (Relationship)** → depended on by: F6, F5, P1
- **C4 (Combat)** → depended on by: F5, F6
- **C5 (Economy)** → depended on by: C3

### Core → Feature
- **F4 (Dialogue)** → depended on by: C3
- **F5 (Boss)** → depended on by: F6
- **F6 (True Ending)** → depended on by: —
- **F7 (NPC Scheduling)** → depended on by: C3

### Feature → Presentation
- **P1 (Traces)** → depended on by: —
- **P2 (Audio)** → depended on by: all
- **P3 (Animation)** → depended on by: —

---

## Implementation Order by Scope Tier

### Pre-MVP (Weeks 1-2) — "Greybox loop walkable"
Build F1, F2, C1 first (the village exists and you can move). Then add C2 countdown + loop transition. Then a greybox battle stub.

| Order | System | Reason |
|-------|--------|--------|
| 1 | F2 — Scene/World Manager | Need somewhere to stand |
| 2 | C1 — Movement System | Need to move around |
| 3 | F1 — Save/Load System | Loop persistence needs serialization |
| 4 | C2 — Time/Loop System | Countdown + diegetic transition |
| 5 | C4 stub — Auto-Battler (placeholder) | Greybox 1v1 from prototype |
| 6 | C5 stub — Economy (placeholder) | Fish item + gift interaction |

### MVP (Weeks 1-4) — "Core loop playable"
All Foundation + Core systems fully implemented. One district, 3 NPCs, 1 battle.

| Order | System | Reason |
|-------|--------|--------|
| 7 | F3 — UI/HUD Framework | Need HUD for countdown, team panel, dialogue |
| 8 | F4 — Dialogue System | NPCs need to speak |
| 9 | C5 — Economy/Inventory System | Fish economy with warmth tiers |
| 10 | C3 — NPC Relationship System | Warmth tiers, memory fragments, loop-aware dialogue |
| 11 | C4 — Auto-Battler Combat System | Full implementation: 2 archetypes, observer-commander, enemy escalation |
| 12 | P1 — Traces Visual Feedback System | Visual marks for relationship progress |

### Tier 1 (Weeks 5-8) — "Shippable game"
Two districts, 5 NPCs, 3 team cats, 2 bosses, full emotional arc.

| Order | System | Reason |
|-------|--------|--------|
| 13 | F7 — NPC Scheduling System | NPCs need routines for a living village |
| 14 | F5 — Boss Encounter System | Multi-phase boss fights |
| 15 | PL1 — Tutorial/Onboarding | First-time player experience |
| 16 | P2 — Audio System | Ambient, battle music, SFX |
| 17 | P3 — Cat Animation System | Idle, walk, leap, emotes |
| 18 | PL2 — Accessibility | Text scaling, colorblind, input |

### Tier 2 (Weeks 9-12) — "Full vision"
Four districts, 10 NPCs, 6 team cats, 4 bosses, true ending.

| Order | System | Reason |
|-------|--------|--------|
| 19 | F6 — True Ending/Progression System | Clue assembly, endgame, mystery resolution |

---

## Authoring Order (Dependency-Respecting)

The GDD authoring order respects the dependency graph so each downstream GDD can reference upstream design decisions:

1. **scene-world-manager.md** (F2) — node graph, districts, terrain types
2. **movement-system.md** (C1) — tap-to-move, verticality, interaction range
3. **save-load-system.md** (F1) — serialization strategy, what persists across loops
4. **time-loop-system.md** (C2) — countdown mechanics, diegetic transition, tick rate
5. **ui-hud-framework.md** (F3) — countdown display, team panel, warmth indicators
6. **dialogue-system.md** (F4) — conversation trees, loop-aware branching, memory fragments
7. **economy-inventory-system.md** (C5) — fish, gifts, warmth-tier gating, carry-over rules
8. **npc-relationship-system.md** (C3) — warmth tiers, persistence, memory fragments, recruitment
9. **auto-battler-combat-system.md** (C4) — team management, battle resolution, observer-commander, enemy AI
10. **traces-visual-feedback-system.md** (P1) — permanent marks, cerulean blue, accumulation
11. **npc-scheduling-system.md** (F7) — daily routines, territory, spawn locations
12. **boss-encounter-system.md** (F5) — multi-phase, escalation, abilities
13. **tutorial-onboarding.md** (PL1) — first 10 minutes flow
14. **audio-system.md** (P2) — ambient, SFX, music triggers
15. **cat-animation-system.md** (P3) — sprites, emotes, visual states
16. **accessibility.md** (PL2) — text scaling, colorblind, input remapping
17. **true-ending-progression-system.md** (F6) — clue assembly, endgame conditions

---

## System Count Summary

| Layer | Systems | Pre-MVP | MVP | Tier 1 | Tier 2 |
|-------|---------|---------|-----|--------|--------|
| Foundation | 3 | 2 | 1 | — | — |
| Core | 5 | 2 | 3 | — | — |
| Feature | 4 | — | 1 | 2 | 1 |
| Presentation | 3 | — | 1 | 2 | — |
| Polish | 2 | — | — | 2 | — |
| **Total** | **17** | **4** | **6** | **6** | **1** |
