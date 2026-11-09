if (paused()) exit;              // dialogue open or hit-stop
if (!instance_exists(obj_player)) exit;
var p = obj_player;
float_t += 1;
if (swing_cd > 0) swing_cd -= 1;
if (swing_t > 0) swing_t -= 1;
if (combo_t > 0) { combo_t -= 1; if (combo_t == 0) combo = 0; }
var attack = p2_attack() && global.allow_attack;
var detach = p2_detach() && global.allow_detach;

if (p.state == "dead") {
    state = "held";
}

// ---- Whirling Return: circle the hero ----
if (state == "orbit") {
    orbit_t -= 1;
    orbit_ang += 12;
    x = p.x + lengthdir_x(24, orbit_ang);
    y = p.y + 6 + lengthdir_y(14, orbit_ang);
    swing_dir = orbit_ang + 90;
    var od = 5 + 2 * blv(2, "orbit"), ox = x, oy = y;
    with (obj_enemy) {
        if (orbit_cd > 0) orbit_cd -= 1;
        if (!dead && orbit_cd <= 0 && point_distance(x, bbox_bottom - 5, ox, oy) < 16) {
            orbit_cd = 15;
            sword_hit(id, od, "orbit");
        }
    }
    if (float_t mod 3 == 0) fx("zap", x, y - hover, 1);
    if (orbit_t <= 0 || attack || detach) state = "held";     // P2 can cut it short and act this frame
}

if (state == "held") {
    x = p.x;
    y = p.y;
    if (attack) with (p) start_slash();
    if (detach && p.state != "dead") {
        state = "out";
        hsp = 0;
        vsp = 0;
        swing_dir = p.facing * 45;
    }
}
else if (state == "out") {
    // fly freely (no collision: floats over pits and cover)
    var ix = keyboard_check(vk_right) - keyboard_check(vk_left);
    var iy = keyboard_check(vk_down) - keyboard_check(vk_up);
    var len = point_distance(0, 0, ix, iy);
    if (len > 0) {
        ix /= len;
        iy /= len;
        swing_dir = point_direction(0, 0, ix, iy);
    }
    hsp = approach(hsp, ix * move_speed, accel);
    vsp = approach(vsp, iy * move_speed, accel);
    x += hsp;
    y += vsp;

    // tether: never further than the leash allows
    var d = point_distance(p.x, p.y, x, y);
    if (d > tether) {
        var a = point_direction(p.x, p.y, x, y);
        x = p.x + lengthdir_x(tether, a);
        y = p.y + lengthdir_y(tether, a);
    }
    x = clamp(x, 8, room_width - 8);
    y = clamp(y, 8, room_height - 8);

    // swing on its own: a hitbox at the weapon's ground point, reduced damage (faster with a Frenzy combo)
    if (attack && swing_cd <= 0) {
        swing_cd = round(swing_cd_max / (1 + 0.05 * min(combo, 10) * blv(2, "frenzy")));
        swing_t = 10;
        make_slash(x + lengthdir_x(8, swing_dir), y + lengthdir_y(8, swing_dir), max(1, p.slash_damage * detached_mult));
        var snd = audio_play_sound(slash_sound, 1, false);
        audio_sound_set_track_position(snd, 0);
    }
    if (detach) start_recall(false);
}
else if (state == "recall") {
    var a = point_direction(x, y, p.x, p.y);
    if (point_distance(x, y, p.x, p.y) <= recall_speed) {
        var ol = blv(2, "orbit");
        if (recall_hurts && ol > 0) {            // Whirling Return
            state = "orbit";
            orbit_t = 60 * ol;
            orbit_ang = point_direction(p.x, p.y, x, y);
        } else {
            state = "held";
            x = p.x;
            y = p.y;
        }
    } else {
        x += lengthdir_x(recall_speed, a);
        y += lengthdir_y(recall_speed, a);
        swing_dir = a;
        if (recall_hurts) {
            if (float_t mod 2 == 0) fx("spark", x, y - hover, 1);
            var rid = recall_id, dmg = recall_damage;
            with (obj_enemy) {
                if (!dead && recall_mark != rid && point_distance(x, bbox_bottom - 5, other.x, other.y) < 16) {
                    recall_mark = rid;
                    kb_dir = a;
                    kb_speed = max(kb_speed, 2.5);
                    sword_hit(id, dmg, "recall");
                }
            }
        }
    }
}

// collect soul orbs wherever the weapon is (it can reach the ones over the void)
with (obj_pickup) if (point_distance(x, y, other.x, other.y) < 14) collect();
