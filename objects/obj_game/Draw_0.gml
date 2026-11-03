// spawn warnings: a red ring that shrinks onto the spot just before the enemy appears
for (var i = 0; i < array_length(pending); i++) {
    var p = pending[i];
    if (p.t > warn_frames) continue;
    var k = p.t / warn_frames;          // 1 -> 0
    draw_set_color(c_red);
    draw_set_alpha(0.8 - 0.5 * k);
    draw_circle(p.x, p.y, 6 + 18 * k, true);
    draw_circle(p.x, p.y, 3, false);
}
draw_set_alpha(1);
draw_set_color(c_white);
