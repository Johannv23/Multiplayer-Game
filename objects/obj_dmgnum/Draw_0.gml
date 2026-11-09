var s = is_string(val) ? val : string(round(val));
var sc = crit ? 1.0 : 0.65;
if (t < 6) sc *= 1 + (6 - t) * 0.12;                 // pop in
var a = (t > 30) ? 1 - (t - 30) / 15 : 1;
draw_set_halign(fa_center);
draw_set_alpha(a);
draw_set_color(c_black);
draw_text_transformed(x + 1, y + 1, s, sc, sc, 0);
draw_set_color(is_string(val) ? make_color_rgb(140, 230, 255) : (crit ? make_color_rgb(255, 215, 80) : c_white));
draw_text_transformed(x, y, s, sc, sc, 0);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_color(c_white);
