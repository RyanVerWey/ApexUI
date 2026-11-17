"""Curated camps, checked against the installed Forever NPC reference database.

Only selected NPC facts and one existing spawn per camp are emitted. The full
Questie database is not redistributed. References and limitations: SOURCES.md.
"""
import json
import math
from research_catalog import rows, spawns, root

# areaID: (uiMapID, zone name, continent, access preference)
zones = {
12:(1429,'Elwynn Forest',0,'Alliance'),1:(1426,'Dun Morogh',0,'Alliance'),
141:(1438,'Teldrassil',1,'Alliance'),14:(1411,'Durotar',1,'Horde'),
215:(1412,'Mulgore',1,'Horde'),85:(1420,'Tirisfal Glades',0,'Horde'),
40:(1436,'Westfall',0,'Alliance'),38:(1432,'Loch Modan',0,'Alliance'),
148:(1439,'Darkshore',1,'Alliance'),130:(1421,'Silverpine Forest',0,'Horde'),
17:(1413,'The Barrens',1,'Horde'),44:(1433,'Redridge Mountains',0,'Alliance'),
10:(1431,'Duskwood',0,'Alliance'),11:(1437,'Wetlands',0,'Alliance'),
331:(1440,'Ashenvale',1,'Both'),400:(1441,'Thousand Needles',1,'Horde'),
33:(1434,'Stranglethorn Vale',0,'Both'),45:(1417,'Arathi Highlands',0,'Both'),
405:(1443,'Desolace',1,'Both'),15:(1445,'Dustwallow Marsh',1,'Both'),
8:(1435,'Swamp of Sorrows',0,'Both'),3:(1418,'Badlands',0,'Both'),
357:(1444,'Feralas',1,'Both'),440:(1446,'Tanaris',1,'Both'),
51:(1427,'Searing Gorge',0,'Both'),16:(1447,'Azshara',1,'Both'),
490:(1449,"Un'Goro Crater",1,'Both'),361:(1448,'Felwood',1,'Both'),
28:(1422,'Western Plaguelands',0,'Both'),46:(1428,'Burning Steppes',0,'Both'),
618:(1452,'Winterspring',1,'Both'),139:(1423,'Eastern Plaguelands',0,'Both'),
1377:(1451,'Silithus',1,'Both'),
16593:(2521,'Zephras Isle',2991,'Both'),
}
# Zone-local normal mobs selected for outdoor solo grinding. Risk is a qualitative
# downtime penalty, never a fabricated XP/h measurement. Comments are original.
groups = [
(16593,[250873,251402,250926,250937,251245,250868,250928,251707,250874,250927],'Zephras wildlife','Stay near unlocked quest areas; island phasing can change availability.',1),
(12,[299,257,525,30,1922,118],'Northshire / Goldshire outskirts','Stay outdoors; skip mine interiors and named enemies.',1),
(12,[40,116],'Elwynn cloth targets','Use outdoor Defias or the mine entrance; skip deep tunnels.',3),
(1,[705,708,1125,1201,1689],'Coldridge / Kharanos countryside','Use open snowfields; avoid tunnel pulls.',0),
(141,[2031,1985,1995,1999,2000],'Shadowglen / Dolanaar woods','Pull individually; avoid cave respawns.',1),
(14,[3098,3124,3125,3099,3100,3127],'Valley of Trials / Razor Hill','Open-ground loop; skip humanoid packs.',0),
(14,[3111,3112,3114],'Durotar quilboar outskirts','Pull camp edges; skip caster packs and retreating adds.',3),
(215,[2955,2966,2958,3035,2957,2960],'Red Cloud Mesa / Bloodhoof plains','Spread-out beasts allow controlled single pulls.',0),
(85,[1508,1513,1547,1548,1554,1549],'Deathknell / Brill countryside','Keep clear of Scarlet camps and named enemies.',0),
(40,[480,36,454,114,157,547,1216],'Westfall fields / coast','Loop outdoor spawns; quest traffic may slow tagging.',1),
(40,[95,117,504,590],'Westfall Defias / gnoll camps','Stay outdoors; skip Defias Pillagers and mine interiors.',3),
(38,[1190,1191,1192],'Loch-side boar grounds','Beasts around the loch; avoid elite hunting targets.',0),
(148,[2321,2069,2070,2237,2071],'Darkshore woodland','Follow the land-side beast loop; avoid underwater pulls.',0),
(130,[1765,1780],'Northern Silverpine woods','Watch for wandering Sons of Arugal elites.',3),
(17,[3244,3415,3246,3242,3425,3245,3256,3240,3239],'Barrens beast loop','Choose open-ground beasts; skip higher-level patrols.',0),
(17,[3267,3265,3266],'Barrens Razormane camps','Pull the camp edge; control runners before they reach adds.',3),
(44,[547],'Lakeridge Highway','Boars near the southern road; avoid Blackrock packs.',0),
(10,[213,923,628,1258],'Duskwood wolf loop','Watch for Stitches on the road; pull away from other mobs.',1),
(10,[202,531],'Raven Hill / Tranquil Gardens','Stay above ground; avoid MorLadim and casters.',2),
(10,[889,892,212],'Vul\'Gol Ogre Mound','Use the outside edge; skip cave interiors and fire casters.',3),
(10,[570],'Raven Hill cemetery north','Ghouls can add downtime; avoid the crypt and named mobs.',3),
(11,[1007,1008,1010,1011,1012],'Mosshide marsh camps','Pull camp edges; avoid casters and multi-pulls.',2),
(11,[1020,1021,1022,1023],'Wetlands raptor grounds','Open raptor loop; avoid elite/named raptors and nest packs.',1),
(331,[3823,3809,3824,3810,3825,3789,3811],'Ashenvale beasts / Terrowulf edge','Pull in open ground; check higher-level neighbours.',1),
(400,[4094,4093,4099,4095],'Splithoof centaur grounds','Use open camp edges and skip spellcasters.',2),
(400,[4107],'Highperch','Narrow paths and poison increase downtime; pull singly.',4),
(400,[4147],'Shimmering Flats','Open loop; basilisk control effects can slow kills.',2),
(33,[681,683,682,736,1085,854,687],'Northern / central jungle beasts','Skinning option; watch for stealth and nearby camp packs.',1),
(45,[2552,2562,2563,2565],'Arathi outdoor camps','Avoid elite ogres; verify the exact mob name before pulling.',2),
(405,[4632,4638,4647,4692],'Desolace centaurs / wildlife','Skip friendly centaurs if reputation makes them unattackable.',2),
(15,[4351,4376],'Northern Dustwallow','Avoid dense swamp packs; keep an escape path.',2),
(8,[767,922],'Swamp of Sorrows wildlife','Wide beast loop; avoid the Horde settlement and water.',1),
(3,[2731,2735,92,2734,2736],'Badlands ridges','Elementals can resist nature damage; choose cats if kills drag.',3),
(33,[667],'Skullsplitter outskirts','Avoid casters and runners reaching another pack.',3),
(357,[5229,5249,5232,5331,5308],'Feralas outdoor camps','Pull edges; skip caves and mixed caster packs.',2),
(357,[5292,5296],'Feralas yeti cave mouths','Skinning candidates. Stay at the entrance; watch respawns.',4),
(440,[5616,5618],'Wastewander camps','Humanoids may run into adds; control fleeing targets.',2),
(440,[7855,7858],'Lost Rigger Cove','Dense pirate loop; skip ships and tightly packed buildings.',2),
(51,[5844,5846],'Searing Gorge surface camps','Remain on the surface; avoid the underground complex.',3),
(16,[6125,6375,6200],'Azshara satyrs / hippogryphs','Choose separated spawns; watch caster and stealth adds.',2),
(490,[6505,6509,6517],'Un\'Goro beasts / tar pits','Watch for roaming devilsaurs; tar mobs are mixed with others.',2),
(361,[7153,7156,7157],'Deadwood / Felpaw Village','Timbermaw reputation bonus; watch runners and caster adds.',2),
(28,[1783],'Southern Plaguelands undead','Avoid casters and mixed packs; disease may slow the loop.',3),
(46,[7033],'Firegut ogre camps','Pull normal ogres outside; skip mages and nearby elites.',2),
(618,[7442,7523,7430,7440,7524,7438,7445],'Winterspring snowfields / villages','Beasts or camp edges; avoid elite giants and named enemies.',1),
(139,[8596,8597,8598],'Plaguelands hound loop','Spread-out beasts; keep clear of higher-level undead packs.',2),
(1377,[11740,11880],'Northern Silithus / Twilight edges','Worms first; skip hive tunnels and mixed Twilight casters.',3),
]

catalog=[]
for area,npcs,place,note,risk in groups:
    map_id,zone,continent,faction=zones[area]
    for npc in npcs:
        row=rows[npc];points=spawns(npc)[area]
        assert row.get(6,0)==0
        points=[p[:2] for p in points if 0<float(p[0])<100 and 0<float(p[1])<100]
        # Select an actual recorded spawn with the most neighbours within 7 map
        # percentage points. Never pin an averaged coordinate in a lake/mountain.
        def density(p):
            near=[q for q in points if (q[0]-p[0])**2+(q[1]-p[1])**2<=49]
            return len(near),-sum((q[0]-p[0])**2+(q[1]-p[1])**2 for q in near)
        point=max(points,key=density)
        cluster=[q for q in points if (q[0]-point[0])**2+(q[1]-point[1])**2<=49]
        radius=max(.015,min(.08,max(math.hypot(q[0]-point[0],q[1]-point[1]) for q in cluster)/100+.008))
        catalog.append(dict(id=f'{npc}-{map_id}',npc=npc,mob=row[1],low=row[4],high=row[5],
            map=map_id,zone=zone,continent=continent,faction=faction,place=place,
            note=note,risk=risk,x=round(point[0]/100,4),y=round(point[1]/100,4),
            radius=round(radius,4),
            nearby=density(point)[0],source=('QuestieDB Forever 1.0.14' if area==16593 else 'QuestieDB Forever 1.0.14 / Classic baseline')))

def lua_value(value):
    if isinstance(value,str): return json.dumps(value,ensure_ascii=True)
    return str(value)
lines=['-- Selected NPC facts checked 2026-11-16; see SOURCES.md.','local _, A = ...','A.spots = {']
for entry in catalog:
    lines.append(' {'+','.join(f'{k}={lua_value(v)}' for k,v in entry.items())+'},')
lines.append('}')
(root/'Spots.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(root/'tools/spot-evidence.json').write_text(json.dumps(catalog,indent=2),encoding='utf-8')
print(f'Built {len(catalog)} non-elite mob/zone candidates from observed spawn points.')
