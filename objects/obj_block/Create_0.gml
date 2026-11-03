// Gray-box cover block. Child of obj_wall, so the player and enemies collide with its footprint.
// Drawn as a box that rises box_h pixels above its footprint, so you can walk "behind" it.
event_inherited();
box_h     = 18;
col_top   = make_color_rgb(176, 178, 184);
col_front = make_color_rgb(112, 114, 124);
col_line  = make_color_rgb(36, 38, 46);
depth = -bbox_bottom;
