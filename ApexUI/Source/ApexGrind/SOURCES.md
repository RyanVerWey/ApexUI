# ApexGrind grinding research

Reviewed 16 November 2026. The recommendations are a solo outdoor shortlist, not proof of a universal fastest camp. A current, independently measured Forever XP/hour ranking for every level/class was not found. No historical XP/hour figures are presented as current Forever performance.

## Evidence and provenance

- [QuestieDB, maintained by the Questie team](https://github.com/Questie/QuestieDB): selected numeric NPC IDs, names, levels, normal/elite rank and spawn points were cross-checked against the installed **Forever 1.0.14** artifact. Static Forever corrections are already baked into that artifact. Original Questie data contributors are credited in the upstream repository. This is reference data, not an in-game sighting by ApexGrind. Classic NPC records remain labelled as a Classic baseline; their presence in a Forever package does not establish unchanged respawn rates, pathing or kill speed.
- [Forever Guides grinding overview](https://theforeverguides.com/leveling/best-grinding-spots-30-60/): reviewed as a candidate-finding source for normal-mob outdoor camps. Its page explicitly identifies its camp facts as Classic Era baseline. Its beta-only discussion is stale relative to the current launch, so it is not used for current XP rules or claimed rates. We independently cross-checked selected NPC levels and avoided its elite targets.
- [GotWarcraft historical grinding guide](https://gotwarcraft.com/guides/leveling/1-60.php): used for candidate areas such as Westfall fields, Duskwood cemeteries and Tanaris pirates. This is an old pre-Cataclysm guide; its suggested player levels and XP/hour figures are not imported. ApexGrind instead computes a target band from the character's own level.
- [ForeverDB leveling overview](https://foreverdb.net/guide/leveling): cross-check for faction routes and starting regions. [Zephras Isle](https://foreverdb.net/guide/zephras-isle) is a separate starting experience, so the addon does not send mainland characters there to grind.
- Online NPC spot checks: [Great Goretusk, level 16-17](https://forever-tavern.com/npcs/classic/547-great-goretusk/), [Ghostpaw Alpha, level 27-28](https://www.classic-wow.com/database/npc/3825/ghostpaw-alpha), [Elder Shardtooth, level 57-58](https://www.classic-wow.com/database/npc/7445/elder-shardtooth), [Scrawny Ursera, level 3-4](https://www.wowhead.com/forever/npc=250926/scrawny-ursera). These corroborate names, levels and zones, not a fastest-XP claim.
- [Blizzard's Forever launch overview](https://worldofwarcraft.blizzard.com/en-us/news/24315820/world-of-warcraft-forever-now-live): Forever contains new and reworked areas and quests. The addon therefore does not describe Classic coverage as exhaustive coverage of Forever. Riverglades is not ranked until an appropriate curated camp set is verified.

## Selection rules

Every level from 1 to 59 has candidates for both factions. At level 60 normal leveling is complete. The desired target band is player level minus two through minus one, clamped to level one. Each suggested camp includes mobs in that band. If its whole range does not fit, the panel explicitly gives the levels to select. No candidate has mobs above the player's level, except the unavoidable level 1-2 range for some level-one starter creatures.

Within that eligible list, ranking uses: full-range fit (+30), same zone (+45) or same continent (+8), a capped count of nearby recorded spawns (up to +12), and qualitative pull/downtime risk (-2 per risk point). When a material is selected, its historical drop percentage divided by five contributes up to 16 additional points as a relative yield preference. These weights are our travel/solo-grinding heuristic, not sourced XP measurements. Faction filtering is an access preference, not a claim that shared wildlife is friendly to the other faction. Camps remain normal mobs and avoid deliberate elite/cave farming. Class, gear, phasing, spawn contention and actual respawn speed can change the winner. Use the existing five-minute rate after arrival to compare alternatives.

## Profession loot filter

The following ClassicDB item pages were downloaded and their structured NPC relation tables checked on 16 November 2026:

| Material | Item | Relation used |
|---|---|---|
| Linen Cloth | [2589](https://classicdb.ch/?item=2589) | Dropped by |
| Wool Cloth | [2592](https://classicdb.ch/?item=2592) | Dropped by |
| Silk Cloth | [4306](https://classicdb.ch/?item=4306) | Dropped by |
| Mageweave Cloth | [4338](https://classicdb.ch/?item=4338) | Dropped by |
| Runecloth | [14047](https://classicdb.ch/?item=14047) | Dropped by |
| Light Leather | [2318](https://classicdb.ch/?item=2318) | Skinned from |
| Medium Leather | [2319](https://classicdb.ch/?item=2319) | Skinned from |
| Heavy Leather | [4234](https://classicdb.ch/?item=4234) | Skinned from |
| Thick Leather | [4304](https://classicdb.ch/?item=4304) | Skinned from |
| Rugged Leather | [8170](https://classicdb.ch/?item=8170) | Skinned from |

Only exact curated NPC IDs with a listed historical percentage of at least 1% are eligible. Creature level alone never determines a material source. These numeric facts are saved in `Materials.lua`; the extraction and audit evidence are in `tools/build_materials.py` and `tools/material-evidence.json`. Small incidental drops are intentionally excluded. Recorded percentages are used for relative sorting only and are not displayed as current Forever rates. Uncorroborated new creatures get no guessed material tags. The interface distinguishes killing/looting for cloth from skinning for leather. No-match states preserve the requested XP band; the nearest-level preview is explicit.

The general WoW-Professions pages were checked but some default to post-Cataclysm locations, so those routes were not used. This prevents importing modern Wetlands/Hillsbrad camps into Forever. Blizzard's [Classic manual](https://us.media.blizzard.com/manuals/wow/wow-classic-manual-enUS.pdf) describes leather as obtained by skinning fallen monsters; it is not ordinary corpse loot.

Each coordinate is an actual stored spawn with many neighbouring records, not the arithmetic center of a zone or an invented entrance. It marks a search area, not a guaranteed live mob or safe path. The optional Navigate click passes that coordinate to Apex Navigator or TomTom. No arrow changes automatically.

## Maintenance

### Buff reminders and rested forecasting (2026-11-16)

- The installed Questie Forever `Database/QuestXP/QuestieXP.lua` identifies sleeping-bag aura **429959**, one stack per minute up to three. This is distinct from the Forever legacy talent with a similar name.
- [ScarletUI's XPFood module](https://github.com/timothyrichards/ScarletUI/blob/master/Modules/XPFood.lua) documents hidden shared food aura **1243969** and the 14 visible Well Fed IDs used for detection. Only those numeric game identifiers and the hidden-aura behavior inform this independently written implementation; no upstream implementation is bundled.
- [KillLog's localized combat message registrations](https://github.com/Aneurin/KillLog/blob/master/KillLogFrame.lua) document total kill XP as format argument 2, including group and rested variants. ApexGrind compiles the running client's own localized templates, supports positional arguments, and excludes unnamed quest awards.
- The client exhaustion threshold represents total doubled kill XP coverage, with half available as bonus. Actual XP and pool depletion are reconciled across adjacent event frames. Historical rates retain all awarded XP; only the forecast removes observed rested bonus and budgets future use. The standard doubled-kill model is an estimate, not a promise about undocumented Forever changes. Food and bag effects are never multiplied onto measured XP again.
- `tools/test_bonuses.py` checks full/partial exhaustion, mixed quest/kill awards, newly acquired rested, split event order, pauses, reload migration, localization, visible food variants, bag stacks and unreadable aura data. `tools/test_addon.py` also exercises event wiring and both panel modes.

`tools/build_spots.py` holds the curated choices and original risk notes. It reads selected facts through `tools/research_catalog.py`, produces `Spots.lua`, and records the selected facts in `tools/spot-evidence.json`. No full upstream database or source implementation is included in the addon. `tools/test_addon.py` checks every level/faction, starter-region continuity, target bands, control behaviour, and explicit-only navigation. Review the reference set after Forever world/level changes; do not silently relabel this dataset as live-measured.
