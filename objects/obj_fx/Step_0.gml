t += 1;
if (kind == "bolt" && array_length(pts) == 0) {          // build the zig-zag once
    var n = 6;
    var len = point_distance(x, y, x2, y2), dir = point_direction(x, y, x2, y2);
    for (var i = 0; i <= n; i++) {
        var off = (i == 0 || i == n) ? 0 : random_range(-7, 7);
        array_push(pts, [x + lengthdir_x(len * i / n, dir) + lengthdir_x(off, dir + 90),
                         y + lengthdir_y(len * i / n, dir) + lengthdir_y(off, dir + 90)]);
    }
}
if (t >= life) instance_destroy();
