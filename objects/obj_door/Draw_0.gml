// Skull door from the Undead pack, standing on the doorway's bottom edge.
// Locked: a dim red glow in the mouth. Open: warm light that pulses.
var cx = (x1 + x2) / 2;
var spr = spr_skull_door_c;          // lighter shadow to match the cobble dais

draw_sprite_ext(spr, 0, cx, y2, 1, 1, 0, merge_color(make_color_rgb(150, 150, 160), c_white, glow), 1);

var pulse = 0.85 + 0.15 * sin(current_time / 250);
gpu_set_blendmode(bm_add);
draw_set_color(merge_color(make_color_rgb(110, 10, 10), make_color_rgb(255, 190, 90), glow));
draw_set_alpha((0.35 + 0.5 * glow) * pulse);
draw_ellipse(cx - 9, y2 - 26, cx + 9, y2 - 4, false);
draw_set_alpha(0.25 * glow * pulse);
draw_ellipse(cx - 18, y2 - 34, cx + 18, y2 + 4, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
