// shadow
draw_set_color(c_black);
draw_set_alpha(0.4);
draw_ellipse(x - 30, bbox_bottom - 8, x + 30, bbox_bottom + 4, false);
draw_set_alpha(1);

// charge telegraph: a pulsing red lane
if (bstate == "aim") {
    var k = 1 - timer / 40;
    draw_set_color(c_red);
    draw_set_alpha(0.25 + 0.5 * k * (0.5 + 0.5 * sin(current_time / 40)));
    var fy = bbox_bottom - 10;
    draw_line_width(x, fy, x + lengthdir_x(240, charge_dir), fy + lengthdir_y(240, charge_dir), 6 + 10 * k);
    draw_set_alpha(1);
}

draw_self();
if (hit_flash > 0) {
    gpu_set_fog(true, c_white, 0, 0);
    draw_self();
    gpu_set_fog(false, c_white, 0, 0);
}

// staggered by a cast
if (stun > 0 && !dead) {
    draw_set_color(make_color_rgb(230, 200, 255));
    for (var i = 0; i < 4; i++) {
        var a = current_time / 4 + i * 90;
        draw_circle(x + lengthdir_x(16, a), bbox_bottom - 70 + lengthdir_y(5, a), 2, false);
    }
}
draw_set_color(c_white);
draw_hitbox(c_red);
