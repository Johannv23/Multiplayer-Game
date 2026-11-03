if (!instance_exists(obj_player)) exit;
var p = obj_player;
float_t += 1;
if (swing_cd > 0) swing_cd -= 1;
if (swing_t > 0) swing_t -= 1;
var attack = p2_attack();
var detach = p2_detach();

if (p.state == "dead") {
    state = "held";
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

    // tether: never more than 5 m from the character
    var d = point_distance(p.x, p.y, x, y);
    if (d > tether) {
        var a = point_direction(p.x, p.y, x, y);
        x = p.x + lengthdir_x(tether, a);
        y = p.y + lengthdir_y(tether, a);
    }
    x = clamp(x, 8, room_width - 8);
    y = clamp(y, 8, room_height - 8);

    // swing on its own: a hitbox at the weapon's ground point, reduced damage
    if (attack && swing_cd <= 0) {
        swing_cd = 20;
        swing_t = 10;
        var half = sprite_get_width(slash_hitbox) / 2;
        var sx = x + lengthdir_x(8, swing_dir), sy = y + lengthdir_y(8, swing_dir);
        var s = instance_create_layer(sx - half, sy - half, "Instances", obj_slash);
        s.damage = max(1, round(p.slash_damage * detached_mult));
        var snd = audio_play_sound(slash_sound, 1, false);
        audio_sound_set_track_position(snd, 0);
    }
    if (detach) start_recall(false);
}
else if (state == "recall") {
    var a = point_direction(x, y, p.x, p.y);
    if (point_distance(x, y, p.x, p.y) <= recall_speed) {
        state = "held";
        x = p.x;
        y = p.y;
    } else {
        x += lengthdir_x(recall_speed, a);
        y += lengthdir_y(recall_speed, a);
        swing_dir = a;
        if (recall_hurts) {
            var rid = recall_id, dmg = recall_damage;
            with (obj_enemy) {
                if (!dead && recall_mark != rid && point_distance(x, bbox_bottom - 5, other.x, other.y) < 16) {
                    recall_mark = rid;
                    take_damage(dmg);
                    kb_dir = a;
                    kb_speed = 2.5;
                    with (obj_player) cast_charge = min(100, cast_charge + 12);
                }
            }
        }
    }
}

// collect soul orbs wherever the weapon is (it can reach the ones over the void)
with (obj_pickup) if (point_distance(x, y, other.x, other.y) < 14) collect();
