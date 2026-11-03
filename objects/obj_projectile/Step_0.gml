life += 1;

var pl = instance_exists(obj_player) ? instance_nearest(x, y, obj_player) : noone;
var px = 0, py = 0;
if (pl != noone) {
    px = (pl.bbox_left + pl.bbox_right) / 2;      // the player's feet box
    py = (pl.bbox_top + pl.bbox_bottom) / 2;
}

if (kind == "bolt") {
    array_insert(trail, 0, [x, y]);
    if (array_length(trail) > 6) array_pop(trail);
    x += lengthdir_x(spd, dir);
    y += lengthdir_y(spd, dir);

    // stopped by cover, props and doors; flies over pits
    if (collision_point(x, y, obj_block, false, true) != noone || collision_point(x, y, obj_prop, false, true) != noone
        || collision_point(x, y, obj_door, false, true) != noone
        || x < 0 || y < 0 || x > room_width || y > room_height || life > 300) {
        instance_destroy();
        exit;
    }
    if (pl != noone && pl.z < 6 && point_distance(x, y, px, py) < 9 && hurt_player(pl, dmg)) {
        instance_destroy();
        exit;
    }
}
else {   // wave
    radius += spd;
    if (radius >= wave_max) {
        instance_destroy();
        exit;
    }
    if (!hit_done && radius > 0 && pl != noone && pl.z < 6 && abs(point_distance(x, y, px, py) - radius) < band) {
        if (hurt_player(pl, dmg)) hit_done = true;
    }
}
