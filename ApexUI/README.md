# ApexUI 0.3.0 standalone beta

A Warcraft-inspired HUD with original Apex frames, action bars, minimap, utilities
and layout controls. No Ellesmere addon, font, artwork or framework is required.
Questie, RestedXP, Auctionator, TomTom and other independent addons remain separate.

## Installation
Extract all five addon folders into Interface/AddOns: ApexUI, ApexFishing,
ApexNavigator, ApexGrind and ApexProfessions. The four Apex data folders preserve
existing saved data; their features run inside ApexUI. Restart the game after a
new install. Use /reload for subsequent Lua updates.

## Controls
- /apexui: features, guides and layout settings.
- /apexui layouts: named saves, rename/update, shared default and character copies.
- /apexbars: independent bar visibility, button counts, rows and icon sizes.
- Frames and placement: readability controls and Move frames & bars.
- /apexframes auto: solo Split Wings or paired Ironbound for companion classes.
- /apexframes motionoff or motionon: smooth public health/resource/XP changes.
- Apex Toolkit: opens the feature picker, closes after selection or Escape.
- Toolkit > Addons opens independent addon shortcuts.
- Chat uses a padded bronze surround and readable native tabs. A dedicated Guild
  tab is added once per character; General keeps its subscriptions. Click Guild
  to read guild chat, or use /g to speak there. Right-click any tab for native
  channel settings. Existing custom tabs and their filters are retained.

Health is red, mana blue; current/max and percentages remain readable. Buffs and
debuffs float above the frames. Bags, menu and exact currency share a right-aligned
utility panel. Normal action slots, macros and saved keyboard bindings remain intact.
Each activation still needs player input; this addon does not automate combat.

## Migration and recovery
Existing layouts are imported once into ApexUIDB.framework, with the original
configuration retained in ApexUIDB.frameworkMigrationBackup. /apexstandalone
switches off only the old Ellesmere UI modules and reloads. A previously chosen
standalone setup also applies to alts. Old provider files remain available for rollback.
Never edit SavedVariables while the game is running. Back up WTF before migration.
Named Apex saves do not include independent addons' entire configurations.

## Validation and limits
Local Lua tests cover clean initialization, migrated settings, independent action
pages, bindings, layout saves and isolation, combat editing guards, restricted
values, geometry, animations, suite modules and combat accounting. Live solo-frame,
spell/cast, action-button, launcher and menu checks were performed on the Forever
client. Companion frames, pet targeting, XP and Mend Pet timers were also checked.
All 17 local test suites pass. Toolkit panels, coordinate validation, compact/full
transitions, dragging, skill detection and planner recalculation were checked live.
Completed dungeon runs, crafting transactions, and broader class/display coverage
remain beta testing areas. Tests with simulated game APIs do not replace gameplay.

GPL-3.0. ApexProfessions includes modified Craft Ladder work by Alex P; its source,
license and credits are included. Independent navigation/data credits are retained.
