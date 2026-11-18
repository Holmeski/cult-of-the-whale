#!/usr/bin/env python3
"""Generate ZDungeon's Data.lua from QuestieDB (Forever).

    python3 export_forever.py QUESTIEDB_PATH      (once per QuestieDB update)
    python3 build_zdungeon.py QUESTIEDB_PATH OUT_DATA_LUA [REPORT_TXT]

For every 5-man dungeon: each quest whose objectives are inside it, with
level, required level, base XP, who gives it and where, who takes it, what
it needs first (the whole chain), and class / faction limits.
"""
import os, re, sys

QDB, OUT = sys.argv[1], sys.argv[2]
REPORT = sys.argv[3] if len(sys.argv) > 3 else None
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qdb  # noqa: E402

li, as_list = qdb.li, qdb.as_list

A_RACES = 1 | 4 | 8 | 64 | (1 << 32)   # Human, Dwarf, Night Elf, Gnome, Skyborne (Alliance)
H_RACES = 2 | 16 | 32 | 128 | (1 << 33)  # Orc, Undead, Tauren, Troll, Skyborne (Horde)
CLASS_BITS = {"Warrior": 1, "Paladin": 2, "Hunter": 4, "Rogue": 8, "Priest": 16,
              "Shaman": 64, "Mage": 128, "Warlock": 256, "Druid": 1024}
ALL_CLASSES = sum(CLASS_BITS.values())


class Quest:
    def __init__(self, qid, row):
        self.id = qid
        self.name = li(row, 1)
        self.startedBy = li(row, 2)
        self.finishedBy = li(row, 3)
        self.reqLevel = li(row, 4) or 1
        self.level = li(row, 5) or self.reqLevel
        self.races = li(row, 6) or 0
        self.classes = li(row, 7) or 0
        self.objectives = li(row, 10)
        self.preGroup = as_list(li(row, 12))
        self.preSingle = as_list(li(row, 13))
        self.zone = li(row, 17)
        self.reqSkill = li(row, 18)
        self.reqRep = li(row, 19)
        self.specialFlags = li(row, 24) or 0

    def class_tag(self):
        if not self.classes or (self.classes & ALL_CLASSES) == ALL_CLASSES:
            return None
        return "/".join(n for n, b in CLASS_BITS.items() if self.classes & b)


# key, name, area ids (the dungeon's own id first), Forever level range, faction,
# instance map id, final boss(es), typical run in minutes (a starting guess; the addon
# replaces it with your own times), other names the game uses.
DUNGEONS = [
    ("RFC", "Ragefire Chasm", (2437,), (13, 18), "H", 389, ("Bazzalan", "Taragaman the Hungerer"), 30, ()),
    ("THANES", "The Hall of Thanes", (16919,), (13, 20), None, None, (), 30, ("Hall of Thanes",)),
    ("WC", "Wailing Caverns", (718,), (15, 24), None, 43, ("Mutanus the Devourer",), 60, ()),
    ("LORD", "Ruins of Lordaeron", (16611, 16612, 16614, 16615, 16617), (15, 22), None, None, (), 40, ()),
    ("DM", "The Deadmines", (1581, 10029), (17, 26), None, 36, ("Edwin VanCleef",), 50, ("Deadmines",)),
    ("SFK", "Shadowfang Keep", (209, 10014, 10015, 10016, 10017, 10018, 10019), (20, 30), None, 33, ("Archmage Arugal",), 45, ()),
    ("BFD", "Blackfathom Deeps", (719, 10020, 10021), (24, 32), None, 48, ("Aku'mai",), 55, ()),
    ("STOCK", "The Stockade", (717,), (24, 32), "A", 34, (), 30, ("Stormwind Stockade",)),
    ("EXCAV", "Excavation Site: Wetlands", (16732, 16877, 16878, 16879, 16880), (26, 33), None, None, (), 45, ("Excavation Site",)),
    ("DALA", "City of Dalaran", (16544, 16558, 16559, 16560, 16562), (28, 35), None, None, (), 45, ()),
    ("GNOMER", "Gnomeregan", (721, 133, 10030, 10031, 10032), (29, 38), None, 90, ("Mekgineer Thermaplugg",), 75, ()),
    ("RFK", "Razorfen Kraul", (491, 1717), (29, 38), None, 47, ("Charlga Razorflank",), 45, ()),
    ("SM", "Scarlet Monastery", (796, 6109, 6386, 10008, 10009, 10010), (30, 46), None, 189,
     ("Bloodmage Thalnos", "Arcanist Doan", "Herod", "High Inquisitor Whitemane", "Scarlet Commander Mograine"), 35, ()),
    ("RFD", "Razorfen Downs", (722,), (37, 46), None, 129, ("Amnennar the Coldbringer",), 45, ()),
    ("ULDA", "Uldaman", (1337, 1517, 10033), (41, 51), None, 70, ("Archaedas",), 75, ()),
    ("ZF", "Zul'Farrak", (1176, 978), (44, 54), None, 209, ("Chief Ukorz Sandscalp",), 60, ()),
    ("MARA", "Maraudon", (2100, 10000), (46, 55), None, 349, ("Princess Theradras",), 90, ()),
    ("ST", "Sunken Temple", (1477, 1417), (50, 60), None, 109, ("Shade of Eranikus",), 90, ("The Temple of Atal'Hakkar", "Temple of Atal'Hakkar")),
    ("BRD", "Blackrock Depths", (1584, 1585, 17803), (52, 60), None, 230, ("Emperor Dagran Thaurissan",), 150, ()),
    ("BRS", "Blackrock Spire", (1583, 10003, 10004, 10005, 10006, 10007, 17804), (55, 60), None, 229,
     ("Overlord Wyrmthalak", "General Drakkisath"), 90, ("Lower Blackrock Spire", "Upper Blackrock Spire")),
    ("DIRE", "Dire Maul", (2557, 10022, 10023, 10024, 10025, 10026, 10027), (54, 60), None, 429,
     ("Alzzin the Wildshaper", "Prince Tortheldrin", "King Gordok"), 60, ()),
    ("STRAT", "Stratholme", (2017, 10001), (58, 60), None, 329, ("Baron Rivendare", "Balnazzar"), 75, ()),
    ("SCHOLO", "Scholomance", (2057, 10011, 10012, 10013), (58, 60), None, 289, ("Darkmaster Gandling",), 75, ()),
    ("SHAPER", "Shaper's Terrace", (16985, 16986), (58, 60), None, None, (), 60, ("The Shaper's Terrace",)),
    # In the game but with no quests in QuestieDB yet (placeholder area ids): listed so
    # their gear and entrance show; quests appear once QuestieDB has them.
    ("DROWNED", "The Drowned City", (990001,), (35, 42), None, None, (), 60, ("Drowned City",)),
    ("KROLDOK", "Krol'dok Stronghold", (990002,), (40, 47), None, None, (), 60, ()),
    ("ALCAZ", "Alcaz Prison", (990003,), (48, 55), None, None, (), 60, ()),
    ("BLACKMAW", "Blackmaw Hold", (990004,), (55, 60), None, None, (), 60, ()),
]

DUNGEONS.sort(key=lambda d: d[3])
# Entrances QuestieDB's dungeon list does not have: (uiMapId, x, y)
EXTRA_ENTRANCES = {"SHAPER": (1449, 48.1, 6.1), "DROWNED": (1434, 21.4, 27.9), "KROLDOK": (2548, 37.5, 37.3),
                   "ALCAZ": (1445, 75.3, 14.1), "BLACKMAW": (1447, 38.6, 33.2)}



def load_xp():
    xp = {}
    d = os.path.join(QDB, "support", "Forever", "QuestXP")
    # classic first, then the values seen in Forever itself
    for f in ("xpDB-classic.lua", "xpDB-traces.lua"):
        p = os.path.join(d, f)
        if not os.path.exists(p):
            continue
        for qid, lvl, x in re.findall(r"\[(\d+)\]\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*\}", open(p, encoding="utf-8").read()):
            xp[int(qid)] = (int(lvl), int(x), "forever" if "traces" in f else "classic")
    return xp


def area_map():
    m = {}
    p = os.path.join(QDB, "support", "Forever", "Zones", "areaIdToUiMapId.lua")
    for a, u in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", open(p, encoding="utf-8").read()):
        m.setdefault(int(a), int(u))
    return m


db = qdb.load(QDB)
XP = load_xp()
AMAP = area_map()
ALL_DUNGEON_AREAS = {a for d in DUNGEONS for a in d[2]}
AREA_TO_DUNGEON = {a: d[1] for d in DUNGEONS for a in d[2]}


def entrances():
    out = {}
    p = os.path.join(QDB, "support", "Forever", "Zones", "dungeons.lua")
    for line in open(p, encoding="utf-8"):
        m = re.match(r"\s*\[(\d+)\]\s*=\s*\{\"", line)
        if not m:
            continue
        for area, x, y in re.findall(r"\{\s*(\d+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\}", line):
            if AMAP.get(int(area)):
                out[int(m.group(1))] = (AMAP[int(area)], round(float(x), 1), round(float(y), 1))
                break
    return out


ENTRANCES = entrances()


def spawns(entity, idx):
    sp = li(entity, idx)
    if isinstance(sp, list):
        sp = {i + 1: v for i, v in enumerate(sp)}
    return sp if isinstance(sp, dict) else {}


def side_of(races):
    races = races or 0
    a, h = races & A_RACES, races & H_RACES
    if races == 0 or (a and h):
        return "B"
    if a:
        return "A"
    if h:
        return "H"
    return "B"


def npc_side_ok(n, side):
    f = li(n, 13)
    if f is None or side == "B":
        return True
    return side in f or "AH" == f


def place(entity, idx):
    """(kind, a, b, c): ('map', uiMapId, x, y) or ('in', dungeon name) or None."""
    sp = spawns(entity, idx)
    best = None
    inside = None
    for area, pts in sp.items():
        if area in ALL_DUNGEON_AREAS:
            inside = AREA_TO_DUNGEON[area]
            continue
        good = [p for p in as_list(pts) if p and len(p) >= 2 and p[0] >= 0]
        if good and AMAP.get(area):
            if not best or len(good) > len(best[1]):
                best = (area, good)
    if best:
        return ("map", AMAP[best[0]], round(best[1][0][0], 1), round(best[1][0][1], 1))
    if inside:
        return ("in", inside)
    return None


def who(ref, side):
    """Describe a quest starter / finisher."""
    cands = []
    for nid in as_list(li(ref, 1)):
        n = db["n"].get(nid)
        if n:
            cands.append((0 if npc_side_ok(n, side) else 1, "npc", li(n, 1), place(n, 7)))
    for oid in as_list(li(ref, 2)):
        o = db["o"].get(oid)
        if o:
            cands.append((0, "obj", li(o, 1), place(o, 4)))
    for iid in as_list(li(ref, 3)):
        it = db["i"].get(iid)
        if it:
            src, pl = None, None
            for nid in as_list(li(it, 2)):
                n = db["n"].get(nid)
                if n:
                    src, pl = li(n, 1), place(n, 7)
                    break
            if not src:
                for oid in as_list(li(it, 3)):
                    o = db["o"].get(oid)
                    if o:
                        src, pl = li(o, 1), place(o, 4)
                        break
            cands.append((0, "item", li(it, 1), pl, src))
    # prefer one we can point at on the world map
    cands.sort(key=lambda c: (c[0], 0 if (c[3] and c[3][0] == "map") else 1 if c[3] else 2))
    return cands[0][1:] if cands else None


def only_in(entity, idx, areas):
    sp = spawns(entity, idx)
    return bool(sp) and all(k in areas for k in sp)


def in_dungeon(q, areas):
    obj = q.objectives or {}
    found = False
    for e in as_list(li(obj, 1)):
        n = db["n"].get(li(e, 1))
        if not (n and only_in(n, 7, areas)):
            return False
        found = True
    for e in as_list(li(obj, 2)):
        o = db["o"].get(li(e, 1))
        if not (o and only_in(o, 4, areas)):
            return False
        found = True
    for e in as_list(li(obj, 3)):
        it = db["i"].get(li(e, 1))
        if not it:
            return False
        nd = [db["n"].get(x) for x in as_list(li(it, 2))]
        od = [db["o"].get(x) for x in as_list(li(it, 3))]
        nd, od = [n for n in nd if n], [o for o in od if o]
        if not nd and not od:
            return False
        if not all(only_in(n, 7, areas) for n in nd) or not all(only_in(o, 4, areas) for o in od):
            return False
        found = True
    return found


QUESTS = {}  # id -> record (dungeon quests and everything in their chains)


def valid(q):
    return q.name and not q.name.startswith("[") and "<" not in q.name


def record(qid):
    if qid in QUESTS:
        return QUESTS[qid]
    row = db["q"].get(qid)
    if not row:
        return None
    q = Quest(qid, row)
    if not valid(q):
        return None
    side = side_of(q.races)
    x = XP.get(qid)
    text = li(row, 8)
    if isinstance(text, (list, dict)):
        text = " ".join(as_list(text))
    r = {
        "id": qid, "name": q.name, "level": q.level, "req": q.reqLevel, "side": side,
        "xp": x[1] if x else 0, "xpsrc": x[2] if x else None,
        "cls": q.class_tag(), "start": who(q.startedBy, side), "end": who(q.finishedBy, side),
        "preAll": [p for p in q.preGroup if isinstance(p, int)],
        "preAny": [p for p in q.preSingle if isinstance(p, int)],
        "skill": bool(q.reqSkill), "rep": bool(q.reqRep), "repeat": bool(q.specialFlags & 1),
        "share": bool((li(row, 23) or 0) & 8),
        "no": sum(len(as_list(li(q.objectives or {}, i))) for i in (1, 2, 3, 5)) if isinstance(q.objectives, (dict, list)) else 0,
        "text": text or "",
    }
    QUESTS[qid] = r
    keep = []
    for p in r["preAll"] + r["preAny"]:
        if record(p):
            keep.append(p)
    r["preAll"] = [p for p in r["preAll"] if p in keep]
    r["preAny"] = [p for p in r["preAny"] if p in keep]
    return r


DUNGEON_QUESTS = {}
for key, name, areas, (lo, hi), fac, inst, bosses, mins, aliases in DUNGEONS:
    aset = set(areas)
    ids = []
    for qid, row in db["q"].items():
        q = Quest(qid, row)
        if not valid(q):
            continue
        byzone = q.zone in aset
        byobj = (not byzone) and (lo - 6 <= q.level <= 60) and in_dungeon(q, aset)
        if not (byzone or byobj):
            continue
        if q.specialFlags & 1:
            continue  # repeatable hand-ins
        if record(qid):
            ids.append(qid)
    ids.sort(key=lambda i: (QUESTS[i]["level"], QUESTS[i]["name"], i))
    DUNGEON_QUESTS[key] = ids


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def lua_place(w):
    if not w:
        return "nil"
    kind, name, pl = w[0], w[1], w[2]
    parts = ["k=" + lua_str(kind), "n=" + lua_str(name)]
    if pl and pl[0] == "map":
        parts += ["m=%d" % pl[1], "x=%s" % pl[2], "y=%s" % pl[3]]
    elif pl and pl[0] == "in":
        parts.append("inside=" + lua_str(pl[1]))
    if kind == "item" and len(w) > 3 and w[3]:
        parts.append("from=" + lua_str(w[3]))
    return "{" + ",".join(parts) + "}"


out = ["-- ZDungeon quest data. Generated by tools/build_zdungeon.py from QuestieDB (Forever). Do not edit by hand.",
       "local _, ns = ...", "ns.quests = {"]
for qid in sorted(QUESTS):
    r = QUESTS[qid]
    f = ["name=" + lua_str(r["name"]), "level=%d" % r["level"], "req=%d" % r["req"], "xp=%d" % r["xp"],
         "side=" + lua_str(r["side"])]
    if r["xpsrc"] == "forever":
        f.append("seen=true")
    if r["cls"]:
        f.append("cls=" + lua_str(r["cls"]))
    if r["start"]:
        f.append("start=" + lua_place(r["start"]))
    if r["end"]:
        f.append("finish=" + lua_place(r["end"]))
    if r["preAll"]:
        f.append("preAll={%s}" % ",".join(map(str, r["preAll"])))
    if r["preAny"]:
        f.append("preAny={%s}" % ",".join(map(str, r["preAny"])))
    if r["no"]:
        f.append("no=%d" % r["no"])
    if r["share"]:
        f.append("share=true")
    for k in ("skill", "rep"):
        if r[k]:
            f.append(k + "=true")
    if r["text"]:
        f.append("text=" + lua_str(r["text"]))
    out.append("[%d]={%s}," % (qid, ",".join(f)))
out.append("}")
out.append("ns.dungeons = {")
for key, name, areas, (lo, hi), fac, inst, bosses, mins, aliases in DUNGEONS:
    f = ["key=" + lua_str(key), "name=" + lua_str(name), "lo=%d" % lo, "hi=%d" % hi, "run=%d" % mins]
    if fac:
        f.append("side=" + lua_str(fac))
    if inst:
        f.append("inst=%d" % inst)
    ent = EXTRA_ENTRANCES.get(key) or ENTRANCES.get(areas[0])
    if ent:
        f.append("entrance={m=%d,x=%s,y=%s}" % ent)
    if bosses:
        f.append("final={%s}" % ",".join(lua_str(x) for x in bosses))
    if aliases:
        f.append("aka={%s}" % ",".join(lua_str(x) for x in aliases))
    f.append("quests={%s}" % ",".join(map(str, DUNGEON_QUESTS[key])))
    out.append("{%s}," % ",".join(f))
out.append("}")
open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")

if REPORT:
    L = []
    for key, name, areas, (lo, hi), fac, inst, bosses, mins, aliases in DUNGEONS:
        L.append("== %s (%d-%d) ==" % (name, lo, hi))
        for qid in DUNGEON_QUESTS[key]:
            r = QUESTS[qid]
            s = r["start"]
            L.append("  %5d %-42s L%-2d req%-2d %s xp%-6d %-8s %-9s pre=%s/%s  start=%s" % (
                qid, r["name"][:42], r["level"], r["req"], r["side"], r["xp"], r["xpsrc"] or "NONE",
                (r["cls"] or "")[:9], r["preAll"], r["preAny"], s))
    L.append("total quests incl. chains: %d" % len(QUESTS))
    open(REPORT, "w").write("\n".join(L) + "\n")
print("wrote", OUT, len(QUESTS), "quests;", {k: len(v) for k, v in DUNGEON_QUESTS.items()})
print("no entrance:", [d[0] for d in DUNGEONS if not (EXTRA_ENTRANCES.get(d[0]) or ENTRANCES.get(d[2][0]))])
