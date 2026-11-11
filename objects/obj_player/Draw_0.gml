// draw at the real (fractional) position so the player moves smoothly with the camera
var dx = x, dy = y;
var dz = z;

// shadow at the feet: stays on the ground and shrinks as we rise
// (gray, since a black shadow would vanish on the black floor)
var feet_y = dy + 11 * scale;
var shadow_w = 7 * scale * (1 - z / 100);
draw_set_color(make_color_rgb(50, 50, 50));
draw_ellipse(dx - shadow_w, feet_y - shadow_w / 3, dx + shadow_w, feet_y + shadow_w / 3, false);
draw_set_color(c_white);

// dash afterimages
for (var i = array_length(ghosts) - 1; i >= 0; i--) {
    var g = ghosts[i];
    draw_sprite_ext(g[2], g[3], g[0], g[1], scale, scale, 0, make_color_rgb(120, 180, 255), 0.35 * (1 - i / 4));
}

if (state == "dead") {
    draw_sprite_ext(sprite_index, 0, dx, dy + 4, scale, scale, 90, c_gray, 1);
    exit;
}

// the sword strip is a 64x64 overlay centred on the player, synced to the slash frame
// (only while player 2's weapon is in hand)
var held = !instance_exists(obj_weapon) || obj_weapon.state == "held";
var sword = (state == "slash") && held;
var sword_behind = sword && (slash_dir <= 1);   // swinging upward: blade goes behind the body

if (sword_behind) draw_sprite_ext(sword_sprites[slash_dir], image_index, dx, dy, scale, scale, 0, c_white, 1);
var tint = (hurt_flash > 0 && (hurt_flash mod 4) < 2) ? c_red : c_white;   // blink red when hit
var alpha = (invuln > 0 && state != "dash" && (invuln mod 6) < 3) ? 0.55 : 1;   // flicker during grace frames
if (state == "ascend" || state == "bond") {
    // risen: an aura, a spinning body, blazing eyes
    var gold = (state == "bond");
    var acol = gold ? make_color_rgb(255, 215, 120) : make_color_rgb(200, 120, 255);
    var tt = gold ? bond_t : asc_t;
    gpu_set_blendmode(bm_add);
    draw_set_color(acol);
    draw_set_alpha(0.25 + 0.1 * sin(current_time / 60));
    draw_circle(dx, dy - dz, 18 + 3 * sin(current_time / 90), false);
    draw_set_alpha(0.5);
    draw_ellipse(dx - 16 - tt * 0.3, dy + 8, dx + 16 + tt * 0.3, dy + 14, true);      // rune ring on the ground
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    var spin = gold ? 1 : cos(tt * 0.35);                                           // the spin: the sprite flips like a coin
    draw_sprite_ext(walk_sprites[6], 0, dx, dy - dz, scale * spin, scale, 0, c_white, 1);
    gpu_set_blendmode(bm_add);
    draw_set_color(gold ? c_white : make_color_rgb(230, 180, 255));
    if (abs(spin) > 0.3) {
        draw_circle(dx - 2 * spin, dy - dz - 9, 1.5, false);
        draw_circle(dx + 2 * spin, dy - dz - 9, 1.5, false);
    }
    gpu_set_blendmode(bm_normal);
    draw_set_color(c_white);
} else {
    draw_sprite_ext(sprite_index, image_index, dx, dy - dz, scale * sx, scale * sy, 0, tint, alpha);
}

// Soul Feast shield bubble
if (shield > 0) {
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(120, 220, 255));
    draw_set_alpha(0.25 + 0.1 * sin(current_time / 120));
    draw_circle(dx, dy - dz, 16, false);
    draw_set_alpha(0.6);
    draw_circle(dx, dy - dz, 16, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
// Meteor Fall: a burning streak while plunging
if (state == "stomp") {
    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(255, 150, 60));
    draw_set_alpha(0.5);
    draw_line_width(dx, dy - dz - 30, dx, dy - dz, 8);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}
if (sword && !sword_behind) draw_sprite_ext(sword_sprites[slash_dir], image_index, dx, dy, scale, scale, 0, c_white, 1);



// ---- debug: body hitbox (green) and the point enemies measure their attack range to (white dot) ----
draw_hitbox(c_lime);
if (global.show_hitboxes) draw_circle(x, y, 1, false);

// Fury Draught: a little red potion tipped back for half a second
if (drink_t > 0) {
    var px_ = x + 6, py_ = y - 22 - z;
    draw_set_color(make_color_rgb(200, 220, 255));
    draw_rectangle(px_ - 1, py_ - 6, px_ + 1, py_ - 3, false);           // neck
    draw_set_color(make_color_rgb(230, 40, 30));
    draw_circle(px_, py_, 3, false);                                      // bottle
    gpu_set_blendmode(bm_add);
    draw_set_alpha(drink_t / 30);
    draw_circle(px_, py_, 6, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- objective arrow: where to go next (runes, the shining Reliquary, an open door, a straggling enemy) ----
var tx_ = 0, ty_ = 0, best = 999999, tcol = c_white;
with (obj_rune) if (!lit) {
    var dd = point_distance(x, y, other.x, other.y);
    if (dd < best) { best = dd; tx_ = x; ty_ = y; tcol = make_color_rgb(140, 240, 255); }
}
if (best == 999999) with (obj_reliquary) if (active && !spent) {
    best = point_distance(cx, by, other.x, other.y); tx_ = cx; ty_ = by; tcol = make_color_rgb(150, 240, 255);
}
if (best == 999999) with (obj_door) if (is_open) {
    var mx_ = (x1 + x2) / 2, my_ = (y1 + y2) / 2, dd = point_distance(mx_, my_, other.x, other.y);
    if (dd < best) { best = dd; tx_ = mx_; ty_ = my_; tcol = make_color_rgb(255, 200, 110); }
}
if (best == 999999 && instance_number(obj_enemy) > 0 && instance_number(obj_enemy) <= 2 && !instance_exists(obj_boss)) {
    var en = instance_nearest(x, y, obj_enemy);
    if (en != noone && !en.dead) { best = point_distance(en.x, en.y, x, y); tx_ = en.x; ty_ = en.y; tcol = make_color_rgb(255, 90, 90); }
}
if (best != 999999 && best > 90 && !instance_exists(obj_dialogue) && state != "dead") {
    var oa = point_direction(x, y, tx_, ty_);
    var ox_ = x + lengthdir_x(30, oa), oy_ = y - 6 + lengthdir_y(22, oa);
    var bob_ = 2 * sin(current_time / 120);
    ox_ += lengthdir_x(bob_, oa);
    oy_ += lengthdir_y(bob_, oa);
    draw_set_color(tcol);
    draw_set_alpha(0.85);
    draw_triangle(ox_ + lengthdir_x(6, oa), oy_ + lengthdir_y(6, oa),
                  ox_ + lengthdir_x(4, oa + 130), oy_ + lengthdir_y(4, oa + 130),
                  ox_ + lengthdir_x(4, oa - 130), oy_ + lengthdir_y(4, oa - 130), false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
