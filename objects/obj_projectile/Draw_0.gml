if (kind == "bolt") {
    // shadow on the ground, glowing orb just above it, fading trail
    draw_set_color(c_black);
    draw_set_alpha(0.35);
    draw_ellipse(x - 4, y - 2, x + 4, y + 2, false);
    gpu_set_blendmode(bm_add);
    for (var i = 0; i < array_length(trail); i++) {
        draw_set_alpha(0.5 * (1 - i / array_length(trail)));
        draw_set_color(col);
        draw_circle(trail[i][0], trail[i][1] - 5, 3 - i * 0.3, false);
    }
    draw_set_alpha(1);
    draw_set_color(col);
    draw_circle(x, y - 5, 4, false);
    draw_set_color(c_white);
    draw_circle(x, y - 5, 2, false);
    gpu_set_blendmode(bm_normal);
}
else if (radius > 0) {
    // shockwave: a bright ring that thins out as it grows
    var a = 1 - radius / wave_max;
    gpu_set_blendmode(bm_add);
    draw_set_color(col);
    for (var k = 0; k < 3; k++) {
        draw_set_alpha(a * (1 - k * 0.3));
        draw_circle(x, y, radius - k, true);
    }
    draw_set_alpha(a * 0.15);
    draw_circle(x, y, radius, false);
    gpu_set_blendmode(bm_normal);
}
draw_set_alpha(1);
draw_set_color(c_white);
