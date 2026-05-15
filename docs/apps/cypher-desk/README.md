# Cypher Desk

## Overview

Cypher Desk is the calm offline writing and utility workspace in the Cypher OS deck. It is document-first, SD-backed, and designed around the Cardputer keyboard.

## What It Does

- Home workspace with recent drafts, notebooks, scratchpad, today list, status, sessions, reference tools, and archive access.
- Plain-text document storage on the SD card.
- Single-pane editor with cursor navigation, autosave, manual save, and command shortcuts.
- Notebook folders, scratchpad capture, today list, and archive workflows.
- Session stats for saves, word count, character count, and focus time.

## Controls

- Move: `W/S`, `K/J`, arrow legends, `,/.`.
- Cursor left/right: `A/D`, `H/L`, or arrow legends.
- Select/newline: `Enter` or BtnA.
- Back/exit: backtick only.
- Delete text: `Del`. Save: `Fn+S`. New: `Fn+N`. Retitle: `Fn+R`. Move to notebook: `Fn+M`. Archive: `Fn+A`.

## SD And Runtime Files

- `/cypher-puter/desk/docs/`
- `/cypher-puter/desk/notebooks/`
- `/cypher-puter/desk/archive/`
- `/cypher-puter/desk/scratch.txt`
- `/cypher-puter/desk/today.txt`
- `/cypher-puter/desk/state/recents.txt`
- `/cypher-puter/desk/state/session.txt`
- Cypher OS app binary: `/cypher-puter/apps/cypher-desk.bin`.

## Return To Cypher OS

Backtick is the explicit exit key. The app is designed to launch from Cypher OS and return without adding extra accidental exit keys.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/cypher-desk
- Cypher OS package notes
