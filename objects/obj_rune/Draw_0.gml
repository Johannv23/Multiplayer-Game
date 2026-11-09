var col = lit ? make_color_rgb(140, 240, 255) : make_color_rgb(70, 90, 110);
var r = 11 + pulse * 0.3;
if (lit) gpu_set_blendmode(bm_add);
draw_set_color(col);
draw_set_alpha(lit ? 0.9 : 0.6 + 0.2 * sin(current_time / 300));
draw_ellipse(x - r, y - r * 0.55, x + r, y + r * 0.55, true);
draw_ellipse(x - r + 3, y - r * 0.55 + 2, x + r - 3, y + r * 0.55 - 2, true);
for (var i = 0; i < 3; i++) {                      // the glyph
    var a = i * 120 + current_time / (lit ? 20 : 60);
    draw_line(x, y, x + lengthdir_x(r - 3, a), y + lengthdir_y((r - 3) * 0.55, a));
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
