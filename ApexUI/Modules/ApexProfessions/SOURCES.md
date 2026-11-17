# Research and evidence, checked 17 November 2026

## Primary implementation and data sources

1. [Craft Ladder source](https://github.com/saintmodx/craft-ladder), release 1.11.0. Downloaded the source, inspected its GPL-3.0 license, all profession data schemas, acquisition requirements, recursive component pricing, inventory accounting, gathering models and tests. The original builders and tests are retained under upstream/. Its data uses Forever client build 1.60.1.70938, with per-file generation dates of November 13–15. This is a modified fork, not an original reimplementation of that engine.
2. [Craft Ladder release and documented limitations](https://www.curseforge.com/wow/addons/craft-ladder). Confirms Forever-specific coverage and explicitly distinguishes client-derived recipe data from Classic-derived trainer/quest estimates. Retained those uncertainty flags instead of presenting them as confirmed Forever mechanics.
3. [QuestieDB](https://github.com/Questie/QuestieDB), installed Forever 1.0.14. Parsed its documented item NPC-drop fields and NPC levels, rank, faction and spawn coordinates. Checked 560 recipe reagents and produced 2,758 outdoor source candidates for 179 items. Source relationships do not supply reliable Forever drop rates. The generator preserves multiple regions and level bands, excludes elite and unplaced creatures, and uses an actual recorded coordinate rather than an averaged point in empty space.
4. [Auctionator source](https://github.com/Auctionator/Auctionator). Verified against the user's installed Source/API/v1/GetAuctionPrice.lua, GetAuctionAge.lua, MultiSearch.lua and Database/Mixin.lua. GetAuctionAgeByItemID returns age in DAYS, not a timestamp. Use API caller ID ApexProfessions, prices by item ID, and a guarded search only with the AH open. Missing/undated/stale data must not be silently called today's price.
5. [CMaNGOS classic-db](https://github.com/cmangos/classic-db). Historical trainer fees, rank requirements, gathering and disenchanting distributions are inherited through Craft Ladder; they are estimates where not observed on Forever.
6. [AllTheThings](https://github.com/ATTWoWAddon/AllTheThings) and GatherMate2_Data, as credited by the upstream dataset. Recipe acquisition/favor/source information and recorded gathering-zone density. Original notices, including ATT's MIT notice, are preserved in CREDITS.txt.

## Coverage audit by profession

| Profession | Recipe/route information inspected | Important constraint retained |
| --- | --- | --- |
| Alchemy | Herbs, oils, vials, Forever recipes and trainer tiers | Stone/tool needs and recipe cooldowns |
| Blacksmithing | Stones, bars, vendor flux, recursive grinding stones | Tools, forge/specialization and recipe access |
| Enchanting | Dust/essence reagents, rods, crafted Forever outputs | Disenchant equipment is not priced as free |
| Engineering | Bars, components, blasting powders and tools | Whole component batches and specialization |
| Leatherworking | Leathers, hides, threads, cured/intermediate materials | Current Skinning skill and mob levels for self-farming |
| Tailoring | Cloth, bolts, thread/dye and recipe sources | Retain crafted bolts for later steps; cooldown exclusions |
| Herbalism | Herb skill thresholds, node density, faction/zone levels | Current gathering skill, safe-access and zone uncertainty |
| Mining | Node unlocks, smelting/alloys and rank caps | Fastest may buy ore; farming keeps skill/level constraints |
| Skinning | Creature levels, skill requirements and leather distributions | Mob level and current Skinning access |
| Cooking | Forever recipe colors, meat/fish, spices and recipe vendors | Book/quest ranks and uncertain recipe-source labels |
| First Aid | Cloth recipes and Forever additions, higher-rank acquisition | Rank gates and recipe learning costs |
| Fishing | Skill/catch estimates, lures, rank books/quests and zone fish | Historical catch mix; no fabricated exact shore coordinate |

## Cross-checks and exclusions

Reviewed the [Forever profession leveling overview](https://metammo.com/wow-forever/professions), the [profession changes comparison](https://metammo.com/wow-forever/profession-changes), and its Alchemy/Blacksmithing routes as cross-checks of the scale of Forever changes. These are secondary material, not bundled/copied leveling guides or the source of gold quotes. They also warn that server-side trainer access is not fully represented in client tables.

Reviewed [ForeverArtisan](https://www.curseforge.com/wow/addons/foreverartisan) and [DeKaTeK SkillEazy](https://www.curseforge.com/wow/addons/dekateks-skilleazy) to compare coverage. Their code was not copied.

The requested daily cost cannot be fetched from the internet: it must use the player's realm/faction Auctionator scan. No prices were fabricated from a generic guide. Cost and speed rankings are explicit models, not guaranteed global optima. Contemporary client tables and observed in-game prices take precedence over generic Classic routes.
