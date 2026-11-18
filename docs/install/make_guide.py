#!/usr/bin/env python3
"""Draw the install guide panels (Raistlin, the fire-obsessed skeleton mage). Writes SVGs to OUT."""
import sys, os, textwrap

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
W, H = 960, 380
FONT = "Segoe UI, Helvetica Neue, Helvetica, Arial, sans-serif"
BG, PANEL, INK, MUTED = "#17121d", "#231a2c", "#f4ead9", "#b7a9c4"
FIRE1, FIRE2, FIRE3 = "#ffd34d", "#ff8a1f", "#e23d16"
ROBE, ROBE_D, BONE, BONE_D = "#6b3fa0", "#4a2a73", "#f1e9d8", "#cbbfa6"
GREEN = "#2ea043"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def flame(x, y, s=1.0, wob=0):
    """A little three-layer flame with its base at (x, y)."""
    def layer(sc, col, dx=0):
        w, h = 14 * s * sc, 34 * s * sc
        return ('<path d="M{x0},{y0} C{a},{b} {c},{d} {tx},{ty} C{e},{f} {g},{hh} {x0},{y0} Z" fill="{col}"/>'
                .format(x0=x + dx, y0=y, a=x + dx - w * 1.5, b=y - h * 0.35, c=x + dx - w * 0.2 + wob, d=y - h * 0.6,
                        tx=x + dx + wob * 1.5, ty=y - h, e=x + dx + w * 0.5, f=y - h * 0.6, g=x + dx + w * 1.5, hh=y - h * 0.3, col=col))
    return layer(1.0, FIRE3) + layer(0.72, FIRE2) + layer(0.42, FIRE1)


def raistlin(cx, base, mood="grin", arm="point", scale=1.0):
    """The guide. cx = centre x, base = y of the robe hem."""
    s = scale
    g = ['<g transform="translate(%s,%s) scale(%s)">' % (cx, base, s)]
    # staff (left hand side), with a flame on top
    g.append('<line x1="-78" y1="0" x2="-66" y2="-205" stroke="#7a5230" stroke-width="7" stroke-linecap="round"/>')
    g.append('<circle cx="-66" cy="-207" r="9" fill="#3b2a1a"/>')
    g.append(flame(-66, -212, 1.25, wob=3))
    # robe
    g.append('<path d="M-58,0 L-34,-128 Q0,-146 34,-128 L58,0 Z" fill="%s"/>' % ROBE)
    g.append('<path d="M-58,0 L-52,-30 L52,-30 L58,0 Z" fill="%s"/>' % ROBE_D)
    g.append('<path d="M-6,-136 L-10,0 L10,0 L6,-136 Z" fill="%s" opacity="0.55"/>' % ROBE_D)
    # scorch marks and a patch
    g.append('<circle cx="26" cy="-58" r="9" fill="#2a1a33"/><circle cx="-30" cy="-84" r="6" fill="#2a1a33"/>')
    g.append('<rect x="-40" y="-52" width="18" height="16" fill="#8e63c7" stroke="%s" stroke-width="1.5" stroke-dasharray="3 2"/>' % BONE)
    # belt with an ember buckle
    g.append('<rect x="-40" y="-104" width="80" height="9" fill="#3b2a1a"/><rect x="-7" y="-107" width="14" height="15" rx="2" fill="%s"/>' % FIRE2)
    # left arm holds the staff
    g.append('<path d="M-30,-122 L-58,-96 L-70,-112" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>' % BONE)
    g.append('<circle cx="-58" cy="-96" r="5" fill="%s"/>' % BONE_D)
    # right arm
    if arm == "point":
        g.append('<path d="M30,-122 L62,-112 L96,-136" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>' % BONE)
        g.append('<circle cx="62" cy="-112" r="5" fill="%s"/>' % BONE_D)
        g.append('<path d="M96,-136 L112,-146 M96,-136 L104,-128 M96,-136 L100,-124" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % BONE)
    elif arm == "up":
        g.append('<path d="M30,-122 L60,-140 L72,-178" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>' % BONE)
        g.append('<circle cx="60" cy="-140" r="5" fill="%s"/>' % BONE_D)
        g.append('<path d="M72,-178 L66,-194 M72,-178 L74,-196 M72,-178 L82,-192" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % BONE)
        g.append(flame(74, -196, 0.8, wob=-2))
    else:  # thumbs up
        g.append('<path d="M30,-122 L64,-104 L86,-122" fill="none" stroke="%s" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>' % BONE)
        g.append('<circle cx="64" cy="-104" r="5" fill="%s"/>' % BONE_D)
        g.append('<rect x="82" y="-132" width="16" height="14" rx="4" fill="%s"/><path d="M90,-132 L90,-148" stroke="%s" stroke-width="6" stroke-linecap="round"/>' % (BONE, BONE))
    # neck and skull
    g.append('<rect x="-5" y="-146" width="10" height="16" fill="%s"/>' % BONE_D)
    g.append('<path d="M-36,-196 Q-36,-236 0,-236 Q36,-236 36,-196 Q36,-172 22,-164 L22,-150 L-22,-150 L-22,-164 Q-36,-172 -36,-196 Z" fill="%s"/>' % BONE)
    # eye sockets with flame pupils (one bigger: goofy)
    g.append('<ellipse cx="-15" cy="-196" rx="12" ry="13" fill="#1b1220"/><ellipse cx="16" cy="-198" rx="9" ry="10" fill="#1b1220"/>')
    g.append('<circle cx="-13" cy="-194" r="5.5" fill="%s"/><circle cx="-12" cy="-195" r="2.4" fill="%s"/>' % (FIRE2, FIRE1))
    g.append('<circle cx="15" cy="-199" r="4" fill="%s"/><circle cx="15.5" cy="-200" r="1.8" fill="%s"/>' % (FIRE2, FIRE1))
    g.append('<path d="M0,-184 L-5,-174 L5,-174 Z" fill="#1b1220"/>')
    # mouth
    if mood == "oh":
        g.append('<ellipse cx="0" cy="-160" rx="9" ry="8" fill="#1b1220"/>')
    else:
        g.append('<path d="M-18,-166 Q0,-152 18,-166" fill="none" stroke="#1b1220" stroke-width="3" stroke-linecap="round"/>')
        for tx in (-10, -3, 4, 11):
            g.append('<line x1="%d" y1="-163" x2="%d" y2="-156" stroke="#1b1220" stroke-width="2"/>' % (tx, tx))
    # hat: floppy, singed, on fire at the tip
    g.append('<path d="M-52,-226 Q0,-246 52,-226 Q0,-216 -52,-226 Z" fill="%s"/>' % ROBE_D)
    g.append('<path d="M-34,-230 Q-10,-300 30,-318 Q14,-280 34,-230 Q0,-240 -34,-230 Z" fill="%s"/>' % ROBE)
    g.append('<path d="M-30,-238 Q0,-248 32,-238" fill="none" stroke="%s" stroke-width="5"/>' % FIRE2)
    g.append('<path d="M14,-304 L30,-318 L26,-298 Z" fill="#2a1a33"/>')
    g.append(flame(29, -316, 0.9, wob=4))
    g.append('</g>')
    return "".join(g)


def bubble(x, y, w, lines, size=19):
    """Speech bubble with its tail pointing down-left toward Raistlin."""
    lh = size * 1.35
    h = len(lines) * lh + 30
    out = ['<path d="M{x},{y1} L{tx},{ty} L{x2},{y1} Z" fill="{c}"/>'.format(x=x + 34, y1=y + h - 2, tx=x + 6, ty=y + h + 30, x2=x + 70, c=INK)]
    out.append('<rect x="%s" y="%s" width="%s" height="%s" rx="18" fill="%s"/>' % (x, y, w, h, INK))
    for i, line in enumerate(lines):
        out.append('<text x="%s" y="%s" font-family="%s" font-size="%s" fill="#1b1220" font-weight="600">%s</text>'
                   % (x + 20, y + 30 + i * lh, FONT, size, esc(line)))
    return "".join(out), h


def wrap(text, n):
    return textwrap.wrap(text, n)


def folder(x, y, label, color="#e7b84b", w=118, sub=None):
    s = ('<path d="M{x},{y} h{t} l12,12 h{r} v{h} h-{w} Z" fill="{c}"/>'
         '<rect x="{x}" y="{y2}" width="{w}" height="{h2}" rx="6" fill="{c}" stroke="#00000033"/>').format(
        x=x, y=y, t=w * 0.36, r=w * 0.64 - 12, h=70, w=w, c=color, y2=y + 14, h2=62)
    s += '<text x="%s" y="%s" text-anchor="middle" font-family="%s" font-size="16" font-weight="700" fill="#2a1a10">%s</text>' % (x + w / 2, y + 51, FONT, esc(label))
    if sub:
        s += '<text x="%s" y="%s" text-anchor="middle" font-family="%s" font-size="13" fill="%s">%s</text>' % (x + w / 2, y + 98, FONT, MUTED, esc(sub))
    return s


def arrow(x1, y1, x2, y2, color=FIRE2):
    """A horizontal arrow from x1 to x2, head at x2."""
    d = 1 if x2 > x1 else -1
    return ('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="6" stroke-linecap="round"/>'
            '<path d="M%s,%s l%s,-11 v22 Z" fill="%s"/>' % (x1, y1, x2 - 14 * d, y2, color, x2, y2, -18 * d, color))


def text(x, y, s, size=18, fill=INK, weight="400", anchor="start", mono=False):
    fam = "Consolas, Menlo, monospace" if mono else FONT
    return '<text x="%s" y="%s" font-family="%s" font-size="%s" fill="%s" font-weight="%s" text-anchor="%s">%s</text>' % (x, y, fam, size, fill, weight, anchor, esc(s))


def panel(name, number, title, says, art, mood="grin", arm="point", alt=""):
    body = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" role="img" aria-label="%s">' % (W, H, W, H, esc(alt or title))]
    body.append('<rect width="%d" height="%d" rx="22" fill="%s"/>' % (W, H, BG))
    body.append('<rect x="318" y="76" width="620" height="282" rx="16" fill="%s"/>' % PANEL)
    # embers
    for ex, ey, er in ((40, 60, 3), (250, 110, 2), (285, 40, 2.5), (20, 200, 2), (300, 250, 2)):
        body.append('<circle cx="%s" cy="%s" r="%s" fill="%s" opacity="0.7"/>' % (ex, ey, er, FIRE2))
    # title
    if number is not None:
        body.append('<circle cx="350" cy="42" r="24" fill="%s"/>' % FIRE2)
        body.append(text(350, 51, str(number), 28, "#1b1220", "800", "middle"))
        body.append(text(388, 52, title, 30, INK, "800"))
    else:
        body.append(text(330, 52, title, 30, INK, "800"))
    body.append(art)
    b, bh = bubble(18, 14, 286, says, 17)
    body.append(b)
    # keep the hat (and its flame) clear of the bubble
    room = (H - 6) - (14 + bh + 10)
    body.append(raistlin(176, H - 6, mood, arm, min(0.8, room / 338.0)))
    body.append('</svg>')
    open(os.path.join(OUT, name), "w", encoding="utf-8").write("\n".join(body))


# ---- 0: hello ----------------------------------------------------------------
art = (text(350, 130, "Two addons. Six steps.", 34, INK, "800")
       + text(350, 172, "No fire required. (He will offer anyway.)", 20, MUTED)
       + folder(360, 215, "ZQuest", sub="leveling guide") + folder(520, 215, "ZDungeon", sub="dungeon planner"))
panel("0-hello.svg", None, "Raistlin's install guide",
      wrap("Hi! I'm Raistlin. I'm dead, I'm a mage, and I have never started a fire on purpose.", 30), art, "grin", "up",
      "Raistlin, a skeleton mage with a burning hat, introduces the two addons")

# ---- 1: download -------------------------------------------------------------
art = ('<rect x="372" y="112" width="150" height="46" rx="8" fill="%s"/>' % GREEN
       + text(447, 142, "<> Code  ▾", 20, "#ffffff", "700", "middle")
       + '<rect x="372" y="170" width="300" height="150" rx="10" fill="#2d2438" stroke="#4b3d5c"/>'
       + text(392, 204, "Clone", 17, MUTED) + text(392, 240, "Open with GitHub Desktop", 17, MUTED)
       + '<rect x="382" y="262" width="280" height="44" rx="8" fill="%s"/>' % FIRE2
       + text(398, 291, "Download ZIP", 20, "#1b1220", "800")
       + arrow(790, 284, 682, 284)
       + text(736, 250, "this one", 18, FIRE1, "700", "middle")
       + text(560, 141, "on the GitHub page", 16, MUTED))
panel("1-download.svg", 1, "Get the zip",
      wrap("Click the green Code button, then Download ZIP. Green. Not orange. I checked twice.", 30), art, "grin", "point",
      "Step 1: on the GitHub page click the green Code button, then Download ZIP")

# ---- 2: unzip ----------------------------------------------------------------
zipicon = ('<rect x="372" y="150" width="120" height="130" rx="10" fill="#8d7aa6"/>'
           '<rect x="424" y="150" width="16" height="130" fill="#17121d" opacity="0.5"/>'
           + "".join('<rect x="426" y="%d" width="12" height="7" fill="%s"/>' % (158 + i * 16, FIRE1) for i in range(7))
           + text(432, 304, "the .zip", 16, MUTED, "400", "middle"))
menu = ('<rect x="520" y="150" width="190" height="96" rx="8" fill="#2d2438" stroke="#4b3d5c"/>'
        + text(536, 180, "Open", 16, MUTED)
        + '<rect x="526" y="194" width="178" height="38" rx="6" fill="%s"/>' % FIRE2
        + text(538, 219, "Extract All...", 18, "#1b1220", "800")
        + text(615, 270, "right-click the zip", 16, MUTED, "400", "middle"))
art = zipicon + menu + arrow(730, 214, 782, 214) + folder(798, 172, "unzipped!", w=124)
panel("2-unzip.svg", 2, "Open the zip",
      wrap("Right-click it and pick Extract All. Do NOT burn it open. I tried. You get ash.", 30), art, "oh", "point",
      "Step 2: right-click the downloaded zip and choose Extract All")

# ---- 3: find AddOns ----------------------------------------------------------
crumbs = ["World of Warcraft", "_forever_", "Interface", "AddOns"]
art = text(350, 118, "Open File Explorer and go here:", 19, MUTED)
y = 132
for i, c in enumerate(crumbs):
    last = i == len(crumbs) - 1
    x = 356 + i * 34
    art += '<rect x="%d" y="%d" width="%d" height="42" rx="8" fill="%s"/>' % (x, y, 330, FIRE2 if last else "#2d2438")
    art += text(x + 44, y + 28, c, 20, "#1b1220" if last else INK, "800" if last else "600")
    art += '<path d="M%d,%d h10 l5,5 h13 v15 h-28 Z" fill="%s"/>' % (x + 10, y + 11, "#1b1220" if last else "#e7b84b")
    y += 50
art += text(356, 346, "World of Warcraft is usually inside", 15, MUTED) + text(600, 346, "C:\\Program Files (x86)", 15, INK, "600", mono=True)
art += arrow(880, 309, 800, 309) + text(868, 290, "here!", 18, FIRE1, "800", "middle")
panel("3-find.svg", 3, "Find your AddOns folder",
      wrap("It's a folder inside a folder inside a folder. Like a filing cabinet. I love filing cabinets. So flammable.", 31), art, "grin", "up",
      "Step 3: open World of Warcraft, then _forever_, then Interface, then AddOns")

# ---- 4: copy -----------------------------------------------------------------
def small(x, y, label):
    return '<g transform="translate(%d,%d) scale(0.8)">%s</g>' % (x, y, folder(0, 0, label, w=132))


art = (small(346, 136, "ZQuest") + small(346, 232, "ZDungeon")
       + arrow(466, 222, 540, 222)
       + '<rect x="556" y="150" width="150" height="150" rx="14" fill="#2d2438" stroke="%s" stroke-width="3"/>' % FIRE2
       + folder(572, 176, "AddOns", "#f0c869", 118)
       + text(631, 290, "drag them in", 16, FIRE1, "700", "middle")
       + '<rect x="728" y="104" width="196" height="112" rx="12" fill="#1f3326"/>'
       + text(744, 132, "✓  Right", 19, "#6ee787", "800")
       + text(744, 160, "AddOns", 16, INK, "600", mono=True) + text(760, 182, "└ ZDungeon", 16, INK, mono=True) + text(776, 204, "└ ZDungeon.toc", 14, MUTED, mono=True)
       + '<rect x="728" y="228" width="196" height="122" rx="12" fill="#3a1d1d"/>'
       + text(744, 256, "✗  Wrong", 19, "#ff8f80", "800")
       + text(744, 284, "AddOns", 16, INK, "600", mono=True) + text(760, 306, "└ cult-of-the-whale", 14, INK, mono=True) + text(776, 328, "└ ZDungeon", 15, MUTED, mono=True))
panel("4-copy.svg", 4, "Drag the two folders in",
      wrap("Just these two. Not the big folder they came in. The game can't see a folder in a folder. I can't either. No eyes.", 31), art, "oh", "point",
      "Step 4: drag ZQuest and ZDungeon straight into AddOns, not the outer folder they came in")

# ---- 5: enable ---------------------------------------------------------------
art = ('<rect x="356" y="104" width="330" height="236" rx="12" fill="#2d2438" stroke="#4b3d5c"/>'
       + text(376, 136, "AddOns", 20, INK, "800"))
for i, n in enumerate(("ZQuest", "ZDungeon")):
    yy = 172 + i * 64
    art += '<rect x="376" y="%d" width="30" height="30" rx="6" fill="%s"/>' % (yy, FIRE2)
    art += '<path d="M%d,%d l7,8 l12,-15" fill="none" stroke="#1b1220" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>' % (382, yy + 15)
    art += text(420, yy + 22, n, 20, INK, "600")
art += (text(712, 150, "1. Close the game", 18, INK, "600") + text(712, 180, "   and start it again.", 18, INK, "600")
        + text(712, 226, "2. On the character", 18, INK, "600") + text(712, 256, "   screen, click AddOns.", 18, INK, "600")
        + text(712, 302, "3. Tick both.", 18, FIRE1, "800"))
panel("5-enable.svg", 5, "Switch them on",
      wrap("Restart the game, click AddOns on the character screen, and tick the boxes. Ticking is like lighting a tiny candle. Allegedly.", 31), art, "grin", "up",
      "Step 5: restart the game, click AddOns on the character screen and tick ZQuest and ZDungeon")

# ---- 6: done -----------------------------------------------------------------
art = text(350, 118, "Type one of these in chat and press Enter:", 19, MUTED)
for i, (cmd, what) in enumerate((("/zq", "ZQuest: your leveling guide"), ("/zd", "ZDungeon: dungeon quests, gear, travel"))):
    yy = 156 + i * 76
    art += '<rect x="356" y="%d" width="110" height="46" rx="8" fill="#0f0b14" stroke="%s" stroke-width="2"/>' % (yy, FIRE2)
    art += text(411, yy + 31, cmd, 24, FIRE1, "800", "middle", mono=True)
    art += text(486, yy + 31, what, 20, INK, "600")
art += text(350, 344, "Nothing shows up? Go back to step 4. It is always step 4.", 17, MUTED)
panel("6-done.svg", 6, "You're done!",
      wrap("That's it! Now if you'll excuse me, something is on fire. It's me. It's fine.", 30), art, "grin", "thumb",
      "Step 6: type /zq or /zd in chat to open each addon")
print("ok")
