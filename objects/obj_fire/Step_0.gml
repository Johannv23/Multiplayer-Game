if (paused()) exit;
life -= 1;
tick -= 1;
if (tick <= 0) {
    tick = 20;
    var fx_ = x, fy_ = y, r = radius, d = dmg;
    with (obj_enemy) if (!dead && point_distance(x, hit_y(id, fy_), fx_, fy_) < r) take_damage(d, false);
}
if (irandom(6) == 0) fx("ember", x + random_range(-5, 5), y, 1);
if (life <= 0) instance_destroy();
