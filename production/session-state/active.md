# Session State — 猫村物语 (Cat Village Story)

<!-- STATUS -->
Epic: Concept Prototype
Feature: cat-auto-battle-loop
Task: Greybox build — Godot 4.6 engine path
<!-- /STATUS -->

## Current Task

Building concept prototype to validate core loop: explore → recruit → battle → reset.

## Progress

- [x] Hypothesis defined
- [x] Path chosen: Engine (Godot 4.6 / GDScript)
- [x] Scope defined
- [ ] Phase 5: Implement prototype
- [ ] Phase 6: Playtest debrief
- [ ] Phase 7: Generate report

## Hypothesis

If the player explores a small village, recruits a cat through trust, positions them for an auto-battle, and experiences a loop reset — they will feel the core loop has promise. Confirmed if a player completes one full cycle without confusion and wants to do another loop.

## Scope

- 1 village area (greybox ColorRects)
- Node-based click-to-move
- 1 NPC cat (dialogue)
- 1 recruitable cat (gift trust mechanic)
- 1 auto-battle (1v1, feline behaviors)
- Loop reset (team persists)

## Key Decisions

- Engine: Godot 4.6, GDScript
- Review mode: full
- All art: placeholder ColorRects
- No save/load, no menus, no sound, no polish
