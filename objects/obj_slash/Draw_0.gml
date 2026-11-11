// the swoosh: the blade crosses in the first half of its life, then the trail fades
var k = t / life;
var sw = min(1, k * 2);
var a0 = dir - half, a1 = dir - half + 2 * half * sw;
gpu_set_blendmode(bm_add);
if (a1 > a0 + 1) {
    draw_primitive_begin(pr_trianglestrip);
    for (var a = a0; a <= a1; a += 6) {
        var f = (a - a0) / (a1 - a0);              // 0 at the tail, 1 at the blade
        var al = (1 - k) * (0.15 + 0.85 * f);
        draw_vertex_colour(cx + lengthdir_x(r * 0.45, a), cy + lengthdir_y(r * 0.45, a) * 0.7, col, al * 0.15);
        draw_vertex_colour(cx + lengthdir_x(r, a), cy + lengthdir_y(r, a) * 0.7, col, al);
    }
    draw_primitive_end();
    // bright leading edge
    draw_set_color(c_white);
    draw_set_alpha(1 - k);
    draw_line_width(cx + lengthdir_x(r * 0.45, a1), cy + lengthdir_y(r * 0.45, a1) * 0.7,
                    cx + lengthdir_x(r, a1), cy + lengthdir_y(r, a1) * 0.7, 2);
}
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
// debug: the arc's edge
if (global.show_hitboxes) {
    draw_set_color(c_yellow);
    for (var a = dir - half; a < dir + half; a += 10)
        draw_line(cx + lengthdir_x(r, a), cy + lengthdir_y(r, a) * 0.7, cx + lengthdir_x(r, a + 10), cy + lengthdir_y(r, a + 10) * 0.7);
    draw_set_color(c_white);
}
