gpu_set_blendmode(bm_add);
if (!landed) {
    draw_set_color(make_color_rgb(200, 120, 255));
    draw_set_alpha(0.4);
    draw_ellipse(x - 4, y - 2, x + 4, y + 2, false);         // shadow-glow on the ground
    draw_set_alpha(1);
    var yy = y - h;
    draw_triangle(x, yy - 6, x - 4, yy, x + 4, yy, false);
    draw_triangle(x, yy + 6, x - 4, yy, x + 4, yy, false);
} else {
    var k = burst_t / 30;
    draw_set_color(make_color_rgb(200, 120, 255));
    draw_set_alpha(1 - k);
    draw_circle(x, y, radius * (0.4 + 0.6 * k), true);
    draw_circle(x, y, radius * (0.4 + 0.6 * k) - 1, true);
    draw_set_alpha((1 - k) * 0.25);
    draw_circle(x, y, radius, false);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
