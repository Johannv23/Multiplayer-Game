"""Build rm_level: a story path of open arenas separated by toxic water.

    python3 _tools/build_level.py          (GameMaker must be closed; Reload after)

South to north: Shore (start) -> Path between two lakes -> Ruins clearing -> River + bridge
-> Graveyard -> Moat + bridge -> Throne plateau (cobblestone).
Writes rooms/rm_level/rm_level.yy, plus obj_spawn / spr_spawn if missing, and a preview PNG.
"""
import os, re, sys, json, copy, uuid, random, glob

TOOLS = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from png import read_png, write_png

random.seed(11)


def load_yy(p):
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", open(p).read()))


def dump_yy(o, p):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(json.dumps(o, indent=2))


def uid():
    return str(uuid.uuid4())


# ------------------------------------------------------------------ layout (in 16px tiles)
TW, TH = 80, 110
RW, RH = TW * 16, TH * 16

THRONE = (0, 23)        # cobblestone plateau, final arena
MOAT = (24, 28)         # coast, 3 water, coast
GRAVEYARD = (29, 58)
RIVER = (59, 63)
RUINS = (64, 85)
PATH = (86, 93)         # two lakes with a gap in the middle
SHORE = (94, 103)       # start, no enemies
LAKE = (104, 109)       # southern lake to the bottom edge

MOAT_BRIDGE = 39        # left column of the 2-wide bridge
RIVER_BRIDGE = 22
PATH_GAP = (37, 43)     # walkable columns between the two path lakes

START = (RW // 2, (SHORE[0] + 5) * 16)

# ------------------------------------------------------------------ tiles
WC = 23                                   # ts_water_coasts columns
wc = lambda col, row: row * WC + col
WATER = wc(22, 0)
GRAY = {"tl": wc(5, 1), "t": [wc(6, 1), wc(7, 1)], "tr": wc(8, 1),
        "l": [wc(5, 2), wc(5, 3)], "r": [wc(8, 2), wc(8, 3)],
        "bl": wc(5, 4), "b": [wc(6, 4), wc(7, 4)], "br": wc(8, 4)}
COBBLE_TOP = [wc(6, 31), wc(7, 31)]      # cobble above, water below
BRIDGE = [[wc(20, r), wc(21, r)] for r in range(1, 6)]   # 2 x 5 stone bridge
GROUND_FILL = 54                          # ts_ground: plain gray ground
COBBLE_FILL = [523, 525, 527, 529]        # ts_ground: seamless cobblestone variants
EMPTY = -2147483648

grid = lambda: [[EMPTY] * TW for _ in range(TH)]
water, ground, cobble, coast, bridges, details = grid(), grid(), grid(), grid(), grid(), grid()

for y in range(TH):
    for x in range(TW):
        if y <= THRONE[1]:
            cobble[y][x] = random.choice(COBBLE_FILL)
        else:
            ground[y][x] = GROUND_FILL

walls = []   # (x1, y1, x2, y2) world rects for invisible obj_wall blockers


def river(rows, bridge_col, top_tiles):
    """Full-width river: top coast, water, bottom coast, with a 2-wide bridge."""
    r0, r1 = rows
    for y in range(r0, r1 + 1):
        for x in range(TW):
            water[y][x] = WATER
            ground[y][x] = cobble[y][x] = EMPTY
    for x in range(TW):
        coast[r0][x] = top_tiles[x % 2]
        coast[r1][x] = GRAY["b"][x % 2]
    for i, y in enumerate(range(r0, r1 + 1)):
        bridges[y][bridge_col] = BRIDGE[i][0]
        bridges[y][bridge_col + 1] = BRIDGE[i][1]
    # block the water from mid-coast to mid-coast, except the bridge (with a 4px rail each side)
    y1, y2 = r0 * 16 + 8, r1 * 16 + 8
    walls.append((0, y1, bridge_col * 16 + 4, y2))
    walls.append(((bridge_col + 2) * 16 - 4, y1, RW, y2))


def lake(x0, y0, x1, y1, open_left=False, open_right=False, open_bottom=False):
    """Rectangular lake from the 9-slice kit; open sides run off the room edge."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            water[y][x] = WATER
            ground[y][x] = EMPTY
            top, bot = y == y0, (y == y1 and not open_bottom)
            left, right = x == x0 and not open_left, x == x1 and not open_right
            if top and left: t = GRAY["tl"]
            elif top and right: t = GRAY["tr"]
            elif bot and left: t = GRAY["bl"]
            elif bot and right: t = GRAY["br"]
            elif top: t = GRAY["t"][x % 2]
            elif bot: t = GRAY["b"][x % 2]
            elif left: t = GRAY["l"][y % 2]
            elif right: t = GRAY["r"][y % 2]
            else: continue
            coast[y][x] = t
    walls.append((x0 * 16 + (0 if open_left else 8), y0 * 16 + 8,
                  (x1 + 1) * 16 - (0 if open_right else 8), RH if open_bottom else (y1 + 1) * 16 - 8))


river(MOAT, MOAT_BRIDGE, COBBLE_TOP)
river(RIVER, RIVER_BRIDGE, GRAY["t"])
lake(0, PATH[0], PATH_GAP[0] - 1, PATH[1], open_left=True)
lake(PATH_GAP[1] + 1, PATH[0], TW - 1, PATH[1], open_right=True)
lake(0, LAKE[0], TW - 1, LAKE[1], open_left=True, open_right=True, open_bottom=True)

# ground cracks/pebbles: small stamps copied from the pack's sample map, gray ground only
from tmx import layers as tmx_layers


def stamps():
    out = []
    for name, cells in tmx_layers():
        if name not in ("details1", "detail2", "details3"):
            continue
        seen = set()
        for c in cells:
            if c in seen:
                continue
            group, todo = [], [c]
            seen.add(c)
            while todo:
                p = todo.pop()
                group.append(p)
                for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (p[0] + d[0], p[1] + d[1])
                    if q in cells and q not in seen:
                        seen.add(q)
                        todo.append(q)
            mx, my = min(p[0] for p in group), min(p[1] for p in group)
            st = [(p[0] - mx, p[1] - my, cells[p][1]) for p in group]
            if max(s[0] for s in st) < 6 and max(s[1] for s in st) < 6:
                out.append(st)
    return out


ST = stamps()
placed = 0
for _ in range(3000):
    if placed == 55:
        break
    st = random.choice(ST)
    ox, oy = random.randrange(0, TW - 6), random.randrange(GRAVEYARD[0], TH - 6)
    if any(ground[oy + dy][ox + dx] != GROUND_FILL or coast[oy + dy][ox + dx] != EMPTY
           or details[oy + dy][ox + dx] != EMPTY for dx, dy, _ in st):
        continue
    for dx, dy, t in st:
        details[oy + dy][ox + dx] = t
    placed += 1

# ------------------------------------------------------------------ props
info = {}
for p in glob.glob(os.path.join(PROJ, "sprites", "spr_*", "spr_*.yy")):
    s = load_yy(p)
    info[s["name"]] = {"xo": s["sequence"]["xorigin"], "yo": s["sequence"]["yorigin"], "solid": s["bboxMode"] == 2,
                       "mask": (s["bbox_left"], s["bbox_top"], s["bbox_right"], s["bbox_bottom"]),
                       "w": s["width"], "h": s["height"]}
family = lambda fam, v: sorted(n for n in info if re.fullmatch(rf"spr_{fam}(_\d+(_\d+)?)?_{v}", n))

props, decor, spawns, blocked = [], [], [], []


def mask_rect(name, x, y, flip=1):
    i = info[name]
    l, t, r, b = i["mask"]
    if flip < 0:
        l, r = 2 * i["xo"] - r, 2 * i["xo"] - l
    return (x - i["xo"] + l, y - i["yo"] + t, x - i["xo"] + r + 1, y - i["yo"] + b + 1)


def hits(r, rects, pad=0):
    return any(r[0] - pad < R[2] and r[2] + pad > R[0] and r[1] - pad < R[3] and r[3] + pad > R[1] for R in rects)


def prop(name, x, y, flip=None, pad=4):
    """Place a solid prop unless its base would overlap water, another prop or a kept-open area."""
    flip = flip if flip is not None else random.choice([1, -1])
    r = mask_rect(name, x, y, flip)
    if r[0] < 0 or r[2] > RW or hits(r, walls + blocked, pad) or hits(r, KEEP_OPEN):
        return False
    blocked.append(r)
    props.append((name, x, y, flip))
    return True


def decor_at(name, x, y):
    if not hits((x - 6, y - 6, x + 6, y), blocked + walls):
        decor.append((name, x, y, random.choice([1, -1])))


def spawn(x, y):
    spawns.append((x, y))


px = lambda col: col * 16
py = lambda row: row * 16

# areas that must stay walkable: arena centres, the bridges' approaches and the start
KEEP_OPEN = [
    (px(16), py(THRONE[0] + 13), px(64), py(THRONE[1] + 1)),               # throne arena floor
    (px(MOAT_BRIDGE - 3), py(THRONE[1] - 3), px(MOAT_BRIDGE + 5), py(GRAVEYARD[0] + 4)),
    (px(18), py(GRAVEYARD[0] + 3), px(62), py(GRAVEYARD[1] - 2)),          # graveyard field
    (px(RIVER_BRIDGE - 3), py(RIVER[0] - 4), px(RIVER_BRIDGE + 5), py(RIVER[1] + 4)),
    (px(14), py(RUINS[0] + 3), px(66), py(RUINS[1] - 1)),                  # ruins clearing
    (px(PATH_GAP[0] - 1), py(RUINS[1] - 2), px(PATH_GAP[1] + 2), py(SHORE[0] + 2)),
    (START[0] - 56, START[1] - 40, START[0] + 56, START[1] + 24),           # start
]

# --- 4. Throne plateau (tan "c" variants to match the cobblestone)
prop("spr_throne_c", RW // 2, py(10), 1)
prop("spr_shrine_c", RW // 2 - 72, py(12), 1)
prop("spr_shrine_c", RW // 2 + 72, py(12), -1)
prop("spr_lich_c", RW // 2 - 150, py(11), 1)
prop("spr_lich_c", RW // 2 + 150, py(11), -1)
prop("spr_pile_skulls_c", RW // 2 - 110, py(12), 1)
prop("spr_pile_skulls_c", RW // 2 + 110, py(12), -1)
for x, y in ((90, 150), (1190, 150), (70, 330), (1210, 330)):
    prop("spr_dead_tree_big_c", x, y, 1 if x < RW // 2 else -1)
for x in range(30, RW, 70):                                              # back wall of ruins/trees
    prop(random.choice(family("ruin", "c") + family("tree", "c")), x + random.randint(-8, 8), py(6), pad=0)
for x, y in ((200, 230), (1080, 230), (230, 300), (1050, 300)):
    prop(random.choice(family("crystal", "c")), x, y)
spawn(RW // 2 - 72, py(14)), spawn(RW // 2 + 72, py(14)), spawn(px(10), py(18)), spawn(px(70), py(18))

# --- 3. Graveyard: neat rows of graves down both sides, open field in the middle
prop("spr_skull_door_a", px(10), py(GRAVEYARD[0] + 2) + 40, 1)            # the crypt the dead come from
graves = [g for g in family("grave", "a") if info[g]["solid"]]
for side in (0, 1):
    for row in range(7):
        for col in range(3):
            x = (px(5) if side == 0 else px(63)) + col * 44 + random.randint(-3, 3)
            y = py(GRAVEYARD[0] + 4) + row * 56 + random.randint(-3, 3)
            prop(random.choice(graves), x, y, pad=2)
for x, y in ((px(3), py(GRAVEYARD[1])), (px(77), py(GRAVEYARD[1])), (px(76), py(GRAVEYARD[0] + 3))):
    prop(random.choice(["spr_dead_tree_mid_a", "spr_dead_tree_big_a"]), x, y)
for row in range(2, 7, 2):
    # just inside each block of graves, facing the field
    spawn(px(15), py(GRAVEYARD[0] + 4) + row * 56 - 24)
    spawn(px(61), py(GRAVEYARD[0] + 4) + row * 56 - 24)
spawn(px(10), py(GRAVEYARD[0] + 2) + 60)

# --- 2. Ruins clearing: a fallen outpost framing the corners
ruins_big = [r for r in family("ruin", "a") if info[r]["w"] >= 128]
ruins_small = [r for r in family("ruin", "a") if info[r]["w"] < 128]
for x, y in ((px(6), py(RUINS[0] + 6)), (px(73), py(RUINS[0] + 6)), (px(8), py(RUINS[1] - 1)), (px(72), py(RUINS[1] - 1))):
    prop(random.choice(ruins_big), x, y, pad=0)
for x, y in ((px(18), py(RUINS[0] + 2)), (px(61), py(RUINS[0] + 2)), (px(12), py(RUINS[0] + 13)), (px(68), py(RUINS[0] + 13))):
    prop(random.choice(ruins_small), x, y, pad=0)
for x, y in ((px(28), py(RUINS[0] + 2)), (px(52), py(RUINS[1])), (px(3), py(RUINS[0] + 12)), (px(77), py(RUINS[0] + 10))):
    prop(random.choice(family("rock", "a")), x, y)
for x, y in ((px(10), py(RUINS[0] + 8)), (px(70), py(RUINS[0] + 8)), (px(12), py(RUINS[1] - 2)), (px(68), py(RUINS[1] - 2))):
    spawn(x, y)

# --- Path: skull totems line the gap between the lakes, pointing north
for y in (py(SHORE[0]) + 10, py(RUINS[1]) + 6):
    prop("spr_totem_a", px(PATH_GAP[0]) - 28, y, 1, pad=0)
    prop("spr_totem_a", px(PATH_GAP[1] + 1) + 28, y, -1, pad=0)

# --- 1. Shore: where earlier adventurers fell
for x in (60, 170, 1110, 1220):
    prop(random.choice(family("broken_tree", "a")), x, py(SHORE[0] + 3))
for x in (300, 980):
    prop(random.choice(family("rock", "a")), x, py(SHORE[0] + 7))
bones_big = [b for b in family("bones", "a") if info[b]["w"] >= 64]
bones_small = [b for b in family("bones", "a") if info[b]["w"] < 64]
for dx, dy in ((-70, -10), (60, 14), (-30, 30), (100, -24), (-120, 20)):
    decor_at(random.choice(bones_big if abs(dx) > 80 else bones_small), START[0] + dx, START[1] + dy)

# --- room edges: a sparse tree line on the left/right of every gray-ground area
for y0, y1 in (GRAVEYARD, RUINS, SHORE):
    for y in range(py(y0) + 30, py(y1), 60):
        prop(random.choice(family("tree", "a") + family("dead_tree", "a")), random.randint(4, 14), y)
        prop(random.choice(family("tree", "a") + family("dead_tree", "a")), RW - random.randint(4, 14), y)

# --- decor: plants and small bones at arena edges only, a few bones in the fields
plants = family("plant", "a") + family("thorn_plant", "a")
for _ in range(70):
    y = random.randint(py(GRAVEYARD[0]) + 10, py(SHORE[1]))
    x = random.choice([random.randint(20, 220), random.randint(RW - 220, RW - 20)])
    decor_at(random.choice(plants), x, y)
for _ in range(14):
    decor_at(random.choice(bones_small), random.randint(300, RW - 300),
             random.choice([random.randint(py(GRAVEYARD[0]) + 40, py(GRAVEYARD[1]) - 20),
                            random.randint(py(RUINS[0]) + 40, py(RUINS[1]) - 20)]))
for _ in range(10):
    decor_at(random.choice(family("bones", "c")), random.randint(150, RW - 150), random.randint(200, py(THRONE[1])))

print(f"props {len(props)}  decor {len(decor)}  spawns {len(spawns)}  walls {len(walls)}  detail stamps {placed}")

# ------------------------------------------------------------------ reachability check
PLAYER = (-6, 0, 6, 12)   # player mask relative to x, y
solid = walls + blocked


def free(x, y):
    if x < 16 or x > RW - 16 or y < 16 or y > RH - 16:
        return False
    r = (x + PLAYER[0], y + PLAYER[1], x + PLAYER[2], y + PLAYER[3])
    return not hits(r, solid)


S = 4
seen, todo = {START}, [START]
while todo:
    p = todo.pop()
    for d in ((S, 0), (-S, 0), (0, S), (0, -S)):
        q = (p[0] + d[0], p[1] + d[1])
        if q not in seen and free(*q):
            seen.add(q)
            todo.append(q)
for name, (y0, y1) in (("throne", THRONE), ("graveyard", GRAVEYARD), ("ruins", RUINS)):
    cx, cy = RW // 2 // S * S, (py(y0) + py(y1)) // 2 // S * S
    assert (cx, cy) in seen, f"{name} arena unreachable"
for x, y in spawns:
    assert free(x, y), f"spawn at {x},{y} is inside something"
print("all arenas reachable from the start")

# ------------------------------------------------------------------ write project files
yyp_path = os.path.join(PROJ, "multiplayergame.yyp")
yyp = load_yy(yyp_path)
res = {r["id"]["name"] for r in yyp["resources"]}

if "spr_spawn" not in res:   # red ring marker, only visible in the Room Editor
    src = os.path.join(PROJ, "sprites", "spr_player_mask")
    s = load_yy(os.path.join(src, "spr_player_mask.yy"))
    d = os.path.join(PROJ, "sprites", "spr_spawn")
    os.makedirs(d, exist_ok=True)
    fid, lid = uid(), uid()
    rows = []
    for y in range(16):
        r = bytearray(16 * 4)
        for x in range(16):
            dist = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if 5 <= dist <= 7.5:
                r[x * 4:x * 4 + 4] = bytes((230, 40, 40, 255))
        rows.append(bytes(r))
    write_png(os.path.join(d, fid + ".png"), 16, 16, rows)
    os.makedirs(os.path.join(d, "layers", fid))
    write_png(os.path.join(d, "layers", fid, lid + ".png"), 16, 16, rows)
    s["%Name"] = s["name"] = s["sequence"]["%Name"] = s["sequence"]["name"] = "spr_spawn"
    s["width"] = s["height"] = 16
    s["bboxMode"] = 0
    s["bbox_left"], s["bbox_top"], s["bbox_right"], s["bbox_bottom"] = 0, 0, 15, 15
    s["sequence"]["xorigin"] = s["sequence"]["yorigin"] = 8
    s["frames"][0]["%Name"] = s["frames"][0]["name"] = fid
    s["layers"][0]["%Name"] = s["layers"][0]["name"] = lid
    s["sequence"]["tracks"][0]["keyframes"]["Keyframes"][0]["Channels"]["0"]["Id"] = {
        "name": fid, "path": "sprites/spr_spawn/spr_spawn.yy"}
    dump_yy(s, os.path.join(d, "spr_spawn.yy"))
    yyp["resources"].append({"id": {"name": "spr_spawn", "path": "sprites/spr_spawn/spr_spawn.yy"}})

if "obj_spawn" not in res:
    o = load_yy(os.path.join(PROJ, "objects", "obj_game", "obj_game.yy"))
    o["%Name"] = o["name"] = "obj_spawn"
    o["spriteId"] = {"name": "spr_spawn", "path": "sprites/spr_spawn/spr_spawn.yy"}
    o["visible"] = False
    dump_yy(o, os.path.join(PROJ, "objects", "obj_spawn", "obj_spawn.yy"))
    yyp["resources"].append({"id": {"name": "obj_spawn", "path": "objects/obj_spawn/obj_spawn.yy"}})
    # its Create_0.gml is written by hand (see the project)

yyp["resources"].sort(key=lambda r: r["id"]["path"])
dump_yy(yyp, yyp_path)


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


def layer_common(kind, name, depth):
    return {f"$GMR{kind}Layer": "", "%Name": name, "depth": depth, "effectEnabled": True, "effectType": None,
            "gridX": 16, "gridY": 16, "hierarchyFrozen": False, "inheritLayerDepth": False,
            "inheritLayerSettings": False, "inheritSubLayers": True, "inheritVisibility": True, "layers": [],
            "name": name, "properties": [], "resourceType": f"GMR{kind}Layer", "resourceVersion": "2.0",
            "userdefinedDepth": False, "visible": True}


def tile_layer(name, depth, ts, g):
    L = layer_common("Tile", name, depth)
    L["tiles"] = {"SerialiseHeight": TH, "SerialiseWidth": TW,
                  "TileCompressedData": rle([c for row in g for c in row]), "TileDataFormat": 1}
    L["tilesetId"] = {"name": ts, "path": f"tilesets/{ts}/{ts}.yy"}
    L["x"] = L["y"] = 0
    return L


def asset_layer(name, depth, items):
    L = layer_common("Asset", name, depth)
    L["assets"] = []
    for spr, x, y, sx in sorted(items, key=lambda it: it[2]):
        g = "graphic_" + uuid.uuid4().hex[:8].upper()
        L["assets"].append({"$GMRSpriteGraphic": "v1", "%Name": g, "animationSpeed": 1.0, "colour": 4294967295,
                            "frozen": False, "headPosition": 0.0, "ignore": False, "inheritedItemId": None,
                            "inheritItemSettings": False, "name": g, "resourceType": "GMRSpriteGraphic",
                            "resourceVersion": "2.0", "rotation": 0.0, "scaleX": float(sx), "scaleY": 1.0,
                            "spriteId": {"name": spr, "path": f"sprites/{spr}/{spr}.yy"},
                            "x": float(x), "y": float(y)})
    return L


def inst(obj, x, y, sx=1.0, sy=1.0):
    n = "inst_" + uuid.uuid4().hex[:8].upper()
    return {"$GMRInstance": "v4", "%Name": n, "colour": 4294967295, "frozen": False, "hasCreationCode": False,
            "ignore": False, "imageIndex": 0, "imageSpeed": 1.0, "inheritCode": False, "inheritedItemId": None,
            "inheritItemSettings": False, "isDnd": False, "name": n,   # room instances use isDnd (lowercase d); events use isDnD
            "objectId": {"name": obj, "path": f"objects/{obj}/{obj}.yy"}, "properties": [],
            "resourceType": "GMRInstance", "resourceVersion": "2.0", "rotation": 0.0,
            "scaleX": float(sx), "scaleY": float(sy), "x": float(x), "y": float(y)}


room_path = os.path.join(PROJ, "rooms", "rm_level", "rm_level.yy")
room = load_yy(room_path)
inst_layer = next(L for L in room["layers"] if L["resourceType"] == "GMRInstanceLayer")
bg = next(L for L in room["layers"] if L["resourceType"] == "GMRBackgroundLayer")

# obj_game first: obj_spawn's Create reads obj_game.arenas; obj_player before obj_camera
instances = [inst("obj_game", 24, 24), inst("obj_player", *START), inst("obj_camera", 40, 24)]
instances += [inst("obj_wall", x1, y1, (x2 - x1) / 64, (y2 - y1) / 64) for x1, y1, x2, y2 in walls]
instances += [inst("obj_spawn", x, y) for x, y in spawns]
inst_layer["instances"] = instances
inst_layer["depth"] = 0
bg["depth"] = 1000
bg["colour"] = 0xFF6A736F

room["layers"] = [inst_layer,
                  asset_layer("Props", 100, props),
                  asset_layer("Decor", 200, decor),
                  tile_layer("Bridges", 300, "ts_water_coasts", bridges),
                  tile_layer("Details", 400, "ts_details", details),
                  tile_layer("Coast", 500, "ts_water_coasts", coast),
                  tile_layer("Cobble", 600, "ts_ground", cobble),
                  tile_layer("Ground", 700, "ts_ground", ground),
                  tile_layer("Water", 800, "ts_water_coasts", water),
                  bg]
room["instanceCreationOrder"] = [{"name": i["name"], "path": "rooms/rm_level/rm_level.yy"} for i in instances]
room["roomSettings"]["Width"], room["roomSettings"]["Height"] = RW, RH
dump_yy(room, room_path)
print("wrote", room_path)
print("arena bounds (px):", {n: (py(a), py(b + 1)) for n, (a, b) in
                             (("ruins", RUINS), ("graveyard", GRAVEYARD), ("throne", THRONE))})
