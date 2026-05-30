# Concept Prototype Report: 猫村物语 (Cat Village Story)

> **Date**: 2026-05-29
> **Prototype Path**: Engine (Godot 4.6 / GDScript)
> **Concept File**: design/gdd/game-concept.md

---

## Hypothesis

"If the player explores a small village, recruits a cat through trust, positions them for an auto-battle, and experiences a loop reset — they will feel the core loop has promise. We'll know this is true if a player completes one full cycle (explore → recruit → battle → reset) without confusion, and expresses interest in what another loop would reveal."

**Verdict**: PARTIALLY CONFIRMED — the core loop functions and movement feels good, but the loop reset itself lacks narrative weight and the fish economy needs clearer sourcing.

---

## Riskiest Assumption Tested

**Auto-battler viability for a first-time dev.** The auto-battle system ran successfully — turn-based combat with cat-specific behaviors (pounce, swipe, hiss), HP bars, and battle log. This risk is downgraded from HIGH to MEDIUM. The basic system works; the challenge is now depth and variety, not feasibility.

---

## Approach

**Path chosen:** Engine (Godot 4.6)
**Reason for path:** Auto-battler timing and node-based movement feel required native rendering. HTML latency would lie about both.

**Shortcuts taken (intentional):**
- All art: ColorRect greybox (no sprites)
- Single-file architecture (~350 lines in `scripts/main.gd`)
- 5 buildings, 2 NPCs, 1 enemy type
- No save/load, no menus, no sound
- Hardcoded cat stats and dialogue
- Loop triggered by button press (no countdown timer)
- Recruit mechanic: one-click "Offer Fish" with no sourcing

---

## Result

**What worked:**
- Click-to-move felt responsive and satisfying — this is the 30-second loop foundation
- Old Tom → Whiskers dialogue chain provided clear direction
- Auto-battle turn-by-turn display was readable and engaging
- Team persistence across loops functioned correctly
- Power increment each loop (P4: loops are growth) gave a sense of progression

**What needs improvement (playtester feedback):**

1. **Countdown missing.** The loop reset is a button — it should be a visible countdown timer in the sky that creates real urgency. The button undermines P3 (time does not wait).

2. **Post-battle transition missing.** After defeating the boss, there's no "world begins to collapse, you reawaken" sequence. The reset button is too mechanical — the loop needs narrative weight.

3. **Loop 2+ dialogue unchanged.** NPCs say the same thing every loop. They should reflect loop awareness — Old Tom should notice something different about you, Whiskers should reference previous battles. This violates P1 (every encounter leaves a mark).

4. **Fish economy unclear.** The player starts with a fish with no explanation. Fish should come from Old Tom (establishing him as a source), and fish should remain useful in later loops to boost team member affinity. Team panel should display affinity level per member.

5. **Team panel too minimal.** Only shows name and stats. Needs affinity level (❤) tied to the fish/gift economy.

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | Engine |
| Iterations to playable | 1 |
| Prototype duration | ~1 session |
| Playtesters | 1 (developer) |
| Feel assessment | Movement responsive and satisfying; loop reset feels mechanical |
| Hypothesis verdict | PARTIALLY CONFIRMED |

---

## Recommendation: PROCEED

The core loop has a functional skeleton — movement flows, auto-battle works, team persists. The issues identified are about narrative weight and economy clarity, not fundamental design flaws. All five improvements are implementation polish on validated systems, not redesigns. Proceed to GDD authoring with these learnings baked in.

---

## If Proceeding

**Core tuning values discovered:**
- Move speed 250px/s felt right for a ~800px village
- Battle turn interval 0.8s was readable
- One recruitable ally with 3-turn battles was the right scope for testing

**Assumptions confirmed:**
- Node-based click-to-move is satisfying for a cat exploration game
- Auto-battler turn-by-turn display is engaging even without animation
- Team persistence across loops creates a sense of continuity

**Assumptions disproved:**
- A button-driven loop reset does NOT feel like a time loop — it needs a countdown, a collapse sequence, and a reawakening
- NPCs repeating identical dialogue across loops feels wrong — P1 demands loop-aware dialogue
- Starting with unexplained resources (fish) creates confusion — all resources need a visible source

**Emergent mechanics worth formalizing:**
- Affinity system: fish/gifts boost team member affinity across loops (P1 + P4 synergy)
- Loop-aware NPC dialogue tiers: Loop 1 = normal, Loop 2+ = NPCs sense something different, Loop 3+ = NPCs remember fragments

**GDD sections that need updating based on prototype findings:**
- Core Loop: add countdown timer as primary driver (not button)
- Core Loop: add post-battle collapse + reawakening sequence
- Economy: add fish sourcing (Old Tom) and affinity boost economy across loops
- NPC System: add loop-aware dialogue tiers
- Team System: add affinity levels and gift economy

**Next steps:**
1. Update `design/gdd/game-concept.md` with prototype learnings
2. `/design-review design/gdd/game-concept.md`
3. `/gate-check`
4. `/art-bible`
5. `/map-systems`
6. `/design-system [mechanic]` (use learnings in Tuning Knobs and Formulas sections)

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  The loop reset being a button is the biggest broken assumption — a time-loop game's reset must be diegetic (countdown → collapse → reawaken), not a UI element. The player needs to see and feel the cycle, not click through it.

- **What surprised us that didn't show up in the brainstorm?**
  Fish economy emerged as a connective tissue between systems (NPC → gift → recruit → affinity boost across loops). The brainstorm treated recruitment as a one-time event; the prototype showed it wants to be an ongoing economy.

- **What would we test differently next time?**
  Test the countdown visual and collapse sequence as the first thing, not the last. The loop transition IS the game's emotional anchor — it should be prototyped before any other system.

---

> *Prototype code location: `prototypes/cat-auto-battle-loop-concept/`*
> *This code is throwaway. Never refactor into production.*
