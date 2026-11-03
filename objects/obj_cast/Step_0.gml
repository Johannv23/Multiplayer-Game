if (!landed) {
    t += 1;
    var k = t / dur;
    x = lerp(sx, tx, k);
    y = lerp(sy, ty, k);
    h = sin(k * pi) * 40;
    if (t >= dur) {
        landed = true;
        h = 0;
        var r = radius, rf = root_frames, dmg = damage;
        with (obj_enemy) {
            if (!dead && point_distance(x, bbox_bottom - 5, other.x, other.y) < r) {
                interrupt();
                stun = max(stun, rf);
                take_damage(dmg);
            }
        }
    }
} else {
    burst_t += 1;
    if (burst_t > 30) instance_destroy();
}
