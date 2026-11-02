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

// the sword strip is a 64x64 overlay centred on the player, synced to the slash frame
var sword = (state == "slash");
var sword_behind = sword && (slash_dir <= 1);   // swinging upward: blade goes behind the body

if (sword_behind) draw_sprite_ext(sword_sprites[slash_dir], image_index, dx, dy, scale, scale, 0, c_white, 1);
draw_sprite_ext(sprite_index, image_index, dx, dy - dz, scale, scale, 0, c_white, 1);
if (sword && !sword_behind) draw_sprite_ext(sword_sprites[slash_dir], image_index, dx, dy, scale, scale, 0, c_white, 1);
