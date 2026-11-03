if (state == "held") exit;                 // in hand: the character draws the slash
if (!instance_exists(obj_player)) exit;
var p = obj_player;
var bob = sin(float_t / 10) * 2;
var wy = y - hover + bob;

// tether line: pale blue, turning orange near the 5 m limit
var k = point_distance(p.x, p.y, x, y) / tether;
draw_set_alpha(0.35 + 0.4 * k);
draw_set_color(merge_color(make_color_rgb(120, 190, 255), make_color_rgb(255, 150, 60), max(0, (k - 0.7) / 0.3)));
draw_line_width(p.x, p.y - 8, x, wy, 1);
draw_set_alpha(1);

// shadow on the ground (or nothing over the void)
draw_set_color(c_black);
draw_set_alpha(0.35);
draw_ellipse(x - 5, y - 2, x + 5, y + 2, false);
draw_set_alpha(1);

// the blade: points along swing_dir, spins during a recall
var ang = (state == "recall") ? float_t * 25 : swing_dir;
var tipx = x + lengthdir_x(10, ang), tipy = wy + lengthdir_y(10, ang);
var hx = x - lengthdir_x(6, ang), hy = wy - lengthdir_y(6, ang);
draw_set_color(make_color_rgb(225, 235, 255));
draw_line_width(hx, hy, tipx, tipy, 3);
draw_set_color(make_color_rgb(200, 160, 80));                      // guard
draw_line_width(hx + lengthdir_x(4, ang + 90), hy + lengthdir_y(4, ang + 90),
                hx + lengthdir_x(4, ang - 90), hy + lengthdir_y(4, ang - 90), 2);
draw_set_color(make_color_rgb(110, 70, 40));                       // grip
draw_line_width(hx, hy, hx - lengthdir_x(4, ang), hy - lengthdir_y(4, ang), 2);

// detached swing arc
if (swing_t > 0) {
    draw_set_color(c_white);
    draw_set_alpha(swing_t / 10);
    for (var a = -70; a <= 70; a += 14) {
        draw_line_width(x + lengthdir_x(6, swing_dir + a), y + lengthdir_y(6, swing_dir + a),
                        x + lengthdir_x(22, swing_dir + a), y + lengthdir_y(22, swing_dir + a), 2);
    }
    draw_set_alpha(1);
}
draw_set_color(c_white);
