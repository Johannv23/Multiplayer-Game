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
} else if (kind == "arc") {
    // a crescent that sweeps across, then fades (y squashed to sit on the ground)
    var sw = min(1, k * 2.5);
    var a0 = dir - half, a1 = dir - half + 2 * half * sw;
    if (a1 > a0 + 1) {
        draw_primitive_begin(pr_trianglestrip);
        for (var a = a0; a <= a1; a += 6) {
            var f = (a - a0) / (a1 - a0);
            var al = (1 - k) * (0.2 + 0.8 * f);
            draw_vertex_colour(x + lengthdir_x(rmax * 0.4, a), y + lengthdir_y(rmax * 0.4, a) * 0.7, col, al * 0.2);
            draw_vertex_colour(x + lengthdir_x(rmax, a), y + lengthdir_y(rmax, a) * 0.7, col, al);
        }
        draw_primitive_end();
    }
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
