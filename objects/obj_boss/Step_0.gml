if (paused()) exit;   // dialogue open

if (hit_flash > 0) hit_flash -= 1;
kb_speed = 0;                      // kicks don't push the Warden
if (stun > 60) stun = 60;          // a cast staggers it for at most 1 s
depth = -bbox_bottom;
if (dead || !instance_exists(obj_player)) exit;
var p = obj_player;

if (stun > 0 && bstate != "break" && bstate != "intro") {
    stun -= 1;
    image_speed = 0;
    exit;
}
if (bstate != "aim") image_speed = 1;
if (summon_cd > 0 && bstate != "intro" && bstate != "break") summon_cd -= 1;

switch (bstate) {
    case "intro":
        sprite_index = idle_sprite;
        timer -= 1;
        if (timer <= 0) { bstate = "chase"; timer = 60; }
        break;

    case "chase":
        var d = point_distance(x, bbox_bottom, p.x, p.bbox_bottom);
        if (d > 44) {
            if (sprite_index != walk_sprite) { sprite_index = walk_sprite; image_index = 0; }
            var dir = point_direction(x, bbox_bottom, p.x, p.bbox_bottom);
            var mx = lengthdir_x(move_speed, dir), my = lengthdir_y(move_speed, dir);
            if (!place_meeting(x + mx, y, obj_wall)) x += mx;
            if (!place_meeting(x, y + my, obj_wall)) y += my;
            if (mx != 0) image_xscale = art_scale * art_faces * sign(mx);
        } else if (sprite_index != idle_sprite) {
            sprite_index = idle_sprite;
            image_index = 0;
        }
        if (summon_cd <= 0) {
            summon_cd = (phase == 1) ? 600 : 480;
            with (obj_game) start_wave([obj_rat, obj_rat]);
        }
        timer -= 1;
        if (timer <= 0) choose_attack();
        break;

    case "attack":
        // fire on the listed animation frames (the rest happens in Animation End)
        if (fi < array_length(fire_frames) && image_index >= fire_frames[fi]) {
            attack_effect();
            fi += 1;
        }
        break;

	case "aim":
	    timer -= 1;
	    if (timer <= 0) {
	        bstate = "charge";
	        timer = 45;
	        charge_hit = false;
	        image_speed = 1;

	        // Play boss charge sound
	        audio_play_sound(boss_charge, 1, false);
	    }
	    break;

    case "charge":
        var cx = lengthdir_x(5, charge_dir), cy = lengthdir_y(5, charge_dir);
        var stopped = false;
        if (!place_meeting(x + cx, y, obj_wall)) x += cx; else stopped = true;
        if (!place_meeting(x, y + cy, obj_wall)) y += cy; else stopped = true;
        if (image_index >= 4) image_index = 2;          // loop the rush frames
        if (!charge_hit && p.z < 6 && point_distance(x, bbox_bottom - 10, p.x, p.bbox_bottom - 6) < 28) {
            if (hurt_player(p, 18)) charge_hit = true;
        }
        timer -= 1;
        if (timer <= 0 || stopped) {
            ring(2.0, 10, 90, 0);
            shake(stopped ? 6 : 3);
            bstate = "recover";
            timer = 40;
            sprite_index = idle_sprite;
        }
        break;

    case "recover":
        if (sprite_index != idle_sprite) { sprite_index = idle_sprite; image_index = 0; }
        timer -= 1;
        if (timer <= 0) {
            bstate = "chase";
            timer = (phase == 1) ? irandom_range(50, 80) : irandom_range(30, 55);
        }
        break;
}
