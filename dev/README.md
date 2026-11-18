# dev

Tools for checking the addons outside the game. Not part of any addon; nothing here is installed.

- `harness.py` loads ZDungeon under a mock WoW API and prints the guides it writes.
  `python3 dev/harness.py 29 zq gear` (set `ZD_SIDE=Alliance` for the other faction).
- `audit_routes.py` builds every dungeon guide for both factions at twelve levels and lists problems.
  `python3 dev/audit_routes.py report.json`

Both need Python 3 with the `lupa` package (`pip install lupa`) and are run from the repo root.
To rebuild ZDungeon's quest data from QuestieDB, see `ZDungeon/tools/`.
