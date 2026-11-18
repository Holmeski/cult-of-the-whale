"""Load QuestieDB's merged Forever export (src/corrections/Forever/combined) into Python."""
import os, pickle, re
from lupa import lua51 as lupa


def _conv(v):
    if lupa.lua_type(v) == "table":
        keys = list(v.keys())
        d = {k: _conv(v[k]) for k in keys}
        n = len(d)
        if n and all(isinstance(k, int) for k in d) and min(d) == 1 and max(d) == n:
            return [d[i] for i in range(1, n + 1)]
        return d
    if isinstance(v, float) and v == int(v):
        return int(v)
    return v


def li(v, i):
    if v is None:
        return None
    if isinstance(v, list):
        return v[i - 1] if 0 < i <= len(v) else None
    if isinstance(v, dict):
        return v.get(i)
    return None


def as_list(v):
    if v is None:
        return []
    if isinstance(v, list):
        return v
    if isinstance(v, dict):
        return [v[k] for k in sorted(v, key=lambda k: (not isinstance(k, int), k))]
    return [v]


def load(questiedb):
    d = os.path.join(questiedb, "src", "corrections", "Forever", "combined")
    cache = os.path.join(d, ".zdungeon-cache.pkl")
    srcs = {k: os.path.join(d, "forever%sDB.lua" % n) for k, n in (("q", "Quest"), ("n", "Npc"), ("o", "Object"), ("i", "Item"))}
    newest = max(os.path.getmtime(p) for p in srcs.values())
    if os.path.exists(cache) and os.path.getmtime(cache) > newest:
        return pickle.load(open(cache, "rb"))
    db = {}
    for k, p in srcs.items():
        rt = lupa.LuaRuntime(unpack_returned_tuples=True)
        parse = rt.eval('function(s) return assert(loadstring("return " .. s))() end')
        out = {}
        for line in open(p, encoding="utf-8"):
            m = re.match(r"^\w+\[(\d+)\]=(\{.*\})\s*$", line)
            if m:
                out[int(m.group(1))] = _conv(parse(m.group(2)))
        db[k] = out
    pickle.dump(db, open(cache, "wb"))
    return db
