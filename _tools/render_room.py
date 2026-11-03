"""Render rm_level to a PNG (first frame of every sprite) to preview a layout without GameMaker.

    python3 _tools/render_room.py [out.png] [--debug]

--debug outlines obj_wall blockers (yellow) and marks obj_spawn points (red).
"""
import os, re, sys, json

TOOLS = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from png import read_png, write_png

out = next((a for a in sys.argv[1:] if not a.startswith("--")), os.path.join(TOOLS, "preview", "level.png"))
debug = "--debug" in sys.argv
load = lambda p: json.loads(re.sub(r",(\s*[}\]])", r"\1", open(p).read()))
room = load(os.path.join(PROJ, "rooms/rm_level/rm_level.yy"))
RW, RH = room["roomSettings"]["Width"], room["roomSettings"]["Height"]
canvas = [bytearray(RW * 4) for _ in range(RH)]

_spr = {}


def sprite(name):
    if name not in _spr:
        d = os.path.join(PROJ, "sprites", name)
        y = load(os.path.join(d, name + ".yy"))
        w, h, rows = read_png(os.path.join(d, y["frames"][0]["name"] + ".png"))
        _spr[name] = (w, h, rows, y["sequence"]["xorigin"], y["sequence"]["yorigin"], y["bbox_bottom"])
    return _spr[name]


def blit(rows, w, h, X, Y, flip=1):
    for y in range(h):
        cy = Y + y
        if not 0 <= cy < RH:
            continue
        src, dst = rows[y], canvas[cy]
        for x in range(w):
            sx = x if flip > 0 else w - 1 - x
            if src[sx * 4 + 3] < 128:
                continue
            cx = X + x
            if 0 <= cx < RW:
                dst[cx * 4:cx * 4 + 4] = src[sx * 4:sx * 4 + 4]


def unrle(a):
    out, i = [], 0
    while i < len(a):
        n = a[i]
        if n < 0:
            out += [a[i + 1]] * -n
            i += 2
        else:
            out += a[i + 1:i + 1 + n]
            i += 1 + n
    return out


bg = next(L for L in room["layers"] if L["resourceType"] == "GMRBackgroundLayer")
c = bg["colour"]
for row in canvas:
    row[:] = bytes((c & 255, (c >> 8) & 255, (c >> 16) & 255, 255)) * RW

for L in sorted(room["layers"], key=lambda L: -L["depth"]):
    kind = L["resourceType"]
    if kind == "GMRTileLayer":
        ts = load(os.path.join(PROJ, "tilesets", L["tilesetId"]["name"], L["tilesetId"]["name"] + ".yy"))
        sw, _, rows, _, _, _ = sprite(ts["spriteId"]["name"])
        cols, W = sw // 16, L["tiles"]["SerialiseWidth"]   # (out_columns is GameMaker's texture layout)
        for i, v in enumerate(unrle(L["tiles"]["TileCompressedData"])):
            if v <= 0:
                continue
            tx, ty = (v % cols) * 16, (v // cols) * 16
            blit([r[tx * 4:(tx + 16) * 4] for r in rows[ty:ty + 16]], 16, 16, (i % W) * 16, (i // W) * 16)
    elif kind == "GMRAssetLayer" and L["name"] != "Props":
        for g in L["assets"]:
            w, h, rows, xo, yo, _ = sprite(g["spriteId"]["name"])
            blit(rows, w, h, int(g["x"]) - xo, int(g["y"]) - yo, g["scaleX"])
    elif kind == "GMRInstanceLayer":
        # props + player sorted by their base, like depth = -bbox_bottom in game
        things = []
        for P in room["layers"]:
            if P["name"] == "Props":
                for g in P["assets"]:
                    w, h, rows, xo, yo, bb = sprite(g["spriteId"]["name"])
                    things.append((g["y"] - yo + bb, rows, w, h, int(g["x"]) - xo, int(g["y"]) - yo, g["scaleX"]))
        for i in L["instances"]:
            if i["objectId"]["name"] == "obj_player":
                w, h, rows, xo, yo, _ = sprite("spr_player_up")
                things.append((i["y"] + 11, rows, w, h, int(i["x"]) - xo, int(i["y"]) - yo, 1))
        for t in sorted(things, key=lambda t: t[0]):
            blit(*t[1:])

if debug:
    inst = next(L for L in room["layers"] if L["resourceType"] == "GMRInstanceLayer")["instances"]
    for i in inst:
        o, x, y = i["objectId"]["name"], int(i["x"]), int(i["y"])
        if o == "obj_wall":
            x2, y2 = x + int(64 * i["scaleX"]), y + int(64 * i["scaleY"])
            for yy in range(max(y, 0), min(y2, RH)):
                for xx in (x, x2 - 1):
                    if 0 <= xx < RW: canvas[yy][xx * 4:xx * 4 + 4] = b"\xff\xff\x00\xff"
            for xx in range(max(x, 0), min(x2, RW)):
                for yy in (y, y2 - 1):
                    if 0 <= yy < RH: canvas[yy][xx * 4:xx * 4 + 4] = b"\xff\xff\x00\xff"
        elif o == "obj_spawn":
            for yy in range(y - 5, y + 6):
                for xx in range(x - 5, x + 6):
                    if 0 <= xx < RW and 0 <= yy < RH: canvas[yy][xx * 4:xx * 4 + 4] = b"\xff\x20\x20\xff"

os.makedirs(os.path.dirname(out), exist_ok=True)
write_png(out, RW, RH, canvas)
print("wrote", out)
