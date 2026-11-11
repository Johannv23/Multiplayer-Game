if (paused()) exit;
t += 1;
// the ground is drawn squashed (y * 0.7), so test the arc in that same squashed space
var me = id;
with (obj_enemy) {
    if (!dead && !in_list(me.hits, id)) {
        var dx = x - me.cx, dy = (hit_y(id, me.cy) - me.cy) / 0.7;      // tall enemies: aim at the nearest part of the body
        var dd = point_distance(0, 0, dx, dy);
        if (dd < me.r + 8 && (dd < 12 || abs(angle_difference(point_direction(0, 0, dx, dy), me.dir)) <= me.half + 10)) {
            array_push(me.hits, id);
            sword_hit(id, me.damage, me.src);
        }
    }
}
if (t >= life) instance_destroy();
