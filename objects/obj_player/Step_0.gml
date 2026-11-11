// ---- input: player 1 = WASD move, Space jump, E kick, R recall weapon, Shift dash, Q cast ----
// (arrows, / and . belong to player 2's weapon)
var ix = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var iy = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var jump_pressed   = keyboard_check_pressed(vk_space);
var kick_pressed   = keyboard_check_pressed(ord("E"));
var recall_pressed = keyboard_check_pressed(ord("R"));
var dash_pressed   = keyboard_check_pressed(vk_shift);
var cast_pressed   = keyboard_check_pressed(ord("Q"));
var bond_pressed   = keyboard_check_pressed(ord("F")) && global.allow_bond;

// ---- tutorial locks ----
if (!global.allow_move) { ix = 0; iy = 0; }
jump_pressed   = jump_pressed && global.allow_jump;
kick_pressed   = kick_pressed && global.allow_kick;
recall_pressed = recall_pressed && global.allow_recall;

// ---- hit-stop: hold this exact frame ----
if (global.hitstop_t > 0) exit;

// ---- dialogue open: stand still ----
if (global.freeze) {
    hsp = 0;
    vsp = 0;
    if (state == "move") { image_speed = 0; image_index = 0; }
    if (walk_sound_id != -1) { audio_stop_sound(walk_sound_id); walk_sound_id = -1; }   // no footsteps during dialogue
    exit;
}

if (invuln > 0) invuln -= 1;
if (bond1_t > 0) bond1_t -= 1;
if (bond2_t > 0) bond2_t -= 1;
if (bond_pressed) bond1_t = 30;
if (global.bond >= 100 && !global.bond_hint_seen) { global.bond_hint_seen = true; bond_hint_t = 240; }
if (bond_hint_t > 0) bond_hint_t -= 1;
if (hurt_flash > 0) hurt_flash -= 1;
if (kick_cd > 0) kick_cd -= 1;
if (kick_timer > 0) kick_timer -= 1;
if (thunder_cd > 0) thunder_cd -= 1;
// dash charges refill one at a time
if (dash_charges < dash_charges_max) {
    dash_recharge += 1;
    if (dash_recharge >= dash_cd_max) { dash_charges += 1; dash_recharge = 0; }
}
// squash & stretch settles back
sx = lerp(sx, 1, 0.2);
sy = lerp(sy, 1, 0.2);

// ---- death: Enter starts a new run ----
hp = clamp(hp, 0, max_hp);
if (hp <= 0 && state != "dead") {
    state = "dead";
    hsp = 0; vsp = 0; z = 0;
    image_speed = 0;
}
if (state == "dead") {
    if (keyboard_check_pressed(vk_enter)) {
        reset_run();
        room_goto(rm_chamber_1);
    }
    exit;
}

// ---- normalize so diagonals aren't faster ----
var len = point_distance(0, 0, ix, iy);
if (len > 0) {
    ix /= len;
    iy /= len;
}

if (state == "move" || state == "jump") {
    // face the input direction, snapped to 8 steps of 45 degrees
    if (len > 0) {
        facing = round(point_direction(0, 0, ix, iy) / 45) mod 8;
        if (ix != 0) face_x = sign(ix);
    }

    // ---- accelerate toward the target velocity, or apply friction (full control in the air too) ----
    var target_h = ix * max_speed;
    var target_v = iy * max_speed;
    var rate_h = (ix != 0) ? accel : fric;
    var rate_v = (iy != 0) ? accel : fric;

    hsp = approach(hsp, target_h, rate_h);
    vsp = approach(vsp, target_v, rate_v);
}

if (state == "move") {
    if (jump_pressed) {
        state = "jump";
        zspd = jump_speed;      // set, not add, so every jump is identical
		
		// Play jump sound
        var jump_sound_id = audio_play_sound(player_jump, 1, false);
		audio_sound_gain(jump_sound_id, 0.3, 0);
		
        jump_timer = 0;
        double_used = false;
        sx = 0.8;
        sy = 1.25;
        fx("smoke", x, bbox_bottom, 3);
    }
    else if (dash_pressed && global.dash_unlocked && dash_charges >= 1) {
        start_dash(ix, iy, len);
    }
    else if (kick_pressed && kick_cd <= 0) {
        do_kick();
    }
    else if (cast_pressed && global.cast_unlocked && cast_charge >= 100) {
        do_cast();
    }
}
else if (state == "jump") {
    // Moon Jump Lv3: one more jump in mid-air
    if (jump_pressed && !double_used && blv(1, "moonjump") >= 3) {
        double_used = true;
        zspd = jump_speed * 0.9;
        fx("spark", x, y - z + 8, 8);
        sx = 0.8;
        sy = 1.25;
    }
    // Meteor Fall: E in mid-air
    else if (kick_pressed && global.stomp_unlocked && z > 6) {
        state = "stomp";
        zspd = 2;                // a tiny hop up first, then down hard
        invuln = max(invuln, 30);
    }
}
else if (state == "slash") {
    // keep walking (slowly) while the sword swings; the facing - the aim - stays put
    hsp = approach(hsp, ix * max_speed * 0.5, (ix != 0) ? accel : slash_fric);
    vsp = approach(vsp, iy * max_speed * 0.5, (iy != 0) ? accel : slash_fric);
}

// ---- Bond Strike: both keys within half a second, meter full ----
if (bond1_t > 0 && bond2_t > 0 && global.bond >= 100 && (state == "move" || state == "jump" || state == "slash")) start_bond();

// ---- Soul Ascension: rise, spin, then the nova ----
if (state == "ascend") {
    asc_t += 1;
    hsp = 0;
    vsp = 0;
    invuln = max(invuln, 2);
    z = lerp(z, 22, 0.15);
    if (asc_t mod 2 == 0) {
        var sa = asc_t * 18;
        fx("soul", x + lengthdir_x(18, sa), y - z + 6 + lengthdir_y(8, sa), 1);
    }
    if (asc_t == asc_len) soul_nova();
    if (asc_t >= asc_len + 8) { state = "jump"; zspd = 0; jump_timer = air_time * 0.5; }   // drift back down
}

// ---- Bond Strike: rise while the sword whirls, then slam ----
if (state == "bond") {
    bond_t += 1;
    hsp = 0;
    vsp = 0;
    invuln = max(invuln, 2);
    z = lerp(z, 26, 0.12);
    if (bond_t == 50) bond_slam();
    if (bond_t >= 62) {
        state = "jump";
        zspd = 0;
        jump_timer = air_time * 0.5;
        with (obj_weapon) state = "held";
    }
}

// ---- recall: yank the weapon back, hurting everything on its way ----
if (recall_pressed && instance_exists(obj_weapon) && obj_weapon.state == "out") {
    with (obj_weapon) start_recall(true);
    drink_fury();
}
if (drink_t > 0) drink_t -= 1;

// ---- dash: fixed burst, invulnerable, leaves afterimages ----
if (state == "dash") {
    hsp = lengthdir_x(dash_speed, dash_dir);
    vsp = lengthdir_y(dash_speed, dash_dir);
    invuln = max(invuln, 2);
    array_insert(ghosts, 0, [x, y, sprite_index, image_index]);
    if (array_length(ghosts) > 4) array_pop(ghosts);
    // Afterburn Dash: a trail of fire
    var ab = blv(1, "afterburn");
    if (ab > 0 && dash_timer mod 3 == 0) instance_create_layer(x, bbox_bottom - 3, "Instances", obj_fire, { lv: ab });
    // Phantom Step: dash straight through enemies, slicing them
    var ph = blv(1, "phantom");
    if (ph > 0) {
        var did = dash_id, pdmg = 6 + 6 * ph, mx = x, my = bbox_bottom - 6;
        with (obj_enemy) {
            if (!dead && phantom_mark != did && point_distance(x, hit_y(id, my), mx, my) < 18) {
                phantom_mark = did;
                take_damage(pdmg, false);
                fx("soul", x, bbox_bottom - 10, 8);
                hitstop(2);
            }
        }
    }
    // Whetstone Step: dash through the floating sword to sharpen it
    var wl = blv(1, "whetstone");
    if (wl > 0 && whet_mark != dash_id && instance_exists(obj_weapon)) {
        var w = obj_weapon;
        if (w.state != "held" && w.state != "bond" && point_distance(x, y, w.x, w.y) < 18) {
            whet_mark = dash_id;
            w.whet = 2 + wl;
            dmg_number(w.x, w.y - 30, "SHARPENED x" + string(w.whet), true);
            fx("zap", w.x, w.y - w.hover, 16);
            fx_ring(w.x, w.y, 22, make_color_rgb(140, 220, 255));
            hitstop(3);
            shake(2);
            if (wl >= 3) explode(w.x, w.y, 40, 12, make_color_rgb(140, 220, 255));
        }
    }
    dash_timer -= 1;
    if (dash_timer <= 0) {
        state = "move";
        hsp *= 0.35;
        vsp *= 0.35;
        end_dash();
    }
}
else if (array_length(ghosts) > 0) {
    array_pop(ghosts);
}

// ---- jump height ----
if (state == "jump") {
    zspd -= jump_grav;
    z += zspd;
    jump_timer += 1;
    if (z <= 0) {               // landed
        z = 0;
        zspd = 0;
        state = "move";
        land();
    }
}

// ---- Meteor Fall: plunge ----
if (state == "stomp") {
    hsp *= 0.85;
    vsp *= 0.85;
    zspd -= 0.9;
    z += zspd;
    if (irandom(1) == 0) fx("ember", x, y - z + 6, 2);
    if (z <= 0) {
        z = 0;
        zspd = 0;
        state = "move";
        land_stomp();
    }
}

// ---- move with collision (pixel-step, axis by axis) ----
if (place_meeting(x + hsp, y, obj_wall)) {
    while (!place_meeting(x + sign(hsp), y, obj_wall)) x += sign(hsp);
    hsp = 0;
}
x += hsp;

if (place_meeting(x, y + vsp, obj_wall)) {
    while (!place_meeting(x, y + sign(vsp), obj_wall)) y += sign(vsp);
    vsp = 0;
}
y += vsp;

// ---- stay inside the room ----
x = clamp(x, sprite_width / 2, room_width - sprite_width / 2);
y = clamp(y, sprite_height / 2, room_height - sprite_height / 2);

// ---- draw order: lower on screen = in front (props do the same with their base) ----
depth = -bbox_bottom;


// Walking sound
if (state == "move" && len > 0 && (hsp != 0 || vsp != 0)) {

    if (!audio_is_playing(walk_sound_id)) {
        walk_sound_id = audio_play_sound(player_walk, 1, true);
        audio_sound_gain(walk_sound_id, 1, 0);
    }

}
else {

    if (walk_sound_id != -1) {
        audio_stop_sound(walk_sound_id);
        walk_sound_id = -1;
    }
}

// ---- animation ----
if (state == "move" || state == "dash") {
    // walk plays while keys are held, frame 0 when idle
    // assign directly (not set_anim) so turning mid-walk keeps the stride
    sprite_index = walk_sprites[facing];
    if (state == "dash") {
        image_speed = 2;
    } else if (len > 0) {
        image_speed = 1;
    } else {
        image_speed = 0;
        image_index = 0;
    }
}
else if (state == "jump" || state == "stomp") {
    // flip frames follow the jump's progress, so the flip always lands on the last (standing) frame
    sprite_index = flip_sprites[facing];
    image_speed = 0;
    image_index = min(jump_timer / air_time * image_number, image_number - 1);
}

// Testing health bar
if (keyboard_check_pressed(ord("H"))) {
	hp -= 10;
}
