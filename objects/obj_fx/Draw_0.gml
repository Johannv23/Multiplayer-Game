var k = t / life;
gpu_set_blendmode(bm_add);
if (kind == "ring") {
    var r = rmax * (1 - power(1 - k, 3));          // fast out, slow settle
    draw_set_color(col);
    draw_set_alpha(1 - k);
    draw_circle(x, y, r, true);
    draw_circle(x, y, r - 1, true);
    draw_circle(x, y, r - 2, true);
    draw_set_alpha((1 - k) * 0.2);
    draw_circle(x, y, r, false);
} else {
    for (var i = 0; i < array_length(pts) - 1; i++) {
        draw_set_alpha(1 - k);
        draw_set_color(col);
        draw_line_width(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], 3);
        draw_set_color(c_white);
        draw_line_width(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], 1);
    }
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
