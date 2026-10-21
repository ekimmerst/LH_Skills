# LH_Skills

Version: 1.0.1. WoW Forever Beta (Interface 16001).

A compact display of your learned professions and secondary skills. Each entry shows its icon and current/maximum skill rank. Hover over an entry to see its localized profession name.

## Display and controls

- White ranks indicate normal skill progress.
- Yellow ranks indicate eligibility for the next training tier according to the addon's skill and character-level checks.
- Orange ranks indicate that the current skill cap has been reached.
- Changes to a skill rank or cap trigger three brief flashes.
- Hold the left mouse button and drag any entry to move the display.
- `/lh_skills reset` restores the default position.

The display hides when no professions or secondary skills are learned. Its position is saved per character in `LH_SkillsDB`. By default, it appears below MiniStats when that addon is available, otherwise below the minimap. MiniStats is optional.

## Installation and upgrade

Place the `LH_Skills` folder in your game's `Interface/AddOns` folder. It must contain `LH_Skills.toc` and `LH_Skills.lua`. Restart WoW and enable **LH_Skills** in the addon list.

When upgrading from MiniSkills, replace the old folder and fully restart WoW. Do not enable both versions together. The reset command is now `/lh_skills reset`.

To retain your position, close WoW and back up each character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/MiniSkills.lua` file. Copy it to `LH_Skills.lua` in the same SavedVariables folder, then change `MiniSkillsDB` to `LH_SkillsDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_Skills.lua` containing settings you want to keep. Without migration, the display starts at its default position.

## Changelog

### 1.0.1 - 2026-10-21

- Renamed MiniSkills to LH_Skills, including its folder, Lua/TOC files, metadata, frame name, saved-variable table and test references.
- Changed the reset command to `/lh_skills reset`.
- Translated addon instructions and chat messages into English.
- Added English documentation and instructions for transferring the saved position.
