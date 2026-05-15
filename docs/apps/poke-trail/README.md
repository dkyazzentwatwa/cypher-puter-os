# Poke-Trail

## Overview

Poke-Trail is an imported creature trail RPG in the Cypher OS SD catalog. It mixes an Oregon Trail-style day-by-day survival loop with original creature battles, catching, audio, and region progression.

## What It Does

- Runs a text-forward trail survival RPG on the Cardputer.
- Tracks supplies, party health, morale, rig durability, lures, and regional progress.
- Includes turn-based creature battles, catching, leveling, and starter growth.
- Uses procedural chiptune audio and does not require SD audio assets.
- Saves to SD when available and keeps running with saves disabled when SD is missing.

## Controls

- `1`-`4`: choose visible actions.
- `w` / `s`: move selection.
- `;` / `.`: alternate up/down keys for Cardputer legends.
- `Enter`: confirm selected menu item.
- `Backspace` / `Delete` / `q`: cancel or return when available.
- `m`: mute or unmute chiptune music and sound effects.

## SD And Runtime Files

- Cypher OS app binary: `/cypher-puter/apps/poke-trail.bin`.
- Save path: `/poke-trail/save.sav`.
- Temporary save: `/poke-trail/save.tmp`.
- Backup save: `/poke-trail/save.bak`.
- Imported from: `/Users/cypher/Documents/GitHub/poke-trail/PokeTrail`.

## Return To Cypher OS

Use `Backspace`, `Delete`, or `q` where the game exposes cancel/return behavior. In the Cypher OS catalog, Poke-Trail is imported as an individual Game OS title.

## Source README Notes

Poke-Trail is a tiny text RPG for the M5Stack Cardputer. It mixes an Oregon Trail-style day-by-day survival loop with lightweight original creature battling, catching, faction-flavored story beats, and region-based progression.

The project is Arduino CLI only. It does not use PlatformIO and does not need internet access at runtime.

## Hardware Target

- M5Stack Cardputer / Cardputer-Adv
- M5StampS3 / ESP32-S3
- 240x135 TFT display
- Built-in keyboard
- microSD card slot

Hardware assumptions follow the official M5Stack Cardputer Arduino examples:

- `M5Cardputer.begin(cfg, true)` enables the keyboard.
- Display access uses `M5Cardputer.Display`.
- Keyboard polling uses `M5Cardputer.Keyboard.keysState()`.
- microSD uses SPI with `SCK=40`, `MISO=39`, `MOSI=14`, `CS=12`.

## File Tree

```text
poke-trail/
|-- README.md
`-- PokeTrail/
    |-- PokeTrail.ino
    |-- GameTypes.h
    |-- GameData.h
    |-- GameData.cpp
    |-- GameLogic.h
    |-- GameLogic.cpp
    |-- DisplayUI.h
    |-- DisplayUI.cpp
    |-- Input.h
    |-- Input.cpp
    |-- SoundEngine.h
    |-- SoundEngine.cpp
    |-- SaveLoad.h
    `-- SaveLoad.cpp
```

## Controls

- `1`-`4`: choose visible actions.
- `w` / `s`: move selection.
- `;` / `.`: alternate up/down keys for Cardputer legends.
- `Enter`: confirm selected menu item.
- `Backspace` / `Delete` / `q`: cancel or return when available.
- `m`: mute or unmute chiptune music and sound effects.

## Gameplay

On boot, Poke-Trail shows a 4-second animated `Poke-Trail` intro inspired by the sibling `cardputer-games` splash: scan-grid frame, moving trail cart, beacon sweep line, and a loading bar before the title menu.

The game includes procedural chiptune audio through the Cardputer speaker: quiet background loops for title, trail, trader, battle, and end screens, plus short sound effects for menus, travel, encounters, battles, catching, saving, and game-over moments. Audio is code-only and does not require SD card sound files.

New players should start with the beginner manual embedded later on this page.

You lead a small party across the Wilderline Trail toward the Beacon Coast. Each day consumes supplies, advances through the current region, wears down the rig, and may trigger a trail event, trader, boss, or wild trailkin encounter.

Resources:

- Food
- Medicine
- Trade tokens
- Scrap
- Batteries / power
- Morale
- Rig durability
- Lure tags
- Party health
- Region miles and total trail miles

Creature stats:

- Species ID
- Type
- Level
- HP / derived max HP
- XP
- Trait
- Bond
- Status
- Stamina

The V2 content model uses fixed compiled tables for 45 original trailkin species and 10 regions. Creature instances store small IDs and stats, while species names, type data, rarity, region masks, abilities, and flavor live in program data.

Trail events include sickness, lost supplies, found supplies, weather setbacks, scrap finds, relay repairs, traders, boss blocks, and wild creature ambushes. Battles are turn-based: hit, use a stamina skill, use medicine, spend a lure tag, or flee. Victories grant XP and level-ups; starter creatures can grow into upgraded forms. Caught creatures join the active roster, up to six total.

Current regions:

1. Crankshaft Hollow
2. Rustgrass Prairie
3. Gumdrop Thicket
4. Mudbell Fen
5. Cinderglass Badlands
6. Fusewire Canyon
7. Frostcap Switchbacks
8. Drowsewood Ruins
9. Chromegrass Divide
10. Beacon Coast

## Save and Load

The V2 save file lives at:

```text
/poke-trail/save.sav
```

The game writes `/poke-trail/save.tmp` first, preserves the previous save as `/poke-trail/save.bak`, then renames the temp file to `/poke-trail/save.sav`. If the SD card is missing or cannot be initialized, the game keeps running and shows that saves are disabled.

The loader also understands the original root-level `/poke-trail.sav` `PTSAVE1` format and migrates it into the V2 in-memory model. The next save writes the new `PTSAVE2` layout.

V2 save format:

```text
PTSAVE2
schema=2
seed=38492017
day=46
region=4
regionMiles=81
totalMiles=710
res=42,3,18,5,27,71,84,2
partyHealth=76
active=0
flags=0000008F,00000012
reps=12,9,15,7,10
caught=00000000000001AF
quest=0,0,0,0,0,0,0,0
ending=0
rosterCount=1
mon=0,9,44,31,0,8,0,67,5,0
crc=7A31
```

## Manual Test Checklist

- Boot the Cardputer and confirm the title menu renders in landscape.
- Confirm the animated `Poke-Trail` intro is readable and lasts about 4 seconds.
- Confirm the intro cue plays, title music starts, and `m` mutes/unmutes audio.
- Verify number keys and `Enter` select menu choices.
- Start a new game and confirm region, miles, food, medicine, tokens, scrap, power, morale, durability, lure tags, party health, and active creature render.
- Travel several days and confirm resources decrease, events appear, regions advance, and autosave works.
- Trigger a battle and test hit, skill, medicine, lure tag, flee, status, stamina, victory XP, and level-up.
- Confirm menu, travel, trader, battle, catch, flee, win, and game-over sound effects do not block input or redraws.
- Catch a wild creature and confirm it appears in the roster.
- Visit a trader and test food, medicine, lure tag, and repair actions.
- Continue far enough to cross into a new region and confirm the milestone text appears.
- Boot with no SD card and confirm the game does not crash.
- Insert a FAT32 microSD card, save, reboot, load, and confirm state is restored.
- Load an old `PTSAVE1` file if available and confirm it migrates.
- Reach party death and Beacon Coast victory paths.

## Beginner Game Guide

Welcome to Poke-Trail, a tiny survival creature RPG for the M5Stack Cardputer.
You are guiding a fragile trail crew across the Wilderline Trail to the Beacon
Coast. Along the way you will manage supplies, repair your rig, battle wild
trailkin, catch new companions, and try to survive long enough to reach the end.

This guide is written for first-time players.

## Goal

Your main goal is simple:

Reach the **Beacon Coast** before your party collapses.

You travel through 10 regions:

1. Crankshaft Hollow
2. Rustgrass Prairie
3. Gumdrop Thicket
4. Mudbell Fen
5. Cinderglass Badlands
6. Fusewire Canyon
7. Frostcap Switchbacks
8. Drowsewood Ruins
9. Chromegrass Divide
10. Beacon Coast

Each day you can travel, rest, check your roster, or save and return to the
title menu. Traveling moves you forward, but it also uses food, power, and rig
durability.

## Controls

| Key | Action |
|---|---|
| `1`-`5` | Choose numbered menu actions |
| `w` / `s` | Move menu selection |
| `;` / `.` | Alternate up/down keys |
| `Enter` | Confirm selected item |
| `Backspace`, `Delete`, or `q` | Go back when available |

Most screens are built around number keys. If you are unsure, press the number
shown beside the action you want.

## Starting Out

A new game begins with one starter trailkin:

| Starter | Type | Beginner style |
|---|---|---|
| Trailcub | Sprout | Balanced and forgiving |

Trailcub is a good first companion because it has solid health and a helpful
camp-style ability. Keep it alive, let it gain XP, and it can eventually grow
into **Brambleback**.

## Main Trail Screen

The trail screen shows your most important information:

| Display | Meaning |
|---|---|
| Day | How long your journey has lasted |
| Region name | Where you are now |
| Mi | Miles through the current region |
| Tot | Total miles toward the Beacon Coast |
| Food | Daily supplies |
| Med | Medicine for healing |
| Tok | Trade tokens, your money |
| Sc | Scrap for repairs |
| Pw | Battery power |
| Mo | Morale |
| Du | Rig durability |
| Tags | Lure tags for catching |
| Party HP | Overall crew health |

Beginner rule: if **Food**, **Party HP**, **Morale**, or **Durability** gets low,
slow down and recover before pushing forward.

## Trail Actions

### 1 Travel

Travel advances the day and moves you forward. It can trigger events, traders,
bosses, or wild trailkin battles.

Travel usually costs:

- Food
- Power
- Rig durability

Bad regions can increase these costs.

### 2 Rest

Resting costs tokens or food. It restores:

- Party health
- Morale
- Creature HP
- Creature stamina

Rest is often better than gambling on another travel day with weak health.

### 3 Roster

The roster shows your active trailkin party. You can carry up to 6 active
trailkin. Press `1`-`6` to choose the active creature.

Only healthy creatures can become active.

### 4 Save/Menu

Saves your current run to SD card and returns to the title menu.

The game also autosaves after travel and important battle results if the SD card
is working.

## Resources

| Resource | What it does | Beginner advice |
|---|---|---|
| Food | Keeps the party alive each travel day | Buy before it drops below 20 |
| Medicine | Heals sickness and battle damage | Save some for dangerous regions |
| Tokens | Used for food, medicine, lures, and repairs | Do not spend all of them early |
| Scrap | Repairs the rig | Keep at least 4 scrap if possible |
| Power | Used by the device and trail systems | Low power can hurt morale |
| Morale | Affects travel pace and survival pressure | Rest if it falls below 35 |
| Durability | Your rig condition | Repair before it drops below 35 |
| Lure tags | Improves catching chances | Use on creatures you really want |

## Battles

Battles are turn-based. Your active trailkin fights one wild trailkin.

Battle menu:

| Action | Use when |
|---|---|
| `1 Hit` | You want safe basic damage |
| `2 Skill` | You want stronger damage or status effects |
| `3 Medicine` | Your creature is hurt or statused |
| `4 Lure tag` | You want to catch the wild trailkin |
| `5 Flee` | The fight is too risky |

### Hit

Hit is the basic attack. It does not cost stamina.

Use this when you are saving stamina or finishing off a weak enemy.

### Skill

Skill costs stamina. It hits harder and can sometimes apply a status effect.

Use this against bosses, dangerous wild trailkin, or creatures you want to weaken
before catching.

### Medicine

Medicine heals your active creature and clears its status.

Use it before your creature gets knocked out. If your active trailkin falls, your
party loses health and morale.

### Lure Tag

Lure tags are used when trying to catch a wild trailkin.

Your catch chance is better when:

- The wild trailkin has low HP
- The wild trailkin has a status effect
- Your active creature is higher level
- You still have lure tags

Bosses and legendary creatures cannot usually be caught.

### Flee

Fleeing can save your run. It is less reliable against bosses.

There is no shame in running from a bad fight. The trail is long.

## Status Effects

| Status | What it means |
|---|---|
| Burn | Takes damage over time |
| Chill | Reduces fighting ability |
| Shock | Can cause a lost turn |
| Sick | Takes damage over time |
| Muddled | Reduces attack |
| Guarded | Raises defense |
| Tired | Can cause a lost turn |

Medicine clears your active creature's status. Resting can also clear some
status effects.

## Creature Types

Trailkin have types. Some types hit harder or weaker against others.

Current types:

- Sprout
- Ember
- Tide
- Stone
- Volt
- Gust
- Umber
- Glow
- Gear
- Frost

Beginner tip: do not worry about memorizing the full type chart right away. If a
skill seems weak, switch to basic hits, flee, or try another creature later.

## Catching Trailkin

You can carry 6 active trailkin. Catching gives you more options and can improve
your ending.

Good first catches:

| Trailkin | Region | Why it helps |
|---|---|---|
| Dustbat | Rustgrass Prairie | Fast and common |
| Tinpeck | Crankshaft/Fusewire/Divide | Can help find scrap |
| Mireling | Mudbell Fen | Balanced Tide type |
| Cinderpup | Cinderglass Badlands | Strong Ember attacker |
| Voltskitter | Fusewire Canyon | Fast Volt status user |
| Geargoat | Chromegrass Divide | Durable Gear/Stone helper |

If your roster is full, a caught creature cannot join. Keep an eye on your 6
slots.

## Leveling And Growth

Winning battles gives XP to the active trailkin. Leveling improves its combat
power.

Some starters can grow into stronger forms around level 10:

| Early form | Growth form |
|---|---|
| Trailcub | Brambleback |
| Sparkit | Kilncat |
| Pebblor | Bouldrum |

The current game starts you with Trailcub, so Brambleback is the growth form most
beginners will see first.

## Regions And Danger

Regions get more dangerous as you travel.

| Region | Danger | Beginner notes |
|---|---:|---|
| Crankshaft Hollow | 1 | Learn the controls |
| Rustgrass Prairie | 2 | Catch common trailkin |
| Gumdrop Thicket | 3 | Food and morale matter |
| Mudbell Fen | 4 | Illness becomes more likely |
| Cinderglass Badlands | 5 | Watch power and durability |
| Fusewire Canyon | 6 | Good place for Volt and Gear types |
| Frostcap Switchbacks | 7 | Food and health pressure rises |
| Drowsewood Ruins | 7 | Strange events and tougher fights |
| Chromegrass Divide | 8 | Repair before pushing through |
| Beacon Coast | 9 | Final stretch, conserve everything |

Each region has a possible boss encounter after you are far enough through it.
Bosses are dangerous and harder to flee from.

## Traders

Traders can appear during travel. They offer:

| Option | Cost |
|---|---:|
| Food +15 | 5 tokens |
| Medicine | 8 tokens |
| 2 Lure tags | 7 tokens |
| Repair rig | 4 scrap or 10 tokens |

Beginner shopping priority:

1. Buy food if below 20.
2. Repair if durability is below 35.
3. Buy medicine if you have 0 or 1.
4. Buy lure tags only when you are stable.

## Saving

Poke-Trail saves to the SD card at:

```text
/poke-trail/save.sav
```

It also keeps a backup:

```text
/poke-trail/save.bak
```

If the SD card is missing, the game still runs, but saves are disabled.

Beginner tip: if you are testing on hardware, keep a FAT32 microSD card inserted
before starting a serious run.

## Beginner Strategy

### First 10 Days

- Travel until a trader appears.
- Catch one extra trailkin if you can.
- Keep at least 20 food.
- Do not waste lure tags on every creature.
- Rest if party health drops below 60.

### Before Leaving A Region

- Check food.
- Check durability.
- Make sure at least one creature is healthy.
- Save from the trail menu.

### Before Boss Fights

- Rest if possible.
- Make sure your active creature has stamina.
- Use `Skill` early.
- Use `Medicine` before HP gets too low.
- Do not try to catch bosses.

### When Things Go Bad

If supplies are low:

- Rest only if you can afford it.
- Buy food before lures.
- Repair before the rig drops too low.
- Flee from fights that are not worth the risk.

If your active creature is weak:

- Open `Roster`.
- Pick another healthy trailkin.
- Rest at the next safe chance.

## Common Beginner Mistakes

| Mistake | Better habit |
|---|---|
| Traveling with low food | Buy food when you can |
| Saving all medicine forever | Use it before a knockout |
| Trying to catch bosses | Fight or flee instead |
| Ignoring durability | Repair below 35 |
| Spending all tokens on lures | Keep tokens for food and medicine |
| Fighting every battle | Flee when survival matters more |

## How To Win

To win, reach the Beacon Coast with the party still alive.

Your ending can change based on your condition and choices:

| Ending | How it tends to happen |
|---|---|
| Guild Ending | Reach the coast in solid condition |
| Bramble Ending | Catch many trailkin and keep creature-friendly progress |
| Coil Ending | Finish with strong power/scrap momentum |
| Baron Ending | Finish with lots of tokens or Rust-style advantage |
| Blackout Ending | Reach the coast with low morale or broken durability |
| Lost Trail | Party health falls to 0 before the coast |

For your first win, do not chase the perfect ending. Aim to survive, learn the
regions, and build a dependable roster.

## Quick Reference

Best early habits:

- Keep food above 20.
- Keep durability above 35.
- Rest before party health drops too low.
- Catch a few common trailkin early.
- Save after big progress.
- Flee from bad fights.
- Use medicine before a creature falls.

The trail is not about winning every fight. It is about arriving with enough
friends, food, bolts, battery, and courage to see the coast.

## Source Docs Used

- `/Users/cypher/Documents/GitHub/poke-trail/README.md`
- `/Users/cypher/Documents/GitHub/poke-trail/docs/BEGINNER_GAME_GUIDE.md`
