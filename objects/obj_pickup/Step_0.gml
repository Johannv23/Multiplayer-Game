life += 1;
if (life > life_max) {
    instance_destroy();
    exit;
}
if (instance_exists(obj_player) && obj_player.state != "dead"
    && point_distance(x, y, obj_player.x, obj_player.bbox_bottom - 6) < 12) collect();
