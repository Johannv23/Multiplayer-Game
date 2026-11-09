t += 1;
if (!active || spent) exit;
if (t mod 4 == 0) fx("mote", cx + random_range(-10, 10), by - random(40), 1);
if (entering > 0) {                  // swallowed by the light, then the shrine
    entering += 1;
    if (entering == 18) {
        if (instance_exists(obj_player)) global.player_hp = obj_player.hp;
        room_goto(target);
    }
    exit;
}
if (paused() || !instance_exists(obj_player)) exit;
if (point_distance(obj_player.x, obj_player.bbox_bottom, cx, by) < 30) {
    entering = 1;
    flash(c_white, 1);
    fx("mote", cx, by - 20, 30);
    shake(3);
    global.freeze = true;
}
