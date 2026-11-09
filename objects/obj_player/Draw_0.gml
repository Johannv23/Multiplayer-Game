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
draw_sprite_ext(sprite_index, image_index, dx, dy - dz, scale * sx, scale * sy, 0, tint, alpha);

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

// kick: a quick white arc in front of the feet
if (kick_timer > 0) {
    draw_set_color(c_white);
    draw_set_alpha(kick_timer / 8);
    for (var a = -60; a <= 60; a += 15) {
        draw_line_width(dx + lengthdir_x(8, kick_dir + a), dy + 6 + lengthdir_y(8, kick_dir + a),
                        dx + lengthdir_x(kick_range, kick_dir + a), dy + 6 + lengthdir_y(kick_range, kick_dir + a), 2);
    }
    draw_set_alpha(1);
}

// ---- debug: body hitbox (green) and the point enemies measure their attack range to (white dot) ----
draw_hitbox(c_lime);
if (global.show_hitboxes) draw_circle(x, y, 1, false);
