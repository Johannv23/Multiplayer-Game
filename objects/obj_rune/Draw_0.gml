var col = lit ? make_color_rgb(140, 240, 255) : make_color_rgb(120, 200, 240);
var r = 12 + pulse * 0.3 + (lit ? 0 : 1.5 * sin(current_time / 200));
gpu_set_blendmode(bm_add);
// a soft filled glow so an unlit rune reads from across the room
draw_set_color(col);
draw_set_alpha(lit ? 0.35 : 0.2 + 0.1 * sin(current_time / 200));
draw_ellipse(x - r - 4, y - (r + 4) * 0.55, x + r + 4, y + (r + 4) * 0.55, false);
draw_set_color(col);
draw_set_alpha(lit ? 1 : 0.8 + 0.2 * sin(current_time / 300));
draw_ellipse(x - r, y - r * 0.55, x + r, y + r * 0.55, true);
draw_ellipse(x - r + 3, y - r * 0.55 + 2, x + r - 3, y + r * 0.55 - 2, true);
for (var i = 0; i < 3; i++) {                      // the glyph
    var a = i * 120 + current_time / (lit ? 20 : 60);
    draw_line(x, y, x + lengthdir_x(r - 3, a), y + lengthdir_y((r - 3) * 0.55, a));
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
