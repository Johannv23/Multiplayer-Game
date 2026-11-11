// ---- tuning ----
// (the camera shows 320x180 at 4x, so 1 world pixel = 4 screen pixels)
max_speed = 1.5;        // pixels per frame at full speed
accel     = 0.25;       // how fast we speed up (~6 frames to full speed)
fric      = 0.2;        // how fast we slow down with no input

jump_grav  = 0.19;      // pulls z back down each frame
jump_speed = 3;         // peak = v*v / (2*grav) = ~24px (3/4 of the character), ~16 frames up + 16 down
slash_fric = 0.15;      // how fast we stop while swinging

scale = 1;              // art size multiplier (1 = pixel-perfect with the 16px tiles)

// ---- state ----
hsp = 0;                // horizontal speed
vsp = 0;                // vertical speed
z = 0;                  // height above the ground (drawn as an upward offset; walls still block)
zspd = 0;               // vertical speed of the jump, positive = rising
air_time = 2 * jump_speed / jump_grav;  // frames from takeoff to landing, times the flip
jump_timer = 0;         // frames since takeoff
state = "move";         // "move", "jump" or "slash"
facing = 6;             // 0-7, one step per 45 degrees: 0 right, 2 up, 4 left, 6 down
face_x = 1;             // last horizontal direction (1 or -1), picks the slash side when facing straight up/down
slash_dir = 3;          // index into slash_sprites / sword_sprites

// ---- sprites, indexed by facing (counter-clockwise from right, like point_direction) ----
walk_sprites = [spr_player_right, spr_player_upright, spr_player_up, spr_player_upleft,
            spr_player_left, spr_player_downleft, spr_player_down, spr_player_downright];
// the roll strip doubles as the jump's front flip
flip_sprites = [spr_player_roll_right, spr_player_roll_upright, spr_player_roll_up, spr_player_roll_upleft,
            spr_player_roll_left, spr_player_roll_downleft, spr_player_roll_down, spr_player_roll_downright];

// slash art only exists for the 4 diagonals: 0 up-right, 1 up-left, 2 down-left, 3 down-right
slash_sprites = [spr_player_slash_upright, spr_player_slash_upleft, spr_player_slash_downleft, spr_player_slash_downright];
sword_sprites = [spr_sword_upright, spr_sword_upleft, spr_sword_downleft, spr_sword_downright];

// fixed 12x12 hitbox at the feet so animation frames never change collision
mask_index = spr_player_mask;
image_xscale = scale;
image_yscale = scale;
sprite_index = walk_sprites[facing];
image_index = 0;
image_speed = 0;

// Health bar
max_hp = 100;
hp = max_hp;

// Slash damage
slash_damage = 10;
slash_hit = false;

// Slash sound
slash_sound_id = -1;
// red flash when hit (frames)
hurt_flash = 0;

invuln = 0;             // frames of invulnerability (dash, stomp, after a hit)
sx = 1;                 // squash & stretch (draw only), eases back to 1
sy = 1;
shield = 0;             // Soul Feast duo: overheal shield
last_stand = false;     // Iron Heart Lv3: survive one lethal hit per room

// ---- dash: Shadowstep (player 1, restored in the first Reliquary) ----
dash_speed  = 4.5;
dash_frames = 9;        // ~40px
dash_timer  = 0;
dash_cd_max = 36;       // frames to recharge one dash charge
dash_recharge = 0;
dash_charges_max = 1;
dash_charges = 1;
dash_dir    = 0;
dash_id     = 0;        // each dash slices an enemy once (Phantom Step)
ghosts = [];            // afterimages: [x, y, sprite, frame]
thunder_cd  = 0;        // Thunder Step cooldown
double_used = false;    // Moon Jump Lv3

// ---- kick (player 1): shoves enemies; next to a pit it kills them ----
kick_range  = 30;
kick_force  = 5;
kick_damage = 3;
kick_cd     = 0;
kick_cd_max = 30;
kick_timer  = 0;        // > 0 while the kick arc is drawn
kick_dir    = 0;
kick_landed = false;    // set when a kick connects (the tutorial watches it)
cannon_lv   = 0;

// ---- cast: Soul Mark (restored in the second Reliquary): charges when the weapon lands hits ----
cast_charge = 0;        // 0-100

asc_t = 0;              // Soul Ascension timer
asc_len = 60;           // frames spent rising and spinning before the nova
bond_t = 0;             // Bond Strike timer
bond1_t = 0;            // frames since P1 pressed Bond (both must press within half a second)
bond2_t = 0;            // frames since P2 pressed Bond (set by obj_weapon)

// ---- Meteor Fall (restored in the third Reliquary): E in mid-air ----
stomp_hits = 0;         // the shrine lesson counts these
heavy_lv = 0;           // Heavy Boots level
bond_hint_t = 0;        // the first full Bond meter gets a big banner
drink_t = 0;            // Fury Draught: > 0 while the potion is drawn at the hero's lips
whet_mark = -1;         // Whetstone Step: the dash that last sharpened the sword

// Walking sound
walk_sound_id = -1;

// stats that come from boons; called again whenever a boon is chosen
function apply_boons() {
    var ih = blv(1, "ironheart");
    max_hp = 100 + 20 * ih;
    var m = blv(1, "moonjump");
    jump_speed = 3 * (1 + 0.12 * m);
    jump_grav = 0.19 * (1 - 0.1 * m);
    air_time = 2 * jump_speed / jump_grav;
    cannon_lv = blv(1, "cannon");
    kick_force = 5 * (1 + 0.4 * cannon_lv);
    kick_cd_max = round(30 * (1 - 0.25 * cannon_lv));
    kick_damage = 3 + 3 * cannon_lv;
    dash_charges_max = 1 + blv(1, "phantom");
    max_speed = 1.5 * (1 + 0.12 * blv(1, "swift"));            // Swift Feet
    heavy_lv = blv(1, "heavy");                                 // Heavy Boots
    kick_force *= 1 + 0.25 * heavy_lv;
    dash_charges = dash_charges_max;
    last_stand = (ih >= 3);
}
apply_boons();
hp = (global.player_hp > 0) ? min(global.player_hp, max_hp) : max_hp;   // HP carries between rooms

// player 2's weapon
if (!instance_exists(obj_weapon)) instance_create_layer(x, y, "Instances", obj_weapon);

// ---- called by obj_weapon when player 2 attacks while the weapon is held ----
function start_slash() {
    if (state != "move") return;
    // pick the closest diagonal: facing 1-3 is "up", face_x picks left or right
    var up = (facing >= 1 && facing <= 3);
    if (up) slash_dir = (face_x > 0) ? 0 : 1;
    else    slash_dir = (face_x > 0) ? 3 : 2;
    state = "slash";
    slash_hit = false;
    set_anim(slash_sprites[slash_dir]);   // ends in Animation End
    // Frenzy: a running combo speeds the swing up
    // a quicker swing than before (1.6x); a Frenzy combo speeds it up further
    image_speed = 1.6 * (1 + 0.15 * blv(2, "honed"));                    // Honed Grip
    if (instance_exists(obj_weapon)) {
        image_speed *= 1 + 0.05 * min(obj_weapon.combo, 10) * blv(2, "frenzy");
        if (obj_weapon.fury_t > 0) image_speed *= 1.3;                  // Fury Draught
    }

    slash_sound_id = audio_play_sound(slash_sound, 1, false);
    audio_sound_set_track_position(slash_sound_id, 0);

    // player 1 aims (facing, 8 directions), player 2 swings: one sweeping arc in front of the hero
    var sd = slash_damage, ang = facing * 45, ax = x, ay = y + 6;
    with (obj_weapon) make_slash(ax, ay, sd, ang, 34, 80);
}

function start_dash(_ix, _iy, _len) {
    dash_charges -= 1;
    state = "dash";
    dash_timer = dash_frames;
    dash_dir = (_len > 0) ? point_direction(0, 0, _ix, _iy) : facing * 45;
    facing = round(dash_dir / 45) mod 8;
    dash_id += 1;
    sx = 1.35;
    sy = 0.75;
    fx("smoke", x, bbox_bottom, 4);
    shake(1);
}

function end_dash() {
    if (blv(1, "afterburn") >= 3) explode(x, bbox_bottom - 6, 40, 15, make_color_rgb(255, 140, 40));
    if (thunder_cd <= 0 && blv(1, "thunder") > 0) { thunder_ring(x, bbox_bottom - 6); thunder_cd = 40; }
}

function land() {
    sx = 1.3;
    sy = 0.72;
    fx("smoke", x, bbox_bottom, 4);
    if (thunder_cd <= 0 && blv(1, "thunder") > 0) { thunder_ring(x, bbox_bottom - 6); thunder_cd = 40; }
}

// Meteor Fall: crash down from a jump
function land_stomp() {
    var m = blv(1, "meteor");
    var r = 50 * (1 + 0.2 * m), dmg = (m >= 3) ? 24 : 12;
    var cx = x, cy = bbox_bottom - 6, n = 0;
    with (obj_enemy) {
        if (!dead && point_distance(x, hit_y(id, cy), cx, cy) < r) {
            take_damage(dmg, false);
            kb_dir = point_direction(cx, cy, x, bbox_bottom - 5);
            kb_speed = max(kb_speed, 4);
            if (object_index != obj_boss) stun = max(stun, 30);
            n += 1;
        }
    }
    stomp_hits += n;
    if (m >= 2) for (var i = 0; i < 8; i++) {
        instance_create_layer(cx + lengthdir_x(r * 0.7, i * 45), cy + lengthdir_y(r * 0.45, i * 45), "Instances", obj_fire, { lv: m });
    }
    fx_ring(cx, cy, r, make_color_rgb(255, 160, 70));
    fx("ember", cx, cy, 30);
    fx("smoke", cx, cy, 12);
    fx("shard", cx, cy, 14);
    shake(8);
    hitstop(5);
    flash(make_color_rgb(255, 160, 80), 0.25);
    sx = 1.5;
    sy = 0.6;
    if (thunder_cd <= 0 && blv(1, "thunder") > 0) { thunder_ring(cx, cy); thunder_cd = 40; }
}

function do_kick() {
    kick_cd = kick_cd_max;
    kick_timer = 10;
    kick_dir = facing * 45;
    // lunge into it, with a golden crescent swoosh
    hsp += lengthdir_x(2.5, kick_dir);
    vsp += lengthdir_y(2.5, kick_dir);
    fx_arc(x, bbox_bottom - 4, kick_dir, kick_range + 6, 70, make_color_rgb(255, 215, 120));
    fx("smoke", x, bbox_bottom, 4);
    var kx = x, ky = bbox_bottom - 6, kdir = kick_dir, hit = false;
    with (obj_enemy) {
        var ex = x, ey = hit_y(id, ky);
        var kd_ = point_distance(kx, ky, ex, ey);
        if (!dead && kd_ < other.kick_range
            && (kd_ < 10 || abs(angle_difference(point_direction(kx, ky, ex, ey), kdir)) < 75)) {
            interrupt();
            other.kick_landed = true;
            hit = true;
            if (object_index == obj_boss) {           // the Warden doesn't budge, but it can be staggered
                if (stagger_cd <= 0) {
                    stagger = 90;
                    stagger_cd = 240;
                    dmg_number(ex, ey - 70, "STAGGER", true);
                    fx_ring(ex, ey, 40, make_color_rgb(255, 210, 80));
                }
            } else {
                if (guarded && stagger <= 0) {        // breaking a guard gets its own flourish
                    dmg_number(ex, ey - 30, "GUARD BREAK", true);
                    fx_ring(ex, ey, 24, make_color_rgb(255, 210, 80));
                }
                kb_dir = point_direction(kx, ky, ex, ey);
                kb_speed = other.kick_force;
                missile = 1 + other.cannon_lv;        // kicked enemies bowl into others
                missile_mark = noone;
                stun = max(stun, 30);
                stagger = round(stagger_max * ((other.heavy_lv >= 3) ? 2 : 1 + 0.25 * other.heavy_lv));
            }
            take_damage(other.kick_damage, false);
            add_bond(8);
            fx("spark", ex, ey - 6, 10);
        }
    }
    sx = 1.35;
    sy = 0.75;
    if (hit) {                                   // the impact: a freeze, a thump, a burst
        hitstop(4);
        shake(3);
        fx("spark", kx + lengthdir_x(18, kdir), ky + lengthdir_y(18, kdir), 12);
        fx_ring(kx + lengthdir_x(18, kdir), ky + lengthdir_y(18, kdir), 18, make_color_rgb(255, 230, 160));
    }
}

// ---- Soul Ascension (Q, when the soul mark is full) ----
// The hero rises, spins, eyes blazing, untouchable for a second - then a soul nova roots,
// staggers and damages everything around him.
function do_cast() {
    cast_charge = 0;
    state = "ascend";
    asc_t = 0;
    hsp = 0;
    vsp = 0;
    fx("soul", x, y, 20);
    flash(make_color_rgb(200, 120, 255), 0.15);
}
function soul_nova() {
    var r = 80 * (1 + 0.25 * blv(1, "soulbloom"));
    var cx = x, cy = bbox_bottom - 6;
    with (obj_enemy) {
        if (!dead && point_distance(x, hit_y(id, cy), cx, cy) < r) {
            interrupt();
            stagger = max(stagger, 120);
            if (object_index != obj_boss) {
                stun = max(stun, 100);
                root_t = 100;
                root_bloom = (blv(1, "soulbloom") >= 3);
                kb_dir = point_direction(cx, cy, x, bbox_bottom - 5);
                kb_speed = 3;
            } else stun = max(stun, 45);
            take_damage(18, false);
        }
    }
    fx_ring(cx, cy, r, make_color_rgb(200, 120, 255));
    fx_ring(cx, cy, r * 0.6, make_color_rgb(255, 180, 255));
    fx("soul", cx, cy, 40);
    flash(make_color_rgb(200, 120, 255), 0.35);
    slowmo(18);
    shake(7);
    hitstop(4);
}

// ---- Bond Strike: both players press their Bond key (P1 F, P2 UP) when the meter is full ----
function start_bond() {
    global.bond = 0;
    state = "bond";
    bond_t = 0;
    hsp = 0;
    vsp = 0;
    bond1_t = 0;
    bond2_t = 0;
    with (obj_weapon) { state = "bond"; orbit_ang = 0; }
    flash(make_color_rgb(255, 230, 150), 0.3);
    fx("spark", x, y, 20);
    shake(3);
}
function bond_slam() {
    var r = 120, cx = x, cy = bbox_bottom - 6;
    with (obj_enemy) {
        if (!dead && point_distance(x, hit_y(id, cy), cx, cy) < r) {
            stagger = max(stagger, 150);
            if (object_index != obj_boss) {
                kb_dir = point_direction(cx, cy, x, bbox_bottom - 5);
                kb_speed = 5;
                stun = max(stun, 40);
            }
            take_damage(35, true);
        }
    }
    fx_ring(cx, cy, r, make_color_rgb(255, 215, 120));
    fx_ring(cx, cy, r * 0.7, c_white);
    fx_ring(cx, cy, r * 0.4, make_color_rgb(150, 230, 255));
    fx("spark", cx, cy, 40);
    fx("ember", cx, cy, 30);
    fx("soul", cx, cy, 20);
    flash(c_white, 0.7);
    slowmo(35);
    shake(10);
    hitstop(6);
}

// ---- Fury Draught: recalling the sword makes the hero drink - and the SWORD gets the fury ----
function drink_fury() {
    var lv = blv(1, "fury");
    if (lv <= 0) return;
    drink_t = 30;
    with (obj_weapon) fury_t = 60 * (2 + 2 * lv);                // 4 / 6 / 8 seconds
    dmg_number(x, y - 34, "FURY!", true);
    fx("ember", x, y - 14, 14);
    fx_ring(x, bbox_bottom - 6, 26, make_color_rgb(255, 80, 40));
    flash(make_color_rgb(255, 60, 30), 0.18);
    shake(2);
}
