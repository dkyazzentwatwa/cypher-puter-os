# Cypher Desk

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `cypher-desk` |
| SD binary | `/cypher-puter/apps/cypher-desk.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cypher-desk |
| Local source path | `/Users/cypher/Documents/GitHub/cypher-desk` |
| Build profile | `cardputer-adv` |
| Extra SD paths | `/cypher-puter/desk/` |
| Return path | Use Return to Launcher from the app menu. |
| Package note | Current upstream app is an ultra-simple SD-backed notepad/file browser for the Cardputer ADV. |
| Use it when | You want a small SD-backed notepad for plain text and Markdown files. |

## Overview

Cypher Desk is the simple offline notepad in the Cypher OS deck. It creates and edits plain `.txt` and `.md` files from a small one-level SD file browser designed around the Cardputer keyboard.

## What It Does

- Creates new `.txt` notes.
- Creates new `.md` notes.
- Creates one-level folders.
- Shows folders first, then loose notes from the home screen.
- Opens a folder to edit files inside it.
- Refreshes the visible file list from the SD card.
- Edits text with cursor navigation, autosave, and manual save.

## Controls

- Menu move: `W/S`, `K/J`, or arrow-labeled keys.
- Open folder / file: `Enter` or BtnA.
- Newline in editor: `Enter` or BtnA.
- Editor cursor move: `Fn` + arrow-labeled keys.
- Back/exit: backtick only.
- Delete text: `Del`.
- Save note: `Fn+S`.
- Refresh file list: select `Refresh files`.

## SD And Runtime Files

- `/cypher-puter/desk/notes/`
- Example loose note: `/cypher-puter/desk/notes/0001_note.txt`
- Example folder note: `/cypher-puter/desk/notes/folder-01/0001_note.md`
- Cypher OS app binary: `/cypher-puter/apps/cypher-desk.bin`.

Older Cypher Desk folders such as `docs`, `notebooks`, `archive`,
`scratch.txt`, `today.txt`, and `state` are not deleted or migrated. The
simplified app just stops showing them.

## Return To Cypher OS

Backtick is the explicit exit key. The app is designed to launch from Cypher OS and return without adding extra accidental exit keys.

## Source Docs Used

- README.md from /Users/cypher/Documents/GitHub/cypher-desk
- Cypher OS package notes
