#!/usr/bin/env python3
"""Audit every dungeon guide ZDungeon writes. Run from the repo root:

    python3 dev/audit_routes.py [report.json]

Builds each dungeon's guide for both factions at several levels in the
offline harness and reports:
  - harness crashes and guide lines ZQuest could not parse
  - a hand-in placed before its pickup
  - pickups / hand-ins with no location (no .goto in the step)
  - a follow-up quest picked up before the quest it needs is handed in
  - routes that come back to a map they already left (extra trips)
  - how many quests each guide covers (to spot data changes between runs)

The harness has no map library, so the planner sees every map change as the
same distance. "Return trips" here are therefore a rough upper bound: use
them to compare one run with the last, not as an absolute score.
"""
import json, os, re, subprocess, sys

LEVELS = (12, 16, 20, 24, 29, 33, 38, 42, 47, 52, 56, 60)
SIDES = (("Horde", "MAGE"), ("Alliance", "MAGE"))
LINE = re.compile(r'^(\.goto \d+,[\d.]+,[\d.]+(,\d+ >>.+)?|>>.+|\.(accept|turnin) -?\d+ >>.+|\.complete -?\d+,\d+|\.(target|mob) [^,>|]+)$')
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(here)

# prerequisites from ZDungeon's data: quest -> (all of these first, any one of these first)
PRE = {}
for m in re.finditer(r'^\[(\d+)\]=\{(.*)$', open(os.path.join(root, "ZDungeon", "Data.lua"), encoding="utf-8").read(), re.M):
    both = []
    for key in ("preAll", "preAny"):
        g = re.search(key + r'=\{([\d,]+)\}', m.group(2))
        both.append([int(x) for x in g.group(1).split(",") if x] if g else [])
    if both[0] or both[1]:
        PRE[int(m.group(1))] = both

report = {"problems": [], "guides": {}, "runs": 0}
def problem(kind, where, detail):
    report["problems"].append({"kind": kind, "where": where, "detail": detail})

for side, cls in SIDES:
    for lvl in LEVELS:
        env = dict(os.environ, ZD_SIDE=side, ZD_CLASS=cls)
        out = subprocess.run([sys.executable, os.path.join(here, "harness.py"), str(lvl), "zq", "gear"],
                             capture_output=True, text=True, cwd=root, env=env)
        report["runs"] += 1
        guides = re.findall(r'---- ZQuest Dungeons\|\|(.*?)\n(.*?)(?=\n---- |\nown card)', out.stdout, re.S)
        if not guides:
            problem("crash", "%s %d" % (side, lvl), (out.stderr or out.stdout)[-400:])
            continue
        for name, text in guides:
            where = "%s, %s" % (name, side)
            steps, cur = [], None
            for raw in text.split("\n"):
                l = raw.strip()
                if not l or l.startswith("#"):
                    continue
                if l == "step":
                    cur = {"map": None, "lines": []}
                    steps.append(cur)
                    continue
                if not LINE.match(l):
                    problem("bad line", where, l[:140])
                if cur is None:
                    continue
                cur["lines"].append(l)
                m = re.match(r'^\.goto (\d+),', l)
                if m and cur["map"] is None:
                    cur["map"] = int(m.group(1))
            acc, trn, quests = {}, {}, set()
            for i, st in enumerate(steps):
                for l in st["lines"]:
                    m = re.match(r'^\.(accept|turnin) (-?)(\d+) >>(.*)', l)
                    if not m:
                        continue
                    q = int(m.group(3))
                    quests.add(q)
                    (acc if m.group(1) == "accept" else trn).setdefault(q, i)
                    if st["map"] is None and not m.group(2) and not any(x.startswith(">>Loot") or x.startswith(">>Find") for x in st["lines"]):
                        problem("no location", where, m.group(4)[:80])
            for q, t in trn.items():
                if q in acc and acc[q] > t:
                    problem("hand-in before pickup", where, "quest %d" % q)
            # a follow-up quest picked up before the quest it needs is handed
            # in (when that earlier quest is in this guide too)
            follow = 0
            for q, a in acc.items():
                need_all, need_any = PRE.get(q, ([], []))
                late = [pq for pq in need_all if (pq in acc or pq in trn) and trn.get(pq, 10 ** 9) > a]
                in_guide = [pq for pq in need_any if pq in acc or pq in trn]
                if in_guide and not any(trn.get(pq, 10 ** 9) <= a for pq in in_guide):
                    late.append(in_guide[0])
                for pq in late:
                    follow += 1
                    problem("follow-up too early", where, "quest %d is picked up before %d is handed in" % (q, pq))
            # trips: runs of consecutive steps on the same map, before the dungeon
            pre = []
            for st in steps:
                if any("entrance" in l for l in st["lines"]):
                    break
                if st["map"] and (not pre or pre[-1] != st["map"]):
                    pre.append(st["map"])
            extra = len(pre) - len(set(pre))
            # guides are named per dungeon, so keep the worst case across levels
            row = {"steps": len(steps), "quests": len(quests), "trips": len(pre), "extraTrips": extra, "followUp": follow}
            old = report["guides"].get("%s|%s" % (name, side), {})
            report["guides"]["%s|%s" % (name, side)] = {k: max(v, old.get(k, 0)) for k, v in row.items()}
            report["built"] = report.get("built", 0) + 1
            if extra >= 3:
                problem("many return trips", where, "%d maps visited more than once before the run: %s" % (extra, pre))

kinds = {}
for p in report["problems"]:
    kinds[p["kind"]] = kinds.get(p["kind"], 0) + 1
print("harness runs: %d, guides built: %d, problems: %d %s" % (report["runs"], report.get("built", 0), len(report["problems"]), kinds))
for p in report["problems"][:60]:
    print("  [%s] %s: %s" % (p["kind"], p["where"], p["detail"]))
if len(sys.argv) > 1:
    json.dump(report, open(sys.argv[1], "w"), indent=1, sort_keys=True)
