# Game Design

# Interstellar Survivors

A game for Play.date https://sdk.play.date/3.0.2/

# Pitch

Interstellar Survivors is a Vampire Survivors (​​[https://vampire.survivors.wiki/](https://vampire.survivors.wiki/)) style single stick auto-shooter rogue-like. The player controls a space station that must defend itself from attack. The station is armed with Tools that automatically fire when threats are in-range. The player uses the Play.date crank to rotate the space station, which can bring different Tools to bear on different enemies. As the player successfully defends the station, they gain upgrades, selected from a random assortment after each leveling event. The upgrades change both the look of the station and offer some new ability or Tool to be used. Some upgrades interact with each other to provide extra effects—when a Tool is paired with its matching Bonus Item, it becomes an Upgraded Tool with significantly improved stats and new abilities. The choices the player makes, and the random chance of which upgrades are made available to them on each level, adds to the gameplay as the player tries to arm the station in a way that supports some strategy of survival. Diverse threats require diverse defensive Tools and unique strategies to counteract. Players can adopt multiple strategies to win, and an experienced player will be able to use whatever upgrades they are allowed to form a unique gameplay style that could win.

As players complete rounds of Episode gameplay, they unlock a progression of levels that allow them to control space stations in different locations. The different locations offer unique dangers and threats. Some levels will be locked at first so the player will not know what to expect until they unlock the level.

Each Episode uses some classic science fiction story/concept as its baseline. These are never directly referenced, but are parodied in a melodramatic, fun way. Each Episode begins and ends with a story segment that sets the scene. These scenes build the sense of adventure and provide fun narrative energy to propel the player forward.

There is a meta game of unlocking Research Specs (specifications). Each Research Spec opens some buff or debuff in the game. For example, one Research Spec might give a \+10% to laser damage. Or another Spec might offer health restoration on a regular timer for the station.

The vibe of the game is sci-fi comedy. This is a melodramatic game centered around a crew of interstellar researchers. They are deployed on Episodes around the universe to do research, protection, resource extraction, and more. The game makes references to many science fiction stories, games, and movies. It favors golden age and new wave science fiction, but all science fiction content and references are allowable.

The game is framed as a campy sci-fi television series called "Interstellar Survivors." Each Episode is a self-contained adventure with its own title, tagline, and story panels. Season 1 consists of 5 Episodes.

# Gameplay

This game has two levels of play, being a rogue-like: There is the primary game, which plays in sessions. Doing different things in the primary game will unlock items that will affect the gameplay in different ways (usually as buffs).

## The Menus

The game opens to the Main Menu, which offers these choices:

1. New Episode  
2. Continue Episode  
3. Research Specs  
4. Game Settings

Note: This game will use the Play.date built in pause menu. It will insert a Main Menu option into the play menu that returns the player to the main game menu.

These actions happen when the player selects a menu option:

1. Pressing New Episode or Continue will take the player into an Episode.  
   1. The player can only have one saved Episode at a time.  
   2. Saved Episodes are deleted after the gameplay session is complete (when the ship hits zero health or the Boss is defeated)  
2. When the player presses "New Episode" if there is a saved Episode they will be reminded that they can continue that game.  
   1. If the player chooses to continue, the previous saved Episode file is loaded and the game continues  
   2. If the player chooses to start a new Episode anyway, the previous save game file is deleted and a new one is started.  
   3. If starting a new Episode, the player must first select an Episode from the Episode Guide  
   4. After selecting an Episode, the player can press the Start button to begin the gameplay  
2. The Research Specs button leads to the Research Specs screen.  
   1. In this screen, Specs are listed with all their info.  
   2. Unlocked and locked specs are differentiated.  
   3. There will be quite a few Specs, so the page must be able to filter between locked and unlocked  
2. The Game Settings button leads to the Game Settings screen.  
   1. Game Settings will include:  
      1. Audio  
         1. Background music on/off  
         2. SFX on/off  
         3. Cutscene audio on/off  
      2. Gameplay  
         1. Cutscenes on/off (Turn off cutscenes so they do not show before/after levels if the player desires. They are on by default.)  
      2. Game Progress  
         1. Percentage of completion based on this formula:  
            **TotalCompletionPercentage \= (SpecsCompletionPercent \+ EpisodeCompletionPercent)/2**  
         2. SpecsCompletionPercent and EpisodeCompletionPercent are both calculated using the same basic formula:  
            **CompletionPercent \= (NumUnlocked / NumTotal) \* 100**  
      2. Reset game progress  
         1. The user sees a confirmation that says: "This clears all game data including unlocked Episodes and Research Specs"  
         2. The user must confirm they intend to reset the game progress by affirming with a button tap  
         3. The user can cancel instead of resetting the game

NOTE: This game uses two forms of saved data:

2. Saved Game Data  
   1. Stores all details about metagame completion and status  
   2. One file per Play.date (always loads the one Saved Game Data when the game runs)  
   3. Tracks unlocked Research Specs and Episodes  
   4. Tracks all challenge and historical gameplay data  
   5. Tracks all game settings  
   6. Automatically managed by the game  
3. Episode Save Data  
   1. Created when a new Episode starts  
   2. Deleted when the Episode ends (whether successful or unsuccessful)  
   3. Tracks all data about current Episode state:  
      1. Status of Space Station  
      2. Status of game field and MOBs  
      3. Status of progress against Episode goals  
   4. Automatically managed by the game

## The Episode Gameplay

Each Episode is designed to be a somewhat quick, disposable experience. The game loop goes like this:

2. Player loads Episode and it automatically loads previous player save data  
3. Player selects an Episode from the Episode Guide  
4. Player views a short story segment that sets the scene (3 intro panels)  
   1. The player can skip past the story segment at any time  
2. The game field is drawn, and a starting message is shown  
   1. This phrase changes per Episode (see Systems Update tab for Starting Messages)  
   2. This text shows over the game field for 1.5 sec then fades  
2. Player controls the space station, rotating it to hit incoming MOBs with projectiles  
   1. MOBs move according to their defined patterns  
   2. MOBs have different levels of health  
      1. MOB health is represented as a small white bar that hovers directly above the MOB  
      2. MOB health is only shown for 1s when the MOB is hit (and the 1s timer restarts whenever the MOB takes another hit, so the bar will be shown while the MOB is being shot, but will fade out 1s after it has been hit for the last time.)  
   3. When a MOB is destroyed, the player earns Research Points according to the MOB definition  
      1. These points are immediately reflected on the RP bar across the top of the game screen  
2. When RP points fill the bar from the left of the screen to the right of the screen, the player levels up  
   1. The amount of RP required to fill up the bar is determined according to the leveling table  
   2. The RP bar display scales based on the amount of RP required to move from the current level to the next level (the Levels Table defines how many RP are needed between each level)  
      1. Example: going from Level 1 to Level 2 requires 130RP. So the bar would be at 50% width when the player has earned 65RP. Then, when going from level 2 to 3 the game requires more RP to be earned. So the bar resets and the game counts toward the new goal.  
2. At each level the player can select one of four items from a randomly generated list of Tools and Bonus Items  
   1. The Episode progress is saved on each level up  
   2. Different items have different effects on the gameplay and attach to the space station in a different way  
   3. Different Tools have different projectile patterns, so the player must rotate the space station to take advantage of them and neutralize incoming objects  
   4. Different Tools and Bonus Items can combine to create Upgraded Tools with new effects. See Systems Update tab for the complete Tools, Bonus Items, and Upgraded Tools tables.  
3. Waves of MOBs come at the space station in 7 waves over 7 minutes, increasing in difficulty. At the 7:00 mark, the Boss spawns. See Systems Update tab for Wave System details.  
4. **Win Condition:** Defeat the Boss to complete the Episode. Ending panels play, Research Spec is unlocked, and the next Episode becomes available.  
5. **Lose Condition:** The space station has a health value that causes the game to end when it hits zero. The station blows up and "To Be Continued..." is displayed.

## The Meta Gameplay

There is an additional level of gameplay that comes through as Research Specs. Research Specs are items that can be gained by completing different challenges in the game. Unlocking a Research Spec is permanent. Once the challenge related to that Research Spec is complete, that item will always affect the game.

Players can view a list available from the main menu of their unlocked Research Specs to learn more about them. They are defined in the Research Specs table (see Systems Update tab), and include items like "Ancient Alloys" to increase the health of the Station, or "Optimized Targeting" to make projectiles track more accurately.

When a new Episode starts, the effects of all unlocked Research Specs are noted and applied to the gameplay session. When a new Research Spec is unlocked, its buffs take effect immediately.

# Game Data

The following are tables that provide game data to be used during play. For complete tables of Tools, Bonus Items, Upgraded Tools, Wave System, Boss Mechanics, and Research Specs, see the **Systems Update** tab.

## General Game Data

1. BOSS\_SPAWN\_TIME=7min  
2. MAX\_TOOLS\_PER\_EPISODE=6  
3. MOB\_DAMAGE\_MULTIPLIER=1  
4. BASE\_XP=100  
5. BASE\_LEVEL\_EXPONENT=1.2  
6. STATION\_BASE\_HEALTH=100  
7. ROTATION\_SPEED=180° per crank revolution

## Research Specifications

See **Systems Update** tab for complete Research Specs table (8 specs with unlock conditions).

## MOBs

MOBs (things that come towards your space station in the game) have a base health. The base health and base damage are multiplied by the wave difficulty scaling, but the base speed is not. Some MOBs have multiple levels. When a MOB has multiple levels look for the \-small, \-medium, and \-large sprites to correspond to levels 1, 2, and 3\.

If a MOB "emits" then it shoots something out of it. MOBs that emit particles will not try to run into the station. They will hover around the station in range of their weapons. The only way to get rid of those MOBs is to destroy them with a Tool.

A MOB has a range, which is how far away they can inflict damage. For example, an asteroid can only inflict damage when it runs into an object, so the range for an asteroid is 1px. However, Mysterious Orbs emit particles that do damage, and their range is 50px.

A MOB will always try to get within range of the Station to inflict damage. For MOBs that DO NOT emit, they follow a straight path across the play field. This path will usually intersect with the station, but the angle of entry for MOBs should be random. MOBs that DO NOT emit cannot change their course.

A MOB that can emit is able to steer itself on its own course. These MOBs will try to get within range of their weapons, and then engage the station without continuing to move forward. The MOBs will move around like flies circling a piece of food as they shoot towards the station.

All MOBs earn the station Research Points. Research Points are required to level up.

### Generic MOBs (used across multiple Episodes)

| Name | Description | Research Points | Base Health | Base Speed | Base Damage | Levels | Range | Emits? |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| Asteroid | Asteroids are common and can threaten the station just by ramming into it. But they also contain minerals and other clues to life in the universe, so they are worth studying when possible. | 5 | 10 | 5 | 5 | 3 | 1 | no |
| Gas Cloud | Gas clouds are slow, but they can still be dangerous. You never know the kind of effect they will have on your station. Best to study them or remove them. | 5 | 20 | 1 | 8 | 3 | 1 | no |
| Mysterious Orbs | These mysterious orbs are a mystery, but we know one thing: They shoot little balls that hurt like heck\! Removing them is more difficult because they are so quick. | 10 | 5 | 10 | 2 | 1 | 50 | yes |

For Episode-specific MOBs (Threats), see the **Mission Content** tab.

## Episodes

Episodes are the "levels" in the game, framed as TV show episodes. Episode 1 is unlocked at the start. Completing each Episode unlocks the next.

| Episode | Title | Tagline | Starting Message |
| :---- | :---- | :---- | :---- |
| 1 | "Spin Cycle" | "They just want to be friends. Aggressively." | WELCOME COMMITTEE INBOUND |
| 2 | "Productivity Review" | "Your feedback is important to us." | QUARTERLY TARGETS: MANDATORY |
| 3 | "Whose Idea Was This?" | "Reality is more of a suggestion." | PROBABILITY: OPTIONAL |
| 4 | "Garbage Day" | "One civilization's apocalypse is another's opportunity." | SALVAGE RIGHTS: CONTESTED |
| 5 | "Academic Standards" | "Peer review can be brutal. Literally." | ATTENDANCE: MANDATORY |

For complete Episode details (Threats, Collectibles, Bosses, Story Panels), see the **Mission Content** tab.

## Station Leveling

The station itself levels up whenever the following research point goals are met. Research Point (RP) progress towards the next level is visualized as a white bar extending across the screen at the very top of the gameplay field. It is just 2px wide. It grows from left to right as research points are earned, scaling according to how many points are required to hit the next level. It hits 100% across the screen when the next level points. (So if the next level was at 100rp, and the player had 50rp then the white bar would extend 50% across the top of the screen.) Note that we do not need to count the total RP earned. The game always looks at the current level, then sets the next level up goal to the amount of RP required to reach the next level. All games start on Level 1, which requires 0 RP. Level 2 requires 130 RP, so the bar will scale accordingly. Each level requires a little more RP to earn it. There is no upper limit for levels.

This game uses the following formula to define levels:

**BASE\_XP × (LEVEL^EXPONENT \- 1\)**

So with a base of 100 and exponent of 1.2:

* Level 1: 100 × (1^1.2 \- 1\) \= 100 × (1 \- 1\) \= 0  
* Level 2: 100 × (2^1.2 \- 1\) \= 100 × (2.30 \- 1\) \= 130  
* Level 5: 100 × (5^1.2 \- 1\) \= 100 × (7.14 \- 1\) \= 614  
* Level 10: 100 × (10^1.2 \- 1\) \= 100 × (15.85 \- 1\) \= 1,585

BASE\_XP will be 100 for the game (set in game constants)

BASE\_LEVEL\_EXPONENT will be 1.2 for the game (set in game constants)

When a new level is achieved, the amount required to hit the next level will be calculated, and the RP bar display will be adjusted accordingly. There may be times when these counts are going up very rapidly, so this needs to be fast to update.

## Tools

Tools extend the capabilities of the space station. They are, effectively, "weapons", but since this is a research vessel the station only has defensive tools and research tools (which the station can use to defend itself, too).

The station has **8 attachment points** arranged around its perimeter. Tools attach to the next available slot when selected. Maximum **6 Tools** can be attached per Episode. All Tools rotate with the station when the player uses the crank.

For the complete Tools table (8 Tools with stats, patterns, and upgrade paths), see the **Systems Update** tab.

### Tool Summary

| Tool | Available | Pairs With | Upgrades To |
| :---- | :---- | :---- | :---- |
| Rail Driver | Start | Alloy Gears | Rail Cannon |
| Frequency Scanner | Start | Expanded Dish | Harmonic Disruptor |
| Tractor Pulse | Start | Magnetic Coils | Gravity Well |
| Thermal Lance | Episode 1 | Cooling Vents | Plasma Cutter |
| Cryo Projector | Episode 2 | Compressor Unit | Absolute Zero |
| EMP Burst | Episode 3 | Capacitor Bank | Ion Storm |
| Probe Launcher | Episode 4 | Probe Swarm | Drone Carrier |
| Repulsor Field | Episode 5 | Field Amplifier | Shockwave Generator |

## Bonus Items

Bonus Items are passive upgrades selected at level-up. Some Bonus Items provide general stat boosts; others combine with specific Tools to create Upgraded Tools with significantly improved stats and special effects.

For the complete Bonus Items table (16 items with effects and unlock conditions), see the **Systems Update** tab.

### Bonus Item Summary

**Tool Upgrade Items:** Alloy Gears, Expanded Dish, Magnetic Coils, Cooling Vents, Compressor Unit, Capacitor Bank, Probe Swarm, Field Amplifier

**General Passive Items:** Reinforced Hull, Overclocked Capacitors, Extended Sensors, Emergency Thrusters, Scrap Collector, Backup Generator, Targeting Computer, Ablative Coating

# Mission Content

# Missions

## Mission 1: "Spin Cycle"

Inspired by Adrian Tchaikovsky's Children of Time

Location: Low Orbit Above a Terraformed World

Objective: Collect cultural sample pods from the uplifted spider civilization while defending against their overly enthusiastic "welcome committee."

Background Image: A verdant green planet curves across the bottom third of the screen. Delicate orbital silk structures glint in the sunlight—part space station, part web.

Threats:

* Greeting Drones (ram) — Small, fast, eager to "hug" your station. They mean well. They'll still dent your hull.  
* Silk Weavers (shoot) — Hover at range and fire sticky webbing that slows your rotation temporarily.  
* Cultural Attaché (boss) — Large ceremonial vessel that alternates between launching smaller drones and demanding you accept their poetry.

Collectibles:

* Sample Pods — Cultural artifacts: music crystals, philosophy fragments, tiny silk sculptures.  
* Diplomatic Gifts — Rare pods containing actually useful tech. Higher RP value.

Intro Panels:

1. "Mission: Collect samples from an uplift project that got out of hand." 
   a. "Spiders. Very smart spiders."
   b. "Nothing ever goes wrong with spiders."  
2. "Update: The spiders have spotted us."
   a."They're very excited. They're sending gifts."
   b. "The gifts are approaching at ramming speed."  
3. "Revised mission: Collect samples, survive welcome party."
   a. "Do NOT insult their poetry."
   b. "Apparently the last research team did that."

Ending Panels:

1. "Sample collection complete: 847 artifacts cataloged..."
   a. "...including one epic poem about a fly."
   b. "It's 11,000 verses long."  
2. "A spider named Maserati has stowed away in the sample bay."
   b. "She claims diplomatic immunity."
   c. "She's also reorganized our filing system."  
3. "Research Spec unlocked:"
   b. "Their silk has remarkable tensile properties."
   c. "Maserati is very smug about this."

Research Spec Unlock: "Silk Weave Plating" — Station takes 10% less damage from ramming attacks.  
---

## Mission 2: "Productivity Review"

Inspired by Martha Wells' Murderbot Diaries

Location: Corporate Sector Research Hub

Objective: Continue your asteroid mineral survey while corporate "efficiency consultants" attempt to help. Collect ore samples. Avoid being optimized.

Background Image: A sleek corporate station in the distance, covered in pulsing advertisements. Billboards cycle through slogans: "SYNERGY." "ALIGNMENT." Behind it, a rich asteroid field glitters with mineral deposits.

Threats:

* Survey Drones (ram) — Corporate sent these to "assist" with your research. They keep getting in the way. And then exploding.  
* Efficiency Monitors (shoot) — Hover at range and fire "feedback pulses" that temporarily disable one of your weapons.  
* Productivity Liaison (boss) — Large vessel that deploys smaller drones while broadcasting mandatory training videos that slow your rotation.

Collectibles:

* Ore Samples — Mineral-rich asteroid fragments. Your actual job.  
* Requisition Forms — Accidentally useful corporate paperwork. Higher RP value.

Intro Panels:

1. "Standard mineral survey. Corporate has assigned consultants..."
   a. "...to ensure we meet quarterly research targets. 
   b. "This is fine."  
2. "The consultants have arrived."
   a. "They have questions about our 'process' and our 'workflow.'"
   b. "They have exploded near the hull."  
3. "New priority: Collect ore samples. Ignore the helpers."
   a. "If a drone asks you to rate your experience..."
   b. "...just keep shooting."

Ending Panels:

1. "Survey complete. Mineral yield: Excellent."
   a. "Consultant survival rate: Unknown"
   b. "We're not tracking that metric."  
2. "Corporate has sent a follow-up survey about the follow-up survey."
   a. "We have filed it appropriately."
   b. "The file is labeled 'dumb'"  
3. "Research Spec unlocked: The drones' targeting software..."
   a. "...was actually pretty good. We've repurposed it."
   b. "Don't tell corporate."

Research Spec Unlock: "Optimized Targeting" — Projectiles track targets 5% more accurately.  
---

## Mission 3: "Whose Idea Was This?"

Inspired by Douglas Adams' The Hitchhiker's Guide to the Galaxy

Location: Probability Research Platform, Unstable Space

Objective: Collect improbability particles before they become something else. Survive whatever they become instead. Document everything for the insurance claim.

Background Image: Space is wrong. Stars are arranged in a pattern that almost spells something. A planet in the distance is the wrong color—plaid, possibly. A sofa drifts serenely past in the far background.

Threats:

* Probability Fluctuations (ram) — Objects that used to be something else. They're confused. They're angry about being confused.  
* Paradox Nodes (shoot) — Hover at range and fire beams that temporarily reverse your rotation controls.  
* The Improbability Itself (boss) — A shimmering mass of "what if" that changes form every few seconds, alternating between ramming and shooting unpredictably.

Collectibles:

* Improbability Particles — Glowing motes of pure maybe.  
* Impossible Objects — Rare things that shouldn't exist: a hot ice cube, a round corner. Higher RP value.

Intro Panels:

1. "The Improbability Drive test was supposed to be contained."
   a. "It was not contained."
   b. "Reality is now 'optional' in this sector."  
2. "Current status: Things are becoming other things."
   a. "Some of those things are hostile."
   b. "One of them is a whale. The whale seems fine."  
3. "Objective: Collect probability particles for study."
   a. "Try not to become something else yourself."
   b. "If you do, please file Form 42-B."

Ending Panels:

1. "Particles collected. Reality is stabilizing."
   a. "Most things are back to being themselves."
   b. "The sofa remains unexplained."  
2. "Final inventory includes 47 impossible objects..."
   a. "... and one cup of tea that appeared exactly when someone needed it."
   b. "Coincidence rate: Improbable."  
3. "Research Spec unlocked: We've learned to predict small impossibilities."
   a. "This should not be possible."
   b. "That's rather the point."

Research Spec Unlock: "Improbability Compensation" — 5% chance for any damage to be negated entirely.  
---

## Mission 4: "Garbage Day"

Inspired by Star Wars (trash compactor scene)

Location: Deep Space Salvage Field

Objective: Collect valuable salvage from an ancient debris field while avoiding active defense systems and the creature that lives here now.

Background Image: Wreckage stretches to infinity—twisted metal, shattered hulls, fragments of ships from civilizations nobody remembers. Something large moves between the debris in the distance. It has eyes. Many eyes.

Threats:

* Debris Swarms (ram) — Chunks of ancient wreckage tumbling toward you. Not malicious, just inevitable.  
* Defense Turrets (shoot) — Automated systems from an old war, still functional, still shooting at anything that moves.  
* Chomper (boss) — The thing that lives here. Very large, very hungry, thinks your station might be food. When it realizes you're not, it calms down. Getting there is the hard part.

Collectibles:

* Salvage Crates — Ancient technology worth studying.  
* Rare Alloys — Fragments of materials nobody makes anymore. Higher RP value.

Intro Panels:

1. "Salvage mission. This debris field dates back..."
   a."... to a war nobody remembers. One civilization's apocalypse..."
   b. "... is another's research opportunity."  
2. "Scans show valuable materials, active defense systems,"
   a. "... and one (1) extremely large life sign."
   b. "The life sign is circling us. Casually."  
3. "Objective: Collect salvage. Avoid the turrets." 
   a. "Make friends with whatever that thing is. It looks lonely."
   b. "Also hungry. But mostly lonely."

Ending Panels:

1. "Salvage complete. We've recovered alloys..."
   a. "... that predate most known civilizations."
   b. "Also, we've made a friend."  
2. "The creature followed us to the edge of the debris field,"
   a. "... then stopped. It made a sound. Acoustics says it might..."
   b. "...have been 'goodbye.' Or 'indigestion.'"  
3. "Research Spec unlocked: The ancient alloys..."
   a. "... have remarkable properties."
   b. "We've named them 'Chompite' in honor of our new friend."

Research Spec Unlock: "Ancient Alloys" — Station hull integrity increased by 15%.  
---

## Mission 5: "Academic Standards"

Inspired by Nnedi Okofor's Binti

Location: Interstellar University Station

Objective: Navigate an academic conference where seven species are presenting research simultaneously. Collect proceedings. Survive the "vigorous debate."

Background Image: A vast crystalline station with sections designed for different atmospheres—one filled with amber liquid, one with swirling gases, one that appears to be on fire (this is normal for them). Banners advertise the "14th Interspecies Symposium."

Threats:

* Debate Drones (ram) — Small vessels from species who consider physical collision an acceptable form of peer review.  
* Citation Beams (shoot) — Platforms that fire focused data streams. They're sharing their research. Aggressively.  
* The Distinguished Professor (boss) — A massive vessel belonging to a senior academic who believes your research is "derivative." Here to provide feedback. Extensively.

Collectibles:

* Research Proceedings — Papers from dozens of fields.  
* Collaborative Data — Rare cross-species research with practical applications. Higher RP value.

Intro Panels:

1. "Welcome to the Interspecies Research Symposium. "
   a. "Today's sessions include 'Is Time Real?' and 'Tentacles: A Reappraisal.'"
   b. "Attendance is mandatory."  
2. "Reminder: What looks like aggression may be enthusiastic agreement."
   a. "What looks like agreement may be a prelude to aggression."
   b. "Read the room."  
3. "Your job: Collect proceedings."
   a. "Facilitate exchange."
   b. "Avoid the Vorthian delegation—they debate with their ships."

Ending Panels:

1. "Conference concluded. Fourteen collaborative papers drafted."
   a. "Only three diplomatic incidents. The organizing committee..."
   b. "... is calling this 'a qualified success.'"  
2. "The Distinguished Professor has revised their..."
   a. "... opinion of our research from 'derivative' to 'merely obvious.'"
   b. "We're choosing to see this as progress."  
3. "Research Spec unlocked: Cross-species collaboration..."
   a. "... yields unexpected insights."
   b. "Also unexpected bruises."

Research Spec Unlock: "Peer Review" — Bonus items appear 10% more frequently.  
---

## Asset Inventory

### Shared Assets (used across all missions)

| Asset | Size | Description |
| :---- | :---- | :---- |
| Health Bar | 20×3 | White bar displayed above damaged MOBs |
| Tractor Beam | 32×8 | Dithered beam effect for pulling collectibles |
| Station (base) | 32×32 | Player's space station (core sprite) |
| Station extensions | Various | Weapon/upgrade attachments (per upgrade item) |

---

### Mission 1: "Spin Cycle"

Background

| Asset | Size | Description |
| :---- | :---- | :---- |
| background\_m1 | 400×240 | Green planet, orbital silk structures, stars |

Threats

| Asset | Size | Description |
| :---- | :---- | :---- |
| greeting\_drone | 16×16 | Small spider drone, 4 eyes, 8 legs |
| greeting\_drone\_anim | 16×16 ×2 | 2-frame leg animation |
| silk\_weaver | 24×24 | Larger spider, expressive eyes, abdomen |
| silk\_projectile | 8×8 | Web ball projectile |
| cultural\_attache | 48×48 | Boss: ornate spider with crown, scroll |

Collectibles

| Asset | Size | Description |
| :---- | :---- | :---- |
| sample\_pod | 12×12 | Organic pod with crystal inside |
| diplomatic\_gift | 16×16 | Fancy container with bow, sparkles |

Story Panels

| Asset | Size | Description |
| :---- | :---- | :---- |
| panel\_m1\_intro\_1 | 400×240 | Station with spider warning sign |
| panel\_m1\_intro\_2 | 400×240 | Swarm approaching, station alarmed |
| panel\_m1\_intro\_3 | 400×240 | Worried crew, happy spider with poetry |
| panel\_m1\_ending\_1 | 400×240 | Shelves of catalogued artifacts |
| panel\_m1\_ending\_2 | 400×240 | Maserati in filing cabinet, smug |
| panel\_m1\_ending\_3 | 400×240 | Silk analysis, proud spider |

---

### Mission 2: "Productivity Review"

Background

| Asset | Size | Description |
| :---- | :---- | :---- |
| background\_m2 | 400×240 | Corporate station, billboards, asteroid field |

Threats

| Asset | Size | Description |
| :---- | :---- | :---- |
| survey\_drone | 16×16 | Boxy corporate drone with logo |
| survey\_drone\_anim | 16×16 ×2 | 2-frame wobble/spin animation |
| efficiency\_monitor | 24×24 | Hovering platform with sensor dish |
| feedback\_pulse | 8×8 | Energy projectile |
| productivity\_liaison | 48×48 | Boss: large vessel with screen displaying graph |

Collectibles

| Asset | Size | Description |
| :---- | :---- | :---- |
| ore\_sample | 12×12 | Rocky chunk with mineral veins |
| requisition\_form | 16×16 | Floating document with stamp |

Story Panels

| Asset | Size | Description |
| :---- | :---- | :---- |
| panel\_m2\_intro\_1 | 400×240 | Station, asteroid field, "all normal" vibe |
| panel\_m2\_intro\_2 | 400×240 | Drones swarming, explosions, chaos |
| panel\_m2\_intro\_3 | 400×240 | Drone asking for rating, crew annoyed |
| panel\_m2\_ending\_1 | 400×240 | Ore containers, mission success |
| panel\_m2\_ending\_2 | 400×240 | Survey form being filed into space |
| panel\_m2\_ending\_3 | 400×240 | Repurposed drone software display |

---

### Mission 3: "Whose Idea Was This?"

Background

| Asset | Size | Description |
| :---- | :---- | :---- |
| background\_m3 | 400×240 | Wrong-colored stars, plaid planet, floating sofa |

Threats

| Asset | Size | Description |
| :---- | :---- | :---- |
| probability\_fluctuation | 16×16 | Glitchy, shifting shape |
| probability\_fluctuation\_anim | 16×16 ×3 | 3-frame morph animation |
| paradox\_node | 24×24 | Geometric impossibility (Escher-like) |
| paradox\_beam | 8×8 | Swirling beam projectile |
| improbability\_itself | 48×48 | Boss: shimmering mass, changes form |
| improbability\_form\_a | 48×48 | Boss alternate form 1 |
| improbability\_form\_b | 48×48 | Boss alternate form 2 |

Collectibles

| Asset | Size | Description |
| :---- | :---- | :---- |
| improbability\_particle | 12×12 | Glowing, unstable mote |
| impossible\_object | 16×16 | Contradictory shape (hot ice cube, etc.) |

Story Panels

| Asset | Size | Description |
| :---- | :---- | :---- |
| panel\_m3\_intro\_1 | 400×240 | Warning signs, unstable space |
| panel\_m3\_intro\_2 | 400×240 | Things becoming other things, whale |
| panel\_m3\_intro\_3 | 400×240 | Form 42-B, bureaucratic absurdity |
| panel\_m3\_ending\_1 | 400×240 | Reality stabilizing, sofa still there |
| panel\_m3\_ending\_2 | 400×240 | Tea cup appearing, question marks |
| panel\_m3\_ending\_3 | 400×240 | Impossible inventory list |

---

### Mission 4: "Garbage Day"

Background

| Asset | Size | Description |
| :---- | :---- | :---- |
| background\_m4 | 400×240 | Infinite wreckage, shadowy creature eyes in distance |

Threats

| Asset | Size | Description |
| :---- | :---- | :---- |
| debris\_chunk | 16×16 | Twisted metal fragment |
| debris\_chunk\_variants | 16×16 ×3 | 3 visual variants for variety |
| defense\_turret | 24×24 | Ancient automated gun platform |
| turret\_projectile | 8×8 | Energy bolt |
| chomper | 64×64 | Boss: large creature, many eyes, big mouth |
| chomper\_anim | 64×64 ×2 | 2-frame idle/chomp animation |

Collectibles

| Asset | Size | Description |
| :---- | :---- | :---- |
| salvage\_crate | 12×12 | Battered container with unknown symbol |
| rare\_alloy | 16×16 | Shimmering metal fragment |

Story Panels

| Asset | Size | Description |
| :---- | :---- | :---- |
| panel\_m4\_intro\_1 | 400×240 | Vast debris field, station entering |
| panel\_m4\_intro\_2 | 400×240 | Creature eyes visible, crew nervous |
| panel\_m4\_intro\_3 | 400×240 | "Make friends" objective, absurdity |
| panel\_m4\_ending\_1 | 400×240 | Salvage collected, success |
| panel\_m4\_ending\_2 | 400×240 | Creature waving goodbye at edge |
| panel\_m4\_ending\_3 | 400×240 | "Chompite" labeled sample |

---

### Mission 5: "Academic Standards"

Background

| Asset | Size | Description |
| :---- | :---- | :---- |
| background\_m5 | 400×240 | Crystalline station, multiple atmosphere sections, banners |

Threats

| Asset | Size | Description |
| :---- | :---- | :---- |
| debate\_drone | 16×16 | Small alien vessel with "aggressive" posture |
| debate\_drone\_variants | 16×16 ×3 | 3 species variants |
| citation\_platform | 24×24 | Floating platform with data dish |
| citation\_beam | 8×8 | Data stream projectile |
| distinguished\_professor | 48×48 | Boss: imposing vessel with academic regalia |

Collectibles

| Asset | Size | Description |
| :---- | :---- | :---- |
| research\_proceedings | 12×12 | Glowing data tablet |
| collaborative\_data | 16×16 | Multi-symbol document (cross-species) |

Story Panels

| Asset | Size | Description |
| :---- | :---- | :---- |
| panel\_m5\_intro\_1 | 400×240 | Conference banner, multiple alien sections |
| panel\_m5\_intro\_2 | 400×240 | Chaos of "agreement" and "disagreement" |
| panel\_m5\_intro\_3 | 400×240 | Vorthian delegation warning |
| panel\_m5\_ending\_1 | 400×240 | Papers drafted, minor damage |
| panel\_m5\_ending\_2 | 400×240 | "Merely obvious" review, backhanded praise |
| panel\_m5\_ending\_3 | 400×240 | Collaborative success, bruises |

---

## Asset Summary

| Category | Count |
| :---- | :---- |
| Backgrounds | 5 |
| Threat sprites (base) | 15 |
| Threat animations/variants | 14 |
| Projectiles | 5 |
| Boss sprites | 5 |
| Boss animations/variants | 4 |
| Collectibles | 10 |
| Story panels | 30 |
| Shared UI elements | 4 |
| Total unique assets | 92 |

# Systems Update

# Interstellar Survivors — Complete Design Document Update

---

## 1\. TV Show Framing

The game is framed as a campy sci-fi television series called **"Interstellar Survivors"**. Each Mission becomes an **Episode** of the show.

### TV Show Elements

| Element | Description | When It Appears |
| :---- | :---- | :---- |
| Game Title Card | "INTERSTELLAR SURVIVORS" logo with random tagline | When game starts from Play.date menu |
| Title Card | "INTERSTELLAR SURVIVORS" logo with episode number | Before intro panels |
| Episode Title | Large text with episode name and tagline | After title card |
| Intro Panels | 3 comic-style panels setting up the episode | Before gameplay |
| Starting Message | Episode-specific phrase over the game field | Start of gameplay (1.5 sec) |
| Ending Panels | 3 comic-style panels wrapping up the episode | After defeating boss |
| "To Be Continued..." | Shown when player fails | On game over |
| Credits Roll | Simple credits with Research Spec unlock | After ending panels |

### Episode List (Season 1\)

| Episode \# | Title | Tagline | Starting Message |
| :---- | :---- | :---- | :---- |
| 1 | "Spin Cycle" | "They just want to be friends. Aggressively." | WELCOME COMMITTEE INBOUND |
| 2 | "Productivity Review" | "Your feedback is important to us." | QUARTERLY TARGETS: MANDATORY |
| 3 | "Whose Idea Was This?" | "Reality is more of a suggestion." | PROBABILITY: OPTIONAL |
| 4 | "Garbage Day" | "One civilization's apocalypse is another's opportunity." | SALVAGE RIGHTS: CONTESTED |
| 5 | "Academic Standards" | "Peer review can be brutal. Literally." | ATTENDANCE: MANDATORY |

### Episode Unlock Progression

- **Episode 1**: Unlocked at game start  
- **Episode 2**: Unlocks after completing Episode 1  
- **Episode 3**: Unlocks after completing Episode 2  
- **Episode 4**: Unlocks after completing Episode 3  
- **Episode 5**: Unlocks after completing Episode 4

### Title Screen Taglines
The following list of taglines should be randomly rotated in on the game title screen. If the game title screen sits idle, the tagline should change every 20 seconds. Each time a random tagline is chosen it should be rejected if it is the same as the current tagline.

"Boldly going to have boldly gone!"
"My gosh, it's full of paperwork!"
"Intrepid Space Adventurers Wanted"
"To probability, and beyond!"
"Live long and file reports."
"In space, no one can hear you take notes."
"The spice must document."
"So long, and thanks for all the data."
"Collect knowledge. Avoid death. Repeat."
"The universe is trying to kill you. Write it down."
"Every discovery could be your last. Make it count."
"Curiosity killed the cat. You're not a cat... probably."
"Set phasers to 'document.'"
"Tea. Earl Grey. And a comprehensive survey."
"The truth is out there. Go catalog it."
"Warning: May contain trace amounts of existential dread."
"Now with 40% more inexplicable alien artifacts!"
"Your sacrifice will be noted. Literally."
"Knowledge is power. Power is survival. Survival is unlikely."
"Maserati sends her regards."
"Do NOT insult the poetry."
"Diplomatic hugs incoming."
"11,000 verses. One fly."
"Please rate your survival experience."
"Synergy. Alignment. Explosion."
"Quarterly targets: survival optional."
"The consultants are here to help."
"The whale seems fine."
"Please file Form 42-B."
"The sofa remains unexplained."
"Reality is more of a suggestion."
"Coincidence rate: Improbable."
"The Chomper remembers."
"Salvage rights: contested."
"Always let the Vorthian win."
"Peer review can be brutal. Literally."
"Attendance is mandatory. Survival is extra credit."
"The Professor has notes."
"A qualified success."


### Intro Panels Rules
   1. When the mission is selected, the mission title screen shows
   2. That fades into the mission Intro Panels
   3. For each panel, do the following:
      1. Show the panel background
      2. Play a randomly chosen audio hit from the game_assets/audio/hits directory
      3. Show the first line of text for 5 sec (or button press)
      4. Show the second line of text for 5 sec (or button press)
      5. Show the third line of text for 5 sec (or button press)
      6. Wait for button press to continue
      6. On button press enter game field and play session

### End Panels Rules
   1. After the mission is beaten, show the End Panels
   3. For each panel, do the following:
      1. Show the panel background
      2. Play a randomly chosen audio hit from the game_assets/audio/hits directory
      3. Show the first line of text for 5 sec (or button press)
      4. Show the second line of text for 5 sec (or button press)
      5. Show the third line of text for 5 sec (or button press)
      6. Wait for button press to continue
      6. On button press go to mission select menu

---

## 2\. Tools System

**Tools** are research and defensive instruments that attach to the space station and interact with MOBs.

### Tool Data Table

| Name | Description | Base Damage | Damage Type | Pattern | Base Speed | Fire Rate | Pairs With (Bonus Item) | Upgraded Tool |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Rail Driver** | A kinetic launcher for breaking up asteroids. Simple, reliable, satisfying. | 3 | physical | straight | 10 | 1.0 | Alloy Gears | Rail Cannon |
| **Frequency Scanner** | Emits tuned waves that disperse gas clouds and destabilize energy threats. | 4 | frequency | straight | 8 | 0.8 | Expanded Dish | Harmonic Disruptor |
| **Tractor Pulse** | Pulls collectibles toward the station faster. Essential for sample collection. | 0 | none | cone | 6 | 0.5 | Magnetic Coils | Gravity Well |
| **Thermal Lance** | A focused heat beam for cutting through dense materials. | 5 | thermal | beam | instant | 0.4 | Cooling Vents | Plasma Cutter |
| **Cryo Projector** | Supercooled particles that slow MOB movement by 50%. | 1 | cold | spread | 7 | 0.7 | Compressor Unit | Absolute Zero |
| **EMP Burst** | Disables mechanical MOBs and deals bonus damage to electronics. | 2 (×3 vs mech) | electric | radial | instant | 0.3 | Capacitor Bank | Ion Storm |
| **Probe Launcher** | Fires probes that attach to MOBs, dealing DoT and collecting bonus RP. | 1/tick | analysis | homing | 5 | 0.6 | Probe Swarm | Drone Carrier |
| **Repulsor Field** | Pushes MOBs away from the station. No damage, creates breathing room. | 0 | force | radial | instant | 0.2 | Field Amplifier | Shockwave Generator |

### Upgraded Tools Table

When a Tool is paired with its matching Bonus Item, it becomes an Upgraded Tool with significantly improved stats and sometimes new effects.

| Upgraded Tool | Base Tool \+ Bonus Item | New Stats | Special Effect |
| :---- | :---- | :---- | :---- |
| **Rail Cannon** | Rail Driver \+ Alloy Gears | Damage: 8, Speed: 12 | Projectiles pierce through first target |
| **Harmonic Disruptor** | Frequency Scanner \+ Expanded Dish | Damage: 10, Width: ×2 | Chains to nearby MOBs |
| **Gravity Well** | Tractor Pulse \+ Magnetic Coils | Cone: 90°, Pull: ×3 | Also slows MOBs caught in cone |
| **Plasma Cutter** | Thermal Lance \+ Cooling Vents | Damage: 12, Fire Rate: 0.2 | Beam persists 1 second, sweeps with rotation |
| **Absolute Zero** | Cryo Projector \+ Compressor Unit | Damage: 3, Slow: 80% | Frozen MOBs take ×2 damage from other Tools |
| **Ion Storm** | EMP Burst \+ Capacitor Bank | Damage: 5 (×4 vs mech), Radius: ×2 | Disabled MOBs explode on death, damaging nearby |
| **Drone Carrier** | Probe Launcher \+ Probe Swarm | Fires 5 probes, DoT: 2/tick | Probes return RP even if MOB not destroyed |
| **Shockwave Generator** | Repulsor Field \+ Field Amplifier | Push: ×3, Radius: ×2 | Pushed MOBs damage other MOBs on collision |

### Tool Pattern Definitions

| Pattern | Behavior |
| :---- | :---- |
| straight | Fires in a line from the Tool's position |
| beam | Continuous line that persists for 0.5 seconds |
| spread | Multiple projectiles (3) in a 45° fan |
| cone | Affects a 45° cone-shaped area (90° when upgraded) |
| radial | Affects all directions around the station equally |
| homing | Projectile tracks the nearest valid target |

### Tool Damage Types

| Type | Strong Against | Weak Against |
| :---- | :---- | :---- |
| physical | Asteroids, debris, organic MOBs | Energy-based MOBs |
| frequency | Gas clouds, energy MOBs | Dense physical MOBs |
| thermal | Organic MOBs, ice-based MOBs | Heat-resistant MOBs |
| cold | Fast MOBs (slows them) | Cold-immune MOBs |
| electric | Mechanical MOBs, drones | Organic MOBs, rocks |
| analysis | All (low damage, \+50% RP) | — |
| force | All (knockback, no damage) | — |

### Tool Unlock Progression

| Tool | Unlock Condition |
| :---- | :---- |
| Rail Driver | Available from start |
| Frequency Scanner | Available from start |
| Tractor Pulse | Available from start |
| Thermal Lance | Complete Episode 1 |
| Cryo Projector | Complete Episode 2 |
| EMP Burst | Complete Episode 3 |
| Probe Launcher | Complete Episode 4 |
| Repulsor Field | Complete Episode 5 |

---

## 3\. Bonus Items System

**Bonus Items** are passive upgrades that either:

1. Provide a general stat boost to the station, OR  
2. Combine with a specific Tool to create an Upgraded Tool

### Bonus Items Table

| Name | Description | Effect | Pairs With Tool |
| :---- | :---- | :---- | :---- |
| **Alloy Gears** | Precision-machined components from ancient salvage. | \+25% physical damage | Rail Driver → Rail Cannon |
| **Expanded Dish** | A wider sensor array for broader coverage. | \+25% frequency damage | Frequency Scanner → Harmonic Disruptor |
| **Magnetic Coils** | Powerful electromagnets for enhanced pulling. | Tractor range \+50% | Tractor Pulse → Gravity Well |
| **Cooling Vents** | Advanced heat dissipation system. | \+25% thermal damage | Thermal Lance → Plasma Cutter |
| **Compressor Unit** | Cryogenic compression for colder output. | Slow duration \+50% | Cryo Projector → Absolute Zero |
| **Capacitor Bank** | High-capacity energy storage. | \+25% electric damage | EMP Burst → Ion Storm |
| **Probe Swarm** | Deploys additional probe units. | \+2 probes per shot | Probe Launcher → Drone Carrier |
| **Field Amplifier** | Boosts repulsor field strength. | Push force \+50% | Repulsor Field → Shockwave Generator |
| **Reinforced Hull** | Extra plating for the station. | \+20% max health | None (general) |
| **Overclocked Capacitors** | Faster energy cycling for all systems. | \+15% fire rate (all Tools) | None (general) |
| **Extended Sensors** | Long-range detection equipment. | Collectibles visible 2 sec earlier | None (general) |
| **Emergency Thrusters** | Backup rotation assistance. | \+25% rotation speed | None (general) |
| **Scrap Collector** | Automated debris analysis. | \+15% RP from destroyed MOBs | None (general) |
| **Backup Generator** | Emergency power supply. | Slowly regenerate health (1/5 sec) | None (general) |
| **Targeting Computer** | Predictive aim assistance. | \+10% projectile accuracy | None (general) |
| **Ablative Coating** | Sacrificial outer layer. | \-15% damage from ramming attacks | None (general) |

### Bonus Item Unlock Progression

| Bonus Item | Unlock Condition |
| :---- | :---- |
| Alloy Gears | Available from start |
| Expanded Dish | Available from start |
| Magnetic Coils | Available from start |
| Reinforced Hull | Available from start |
| Emergency Thrusters | Available from start |
| Cooling Vents | Complete Episode 1 |
| Overclocked Capacitors | Complete Episode 1 |
| Compressor Unit | Complete Episode 2 |
| Extended Sensors | Complete Episode 2 |
| Capacitor Bank | Complete Episode 3 |
| Scrap Collector | Complete Episode 3 |
| Probe Swarm | Complete Episode 4 |
| Backup Generator | Complete Episode 4 |
| Field Amplifier | Complete Episode 5 |
| Targeting Computer | Complete Episode 5 |
| Ablative Coating | Complete all episodes |

---

## 4\. Tool Attachment & Rotation Mechanics

### Station Layout

The station has **8 attachment points** arranged around its perimeter like a clock face:

- Position 0: Top (12 o'clock)  
- Position 1: Top-right (1:30)  
- Position 2: Right (3 o'clock)  
- Position 3: Bottom-right (4:30)  
- Position 4: Bottom (6 o'clock)  
- Position 5: Bottom-left (7:30)  
- Position 6: Left (9 o'clock)  
- Position 7: Top-left (10:30)

### Tool Attachment Rules

1. When a Tool is selected at level-up, it attaches to the **next available slot** (starting from Position 0\)  
2. Maximum **6 Tools** can be attached (MAX\_TOOLS\_PER\_EPISODE \= 6\)  
3. Tools cannot be removed or repositioned during gameplay  
4. Each Tool fires **outward** from its position on the station  
5. Radial-pattern Tools (EMP Burst, Repulsor Field) affect all directions regardless of position

### Rotation Mechanics

1. Player uses the **crank** to rotate the entire station  
2. All attached Tools rotate with the station  
3. Rotation speed: 180° per full crank revolution (adjustable by Emergency Thrusters bonus)  
4. Tools maintain their relative positions to each other  
5. Straight/beam/spread/cone patterns fire in the direction the Tool is facing after rotation

### Visual Feedback

- Station sprite rotates smoothly with crank input  
- Tool attachment points are visually indicated on station sprite  
- Active Tool shows brief muzzle flash when firing  
- Rotation indicator shows current orientation (optional HUD element)

---

## 5\. Level-Up Selection UI

### When Level-Up Occurs

1. RP bar fills completely  
2. Gameplay **pauses**  
3. "LEVEL UP\!" text appears briefly  
4. Selection UI slides in from bottom

### Selection UI Layout

┌─────────────────────────────────────────┐

│           CHOOSE YOUR UPGRADE           │

├─────────────────────────────────────────┤

│ ► TOOL │ Rail Driver                    │

│         Kinetic launcher. Dmg: 3        │

├─────────────────────────────────────────┤

│   TOOL │ Frequency Scanner              │

│         Disperses gas clouds. Dmg: 4    │

├─────────────────────────────────────────┤

│  BONUS │ Alloy Gears                    │

│         \+25% physical dmg → Rail Cannon │

├─────────────────────────────────────────┤

│  BONUS │ Reinforced Hull                │

│         \+20% max station health         │

├─────────────────────────────────────────┤

│       ▲▼ D-PAD to select, A to confirm  │

└─────────────────────────────────────────┘

### Card Layout (Full-width rows, \~360×40 pixels each)

Each card row displays:

- **Type label** (left column, 60px): "TOOL" or "BONUS"  
- **Icon** (32×32): Next to type label  
- **Name** (bold, top line): Item name  
- **Description** (second line): Brief effect \+ key stats  
- **Synergy indicator**: If Bonus pairs with owned Tool, shows "→ \[Upgraded Tool Name\]"

### Selection Rules

1. **4 cards** displayed in vertical list: 2 Tools, 2 Bonus Items  
2. Cards are **randomly selected** from unlocked pool  
3. Tools already attached to station are **excluded** from pool  
4. Bonus Items already acquired are **excluded** from pool  
5. If fewer than 2 Tools/Bonus Items available, fill remaining slots from other category  
6. Player **must select 1 card** to continue  
7. D-pad **up/down** to move selection cursor (►)  
8. **A button** to confirm selection  
9. Selected card highlighted with inverted colors or border

### Special Cases

- If player has a Tool and its matching Bonus Item appears, the synergy is shown inline (e.g., "→ Rail Cannon")  
- If all Tools are attached (6), only Bonus Items appear  
- If all items unlocked, show "MAXIMUM UPGRADES" and auto-continue

### Advantages of Vertical Layout

- More room for descriptive text on each card  
- Easier to read on Playdate's 400×240 screen  
- Natural D-pad up/down navigation  
- Synergy info displayed inline without extra UI

---

## 6\. Collectible Mechanics

### Collectible Types Per Episode

| Episode | Standard Collectible | Rare Collectible | Standard RP | Rare RP |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Sample Pod | Diplomatic Gift | 10 | 25 |
| 2 | Ore Sample | Requisition Form | 10 | 25 |
| 3 | Improbability Particle | Impossible Object | 10 | 25 |
| 4 | Salvage Crate | Rare Alloy | 10 | 25 |
| 5 | Research Proceedings | Collaborative Data | 10 | 25 |

### Spawn Behavior

1. Collectibles spawn **with MOB waves** (see Wave System)  
2. **2-4 standard collectibles** spawn per wave  
3. **0-1 rare collectible** spawns per wave (20% chance)  
4. Spawn at random positions along screen edges  
5. Collectibles are **immune to all damage** (Tools pass through them)

### Movement Behavior

| State | Speed | Direction |
| :---- | :---- | :---- |
| Default drift | 0.5 px/frame | Toward station center |
| Tractor Pulse (standard) | 3 px/frame | Toward station center |
| Tractor Pulse (upgraded Gravity Well) | 5 px/frame | Toward station center |

### Collection

1. Collectible is collected when it **touches the station** hitbox  
2. RP is awarded **immediately**  
3. Collection sound plays  
4. Brief sparkle effect at collection point  
5. If Extended Sensors bonus active, collectibles appear on edge of screen 2 seconds before entering play area

### Collectibles vs MOBs

- Collectibles **cannot damage** the station  
- Collectibles **do not block** MOB movement or projectiles  
- MOBs **cannot destroy** collectibles  
- Collectibles and MOBs can occupy the same space

---

## 7\. Wave System & MOB Spawning

### Wave Structure

Each episode consists of **7 waves** before the boss appears.

| Wave | Time | Duration | Composition | Spawn Rate |
| :---- | :---- | :---- | :---- | :---- |
| 1 | 0:00 | 60 sec | Ramming MOBs only | 1 per 3 sec |
| 2 | 1:00 | 60 sec | Ramming MOBs only | 1 per 2.5 sec |
| 3 | 2:00 | 60 sec | 70% ramming, 30% shooting | 1 per 2.5 sec |
| 4 | 3:00 | 60 sec | 60% ramming, 40% shooting | 1 per 2 sec |
| 5 | 4:00 | 60 sec | 50% ramming, 50% shooting | 1 per 2 sec |
| 6 | 5:00 | 60 sec | 40% ramming, 60% shooting | 1 per 1.5 sec |
| 7 | 6:00 | 60 sec | 30% ramming, 70% shooting | 1 per 1.5 sec |
| BOSS | 7:00 | Until defeated | Boss \+ reduced spawns | 1 per 4 sec |

### Difficulty Scaling Within Waves

| Wave | MOB Health Multiplier | MOB Damage Multiplier | MOB Speed Multiplier |
| :---- | :---- | :---- | :---- |
| 1 | 1.0× | 1.0× | 1.0× |
| 2 | 1.0× | 1.0× | 1.1× |
| 3 | 1.2× | 1.1× | 1.1× |
| 4 | 1.3× | 1.2× | 1.2× |
| 5 | 1.5× | 1.3× | 1.2× |
| 6 | 1.7× | 1.4× | 1.3× |
| 7 | 2.0× | 1.5× | 1.3× |
| BOSS | 1.0× (for adds) | 1.0× (for adds) | 1.0× (for adds) |

### Wave Transition

1. Wave complete when timer reaches next wave threshold  
2. No "wave clear" requirement—waves are time-based  
3. Brief "WAVE X" text appears at wave start (0.5 sec)  
4. At 6:45, "WARNING: BOSS INCOMING" appears  
5. At 7:00, boss spawns and boss music begins

### Spawn Positions

- MOBs spawn at random positions along screen edges  
- Minimum distance between spawn points: 40 pixels  
- MOBs spawn **off-screen** and move into play area  
- Ramming MOBs aim toward station center  
- Shooting MOBs aim to reach their weapon range, then orbit

---

## 8\. Boss Mechanics

### Boss Timing

- **6:45** — Warning message: "INCOMING: \[Boss Name\]"  
- **7:00** — Boss spawns, boss health bar appears, boss music starts  
- Regular MOB spawns continue at reduced rate during boss fight

### Win Condition

- **Defeat the Boss** \= Episode complete  
- No time limit after boss spawns  
- If station destroyed before boss defeated \= Episode failed ("To Be Continued...")

### Boss Table

| Episode | Boss Name | Health | Behavior Phase 1 (100-50%) | Behavior Phase 2 (50-0%) |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Cultural Attaché | 200 | Launches greeting drones (2 per 5 sec), fires slowing poetry scrolls | Faster drone spawns (3 per 4 sec), poetry scrolls home slightly |
| 2 | Productivity Liaison | 250 | Deploys survey drones, fires feedback pulses (disable 1 Tool for 3 sec) | Movement speed \+50%, pulse fire rate doubled |
| 3 | The Improbability Itself | 300 | Form A: Rams. Form B: Shoots. Changes every 10 sec. | Form C added: Teleports randomly, rapid shots. Cycles all 3 forms every 7 sec. |
| 4 | Chomper | 350 | Circles station at distance, charges for ram every 8 sec | Charge frequency increased to every 5 sec, spawns debris chunks when hit |
| 5 | The Distinguished Professor | 400 | Stays at max range, fires citation beams (high damage) | Summons debate drone squad (5) every 15 sec, citation beams chain |

### Boss Health Bar

- Displayed below RP bar, centered  
- 200 pixels wide, 6 pixels tall  
- Shows boss name above bar  
- Depletes left-to-right as boss takes damage  
- Flashes when boss enters Phase 2

---

## 9\. Research Specs System

### Research Specs Table

Research Specs are permanent meta-progression unlocks that affect all future playthroughs.

| Spec Name | Effect | Unlock Condition |
| :---- | :---- | :---- |
| **Silk Weave Plating** | Station takes 10% less damage from ramming attacks | Complete Episode 1 |
| **Optimized Targeting** | All projectiles track 5% more accurately | Complete Episode 2 |
| **Improbability Compensation** | 5% chance for any damage to be negated | Complete Episode 3 |
| **Ancient Alloys** | Station max health increased by 15% | Complete Episode 4 |
| **Peer Review** | Bonus Items appear 10% more frequently in level-up selection | Complete Episode 5 |
| **Veteran Researcher** | Start each episode at Level 2 | Complete all episodes |
| **Efficient Systems** | All Tools fire 5% faster | Complete any episode without taking damage |
| **Completionist** | \+10% RP from all sources | Unlock all other Research Specs |

### Research Specs UI

- Accessible from Main Menu → "Research Specs"  
- Shows grid of all specs  
- Locked specs show "???" and silhouette icon  
- Unlocked specs show name, icon, effect, and unlock date  
- Filter toggle: All / Locked / Unlocked

---

## 10\. Updated Game Constants

BOSS\_SPAWN\_TIME \= 7min (420 seconds)

MAX\_TOOLS\_PER\_EPISODE \= 6

MOB\_DAMAGE\_MULTIPLIER \= 1

BASE\_XP \= 100

BASE\_LEVEL\_EXPONENT \= 1.2

STATION\_BASE\_HEALTH \= 100

ROTATION\_SPEED \= 180° per crank revolution

COLLECTIBLE\_DRIFT\_SPEED \= 0.5 px/frame

TRACTOR\_PULL\_SPEED \= 3 px/frame

TRACTOR\_UPGRADED\_SPEED \= 5 px/frame

STANDARD\_COLLECTIBLE\_RP \= 10

RARE\_COLLECTIBLE\_RP \= 25

---

## 11\. Complete Media Index

### IMAGES

#### Shared UI & System (26 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| logo\_title.png | 400×100 | "INTERSTELLAR SURVIVORS" title logo |
| logo\_icon.png | 32×32 | Small logo for UI |
| station\_base.png | 32×32 | Player's space station (core) |
| station\_slot\_indicator.png | 8×8 | Tool attachment point indicator |
| station\_damaged\_1.png | 32×32 | Station at 66% health |
| station\_damaged\_2.png | 32×32 | Station at 33% health |
| station\_destroyed\_anim.png | 32×32 ×4 | 4-frame explosion (sprite sheet) |
| health\_bar\_bg.png | 20×3 | MOB health bar background |
| health\_bar\_fill.png | 20×3 | MOB health bar fill |
| rp\_bar\_bg.png | 400×2 | RP bar background |
| rp\_bar\_fill.png | 400×2 | RP bar fill |
| boss\_health\_bar\_bg.png | 200×6 | Boss health bar background |
| boss\_health\_bar\_fill.png | 200×6 | Boss health bar fill |
| panel\_frame.png | 400×240 | Comic panel border |
| text\_box.png | 360×50 | Story panel text box |
| to\_be\_continued.png | 400×240 | Game over screen |
| episode\_complete.png | 400×240 | Victory screen |
| level\_up\_popup.png | 100×30 | "LEVEL UP\!" popup |
| wave\_indicator.png | 80×20 | "WAVE X" indicator |
| boss\_warning.png | 200×30 | "BOSS INCOMING" warning |
| menu\_bg.png | 400×240 | Main menu background |
| menu\_selector.png | 16×16 | Menu selection cursor |
| episode\_locked.png | 80×60 | Locked episode thumbnail |
| episode\_unlocked.png | 80×60 | Unlocked episode thumbnail |
| spec\_locked.png | 24×24 | Locked Research Spec icon |
| spec\_unlocked.png | 24×24 | Unlocked Research Spec icon |

#### Level-Up UI (5 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| upgrade\_panel\_bg.png | 360×200 | Selection panel background |
| upgrade\_card\_row.png | 360×40 | Card row background |
| upgrade\_card\_selected.png | 360×40 | Selected card highlight |
| upgrade\_header.png | 300×30 | "CHOOSE YOUR UPGRADE" header |
| upgrade\_cursor.png | 12×12 | Selection cursor (►) |

#### Tool Sprites (24 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| tool\_rail\_driver.png | 16×16 | Rail Driver attachment |
| tool\_rail\_driver\_projectile.png | 8×4 | Rail Driver projectile |
| tool\_rail\_cannon.png | 16×16 | Upgraded Rail Cannon |
| tool\_frequency\_scanner.png | 16×16 | Frequency Scanner |
| tool\_frequency\_scanner\_beam.png | 32×8 | Scanner beam |
| tool\_harmonic\_disruptor.png | 16×16 | Upgraded Harmonic Disruptor |
| tool\_tractor\_pulse.png | 16×16 | Tractor Pulse |
| tool\_tractor\_effect.png | 48×32 | Tractor cone effect |
| tool\_gravity\_well.png | 16×16 | Upgraded Gravity Well |
| tool\_thermal\_lance.png | 16×16 | Thermal Lance |
| tool\_thermal\_beam.png | 64×4 | Thermal beam |
| tool\_plasma\_cutter.png | 16×16 | Upgraded Plasma Cutter |
| tool\_cryo\_projector.png | 16×16 | Cryo Projector |
| tool\_cryo\_particle.png | 6×6 | Cryo particle |
| tool\_absolute\_zero.png | 16×16 | Upgraded Absolute Zero |
| tool\_emp\_burst.png | 16×16 | EMP Burst |
| tool\_emp\_effect.png | 64×64 | EMP burst effect |
| tool\_ion\_storm.png | 16×16 | Upgraded Ion Storm |
| tool\_probe\_launcher.png | 16×16 | Probe Launcher |
| tool\_probe.png | 8×8 | Probe projectile |
| tool\_drone\_carrier.png | 16×16 | Upgraded Drone Carrier |
| tool\_repulsor\_field.png | 16×16 | Repulsor Field |
| tool\_repulsor\_wave.png | 80×80 | Repulsor wave effect |
| tool\_shockwave\_gen.png | 16×16 | Upgraded Shockwave Generator |

#### Bonus Item Icons (16 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bonus\_alloy\_gears.png | 32×32 | Alloy Gears icon |
| bonus\_expanded\_dish.png | 32×32 | Expanded Dish icon |
| bonus\_magnetic\_coils.png | 32×32 | Magnetic Coils icon |
| bonus\_cooling\_vents.png | 32×32 | Cooling Vents icon |
| bonus\_compressor\_unit.png | 32×32 | Compressor Unit icon |
| bonus\_capacitor\_bank.png | 32×32 | Capacitor Bank icon |
| bonus\_probe\_swarm.png | 32×32 | Probe Swarm icon |
| bonus\_field\_amplifier.png | 32×32 | Field Amplifier icon |
| bonus\_reinforced\_hull.png | 32×32 | Reinforced Hull icon |
| bonus\_overclocked\_caps.png | 32×32 | Overclocked Capacitors icon |
| bonus\_extended\_sensors.png | 32×32 | Extended Sensors icon |
| bonus\_emergency\_thrusters.png | 32×32 | Emergency Thrusters icon |
| bonus\_scrap\_collector.png | 32×32 | Scrap Collector icon |
| bonus\_backup\_generator.png | 32×32 | Backup Generator icon |
| bonus\_targeting\_computer.png | 32×32 | Targeting Computer icon |
| bonus\_ablative\_coating.png | 32×32 | Ablative Coating icon |

#### Research Spec Icons (8 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| spec\_silk\_weave.png | 24×24 | Silk Weave Plating |
| spec\_optimized\_targeting.png | 24×24 | Optimized Targeting |
| spec\_improbability.png | 24×24 | Improbability Compensation |
| spec\_ancient\_alloys.png | 24×24 | Ancient Alloys |
| spec\_peer\_review.png | 24×24 | Peer Review |
| spec\_veteran.png | 24×24 | Veteran Researcher |
| spec\_efficient.png | 24×24 | Efficient Systems |
| spec\_completionist.png | 24×24 | Completionist |

#### Episode 1: "Spin Cycle" (14 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bg\_ep1.png | 400×240 | Green planet, orbital silk structures |
| ep1\_greeting\_drone.png | 16×16 | Small spider drone |
| ep1\_greeting\_drone\_anim.png | 16×16 ×2 | 2-frame animation |
| ep1\_silk\_weaver.png | 24×24 | Larger spider |
| ep1\_silk\_projectile.png | 8×8 | Web ball |
| ep1\_boss\_cultural\_attache.png | 48×48 | Boss sprite |
| ep1\_boss\_poetry\_scroll.png | 12×8 | Boss projectile |
| ep1\_sample\_pod.png | 12×12 | Standard collectible |
| ep1\_diplomatic\_gift.png | 16×16 | Rare collectible |
| ep1\_intro\_1.png | 400×240 | Story panel |
| ep1\_intro\_2.png | 400×240 | Story panel |
| ep1\_intro\_3.png | 400×240 | Story panel |
| ep1\_ending\_1.png | 400×240 | Story panel |
| ep1\_ending\_2.png | 400×240 | Story panel |
| ep1\_ending\_3.png | 400×240 | Story panel |

#### Episode 2: "Productivity Review" (14 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bg\_ep2.png | 400×240 | Corporate station, asteroids |
| ep2\_survey\_drone.png | 16×16 | Corporate drone |
| ep2\_survey\_drone\_anim.png | 16×16 ×2 | 2-frame animation |
| ep2\_efficiency\_monitor.png | 24×24 | Hovering platform |
| ep2\_feedback\_pulse.png | 8×8 | Energy projectile |
| ep2\_boss\_productivity\_liaison.png | 48×48 | Boss sprite |
| ep2\_boss\_training\_video.png | 16×12 | Boss projectile |
| ep2\_ore\_sample.png | 12×12 | Standard collectible |
| ep2\_requisition\_form.png | 16×16 | Rare collectible |
| ep2\_intro\_1.png | 400×240 | Story panel |
| ep2\_intro\_2.png | 400×240 | Story panel |
| ep2\_intro\_3.png | 400×240 | Story panel |
| ep2\_ending\_1.png | 400×240 | Story panel |
| ep2\_ending\_2.png | 400×240 | Story panel |
| ep2\_ending\_3.png | 400×240 | Story panel |

#### Episode 3: "Whose Idea Was This?" (16 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bg\_ep3.png | 400×240 | Wrong stars, plaid planet, sofa |
| ep3\_probability\_fluctuation.png | 16×16 | Glitchy shape |
| ep3\_probability\_fluctuation\_anim.png | 16×16 ×3 | 3-frame morph |
| ep3\_paradox\_node.png | 24×24 | Escher-like shape |
| ep3\_paradox\_beam.png | 8×8 | Swirling projectile |
| ep3\_boss\_improbability.png | 48×48 | Boss base form |
| ep3\_boss\_improbability\_form\_a.png | 48×48 | Boss form A |
| ep3\_boss\_improbability\_form\_b.png | 48×48 | Boss form B |
| ep3\_boss\_improbability\_form\_c.png | 48×48 | Boss form C (phase 2\) |
| ep3\_improbability\_particle.png | 12×12 | Standard collectible |
| ep3\_impossible\_object.png | 16×16 | Rare collectible |
| ep3\_intro\_1.png | 400×240 | Story panel |
| ep3\_intro\_2.png | 400×240 | Story panel |
| ep3\_intro\_3.png | 400×240 | Story panel |
| ep3\_ending\_1.png | 400×240 | Story panel |
| ep3\_ending\_2.png | 400×240 | Story panel |
| ep3\_ending\_3.png | 400×240 | Story panel |

#### Episode 4: "Garbage Day" (16 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bg\_ep4.png | 400×240 | Wreckage field, creature eyes |
| ep4\_debris\_chunk.png | 16×16 | Metal fragment |
| ep4\_debris\_chunk\_v2.png | 16×16 | Variant 2 |
| ep4\_debris\_chunk\_v3.png | 16×16 | Variant 3 |
| ep4\_defense\_turret.png | 24×24 | Ancient turret |
| ep4\_turret\_projectile.png | 8×8 | Energy bolt |
| ep4\_boss\_chomper.png | 64×64 | Boss sprite |
| ep4\_boss\_chomper\_anim.png | 64×64 ×2 | Chomp animation |
| ep4\_boss\_debris\_spawn.png | 16×16 | Debris from damaged boss |
| ep4\_salvage\_crate.png | 12×12 | Standard collectible |
| ep4\_rare\_alloy.png | 16×16 | Rare collectible |
| ep4\_intro\_1.png | 400×240 | Story panel |
| ep4\_intro\_2.png | 400×240 | Story panel |
| ep4\_intro\_3.png | 400×240 | Story panel |
| ep4\_ending\_1.png | 400×240 | Story panel |
| ep4\_ending\_2.png | 400×240 | Story panel |
| ep4\_ending\_3.png | 400×240 | Story panel |

#### Episode 5: "Academic Standards" (15 assets)

| Filename | Size | Description |
| :---- | :---- | :---- |
| bg\_ep5.png | 400×240 | Crystalline station, banners |
| ep5\_debate\_drone.png | 16×16 | Alien vessel |
| ep5\_debate\_drone\_v2.png | 16×16 | Species variant 2 |
| ep5\_debate\_drone\_v3.png | 16×16 | Species variant 3 |
| ep5\_citation\_platform.png | 24×24 | Data platform |
| ep5\_citation\_beam.png | 8×8 | Data projectile |
| ep5\_boss\_professor.png | 48×48 | Boss sprite |
| ep5\_boss\_citation\_chain.png | 32×8 | Chaining beam (phase 2\) |
| ep5\_research\_proceedings.png | 12×12 | Standard collectible |
| ep5\_collaborative\_data.png | 16×16 | Rare collectible |
| ep5\_intro\_1.png | 400×240 | Story panel |
| ep5\_intro\_2.png | 400×240 | Story panel |
| ep5\_intro\_3.png | 400×240 | Story panel |
| ep5\_ending\_1.png | 400×240 | Story panel |
| ep5\_ending\_2.png | 400×240 | Story panel |
| ep5\_ending\_3.png | 400×240 | Story panel |

---

### AUDIO

#### Music (7 tracks)

| Filename | Format | Duration | Description |
| :---- | :---- | :---- | :---- |
| music\_title\_theme.wav | ADPCM | \~15 sec | Title screen (loop) |
| music\_menu.wav | ADPCM | \~30 sec | Menu music (loop) |
| music\_gameplay\_1.wav | ADPCM | \~60 sec | Gameplay track 1 (loop) |
| music\_gameplay\_2.wav | ADPCM | \~60 sec | Gameplay track 2 (loop) |
| music\_boss.wav | ADPCM | \~45 sec | Boss fight (loop) |
| music\_victory.wav | ADPCM | \~10 sec | Episode complete |
| music\_game\_over.wav | ADPCM | \~8 sec | Game over sting |

#### Sound Effects (26 effects)

| Filename | Format | Description |
| :---- | :---- | :---- |
| sfx\_menu\_select.wav | ADPCM | Menu cursor move |
| sfx\_menu\_confirm.wav | ADPCM | Menu confirm |
| sfx\_menu\_back.wav | ADPCM | Menu back |
| sfx\_crank\_rotate.wav | ADPCM | Crank feedback |
| sfx\_tool\_rail\_driver.wav | ADPCM | Rail Driver fire |
| sfx\_tool\_frequency\_scanner.wav | ADPCM | Scanner fire |
| sfx\_tool\_tractor\_pulse.wav | ADPCM | Tractor activation |
| sfx\_tool\_thermal\_lance.wav | ADPCM | Thermal Lance fire |
| sfx\_tool\_cryo\_projector.wav | ADPCM | Cryo shot |
| sfx\_tool\_emp\_burst.wav | ADPCM | EMP discharge |
| sfx\_tool\_probe\_launcher.wav | ADPCM | Probe launch |
| sfx\_tool\_repulsor\_field.wav | ADPCM | Repulsor push |
| sfx\_tool\_upgrade.wav | ADPCM | Tool upgrade activated |
| sfx\_mob\_hit.wav | ADPCM | MOB damaged |
| sfx\_mob\_destroyed.wav | ADPCM | MOB destroyed |
| sfx\_collectible\_get.wav | ADPCM | Collectible acquired |
| sfx\_collectible\_rare.wav | ADPCM | Rare collectible acquired |
| sfx\_station\_hit.wav | ADPCM | Station damaged |
| sfx\_station\_destroyed.wav | ADPCM | Station explosion |
| sfx\_level\_up.wav | ADPCM | Level up chime |
| sfx\_card\_select.wav | ADPCM | Card selection |
| sfx\_card\_confirm.wav | ADPCM | Card confirmed |
| sfx\_wave\_start.wav | ADPCM | New wave begins |
| sfx\_boss\_warning.wav | ADPCM | Boss incoming |
| sfx\_boss\_hit.wav | ADPCM | Boss damaged |
| sfx\_boss\_defeated.wav | ADPCM | Boss destroyed |
| sfx\_panel\_advance.wav | ADPCM | Story panel advance |

#### Voice/Narration \- Optional (4 clips)

| Filename | Format | Description |
| :---- | :---- | :---- |
| vo\_previously\_on.wav | ADPCM | "Previously on Interstellar Survivors..." |
| vo\_boss\_warning.wav | ADPCM | "Warning: Hostile approaching\!" |
| vo\_episode\_complete.wav | ADPCM | "Mission accomplished\!" |
| vo\_to\_be\_continued.wav | ADPCM | "To be continued..." |

---

### FONTS (3 fonts)

| Filename | Format | Description |
| :---- | :---- | :---- |
| font\_main.fnt | Playdate | Primary UI font |
| font\_title.fnt | Playdate | Large title font |
| font\_panel.fnt | Playdate | Story panel text |

---

### ASSET SUMMARY

| Category | Count |
| :---- | :---- |
| **IMAGES** |  |
| Shared UI & System | 26 |
| Level-Up UI | 5 |
| Tool Sprites & Effects | 24 |
| Bonus Item Icons | 16 |
| Research Spec Icons | 8 |
| Episode 1 Assets | 14 |
| Episode 2 Assets | 14 |
| Episode 3 Assets | 16 |
| Episode 4 Assets | 16 |
| Episode 5 Assets | 15 |
| **Image Subtotal** | **154** |
| **AUDIO** |  |
| Music Tracks | 7 |
| Sound Effects | 26 |
| Voice (Optional) | 4 |
| **Audio Subtotal** | **37** |
| **FONTS** | 3 |
| **GRAND TOTAL** | **194 assets** |

---

## 12\. Technical Specifications

### Collision & Hitboxes

| Entity | Hitbox Size | Shape | Notes |
| :---- | :---- | :---- | :---- |
| Station | 64×64 | Circle (32px radius) | Rotates on axis; collision is edge of circular graphic |
| Tools | Same as sprite | Rectangle | Attached to station, rotate with it |
| Tool Projectiles | Same as sprite | Rectangle | Travel on straight path from fire point |
| MOBs (small) | 16×16 | Rectangle | Ramming MOBs |
| MOBs (medium) | 24×24 | Rectangle | Shooting MOBs |
| Bosses | 48×48 to 64×64 | Rectangle | Per-boss sizing |
| Collectibles | 12×12 to 16×16 | Rectangle | Standard 12×12, Rare 16×16 |
| MOB Projectiles | 8×8 | Rectangle | Enemy fire |

**Collision Rules:**

- Hitboxes match sprite sizes exactly  
- Station hitbox is circular (inscribed in 64×64 square)  
- Tools fire from their position on station perimeter and continue on straight paths  
- Beams fired mid-rotation continue on their original trajectory (do not curve)

### Screen Layout

Based on 400×240 Playdate screen:

┌────────────────────────────────────────┐

│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│ ← RP Bar (y: 0-2, full width)

├────────────────────────────────────────┤

│ \[T1\]\[T2\]\[T3\]         2:43              │ ← Tool Icons (left), Timer (center)

│ \[T4\]\[T5\]\[T6\]                  Level 13 │ ← More Tools, Level (right)

│                                  100♥  │ ← Health (right)

│                                        │

│                                        │

│              \[STATION\]                 │ ← Play Field (center)

│                                        │

│                                        │

│                                        │

└────────────────────────────────────────┘

| Element | Position | Size | Notes |
| :---- | :---- | :---- | :---- |
| RP Bar | x: 0, y: 0 | 400×2 | Full width, top of screen |
| Boss Health Bar | x: 100, y: 0 | 200×6 | Replaces RP bar during boss wave |
| Tool Icons | x: 4, y: 6 | 18×18 each | 2 columns × 3 rows, 2px gap |
| Timer | x: 180, y: 6 | \~40×12 | Centered horizontally below RP bar |
| Level Display | x: 340, y: 6 | \~56×12 | Right side, "Level \#\#" |
| Health Display | x: 356, y: 20 | \~40×12 | Right side, "\#\#\#♥" |
| Station | x: 168, y: 88 | 64×64 | Centered in play field |
| MOB Health Bar | Relative to MOB | 20×3 | Centered above MOB, 4px gap |
| Wave Indicator | x: 160, y: 112 | 80×20 | Center screen, temporary (0.5 sec) |
| Boss Warning | x: 100, y: 100 | 200×30 | Center screen, temporary |
| Starting Message | x: centered, y: 110 | Variable | Center screen, fades after 1.5 sec |

### Tool Firing Mechanics

**Firing Behavior:**

- Tools fire **constantly** at their defined Fire Rate  
- No range detection needed—projectiles travel until they hit something or leave screen  
- Each Tool fires from its attachment point on station perimeter  
- Projectile inherits the Tool's facing direction at moment of firing

**Projectile Travel:**

- Projectiles travel in a **straight line** from fire point  
- Direction is locked at fire time (rotation mid-flight does not curve projectiles)  
- Beams persist for their duration (0.5 sec) at their fired angle  
- Radial patterns (EMP, Repulsor) expand outward from station center

**Fire Rate Reference:**

| Tool | Fire Rate | Fires Every |
| :---- | :---- | :---- |
| Rail Driver | 1.0 | 1.0 sec |
| Frequency Scanner | 0.8 | 1.25 sec |
| Tractor Pulse | 0.5 | 2.0 sec |
| Thermal Lance | 0.4 | 2.5 sec |
| Cryo Projector | 0.7 | 1.43 sec |
| EMP Burst | 0.3 | 3.33 sec |
| Probe Launcher | 0.6 | 1.67 sec |
| Repulsor Field | 0.2 | 5.0 sec |

### Damage System

**Station Health:**

- Base Health: 100 HP  
- No invincibility frames after damage  
- All damage types subtract directly from health pool

**MOB Damage to Station:**

| MOB Type | Damage Range | Notes |
| :---- | :---- | :---- |
| Small ramming MOBs | 1-5 | Per collision |
| Medium ramming MOBs | 3-8 | Per collision |
| Shooting MOB projectiles | 2-5 | Per hit |
| Boss ramming | 10-15 | Per collision |
| Boss projectiles | 5-10 | Per hit |
| Boss special attacks | 10-20 | Per hit |

**Ramming vs Projectile Damage:**

- Both subtract from station health identically  
- No damage type resistances (unless Research Spec modifies)  
- Ramming MOBs are destroyed on collision with station  
- Shooting MOB projectiles disappear on hit

### Audio Behavior

**Music:**

- Menu music plays on all menu screens  
- Gameplay music plays during waves 1-7  
- Boss music triggers at 7:00 when boss spawns  
- Victory music plays on episode complete  
- Game over music plays on station destruction  
- Music tracks loop seamlessly

**Sound Effects:**

- SFX **overlap** (do not cut each other off)  
- Multiple Tools firing simultaneously \= multiple overlapping sounds  
- Volume mixing: Music at 70%, SFX at 100%  
- Critical sounds (boss warning, level up) play at full volume

### Save Data Structure

**Saved Game Data (persistent):**

{

  unlocked\_episodes: \[1, 2, 3\],

  unlocked\_specs: \["silk\_weave", "optimized\_targeting"\],

  unlocked\_tools: \["rail\_driver", "frequency\_scanner", "tractor\_pulse", "thermal\_lance"\],

  unlocked\_bonus\_items: \["alloy\_gears", "expanded\_dish", ...\],

  settings: {

    music\_on: true,

    sfx\_on: true,

    cutscenes\_on: true

  },

  stats: {

    episodes\_completed: 3,

    total\_mobs\_destroyed: 1547,

    total\_playtime\_seconds: 7200

  }

}

**Episode Save Data (temporary, per-wave):**

{

  episode\_id: 1,

  current\_wave: 4,

  elapsed\_time: 243,

  station: {

    health: 78,

    rotation\_angle: 127.5,

    tools: \[

      { id: "rail\_driver", slot: 0, upgraded: false },

      { id: "frequency\_scanner", slot: 1, upgraded: true },

      { id: "thermal\_lance", slot: 3, upgraded: false }

    \],

    bonus\_items: \["expanded\_dish", "reinforced\_hull"\]

  },

  player: {

    level: 7,

    rp\_current: 340,

    rp\_to\_next\_level: 892

  },

  mobs: \[

    { type: "greeting\_drone", x: 120, y: 45, health: 8, angle: 215 },

    { type: "silk\_weaver", x: 280, y: 180, health: 15, angle: 45 }

  \],

  collectibles: \[

    { type: "sample\_pod", x: 200, y: 150 },

    { type: "diplomatic\_gift", x: 90, y: 200 }

  \],

  projectiles: \[

    { type: "silk\_projectile", x: 175, y: 160, angle: 180 }

  \]

}

**Save Triggers:**

- Auto-save after each wave completes  
- Save includes full game field state  
- On Episode end (win or lose), Episode Save Data is deleted

### Crank Input

**Rotation Mapping:**

- 1 full crank revolution (360°) \= 180° station rotation  
- Ratio: 2:1 (crank : station)

**Smoothing:**

- Input smoothing enabled (not 1:1 raw input)  
- Smoothing factor: 0.3 (30% of target per frame)  
- Prevents jerky rotation, feels fluid  
- Dead zone: ±2° crank movement ignored (prevents drift)

**Implementation:**

target\_angle \+= crank\_delta \* 0.5  // 2:1 ratio

current\_angle \= lerp(current\_angle, target\_angle, 0.3)  // smoothing

### Tool Attachment

**Slot Assignment:**

- 8 slots around station perimeter (0-7, clockwise from top)  
- When Tool selected at level-up, assigned to **random available slot**  
- Tools cannot be repositioned during gameplay  
- Maximum 6 Tools per Episode (2 slots always empty)

**Slot Positions (on 64×64 station):**

| Slot | Position | Angle | Pixel Offset from Center |
| :---- | :---- | :---- | :---- |
| 0 | Top | 0° | (0, \-32) |
| 1 | Top-Right | 45° | (23, \-23) |
| 2 | Right | 90° | (32, 0\) |
| 3 | Bottom-Right | 135° | (23, 23\) |
| 4 | Bottom | 180° | (0, 32\) |
| 5 | Bottom-Left | 225° | (-23, 23\) |
| 6 | Left | 270° | (-32, 0\) |
| 7 | Top-Left | 315° | (-23, \-23) |

