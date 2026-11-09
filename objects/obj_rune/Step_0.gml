if (pulse > 0) pulse -= 1;
if (!lit && instance_exists(obj_player) && obj_player.state == "dash"
    && point_distance(x, y, obj_player.x, obj_player.bbox_bottom - 6) < 20) {
    lit = true;
    pulse = 20;
    fx("zap", x, y, 16);
    fx_ring(x, y, 26, make_color_rgb(120, 230, 255));
    shake(2);
}
if (lit && irandom(10) == 0) fx("mote", x + random_range(-8, 8), y, 1);
