# Game Concept: 猫村物语 (Cat Village Story)

*Created: 2026-05-27*
*Updated: 2026-05-29 (prototype learnings incorporated)*
*Status: Draft — prototype-validated*

> **Creative Director Review (CD-PILLARS)**: CONCERNS — resolved 2026-05-27. P2/P5 tension resolved, P4 falsifiable test added, P5 cat-specificity added. Pillars locked.

> **Art Director Review (AD-CONCEPT-VISUAL)**: STRONG — 痕迹 (Traces) selected 2026-05-27. Visual rule: "The world remembers you."

> **Technical Director Review (TD-FEASIBILITY)**: CONCERNS — mitigated 2026-05-27. Node-based traversal, 3-archetype limit, PC-first.

> **Producer Review (PR-SCOPE)**: OPTIMISTIC — timeline revised 2026-05-27. Pre-MVP (wk1-2), MVP (wk1-4), Tier 1 ship (wk5-8), Tier 2 full vision (wk9-12). Mobile deferred to post-launch.

> **Concept Prototype (cat-auto-battle-loop)**: PROCEED 2026-05-29. PARTIALLY CONFIRMED — movement + auto-battle work. P3 countdown, loop transition, loop-aware NPC dialogue, fish economy, and affinity system need implementation.

> **Creative Director Review (CD-PLAYTEST)**: APPROVE with CONCERNS 2026-05-29. Core fantasy foundation verified. P1 and P3 must be demonstrable before next gate.

---

## Elevator Pitch

> It's a narrative-exploration game with strategic auto-battler combat where you play as a cat in a doomed village, racing against a 7-year countdown in the sky. When time runs out, the world cracks and you enter a new loop — but your relationships and knowledge persist.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Narrative-Exploration / Strategic Auto-Battler |
| **Platform** | PC (Steam) — mobile post-launch |
| **Target Audience** | Explorers + Storytellers (see Target Player Profile) |
| **Player Count** | Single-player |
| **Session Length** | 45-90 minutes per loop session |
| **Monetization** | Premium |
| **Estimated Scope** | Medium (12 weeks full vision, solo). Shippable Tier 1 at 8 weeks. |
| **Comparable Titles** | Outer Wilds (loop mystery), Spiritfarer (NPC relationships), Super Auto Pets (auto-battler) |

---

## Core Fantasy

You are a cat who sees what others don't — a countdown in the sky counting toward annihilation. You explore a dense, vertical village, befriend its inhabitants, and uncover the cosmic mystery behind the cycle. The fantasy is twofold: the **curiosity-driven discovery** of a cat exploring every rooftop and alleyway, and the **strategic mastery** (运筹帷幄) of recruiting, raising, and positioning a team of cats whose battles play out based on your preparation — not your reflexes.

This game answers: "What would I do if I knew exactly when the world would end, and I was the only one who remembered?"

---

## Unique Hook

Like Outer Wilds meets an auto-battler, **AND ALSO** your relationships with NPC cats persist across loops. The village remembers you — a cat you befriended last loop might leave you a clue this loop. The world accumulates evidence of your existence loop over loop. No reset is truly clean.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Narrative** (drama, story arc) | 1 | Cross-loop mystery unraveling; NPC relationship arcs that deepen across resets |
| **Discovery** (exploration, secrets) | 2 | Dense vertical village with hidden areas; loop-specific secrets that require future-loop knowledge |
| **Fantasy** (make-believe, role-playing) | 3 | Being a cat — rooftop traversal, territory, curiosity-driven social bonds |
| **Challenge** (obstacle course, mastery) | 4 | Strategic team composition and positioning; boss encounters that test preparation |
| **Expression** (self-expression, creativity) | 5 | Team composition choices; which NPCs to prioritize with limited time |
| **Sensation** (sensory pleasure) | 6 | Warm, cozy visual style with Traces marks accumulating; atmospheric audio |
| **Submission** (relaxation, comfort zone) | 7 | The village is a comforting space — familiarity deepens across loops |
| **Fellowship** (social connection) | N/A | Single-player experience; NPC relationships simulate fellowship |

### Key Dynamics (Emergent player behaviors)

- Players will plan routes through the village to maximize relationship progress within limited time
- Players will experiment with team compositions to find synergies for specific boss encounters
- Players will leave deliberate "markers" for their future-loop self (hidden items, unfinished conversations)
- Players will develop emotional attachments to specific NPC cats and prioritize their arcs
- Players will share discoveries and hidden clues with the community

### Core Mechanics (Systems we build)

1. **Node-based cat traversal** — tap-to-move rooftop pathfinding with verticality (P2: cat perspective)
2. **Relationship system with loop persistence** — NPCs remember fragments across resets; dialogue changes across loops. Loop 1: normal introduction. Loop 2+: NPCs sense something different about you (deja vu). Loop 3+: specific NPCs remember fragments of previous interactions. Deeper relationships unlock new dialogue, clues, and recruitment opportunities (P1: every encounter matters)
3. **Time-pressure loop mechanic** — 7-year countdown visible in the sky at all times; real trade-offs about how to spend limited time. Loop transition is diegetic: sky cracks → world collapses → player reawakens (P3: time does not wait)
4. **Strategic auto-battler** — recruit cats through trust and gifts, train them, position by territory. They fight autonomously with feline-specific behaviors. Team panel shows name, stats, and affinity level (❤) for each member — affinity grows through gifts and shared battles across loops (P5: strategic mastery, P1, P4)
5. **Gift economy (fish)** — resources have visible sources. Example: Old Tom gives the player a fish → use fish to recruit Whiskers → fish respawns in specific locations each loop → fish can be given to existing team members to boost affinity in later loops. Every resource has a source the player can see and understand (P1, P2, P4)
6. **Traces visual feedback system** — every significant interaction deposits a permanent visual mark in the world. Affinity growth changes team cats' visual appearance (coat sheen, accessories). The village accumulates evidence of the player's existence loop over loop (P1, P4)

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Real choices about who to befriend, what to investigate, how to spend limited time each loop | Core |
| **Competence** (mastery, skill growth) | Strategic mastery of team composition and positioning; knowledge mastery of NPC schedules and loop patterns | Supporting |
| **Relatedness** (connection, belonging) | Deep relationship system with NPC cats — they remember across loops, react to choices, and their fates matter | Core |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: Dense vertical village with hidden areas; cosmic mystery to unravel; loop-specific secrets requiring future knowledge
- [x] **Socializers** (relationships, cooperation, community) — How: NPC relationship system with persistent memory across loops; emotional investment in cat characters
- [x] **Achievers** (goal completion, collection, progression) — How: Recruiting team cats; completing NPC relationship arcs; discovering the true ending
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — Minimal. Auto-battler provides strategic mastery satisfaction but no PvP.

### Flow State Design

- **Onboarding curve**: First 10 minutes — cat wakes up in village, sees countdown for the first time, meets a friendly NPC who introduces traversal, observes a small auto-battle encounter. No systems dumped at once.
- **Difficulty scaling**: Early loops are generous with time — the player learns the village. Later loops introduce harder boss encounters and more complex relationship webs. The challenge shifts from "how do I move?" to "how do I optimize my limited time?"
- **Feedback clarity**: Traces visual marks on the world show relationship progress. Relationship tier indicators on NPC dialogue. Countdown is always visible. Battle outcomes clearly show why teams won or lost.
- **Recovery from failure**: Loop reset is instant. Player always carries forward new knowledge, deeper relationships, and at least one new option. Failure is information — never a dead end.

---

## Core Loop

### Moment-to-Moment (30 seconds)
The player taps rooftops and landmarks to move their cat gracefully through the village. They pause to observe NPCs, read environmental clues, and notice Traces marks from previous loops. Movement itself is satisfying — the cat leaps, climbs, and slips through gaps. The countdown clock is always visible in the sky, ticking down — it is the dominant visual element and the primary driver of all decisions.

### Short-Term (5-15 minutes)
"One more conversation" psychology: the player follows a narrative thread — finding a specific NPC, completing a dialogue chain, exploring one district, positioning a team cat in a new territory. Each interaction potentially reveals a clue about the countdown, deepens a relationship, or opens a new thread.

### Session-Level (45-90 minutes)
One complete loop. The player reaches a narrative beat — a relationship deepens, a hidden area is discovered, a boss encounter is triggered. The countdown advances visibly toward zero. Hard choices: pursue Cat A's storyline or Cat B's? Investigate the shrine or the old mill?

**When the countdown hits zero** (or the player triggers the final boss), a diegetic sequence plays: the sky cracks, the world begins to collapse, and the player's cat is enveloped in light. They reawaken at the start of the village — but their team, relationships, and Traces marks persist. This transition is the emotional anchor of the game: it must feel like a genuine death-and-rebirth, not a UI button.

### Long-Term Progression (across loops)
The player grows through knowledge (understanding NPC schedules, hidden paths, boss weaknesses), relationships (NPC memory fragments persist and deepen), and team strength (recruited cats carry forward). The long-term goal: understand WHY the countdown exists and whether the cycle can be broken.

### Retention Hooks
- **Curiosity**: What happens when the countdown hits zero? Who is behind the cycle? What secret does the locked shrine hold in loop 3?
- **Investment**: NPC cats the player genuinely cares about. Time spent building relationships that persist. The village itself feels like home.
- **Mastery**: Optimizing loop routes, perfecting team compositions, discovering synergies, reaching the true ending.

---

## Game Pillars

### Pillar 1: 每一次相遇都有意义 (Every Encounter Leaves a Mark)
No throwaway NPCs. Every cat in the village has a story, a personality, and a memory of you that persists across loops.

*Design test*: If we're debating between adding a new NPC or deepening an existing one, this pillar says deepen.

### Pillar 2: 猫的视角 (A Cat's Perspective)
The world is seen and interacted with as a cat would — vertical movement, curiosity-driven exploration, and social bonds formed through territory, play, and gift-giving, not commands. You don't recruit a cat; you earn their trust by entering their world on their terms.

*Design test*: If a mechanic would also work for a human protagonist, it's not cat enough.

### Pillar 3: 时间不等人 (Time Does Not Wait)
The countdown is real. You cannot do everything in one loop. Every decision to pursue something is a decision to let something else go.

*Design test*: If a feature lets players do everything comfortably in one loop, it violates this pillar.

### Pillar 4: 轮回即成长 (Loops Are Growth)
Failure isn't failure — it's information. Each loop you know more, relationships are deeper, and new possibilities open. The game gets richer, not harder.

*Design test*: After each loop reset, has the player gained at least one concrete new option that was unavailable last loop — a deeper relationship tier, a new area opened by trust, a clue about the mystery, or a new team member? If the answer is ever "no," this pillar is failing.

### Pillar 5: 运筹帷幄 (Strategic Mastery)
Combat is won before the fight starts. The player recruits cats through trust, trains them, and positions them by territory. When battle begins, cats fight on their own — their behaviors, synergies, and victory conditions express feline nature (curiosity, agility, territory, pride), not generic RPG roles. No warriors, mages, or healers — only cats being cats.

*Design test*: If a combat outcome depends on the player pressing buttons at the right time, it violates this pillar.

### Anti-Pillars (What This Game Is NOT)

- **NOT manual action combat**: No button-timing, no dodge-rolling, no skill shots. The player's combat skill is preparation, positioning, and team composition. This preserves P5.
- **NOT a massive open world**: The village is dense and finite — a curated, looping space with verticality. Density over sprawl. This preserves P3 and respects the timeline.
- **NOT voice acting or cutscene-driven storytelling**: The narrative lives in conversations, environmental details, and player discoveries. This preserves P2 and keeps scope manageable.

---

## Visual Identity Anchor

### Direction: 痕迹 (Traces)

**Visual Rule**: "The world remembers you."

Nothing resets clean. Every NPC interaction deposits a permanent visual mark — a pawprint scar on a wall, a gifted ribbon tied to a post, a cat's coat changing color after a significant conversation. The village accumulates evidence of the player's existence loop over loop.

### Mood and Atmosphere
Bittersweet accumulation. Cozy but heavy with history. A scrapbook village — lived-in, personal, always becoming more.

### Shape Language
Soft, rounded, layered. Cats are circles within circles — silhouettes should read as brush-stroke blobs, not sharp lines. Environments use overlapping organic forms — stacked cushions, woven baskets, draped fabric, knotted rope bridges.

### Color Philosophy
Warm earth base (ochre, terracotta, moss, amber, sage). Memory-marks use a single accent hue — cerulean blue — that grows in saturation each loop. Blue = permanence. The countdown in the sky is pale gold bleeding to white (urgency without menace).

### Design Tests
- If a new visual element doesn't answer "how will this change across loops?", it's not finished.
- If an NPC's visual state is identical between loop 1 and loop 3, Traces is failing.
- The cerulean blue accent should never appear on things that reset — only on things that persist.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Outer Wilds | Knowledge-gated progression; cosmic mystery unraveled through exploration; loop resets that feel enlightening, not punishing | NPC relationships persist across loops and drive the emotional core, not just curiosity | Validates that loop-based mystery games have an audience and can be deeply moving |
| Spiritfarer | Emotional NPC relationships as the primary driver; helping characters complete their arcs; cozy aesthetic with heavy themes | Auto-battler strategic layer adds a mechanical hook beyond relationships; time-pressure creates real stakes | Validates that emotional NPC bonds can carry a game without traditional combat |
| Super Auto Pets | Accessible auto-battler design; strategic depth through team composition and positioning | Feline-specific behaviors and synergies instead of generic archetypes; battles framed as territorial disputes, not fights to the death | Validates auto-battler as a commercially viable genre with low barrier to entry |

**Non-game inspirations**: The concept of 轮回 (reincarnation cycle) from Buddhist philosophy — the idea that each life carries forward karma from the previous one. Studio Ghibli's slice-of-life pacing and reverence for small, quiet moments. The idiom "运筹帷幄之中，决胜千里之外" (devise strategies within a command tent to win battles a thousand miles away) from Sun Tzu's The Art of War.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-35 |
| **Gaming experience** | Mid-core — comfortable with narrative games and light strategy |
| **Time availability** | 45-90 minute sessions; game respects both short and long sessions |
| **Platform preference** | PC (primary), mobile (future) |
| **Current games they play** | Outer Wilds, Spiritfarer, Honkai: Star Rail, Stardew Valley |
| **What they're looking for** | A game that makes them feel something — emotional connection to characters, the thrill of discovery, the satisfaction of a plan coming together |
| **What would turn them away** | Mindless action, paper-thin characters, pay-to-win mechanics, games that waste their time without meaningful choices |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 — already pinned in project. Excellent for 2D, strong multi-platform export (PC → mobile later), lightweight. Scene/node model maps cleanly to NPCs and combat units. Resource system handles loop persistence serialization. |
| **Key Technical Challenges** | Auto-battler AI (cat-specific behaviors, positioning mechanics, synergy logic); NPC memory persistence across loops (save/load complexity, relationship state management); countdown-time trade-off balancing |
| **Art Style** | 2D — soft rounded shapes, warm earth palette, cerulean blue Traces accent. Flat-color with subtle texture. |
| **Art Pipeline Complexity** | Low-Medium. 2D sprites with overlay systems for Traces marks. Cat sprites need differentiation (coat patterns, accessories). Minimal animation — idle, walk, leap, a few emotes. |
| **Audio Needs** | Moderate. Ambient village atmosphere (wind, distant chatter, clock ticking). Simple UI sounds. Battle music — one track per boss. No voice acting (anti-pillar). |
| **Networking** | None — single-player |
| **Content Volume** | 4 village districts, 10 NPC cats, 6 team cats, 4 boss encounters, 3-4 narrative loops, 6-10 hours total playtime (full vision) |
| **Procedural Systems** | None — hand-crafted village and NPC schedules |

---

## Risks and Open Questions

### Design Risks
- Time pressure balance: too much pressure = stressful and unfun; too little = P3 fails and choices feel meaningless
- Auto-battler may feel disconnected from the narrative core if not thematically integrated
- Players who dislike missing content may reject P3's trade-off structure

### Technical Risks
- Auto-battler AI — HIGH. Combinatorial testing debt: every new cat archetype multiplies test cases. Mitigated by launching with exactly 3 archetypes and 1 synergy pair.
- NPC memory persistence across loops — MEDIUM. Save/load complexity for relationship states. Godot's Resource system handles serialization well but needs careful design.
- Dual-genre scope (narrative + auto-battler) — HIGH. Building two full gameplay loops as a first game. Mitigated by node-based traversal (not physics) and ruthless scope discipline.

### Market Risks
- Niche intersection: loop-mystery + NPC relationships + auto-battler is novel but unproven as a combination
- Solo-developed narrative game competes with studio productions on emotional impact
- Chinese-culture 轮回 framing may resonate differently across markets

### Scope Risks
- Content volume for 10 NPCs with full relationship arcs is ambitious for a solo first game
- Mobile port as post-launch scope — needs to be considered in initial UI architecture even if deferred

### Open Questions
- How does a cat "recruit" another cat in a way that feels feline? **ANSWERED (prototype): Gift-giving economy — NPC gives fish, player offers fish to recruitable cat. Trust established through visible resource exchange.**
- What specifically triggers the countdown advance? Real-time? Action-based? Hybrid? **ANSWERED (prototype): Countdown is a visible clock always ticking in the sky. Loop transition is diegetic — collapse + reawakening, not a button. Exact tick rate TBD (real-time vs. action-gated).**
- Can the 3-archetype auto-battler limit still feel strategically deep? **PARTIALLY ANSWERED (prototype): Basic 1v1 auto-battle works. Depth at 3 archetypes needs testing in MVP.**
- What is the "true ending" — does the player break the cycle, or accept it?
- How many loops before NPC dialogue variation exhausts? Loop 1 / Loop 2+ / Loop 3+ tiers defined — need exact dialogue count per tier per NPC.
- Affinity system: what mechanical benefits does higher affinity unlock? (Team stat bonuses? New abilities? Narrative reveals?)

---

## MVP Definition

**Core hypothesis**: Players find the exploration-relationship-loop core engaging, and the auto-battler adds strategic depth without undermining the narrative intimacy.

**Required for Pre-MVP (Weeks 1-2)**:
1. Greybox traversal (node-based tap-to-move on a simple village layout)
2. Placeholder auto-battle (one cat vs. one enemy, basic AI)
3. Visible countdown timer in the sky (greybox — number counting down)
4. Diegetic loop transition (countdown hits zero → flash/screen shake → player reawakens at start with team intact)
5. One gift item (fish) with visible source (NPC gives it) and visible use (recruit or boost affinity)

**Required for MVP (Weeks 1-4)**:
1. 1 village district with full art (Traces visual style)
2. 3 NPC cats with relationship system (tier 1-3, loop-aware dialogue for loops 2+)
3. 1 recruitable team cat via fish gift
4. Team panel with affinity levels (❤) per member
5. 1 auto-battle encounter with 2 archetypes
6. 1 full loop with diegetic collapse + reawakening sequence (countdown → sky cracks → world collapses → reawaken with memory and new options)
7. Fish respawns in loop 2+, usable to boost team affinity

**Explicitly NOT in MVP**:
- Multiple village districts
- More than 3 archetypes
- Boss encounter variety
- Mobile support
- True ending

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **Pre-MVP** | Greybox layout, 1 placeholder NPC | Basic traversal + loop trigger + placeholder battle | Weeks 1-2 |
| **MVP** | 1 district, 3 NPCs, 1 team cat, 1 boss | Core loop fully functional — validates the hypothesis | Weeks 1-4 |
| **Tier 1 (Minimum Shippable)** | 2 districts, 5 NPCs, 3 team cats, 2 bosses | 2 narrative loops, full emotional arc, shippable game | Weeks 5-8 |
| **Tier 2 (Full Vision)** | 4 districts, 10 NPCs, 6 team cats, 4 bosses | 3-4 narrative loops, true ending, full polish | Weeks 9-12 |
| **Post-Launch** | Mobile port | Touch UI, performance optimization, additional archetypes | After Week 12 |

---

## Next Steps

- [x] Get concept approval from creative-director (CD-PILLARS: CONCERNS resolved, pillars locked)
- [x] Visual identity anchor selected (AD-CONCEPT-VISUAL: STRONG, Traces chosen)
- [x] Technical feasibility assessed (TD-FEASIBILITY: CONCERNS mitigated)
- [x] Scope validated (PR-SCOPE: OPTIMISTIC, timeline revised)
- [x] Run `/setup-engine` — Godot 4.6 / GDScript configured, technical preferences populated
- [x] Run `/prototype cat-auto-battle-loop` — PROCEED. Core loop validated, 5 improvements identified and incorporated into this document
- [ ] Run `/design-review design/gdd/game-concept.md` — validate concept completeness after prototype revisions
- [ ] Run `/gate-check` — confirm readiness to advance to Systems Design
- [ ] Run `/art-bible` — create the visual identity specification based on 痕迹 (Traces) direction
- [ ] Run `/map-systems` — decompose concept into individual systems with dependencies
- [ ] Run `/design-system [system-name]` — author per-system GDDs in dependency order
- [ ] Run `/create-architecture` — produce the master architecture blueprint
- [ ] Run `/architecture-review` — validate architecture coverage
