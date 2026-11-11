// move a value toward a target by a fixed amount, without overshooting
function approach(_start, _end, _amount) {
    if (_start < _end) return min(_start + _amount, _end);
    return max(_start - _amount, _end);
}

// switch animation only if it's different, restarting it from _frame
function set_anim(_spr, _frame = 0) {
    if (sprite_index != _spr) {
        sprite_index = _spr;
        image_index = _frame;
        image_speed = 1;
    }
}

// ---- debug hitboxes (press B in game to toggle) ----
// script globals run once at game start, before any Create event
global.show_hitboxes = true;

// draws the calling instance's collision box: translucent fill + solid outline
function draw_hitbox(_col) {
    if (!global.show_hitboxes) return;
    draw_set_color(_col);
    draw_set_alpha(0.25);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(1);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_color(c_white);
}

// ---- run state (survives room changes; reset on death) ----
global.dash_unlocked = false;   // unlocked by clearing chamber 1
global.cast_unlocked = false;   // unlocked by clearing chamber 2
global.player_hp = -1;          // carried between chambers (-1 = start full)

function reset_run() {
    global.freeze = false;
    global.cleared = {};
    global.shrine_done = [false, false, false, false];
    global.stomp_unlocked = false;
    global.boons_p1 = {};
    global.boons_p2 = {};
    global.duos = {};
    set_allow_all(true);
    global.dash_unlocked = false;
    global.cast_unlocked = false;
    global.player_hp = -1;
    global.bond = 0;
}

// every hit on the character goes through here: respects i-frames (dash, recent hit) and death
function hurt_player(_p, _dmg) {
    if (global.freeze || _p.invuln > 0 || _p.state == "dead") return false;
    // Soul Feast shield soaks damage first
    if (_p.shield > 0) {
        var soak = min(_p.shield, _dmg);
        _p.shield -= soak;
        _dmg -= soak;
    }
    // Iron Heart Lv3: survive one lethal hit per room
    if (_dmg > 0 && _p.hp - _dmg <= 0 && _p.last_stand) {
        _p.last_stand = false;
        _dmg = _p.hp - 1;
        flash(c_white, 0.8);
        slowmo(45);
        shake(8);
        dmg_number(_p.x, _p.y - 24, "LAST STAND", true);
    }
    _p.hp -= _dmg;
    _p.hurt_flash = 12;
    _p.invuln = 40;                 // short grace period so a crowd can't chain-hit you
    shake(3);
    hitstop(3);
    flash(c_red, 0.2);
    return true;
}

// ---- dialogue / tutorial ----
global.freeze = false;          // true while a dialogue box is open: nothing moves, nothing gets hurt
global.tutorial_done = false;   // the chamber 1 tutorial plays once per session (set true here to skip it while testing)

// what the players may use. The tutorial switches these on one at a time; normally all true.
global.allow_move = true;
global.allow_jump = true;
global.allow_kick = true;
global.allow_recall = true;
global.allow_attack = true;     // player 2: swing
global.allow_detach = true;     // player 2: fly out / return

function set_allow_all(_on) {
    global.allow_move = _on;
    global.allow_jump = _on;
    global.allow_kick = _on;
    global.allow_recall = _on;
    global.allow_attack = _on;
    global.allow_detach = _on;
    global.allow_bond = _on;
}

// open a dialogue: _lines = [ ["SWORD", "text"], ["HERO", "text"], ... ]. Space advances; play is frozen until the last line.
function start_dialogue(_lines) {
    var d = instance_create_depth(0, 0, -16000, obj_dialogue);
    d.lines = _lines;
    global.freeze = true;
    return d;
}

// ======================================================================
// ---- Reliquaries, shrines and boons (run state; reset_run clears it) ----
// ======================================================================
global.cleared = {};                                 // room name -> true once its fight is won
global.shrine_done = [false, false, false, false];   // [1..3]: the Reliquary of chamber 1 / chamber 2 / the boss
global.stomp_unlocked = false;                       // Meteor Fall (shrine 3)
global.boons_p1 = {};                                // boon id -> level (1-3)   player 1: body
global.boons_p2 = {};                                //                          player 2: blade
global.duos = {};                                    // duo id -> true
global.banner_next = "";                             // shown by the next room's obj_game
global.runs_won = 0;

// Every boon has 3 levels; picking it again levels it up. "req" = needs that ability first.
// Every Reliquary offers each player one card of each category:
//   flair = a showy upgrade to an ability   bond = one player's action powers up the other   stat = plain numbers
// Picking a boon again levels it up (max 3).
global.BOON_LIST = [
    // ---- player 1: body ----
    { id: "afterburn", side: 1, cat: "flair", name: "Afterburn Dash", col: make_color_rgb(255, 120, 40), req: "dash",
      desc: ["Your dash leaves a trail of fire that burns enemies.", "The fire burns longer and hotter.", "Every dash ends in an explosion."] },
    { id: "thunder", side: 1, cat: "flair", name: "Thunder Step", col: make_color_rgb(150, 200, 255), req: "",
      desc: ["Landing a jump or ending a dash calls down lightning around you.", "Bigger strike, more damage.", "Huge strike. Struck enemies are stunned longer."] },
    { id: "phantom", side: 1, cat: "flair", name: "Phantom Step", col: make_color_rgb(170, 130, 255), req: "dash",
      desc: ["+1 dash charge. Dashing through enemies slices them.", "+1 more charge. Slices cut deeper.", "+1 more charge. Slices cut to the bone."] },
    { id: "cannon", side: 1, cat: "flair", name: "Cannon Kick", col: make_color_rgb(255, 200, 90), req: "",
      desc: ["Kicked enemies hit others much harder.", "Kicked enemies explode when they hit a wall.", "Kicks recharge almost instantly."] },
    { id: "moonjump", side: 1, cat: "flair", name: "Moon Jump", col: make_color_rgb(200, 220, 255), req: "",
      desc: ["Jump higher and hang in the air longer.", "PERFECT HOP: clearing an attack mid-jump slows time.", "Jump again in mid-air."] },
    { id: "soulbloom", side: 1, cat: "flair", name: "Soul Bloom", col: make_color_rgb(210, 130, 255), req: "cast",
      desc: ["Bigger Soul Ascension. It charges faster.", "Rooted enemies take 25% more damage.", "When a root ends, the victim bursts in soul fire."] },
    { id: "meteor", side: 1, cat: "flair", name: "Meteor Core", col: make_color_rgb(255, 140, 60), req: "stomp",
      desc: ["Meteor Fall hits a wider area.", "Meteor Fall leaves a ring of fire.", "Meteor Fall deals double damage."] },
    { id: "fury", side: 1, cat: "bond", name: "Fury Draught", col: make_color_rgb(255, 60, 40), req: "",
      desc: ["When you recall the sword, you drink a potion: the sword burns with FURY for 4 s (+40% damage, faster swings, fire).", "FURY lasts 6 s.", "FURY lasts 8 s and its swings set the ground on fire."] },
    { id: "whetstone", side: 1, cat: "bond", name: "Whetstone Step", col: make_color_rgb(140, 220, 255), req: "dash",
      desc: ["Dash through the floating sword to sharpen it: its next 3 hits deal double damage.", "Next 4 hits.", "Next 5 hits, and the sharpening blasts enemies around the sword."] },
    { id: "ironheart", side: 1, cat: "stat", name: "Iron Heart", col: make_color_rgb(255, 90, 110), req: "",
      desc: ["+20 max health. Soul orbs heal 50% more.", "+20 max health. Soul orbs heal double.", "+20 max health. Survive one deadly hit per room."] },
    { id: "swift", side: 1, cat: "stat", name: "Swift Feet", col: make_color_rgb(200, 255, 180), req: "",
      desc: ["+12% move speed.", "+24% move speed.", "+36% move speed."] },
    { id: "heavy", side: 1, cat: "stat", name: "Heavy Boots", col: make_color_rgb(230, 190, 120), req: "",
      desc: ["Kicks push 25% further and stagger 25% longer.", "50% further and longer.", "Kicks push 75% further and stagger twice as long."] },
    // ---- player 2: sword ----
    { id: "chain", side: 2, cat: "flair", name: "Chain Lightning", col: make_color_rgb(140, 200, 255), req: "",
      desc: ["Hits arc to 1 nearby enemy.", "Hits arc to 2 enemies.", "Hits arc to 3 enemies."] },
    { id: "orbit", side: 2, cat: "flair", name: "Whirling Return", col: make_color_rgb(160, 255, 220), req: "",
      desc: ["Recall hits harder; the blade then orbits the hero for 1 s.", "Orbits for 2 s and hits harder.", "Orbits for 3 s and hits hardest."] },
    { id: "executioner", side: 2, cat: "flair", name: "Executioner", col: make_color_rgb(255, 210, 60), req: "",
      desc: ["CRITS: x2 damage on stunned, rooted or flying enemies.", "Crits deal x2.5.", "Crits deal x3 and crit kills explode."] },
    { id: "frenzy", side: 2, cat: "flair", name: "Frenzy", col: make_color_rgb(255, 80, 60), req: "",
      desc: ["Combos speed up your swings. 10 hits: a giant CLEAVE.", "Faster. CLEAVE every 8 hits.", "Fastest. CLEAVE every 6 hits."] },
    { id: "tetherlash", side: 2, cat: "bond", name: "Tether Lash", col: make_color_rgb(255, 150, 60), req: "",
      desc: ["The tether burns: enemies crossing the line between you take damage.", "It burns hotter.", "It burns hottest and staggers."] },
    { id: "skewer", side: 2, cat: "bond", name: "Skewer", col: make_color_rgb(255, 230, 120), req: "",
      desc: ["Enemies the hero kicks into the flying sword get skewered for big damage.", "Skewers hit harder.", "Skewers hit hardest and explode."] },
    { id: "bloodedge", side: 2, cat: "bond", name: "Blood Edge", col: make_color_rgb(220, 40, 60), req: "",
      desc: ["Every hit heals the hero 1.", "Every hit heals 2.", "Kills always drop a soul orb."] },
    { id: "edge", side: 2, cat: "stat", name: "Keen Edge", col: make_color_rgb(230, 235, 255), req: "",
      desc: ["+25% damage. Bigger swings.", "+50% damage. Even bigger swings.", "+75% damage. Massive swings."] },
    { id: "leash", side: 2, cat: "stat", name: "Long Leash", col: make_color_rgb(120, 230, 200), req: "",
      desc: ["Fly 30px further. Detached hits deal 75%.", "Fly 60px further. Detached hits deal 90%.", "Fly 90px further. Detached hits deal full damage, faster."] },
    { id: "honed", side: 2, cat: "stat", name: "Honed Grip", col: make_color_rgb(200, 200, 255), req: "",
      desc: ["Swings 15% faster.", "Swings 30% faster.", "Swings 45% faster."] }
];

function blv(_side, _id) {
    var s = (_side == 1) ? global.boons_p1 : global.boons_p2;
    return variable_struct_exists(s, _id) ? s[$ _id] : 0;
}
function has_duo(_id) { return variable_struct_exists(global.duos, _id); }
function boon_ok(_b) {
    switch (_b.req) {
        case "dash":  return global.dash_unlocked;
        case "cast":  return global.cast_unlocked;
        case "stomp": return global.stomp_unlocked;
    }
    return true;
}
// 3 random boons a side can take (not maxed, requirement met)
// one random card from each category (flair, bond, stat) a side can still take
function roll_offers(_side) {
    var out = [];
    var cats = ["flair", "bond", "stat"];
    for (var c = 0; c < 3; c++) {
        var pool = [];
        for (var i = 0; i < array_length(global.BOON_LIST); i++) {
            var b = global.BOON_LIST[i];
            if (b.side == _side && b.cat == cats[c] && blv(_side, b.id) < 3 && boon_ok(b)) array_push(pool, b);
        }
        if (array_length(pool) > 0) array_push(out, pool[irandom(array_length(pool) - 1)]);
    }
    return out;
}
function grant_boon(_side, _id) {
    var s = (_side == 1) ? global.boons_p1 : global.boons_p2;
    s[$ _id] = blv(_side, _id) + 1;
    if (_id == "ironheart" && instance_exists(obj_player)) obj_player.hp += 20;
}
// duo boons: owning the right pair from both players unlocks a bonus. Returns its banner text, or "".
function check_duos() {
    if (!has_duo("storm") && blv(1, "thunder") > 0 && blv(2, "chain") > 0) {
        global.duos[$ "storm"] = true;
        return "DUO  -  STORM BOND: lightning everywhere stuns, chains reach further";
    }
    if (!has_duo("feast") && blv(1, "ironheart") > 0 && blv(2, "bloodedge") > 0) {
        global.duos[$ "feast"] = true;
        return "DUO  -  SOUL FEAST: healing past full health becomes a shield";
    }
    return "";
}
// debug: hand each player a random boon (used when skipping ahead past a shrine)
function give_random_boons() {
    var o1 = roll_offers(1), o2 = roll_offers(2);
    if (array_length(o1) > 0) grant_boon(1, o1[0].id);
    if (array_length(o2) > 0) grant_boon(2, o2[0].id);
    check_duos();
}

// ======================================================================
// ---- juice: shake, hit-stop, slow-mo, flash, particles, numbers ----
// ======================================================================
global.hitstop_t = 0;      // frames the action holds still on a big hit
global.slowmo_t = 0;       // frames of half-speed bullet time
global.flash_a = 0;      // full-screen flash (Draw GUI in obj_juice)
global.flash_col = c_white;

function paused() { return global.freeze || global.hitstop_t > 0; }
function shake(_a) { if (instance_exists(obj_camera)) obj_camera.shake_amt = max(obj_camera.shake_amt, _a); }
function hitstop(_f) { global.hitstop_t = max(global.hitstop_t, _f); }
function slowmo(_f) { global.slowmo_t = max(global.slowmo_t, _f); }
function flash(_col, _a) { global.flash_col = _col; global.flash_a = max(global.flash_a, _a); }
// particles: "spark", "ember", "smoke", "shard", "soul", "zap", "mote"
function fx(_type, _x, _y, _n) {
    if (instance_exists(obj_juice)) with (obj_juice) part_particles_create(ps, _x, _y, pt[$ _type], _n);
}
function fx_ring(_x, _y, _r, _col) {
    with (instance_create_depth(_x, _y, -15002, obj_fx)) { kind = "ring"; rmax = _r; col = _col; }
}
function fx_bolt(_x1, _y1, _x2, _y2, _col) {
    with (instance_create_depth(_x1, _y1, -15002, obj_fx)) { kind = "bolt"; x2 = _x2; y2 = _y2; col = _col; life = 10; }
}
function dmg_number(_x, _y, _v, _crit) {
    with (instance_create_depth(_x, _y, -15003, obj_dmgnum)) { val = _v; crit = _crit; }
}

// ======================================================================
// ---- damage helpers ----
// ======================================================================
function heal_player(_n) {
    if (!instance_exists(obj_player)) return;
    with (obj_player) {
        var over = hp + _n - max_hp;
        hp = min(max_hp, hp + _n);
        if (over > 0 && has_duo("feast")) shield = min(25, shield + over);
    }
}
function in_list(_arr, _v) {
    for (var i = 0; i < array_length(_arr); i++) if (_arr[i] == _v) return true;
    return false;
}
// knock everything near (_x, _y) away and hurt it
function explode(_x, _y, _r, _dmg, _col) {
    with (obj_enemy) {
        if (!dead && point_distance(x, hit_y(id, _y), _x, _y) < _r) {
            take_damage(_dmg, false);
            kb_dir = point_direction(_x, _y, x, bbox_bottom - 5);
            kb_speed = max(kb_speed, 3);
        }
    }
    fx_ring(_x, _y, _r, _col);
    fx("ember", _x, _y, 24);
    fx("smoke", _x, _y, 8);
    shake(4);
    hitstop(2);
}
// Chain Lightning: hops from enemy to enemy
function chain_lightning(_src, _dmg, _n) {
    var sx = _src.x, sy = _src.bbox_bottom - 10;
    var done = [_src];
    var reach = has_duo("storm") ? 110 : 80;
    for (var k = 0; k < _n; k++) {
        var best = noone, bd = reach;
        with (obj_enemy) {
            if (!dead && !in_list(done, id)) {
                var d = point_distance(x, bbox_bottom - 10, sx, sy);
                if (d < bd) { bd = d; best = id; }
            }
        }
        if (best == noone) break;
        fx_bolt(sx, sy, best.x, best.bbox_bottom - 10, make_color_rgb(150, 200, 255));
        fx("zap", best.x, best.bbox_bottom - 10, 6);
        with (best) {
            take_damage(_dmg, false);
            if (has_duo("storm") && object_index != obj_boss) stun = max(stun, 30);
        }
        array_push(done, best);
        sx = best.x;
        sy = best.bbox_bottom - 10;
    }
}
// Thunder Step: lightning around the hero's feet
function thunder_ring(_x, _y) {
    var lv = blv(1, "thunder");
    if (lv <= 0) return;
    var r = 36 + 12 * lv, dmg = 6 + 4 * lv, st = 15 + 10 * lv;
    if (has_duo("storm")) r *= 1.4;
    var col = make_color_rgb(150, 200, 255);
    with (obj_enemy) {
        if (!dead && point_distance(x, hit_y(id, _y), _x, _y) < r) {
            fx_bolt(_x, _y - 40, x, bbox_bottom - 10, col);
            take_damage(dmg, false);
            if (object_index != obj_boss) stun = max(stun, st);
        }
    }
    repeat (5) {
        var a = random(360);
        fx_bolt(_x, _y, _x + lengthdir_x(r, a), _y + lengthdir_y(r * 0.6, a), col);
    }
    fx_ring(_x, _y, r, col);
    fx("zap", _x, _y, 16);
    shake(3);
    flash(col, 0.12);
}
// every hit from player 2's sword goes through here (held swing, detached swing, recall, orbit)
function sword_hit(_e, _dmg, _src) {
    if (_e.dead) return;
    var d = _dmg * (1 + 0.25 * blv(2, "edge"));
    var crit = false;
    var w = instance_exists(obj_weapon) ? obj_weapon : noone;
    if (w != noone && w.fury_t > 0) d *= 1.4;                       // Fury Draught
    if (w != noone && w.whet > 0) { d *= 2; w.whet -= 1; fx("zap", _e.x, _e.bbox_bottom - 10, 8); }   // Whetstone Step
    // STAGGER (from a kick) opens enemies up; a GUARD blocks most of the damage until it's broken
    if (_e.stagger > 0) {
        d *= 1.5;
        add_bond(5);
    } else if (_e.guarded) {
        d *= 0.3;
        with (_e) take_damage(d, -1);                                // grey "blocked" number
        fx("spark", _e.x, _e.bbox_bottom - 14, 3);
        return;
    }
    var ex = blv(2, "executioner");
    if (ex > 0 && (_e.stun > 0 || _e.kb_speed > 0.5)) {
        d *= 1.5 + 0.5 * ex;
        crit = true;
    }
    with (_e) take_damage(d, crit);
    fx("spark", _e.x, _e.bbox_bottom - 10, crit ? 16 : 6);
    shake(crit ? 3 : 1);
    if (crit) hitstop(4);
    if (crit && ex >= 3 && _e.dead) explode(_e.x, _e.bbox_bottom - 6, 36, 10, make_color_rgb(255, 200, 80));

    var ch = blv(2, "chain");
    if (ch > 0) chain_lightning(_e, d * 0.5, ch + (has_duo("storm") ? 1 : 0));

    var be = blv(2, "bloodedge");
    if (be > 0) heal_player(min(be, 2));
    if (be >= 3 && _e.dead && _e.drop_chance > 0) instance_create_layer(_e.x, _e.bbox_bottom - 4, "Instances", obj_pickup);

    // the hits feed player 1's soul mark (much faster inside a shrine, for the lesson)
    var gain = 12 * (1 + 0.25 * blv(1, "soulbloom"));
    if (instance_exists(obj_game) && obj_game.shrine_room) gain *= 3;
    if (instance_exists(obj_player)) obj_player.cast_charge = min(100, obj_player.cast_charge + gain);

    if (instance_exists(obj_weapon)) with (obj_weapon) add_combo();
}

// ======================================================================
// ---- debug: jump straight to any room (F1 / ` menu in obj_juice) ----
// ======================================================================
function debug_jump(_k) {
    var keep_tut = global.tutorial_done;
    reset_run();
    global.tutorial_done = (_k > 1) ? true : keep_tut;
    if (_k >= 2) global.cleared[$ "rm_chamber_1"] = true;
    if (_k >= 3) { global.shrine_done[1] = true; global.dash_unlocked = true; give_random_boons(); }
    if (_k >= 4) global.cleared[$ "rm_chamber_2"] = true;
    if (_k >= 5) { global.shrine_done[2] = true; global.cast_unlocked = true; give_random_boons(); }
    if (_k >= 6) global.cleared[$ "rm_boss"] = true;
    var rooms = [rm_chamber_1, rm_shrine_1, rm_chamber_2, rm_shrine_2, rm_boss, rm_shrine_3];
    room_goto(rooms[_k - 1]);
}
// Backspace: skip the current dialogue / tutorial / shrine lesson straight to the fighting or the boon choice
function debug_skip() {
    with (obj_dialogue) instance_destroy();
    if (!instance_exists(obj_boonselect)) global.freeze = false;
    with (obj_tutorial) skip();
    with (obj_shrine) skip();
}

// ======================================================================
// ---- Bond Strike: the duo spell. Teamwork fills the meter; both players press their Bond key together ----
// ======================================================================
global.bond = 0;                 // 0-100
global.allow_bond = true;
function add_bond(_n) { global.bond = min(100, global.bond + _n); }

// ---- player 2's keys: IJKL fly the sword, LEFT = attack, RIGHT = fly out / return, UP = Bond ----
function p2_move_x() { return keyboard_check(ord("L")) - keyboard_check(ord("J")); }
function p2_move_y() { return keyboard_check(ord("K")) - keyboard_check(ord("I")); }
function p2_attack_pressed() { return keyboard_check_pressed(vk_left); }
function p2_detach_pressed() { return keyboard_check_pressed(vk_right); }
function p2_bond_pressed() { return keyboard_check_pressed(vk_up); }

// a crescent swoosh (the kick); drawn by obj_fx kind "arc"
function fx_arc(_x, _y, _dir, _r, _half, _col) {
    with (instance_create_depth(_x, _y, -15002, obj_fx)) { kind = "arc"; dir = _dir; rmax = _r; half = _half; col = _col; life = 10; }
}

// shortest distance from point (px, py) to the segment (x1, y1)-(x2, y2)
function dist_to_segment(_px, _py, _x1, _y1, _x2, _y2) {
    var dx = _x2 - _x1, dy = _y2 - _y1;
    var l2 = dx * dx + dy * dy;
    var t = (l2 == 0) ? 0 : clamp(((_px - _x1) * dx + (_py - _y1) * dy) / l2, 0, 1);
    return point_distance(_px, _py, _x1 + t * dx, _y1 + t * dy);
}

global.bond_hint_seen = false;   // the first full Bond meter shows a banner once per game

// the height on an enemy's body closest to an attack at height _py: the feet for most enemies,
// anywhere from feet to head for tall ones (hit_h). Hit checks measure to this point.
function hit_y(_e, _py) { return clamp(_py, _e.bbox_bottom - 5 - _e.hit_h, _e.bbox_bottom - 5); }
