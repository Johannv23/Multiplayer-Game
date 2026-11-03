// flat floor + a faint 32px grid, so movement and distance read on screen
var l = bbox_left, t = bbox_top, r = bbox_right + 1, b = bbox_bottom + 1;
draw_set_color(col_floor);
draw_rectangle(l, t, r, b, false);
draw_set_color(col_grid);
for (var gx = l; gx < r; gx += 32) draw_line(gx, t, gx, b);
for (var gy = t; gy < b; gy += 32) draw_line(l, gy, r, gy);
draw_set_color(c_white);
