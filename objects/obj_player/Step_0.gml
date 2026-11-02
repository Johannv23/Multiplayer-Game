// ---- input: -1, 0 or 1 on each axis ----
var ix = (keyboard_check(vk_right) || keyboard_check(ord("D")))
       - (keyboard_check(vk_left)  || keyboard_check(ord("A")));
var iy = (keyboard_check(vk_down)  || keyboard_check(ord("S")))
       - (keyboard_check(vk_up)    || keyboard_check(ord("W")));
var jump_pressed  = keyboard_check_pressed(vk_space);
var slash_pressed = keyboard_check_pressed(ord("J")) || mouse_check_button_pressed(mb_left);

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
    // ---- start a jump or a slash ----
    if (jump_pressed) {
        state = "jump";
        zspd = jump_speed;      // set, not add, so every jump is identical
        jump_timer = 0;
    }
    else if (slash_pressed) {
        // pick the closest diagonal: facing 1-3 is "up", face_x picks left or right
        var up = (facing >= 1 && facing <= 3);
        if (up) slash_dir = (face_x > 0) ? 0 : 1;
        else    slash_dir = (face_x > 0) ? 3 : 2;
        state = "slash";
        set_anim(slash_sprites[slash_dir]);   // ends in Animation End
    }
}
else if (state == "slash") {
    hsp = approach(hsp, 0, slash_fric);
    vsp = approach(vsp, 0, slash_fric);
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

// ---- animation ----
if (state == "move") {
    // walk plays while keys are held, frame 0 when idle
    // assign directly (not set_anim) so turning mid-walk keeps the stride
    sprite_index = walk_sprites[facing];
    if (len > 0) {
        image_speed = 1;
    } else {
        image_speed = 0;
        image_index = 0;
    }
}
else if (state == "jump") {
    // flip frames follow the jump's progress, so the flip always lands on the last (standing) frame
    sprite_index = flip_sprites[facing];
    image_speed = 0;
    image_index = min(jump_timer / air_time * image_number, image_number - 1);
}

// Testing health bar
if (keyboard_check_pressed(ord("H"))) {
	hp -= 10;
}

hp = clamp(hp, 0, max_hp);

	