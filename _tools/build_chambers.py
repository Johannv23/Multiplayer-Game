"""Build Hades-style chamber rooms from ASCII blockouts in _tools/chambers/chamber_N.txt.

    python3 _tools/build_chambers.py        (save + close GameMaker first, Reload after)

Each map cell is 32x32 px:
    #  void (invisible wall; the island's edge and any holes)
    .  floor
    B  cover block (solid, drawn as a gray box)
    L  landmark (solid, tall blue box: statues, shrines...)
    S  enemy spawn point (floor)
    E  entrance: player starts at the centre of the E cells
    X  exit door: solid until every wave in the room is cleared
Lines starting with "# " (hash + space) are comments.
Writes rooms/rm_chamber_N, the blockout objects if missing, and the room order (chambers first).

Art pass (Undead pack): the map becomes ts_ground tile layers (floor, cliff faces under the island
edges, spiky back edges, cobble daises), B/L cells get props on the "Props" layer (obj_game turns them
into solid, depth-sorted obj_prop), small plants/bones go on the flat "Decor" layer, and dark trees
frame the bottom and sides in the void. The invisible obj_wall / obj_block collision is unchanged.
Previews: _tools/preview/chamber_N_art.png
"""
import os, re, json, uuid, glob

TOOLS = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(TOOLS)
CELL = 32
CLIFF_H = 20
VIEW = (640, 360)          # camera size; scaled 2x into the 1280x720 viewport
VOID_COLOUR = 0xFF140F0C   # ABGR: rgb(12, 15, 20)


def load_yy(p):
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", open(p).read()))


def dump_yy(o, p):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(json.dumps(o, indent=2))


def uid():
    return uuid.uuid4().hex[:8].upper()


def rects(cells):
    """Greedy merge of a set of (col,row) cells into rectangles (c, r, w, h)."""
    cells, out = set(cells), []
    todo = sorted(cells, key=lambda c: (c[1], c[0]))
    used = set()
    for c, r in todo:
        if (c, r) in used:
            continue
        w = 1
        while (c + w, r) in cells and (c + w, r) not in used:
            w += 1
        h = 1
        while all((c + i, r + h) in cells and (c + i, r + h) not in used for i in range(w)):
            h += 1
        for i in range(w):
            for j in range(h):
                used.add((c + i, r + j))
        out.append((c, r, w, h))
    return out


def inst(obj, x, y, sx=1.0, sy=1.0):
    n = "inst_" + uid()
    return {"$GMRInstance": "v4", "%Name": n, "colour": 4294967295, "frozen": False, "hasCreationCode": False,
            "ignore": False, "imageIndex": 0, "imageSpeed": 1.0, "inheritCode": False, "inheritedItemId": None,
            "inheritItemSettings": False, "isDnd": False, "name": n,   # room instances: isDnd (lowercase d)
            "objectId": {"name": obj, "path": f"objects/{obj}/{obj}.yy"}, "properties": [],
            "resourceType": "GMRInstance", "resourceVersion": "2.0", "rotation": 0.0,
            "scaleX": float(sx), "scaleY": float(sy), "x": float(x), "y": float(y)}


def rect_inst(obj, c, r, w, h, y_off=0, px_h=None):
    """spr_wall is 64x64 with a Top Left origin, so scale it to cover the cells."""
    hh = px_h if px_h is not None else h * CELL
    return inst(obj, c * CELL, r * CELL + y_off, w * CELL / 64, hh / 64)



import random
from PIL import Image

# ------------------------------------------------------------------ art: ts_ground tile ids
TSC = 26                                        # ts_ground columns
T = lambda c, r: r * TSC + c
EMPTY = -2147483648
GROUND = T(2, 2)                                # plain gray ground
COBBLE = [T(3, 20), T(5, 20), T(7, 20), T(9, 20)]
# same shapes exist twice: gray ground (rows 0-19) and cobble (rows +21)
def V(c, r, cob): return T(c, r + (21 if cob else 0))
DARK_BLOB = [(c, r) for r in range(56, 59) for c in range(12, 15)]   # 3x3 darker-ground stamp

SPR = {}
for p in glob.glob(os.path.join(PROJ, "sprites", "spr_*", "spr_*.yy")):
    s = load_yy(p)
    SPR[s["name"]] = s
def ok(n): return n in SPR

# cover themes: one prop per 2x2 chunk of B cells, one per leftover cell
PROP64 = {"ruins": ["spr_ruin_1", "spr_ruin_2"], "rocks": ["spr_broken_tree_1", "spr_pile_skulls"],
          "graves": ["spr_ruin_1", "spr_ruin_2"], "crystals": ["spr_crystal_1", "spr_crystal_2"],
          "trees": ["spr_tree_1", "spr_dead_tree_1", "spr_dead_tree_2"]}
PROP32 = {"ruins": ["spr_ruin_3", "spr_ruin_4"], "rocks": ["spr_rock_1", "spr_rock_2", "spr_rock_3"],
          "graves": [f"spr_grave_{i}" for i in (1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17)],
          "crystals": ["spr_crystal_1", "spr_crystal_2"], "trees": ["spr_tree_2", "spr_dead_tree_3", "spr_dead_arm_1"]}
LANDMARK = ["spr_shrine", "spr_throne", "spr_pile_skulls", "spr_dead_tree_big", "spr_totem"]
DECOR_SMALL = (["spr_plant_3", "spr_plant_4", "spr_plant_5", "spr_thorn_plant_3", "spr_thorn_plant_6",
                "spr_rock_5", "spr_crystal_4", "spr_broken_tree_7"] +
               [f"spr_bones_{i}" for i in (1, 2, 3, 4, 5, 15, 16, 17, 18)])
DECOR_BIG = [f"spr_bones_{i}" for i in (6, 7, 8, 11, 12, 13, 14)] + ["spr_plant_2", "spr_thorn_plant_5"]
FOREGROUND = ["spr_dead_tree_1", "spr_dead_tree_2", "spr_tree_1", "spr_dead_tree_big", "spr_thorn_plant_1"]
FG_COLOUR = 0xFF383838                          # ABGR: foreground silhouettes drawn dark


def layer_common(kind, name, depth):
    return {f"$GMR{kind}Layer": "", "%Name": name, "depth": depth, "effectEnabled": True, "effectType": None,
            "gridX": 16, "gridY": 16, "hierarchyFrozen": False, "inheritLayerDepth": False,
            "inheritLayerSettings": False, "inheritSubLayers": True, "inheritVisibility": True, "layers": [],
            "name": name, "properties": [], "resourceType": f"GMR{kind}Layer", "resourceVersion": "2.0",
            "userdefinedDepth": False, "visible": True}


def rle(cells):
    out, i = [], 0
    while i < len(cells):
        j = i
        while j < len(cells) and cells[j] == cells[i]:
            j += 1
        if j - i >= 2:
            out += [-(j - i), cells[i]]
            i = j
        else:
            lit = []
            while i < len(cells) and (i + 1 >= len(cells) or cells[i + 1] != cells[i]):
                lit.append(cells[i])
                i += 1
            out += [len(lit)] + lit
    return out


def tile_layer(name, depth, grid):
    L = layer_common("Tile", name, depth)
    L["tiles"] = {"SerialiseHeight": len(grid), "SerialiseWidth": len(grid[0]),
                  "TileCompressedData": rle([c for row in grid for c in row]), "TileDataFormat": 1}
    L["tilesetId"] = {"name": "ts_ground", "path": "tilesets/ts_ground/ts_ground.yy"}
    L["x"] = L["y"] = 0
    return L


def asset_layer(name, depth, items):
    L = layer_common("Asset", name, depth)
    L["assets"] = []
    for spr, x, y, sx, col in sorted(items, key=lambda it: it[2]):
        g = "graphic_" + uid()
        L["assets"].append({"$GMRSpriteGraphic": "v1", "%Name": g, "animationSpeed": 1.0, "colour": col,
                            "frozen": False, "headPosition": 0.0, "ignore": False, "inheritedItemId": None,
                            "inheritItemSettings": False, "name": g, "resourceType": "GMRSpriteGraphic",
                            "resourceVersion": "2.0", "rotation": 0.0, "scaleX": float(sx), "scaleY": 1.0,
                            "spriteId": {"name": spr, "path": f"sprites/{spr}/{spr}.yy"},
                            "x": float(x), "y": float(y)})
    return L


_frames = {}
def frame0(name):
    if name not in _frames:
        s = SPR[name]
        _frames[name] = Image.open(os.path.join(PROJ, "sprites", name, s["frames"][0]["name"] + ".png")).convert("RGBA")
    return _frames[name]


def preview(path, W, H, tile_layers, decor, props, player, doors):
    ts = Image.open(os.path.join(PROJ, "sprites", "spr_ts_ground",
                                 SPR["spr_ts_ground"]["frames"][0]["name"] + ".png")).convert("RGBA")
    im = Image.new("RGBA", (W, H), (12, 15, 20, 255))
    for grid in tile_layers:                                  # back to front
        for r, row in enumerate(grid):
            for c, t in enumerate(row):
                if t != EMPTY:
                    tc, tr = t % TSC, t // TSC
                    im.alpha_composite(ts.crop((tc * 16, tr * 16, tc * 16 + 16, tr * 16 + 16)), (c * 16, r * 16))
    def put(spr, x, y, sx, col):
        f = frame0(spr)
        if sx < 0:
            f = f.transpose(Image.FLIP_LEFT_RIGHT)
        if col != 4294967295:
            k = (col & 0xFF) / 255
            px = f.split(); f = Image.merge("RGBA", [b.point(lambda v: int(v * k)) for b in px[:3]] + [px[3]])
        s = SPR[spr]
        xo = s["sequence"]["xorigin"] if sx > 0 else s["width"] - s["sequence"]["xorigin"]
        ox, oy = int(x - xo), int(y - s["sequence"]["yorigin"])
        if ox < W and oy < H and ox + f.width > 0 and oy + f.height > 0:
            im.alpha_composite(f, (max(0, ox), max(0, oy)), (max(0, -ox), max(0, -oy)))
    for d in decor:
        put(*d)
    from PIL import ImageDraw
    dr = ImageDraw.Draw(im)
    for x1, y1, x2, y2 in doors:
        dr.rectangle([x1, y1 - 28, x2, y2], fill=(70, 62, 56)); dr.rectangle([x1 + 8, y1 - 20, x2 - 8, y2], fill=(70, 16, 16))
    things = [(p[2], p) for p in props] + [(player[1], None)]
    for _, p in sorted(things, key=lambda t: t[0]):
        if p is None:
            dr.ellipse([player[0] - 6, player[1] - 14, player[0] + 6, player[1] + 10], fill=(220, 60, 50))
        else:
            put(*p)
    im.convert("RGB").save(path)


# ------------------------------------------------------------------ objects
yyp_path = os.path.join(PROJ, "multiplayergame.yyp")
yyp = load_yy(yyp_path)
res = {r["id"]["name"] for r in yyp["resources"]}
EV = {"create": (0, 0), "step": (0, 3), "draw": (0, 8), "gui": (64, 8)}
OBJECTS = {   # name: (parent, visible, events)  -- the .gml files are written by hand
    "obj_floor": (None, True, ["create", "draw"]),
    "obj_cliff": (None, True, ["create", "draw"]),
    "obj_block": ("obj_wall", True, ["create", "draw"]),
    "obj_landmark": ("obj_block", True, ["create"]),
    "obj_door": ("obj_wall", True, ["create", "step", "draw"]),
}
for name, (parent, visible, events) in OBJECTS.items():
    if name in res:
        continue
    o = load_yy(os.path.join(PROJ, "objects", "obj_game", "obj_game.yy"))
    o["%Name"] = o["name"] = name
    o["spriteId"] = {"name": "spr_wall", "path": "sprites/spr_wall/spr_wall.yy"}
    o["parentObjectId"] = {"name": parent, "path": f"objects/{parent}/{parent}.yy"} if parent else None
    o["visible"] = visible
    o["eventList"] = [{"$GMEvent": "v1", "%Name": "", "collisionObjectId": None, "eventNum": EV[e][0],
                       "eventType": EV[e][1], "isDnD": False, "name": "", "resourceType": "GMEvent",
                       "resourceVersion": "2.0"} for e in events]
    dump_yy(o, os.path.join(PROJ, "objects", name, name + ".yy"))
    yyp["resources"].append({"id": {"name": name, "path": f"objects/{name}/{name}.yy"}})

# ------------------------------------------------------------------ rooms
template = load_yy(os.path.join(PROJ, "rooms", "rm_level", "rm_level.yy"))
chamber_rooms = []
maps = [(p, int(re.search(r"(\d+)", os.path.basename(p)).group(1))) for p in
        glob.glob(os.path.join(TOOLS, "chambers", "chamber_*.txt"))]
maps = [(p, n, f"rm_chamber_{n}") for p, n in sorted(maps, key=lambda m: m[1])]
if os.path.exists(os.path.join(TOOLS, "chambers", "boss.txt")):       # the boss arena comes after the chambers
    maps.append((os.path.join(TOOLS, "chambers", "boss.txt"), 99, "rm_boss"))
for sp in sorted(glob.glob(os.path.join(TOOLS, "chambers", "shrine_*.txt"))):   # Reliquary shrines (side rooms)
    sn = int(re.search(r"(\d+)", os.path.basename(sp)).group(1))
    maps.append((sp, 100 + sn, f"rm_shrine_{sn}"))
for path, n, rname in maps:
    lines = [l.rstrip("\n") for l in open(path) if not l.startswith("# ")]
    lines = [l for l in lines if l.strip()]
    W = max(len(l) for l in lines)
    g = [l.ljust(W, "#") for l in lines] + ["#" * W] * 2   # 2 extra void rows so the bottom cliffs show
    H = len(g)
    at = lambda c, r: g[r][c] if 0 <= r < H and 0 <= c < W else "#"
    cells = lambda ch: [(c, r) for r in range(H) for c in range(W) if g[r][c] in ch]
    bad = set("".join(g)) - set("#.BLSEXKPRT")
    assert not bad, f"{rname}: unknown characters {bad}"

    # reachability: everything must be reachable from the entrance
    E = cells("E")
    assert E, f"{rname}: no E (entrance)"
    seen, todo = {E[0]}, [E[0]]
    while todo:
        c, r = todo.pop()
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (c + d[0], r + d[1])
            if q not in seen and at(*q) in ".SEXKRT":
                seen.add(q)
                todo.append(q)
    for need in cells("SXK"):
        assert need in seen, f"{rname}: {at(*need)} at col {need[0]} row {need[1]} is unreachable"
    open_floor = [c for c in cells(".SE") if c not in seen]
    if open_floor:
        print(f"  note: {rname} has {len(open_floor)} floor cells you can't walk to")

    ex = sum(c for c, _ in E) / len(E) * CELL + CELL / 2
    ey = sum(r for _, r in E) / len(E) * CELL + CELL / 2

    random.seed(n * 101)
    insts = [inst("obj_game", 16, 16), inst("obj_player", ex, ey), inst("obj_camera", 48, 16)]
    insts += [rect_inst("obj_wall", *rc) for rc in rects(cells("#"))]
    insts += [rect_inst("obj_block", *rc) for rc in rects(cells("B"))]
    insts += [rect_inst("obj_landmark", *rc) for rc in rects(cells("L"))]
    insts += [rect_inst("obj_door", *rc) for rc in rects(cells("X"))]
    insts += [inst("obj_spawn", c * CELL + CELL / 2, r * CELL + CELL / 2) for c, r in cells("S")]
    # Reliquary pillar, dash runes, training sentinels
    insts += [rect_inst("obj_reliquary", c, r, 1, 1) for c, r in cells("P")]
    insts += [inst("obj_rune", c * CELL + CELL / 2, r * CELL + CELL / 2) for c, r in cells("R")]
    insts += [inst("obj_dummy", c * CELL + CELL / 2, r * CELL + CELL / 2) for c, r in cells("T")]
    K = cells("K")
    if K:                                              # boss start: centre of the K cells
        insts.append(inst("obj_boss", sum(c for c, _ in K) / len(K) * CELL + CELL / 2,
                          sum(r for _, r in K) / len(K) * CELL + CELL / 2 - 20))

    # ---------------- tiles (16px grid = 2x2 per map cell)
    TW, TH = W * 2, H * 2
    floor = [[at(c // 2, r // 2) != "#" for c in range(TW)] for r in range(TH)]
    F = lambda c, r: 0 <= c < TW and 0 <= r < TH and floor[r][c]
    grid = lambda: [[EMPTY] * TW for _ in range(TH)]
    ground, patches, edges, cliffs = grid(), grid(), grid(), grid()

    # cobble daises: under landmarks, in front of doors and around the entrance (1 tile margin)
    cob = [[False] * TW for _ in range(TH)]
    def dais(c0, r0, w, h, m=1):
        for r in range(r0 * 2 - m, (r0 + h) * 2 + m):
            for c in range(c0 * 2 - m, (c0 + w) * 2 + m):
                if F(c, r):
                    cob[r][c] = True
    for c0, r0, w, h in rects(cells("L")):
        dais(c0, r0, w, h)
    for c0, r0, w, h in rects(cells("X")):
        dais(c0, r0, w, h + 1)
    for c0, r0, w, h in rects(cells("E")):
        dais(c0, r0, w, h)
    for c0, r0, w, h in rects(cells("K")):            # a wide cobble arena floor under the boss
        dais(c0, r0, w, h, 6)
    for c0, r0, w, h in rects(cells("P")):            # a cobble plinth around each Reliquary
        dais(c0, r0, w, h, 2)
    if rname.startswith("rm_shrine"):                 # shrines: the whole floor is worked stone
        for r in range(TH):
            for c in range(TW):
                if F(c, r):
                    cob[r][c] = True
    C = lambda c, r: 0 <= c < TW and 0 <= r < TH and cob[r][c]

    for r in range(TH):
        for c in range(TW):
            if F(c, r):
                ground[r][c] = random.choice(COBBLE) if cob[r][c] else GROUND

    # darker ground stamps in open floor, away from the daises
    for _ in range(400):
        if sum(1 for row in patches for v in row if v != EMPTY) >= 9 * 7:
            break
        c0, r0 = random.randrange(TW - 3), random.randrange(TH - 3)
        if all(F(c0 + dc, r0 + dr) and not C(c0 + dc, r0 + dr) and patches[r0 + dr][c0 + dc] == EMPTY
               for dc in range(-1, 4) for dr in range(-1, 4) if 0 <= c0 + dc < TW and 0 <= r0 + dr < TH):
            for (tc, tr) in DARK_BLOB:
                patches[r0 + tr - 56][c0 + tc - 12] = T(tc, tr)

    for r in range(TH):
        for c in range(TW):
            if not F(c, r):
                continue
            cb = C(c, r)
            if not F(c, r - 1):                        # back edge: spiky lip + tips poking into the void
                edges[r][c] = V(5 + c % 2, 1, cb)
                if r > 0:
                    edges[r - 1][c] = V(5 + c % 2, 0, cb)
            if not F(c - 1, r) and c > 0 and edges[r][c - 1] == EMPTY:    # side edges
                edges[r][c - 1] = V(0, 2 + r % 2, cb)
            if not F(c + 1, r) and c + 1 < TW and edges[r][c + 1] == EMPTY:
                edges[r][c + 1] = V(4, 2 + r % 2, cb)

    # front edge: a cliff face hangs into the void under every floor run (ends rounded)
    for r in range(TH):
        run = []
        for c in range(TW + 1):
            if c < TW and F(c, r) and not F(c, r + 1):
                run.append(c)
                continue
            for i, cc in enumerate(run):
                col = 16 if i == 0 else 19 if i == len(run) - 1 else (17 if i % 2 else 18)
                for d in (1, 2, 3, 4):
                    if F(cc, r + d) or r + d >= TH:
                        break
                    cliffs[r + d][cc] = V(col, d, C(cc, r))
            run = []

    # ---------------- props (solid, depth-sorted via obj_game -> obj_prop) and flat decor
    WHITE = 4294967295
    props, decor, used = [], [], set()
    def sfx(c, r):                                     # _c props match the cobble's lighter shadow
        return "_c" if C(c * 2, r * 2 + 1) else "_a"
    def P(base, x, y, c, r, col=WHITE, flip=None):
        name = base + sfx(c, r)
        if not ok(name):
            name = base + "_a"
        if ok(name):
            s = SPR[name]
            if s["bboxMode"] == 2:                     # manual mask = the prop's base: put the base where asked
                y += s["height"] - 1 - s["bbox_bottom"]
            props.append((name, x, y, flip if flip is not None else random.choice([1, -1]), col))

    for c0, r0, w, h in rects(cells("B")):
        theme = random.choice(["ruins", "ruins", "rocks"] if rname == "rm_boss" else list(PROP64))   # boss pillars look solid: they stop bolts
        cl = {(c0 + i, r0 + j) for i in range(w) for j in range(h)}
        for j in range(0, h - 1, 2):                   # 2x2 chunks get one big prop
            for i in range(0, w - 1, 2):
                c, r = c0 + i, r0 + j
                if random.random() < 0.8:
                    P(random.choice(PROP64[theme]), (c + 1) * CELL, (r + 2) * CELL - 6, c, r)
                    cl -= {(c, r), (c + 1, r), (c, r + 1), (c + 1, r + 1)}
        for c, r in sorted(cl, key=lambda q: q[1]):
            if theme == "graves":                      # graves are small: two per cell
                P(random.choice(PROP32[theme]), c * CELL + 9, (r + 1) * CELL - 10, c, r)
                P(random.choice(PROP32[theme]), c * CELL + 23, (r + 1) * CELL - 2, c, r)
            else:
                P(random.choice(PROP32[theme]), c * CELL + 16, (r + 1) * CELL - 4, c, r)
        used |= {(c0 + i, r0 + j) for i in range(w) for j in range(h)}

    marks = []
    for c0, r0, w, h in rects(cells("L")):
        base = "spr_lich" if w >= 4 else ("spr_shrine" if rname.startswith("rm_shrine") else random.choice(LANDMARK))
        P(base, (c0 + w / 2) * CELL, (r0 + h) * CELL - 4, c0, r0, flip=1)
        marks.append(base)
        used |= {(c0 + i, r0 + j) for i in range(w) for j in range(h)}

    doors = []
    for c0, r0, w, h in rects(cells("X")):
        x1, y1, x2, y2 = c0 * CELL, r0 * CELL, (c0 + w) * CELL, (r0 + h) * CELL
        doors.append((x1, y1, x2, y2))
        for x, fl in ((x1 - 10, 1), (x2 + 10, -1)):     # glowing crystals flank every door
            P("spr_crystal_1", x, y2 - 2, c0, r0 + 1, flip=fl)

    # foreground silhouettes in the void along the bottom and sides (drawn dark, in front of everything)
    for x in range(40, W * CELL, 150):
        x += random.randint(-30, 30)
        props.append((random.choice(FOREGROUND) + "_a", x, H * CELL + random.randint(10, 40),
                      random.choice([1, -1]), FG_COLOUR))
    for y in range(160, H * CELL - 60, 180):
        for x in (6, W * CELL - 6):
            if at(int(x // CELL), int(y // CELL)) == "#":
                props.append((random.choice(FOREGROUND) + "_a", x, y + random.randint(-20, 20),
                              1 if x < 100 else -1, FG_COLOUR))

    # decor: small plants/bones clustered around cover, a few along the island edge, big bones in the open
    keep_clear = set(cells("ESXKPRT"))
    for c, r in cells("ESXKPRT"):
        keep_clear |= {(c + dc, r + dr) for dc in (-1, 0, 1) for dr in (-1, 0, 1)}
    floor_cells = [q for q in cells(".") if q not in keep_clear]
    near_cover = [q for q in floor_cells if any((q[0] + dc, q[1] + dr) in used for dc in (-1, 0, 1) for dr in (-1, 0, 1))]
    near_edge = [q for q in floor_cells if any(at(q[0] + dc, q[1] + dr) == "#" for dc in (-1, 0, 1) for dr in (-1, 0, 1))]
    for pool, count in ((near_cover, len(near_cover) // 3), (near_edge, len(near_edge) // 7)):
        for c, r in random.sample(pool, min(count, len(pool))):
            decor.append((random.choice(DECOR_SMALL) + sfx(c, r), c * CELL + random.randint(6, 26),
                          r * CELL + random.randint(14, 30), random.choice([1, -1]), WHITE))
    open_cells = [q for q in floor_cells if q not in near_cover and q not in near_edge]
    for c, r in random.sample(open_cells, min(4, len(open_cells))):
        decor.append((random.choice(DECOR_BIG) + sfx(c, r), c * CELL + 16, r * CELL + 30, random.choice([1, -1]), WHITE))
    decor = [d for d in decor if ok(d[0])]
    props = [p for p in props if ok(p[0])]

    room = json.loads(json.dumps(template))
    room["%Name"] = room["name"] = rname
    il = next(L for L in room["layers"] if L["resourceType"] == "GMRInstanceLayer")
    bg = next(L for L in room["layers"] if L["resourceType"] == "GMRBackgroundLayer")
    il["instances"], il["depth"] = insts, 0
    bg["colour"], bg["depth"], bg["spriteId"] = VOID_COLOUR, 1000, None
    room["layers"] = [il,
                      asset_layer("Props", 100, props),          # converted to obj_prop at room start
                      asset_layer("Decor", 600, decor),
                      tile_layer("Cliffs", 760, cliffs),
                      tile_layer("Edges", 770, edges),
                      tile_layer("Patches", 790, patches),
                      tile_layer("Ground", 800, ground),
                      bg]
    room["instanceCreationOrder"] = [{"name": i["name"], "path": f"rooms/{rname}/{rname}.yy"} for i in insts]
    preview(os.path.join(TOOLS, "preview", rname.replace("rm_", "") + "_art.png"), W * CELL, H * CELL,
            [ground, patches, edges, cliffs], decor, props, (ex, ey), doors)
    room["roomSettings"]["Width"], room["roomSettings"]["Height"] = W * CELL, H * CELL
    v = room["views"][0]
    v["wview"], v["hview"], v["wport"], v["hport"] = VIEW[0], VIEW[1], 1280, 720
    dump_yy(room, os.path.join(PROJ, "rooms", rname, rname + ".yy"))
    if rname not in res:
        yyp["resources"].append({"id": {"name": rname, "path": f"rooms/{rname}/{rname}.yy"}})
    chamber_rooms.append(rname)
    print(f"{rname}: {W*CELL}x{H*CELL}px, {len(insts)} instances, {len(props)} props, {len(decor)} decor, "
          f"{len(cells('S'))} spawns, {len(rects(cells('X')))} doors, landmarks {marks}")

# chambers first in the room order (the game starts in rm_chamber_1), everything else after
others = [n for n in yyp["RoomOrderNodes"] if n["roomId"]["name"] not in chamber_rooms]
yyp["RoomOrderNodes"] = [{"roomId": {"name": r, "path": f"rooms/{r}/{r}.yy"}} for r in chamber_rooms] + others
yyp["resources"].sort(key=lambda r: r["id"]["path"])
dump_yy(yyp, yyp_path)
print("room order:", [n["roomId"]["name"] for n in yyp["RoomOrderNodes"]])
