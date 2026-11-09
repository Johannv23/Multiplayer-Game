var glow = (active && !spent) ? 1 : 0;
var bob = sin(t / 20) * 2;

// beam of light up into the dark (when active)
if (glow > 0) {
    gpu_set_blendmode(bm_add);
    var w = 9 + 2 * sin(t / 9);
    draw_set_alpha(0.18);
    draw_set_color(make_color_rgb(110, 210, 255));
    draw_rectangle(cx - w, 0, cx + w, by - 30, false);
    draw_set_alpha(0.35);
    draw_rectangle(cx - w / 3, 0, cx + w / 3, by - 30, false);
    draw_set_alpha(0.3 + 0.15 * sin(t / 10));
    draw_ellipse(cx - 22, by - 7, cx + 22, by + 7, true);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
}

// the pillar: dark stone with glowing runes
draw_set_color(c_black);
draw_set_alpha(0.35);
draw_ellipse(cx - 12, by - 4, cx + 12, by + 4, false);
draw_set_alpha(1);
draw_set_color(make_color_rgb(44, 48, 62));
draw_rectangle(cx - 7, by - 42, cx + 7, by, false);
draw_set_color(make_color_rgb(70, 76, 96));
draw_rectangle(cx - 9, by - 46, cx + 9, by - 42, false);      // cap
draw_rectangle(cx - 9, by - 4, cx + 9, by, false);            // base
var rc = merge_color(make_color_rgb(60, 80, 100), make_color_rgb(140, 240, 255), glow * (0.7 + 0.3 * sin(t / 8)));
draw_set_color(rc);
draw_line(cx - 3, by - 36, cx + 3, by - 30);
draw_line(cx + 3, by - 30, cx - 3, by - 24);
draw_line(cx - 3, by - 24, cx + 3, by - 18);
draw_line(cx, by - 14, cx, by - 8);

// floating crystal fragment (gone once claimed)
if (!spent) {
    var cy = by - 60 + bob * (glow ? 2 : 0.5);
    if (glow) gpu_set_blendmode(bm_add);
    draw_set_color(glow ? make_color_rgb(150, 245, 255) : make_color_rgb(80, 100, 120));
    draw_triangle(cx, cy - 9, cx - 5, cy, cx + 5, cy, false);
    draw_triangle(cx, cy + 9, cx - 5, cy, cx + 5, cy, false);
    gpu_set_blendmode(bm_normal);
}
draw_set_color(c_white);
