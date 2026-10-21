# LH_Skills

Version: 1.1.0. WoW Forever Beta (Interface 16001).

A compact display of your learned professions and secondary skills. Each entry shows its icon and current/maximum skill rank. Hover over an entry to see its localized profession name. The rank text uses the same 10-point quest objective font and shadow treatment as LH_PetStats.

## Display and controls

- White ranks indicate normal skill progress.
- Yellow ranks indicate eligibility for the next training tier according to the addon's skill and character-level checks.
- Orange ranks indicate that the current skill cap has been reached.
- Changes to a skill rank or cap trigger three brief flashes.
- Unlock the bar in Settings or with `/lh_skills unlock`, then left-drag an entry or the empty bar area to move it. A gray background shows the bar's bounds while unlocked, including when changing its width. Lock it with `/lh_skills lock` to prevent accidental moves. The unlocked preview stays visible even without learned skills.
- `/lh_skills reset` restores the default position.

The locked display hides when no professions or secondary skills are learned. Its position, activation, lock state, group alignment and width are saved per character in `LH_SkillsDB`. By default, it appears below LH_Stats when that addon is available, otherwise below the minimap. LH_Stats is optional.

## Native settings

Open WoW Settings > AddOns > LH Tweaks > LH Skills, or type `/lh_skills`. The page lets you enable or disable the display, unlock or lock moving, align the **whole group** of skill icons and values to the left, center or right of the bar, and set the bar width from 160 to 800 UI units (320 by default). If the combined skills need more space, the bar grows to fit them. Reset position restores the original anchor without changing the other preferences. The AddOn list groups LH Skills below LH Tweaks and uses its shared gold icon.

`/lh_skills on` and `/lh_skills off` toggle the display directly. All options are per character and update immediately.

## Installation and upgrade

Place the complete `LH_Skills` folder in your game's `Interface/AddOns` folder. It must contain `LH_Skills.toc`, `LH_Skills.lua`, `Settings.lua` and `Media`. Install and enable LH_Tweaks as well. Fully restart WoW and enable **LH Skills** below **LH Tweaks** in the addon list. Version 1.1.0 loads a new settings file and icon metadata, so `/reload` alone is insufficient for this upgrade.

When upgrading from MiniSkills, replace the old folder and fully restart WoW. Do not enable both versions together. The reset command is now `/lh_skills reset`.

To retain your position, close WoW and back up each character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/MiniSkills.lua` file. Copy it to `LH_Skills.lua` in the same SavedVariables folder, then change `MiniSkillsDB` to `LH_SkillsDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_Skills.lua` containing settings you want to keep. Without migration, the display starts at its default position.

## Changelog

### 1.1.0 - 2026-10-21

- Added native LH Skills options under LH Tweaks and the shared icon and AddOn grouping.
- Added persistent activation and lock controls, with an unlocked preview when no skills are learned.
- Added left/center/right alignment for the complete skill group within an adjustable bar width.
- Matched the LH_PetStats quest objective font style at 10 points, including its lighter shadow.
- Covered layout, font, drag lock, activation, native settings and icon matching in `_settings_test.py` and `.test.py`.

### 1.0.2 - 2026-10-21

- Updated the optional dependency and default positioning to use LH_Stats after its rename.


### 1.0.1 - 2026-10-21

- Renamed MiniSkills to LH_Skills, including its folder, Lua/TOC files, metadata, frame name, saved-variable table and test references.
- Changed the reset command to `/lh_skills reset`.
- Translated addon instructions and chat messages into English.
- Added English documentation and instructions for transferring the saved position.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
