var l = bbox_left, t = bbox_top, r = bbox_right + 1, b = bbox_bottom + 1;
draw_set_color(col_face);
draw_rectangle(l, t, r, b, false);
// light lip where the floor ends, dark bottom fading into the void
draw_set_color(col_lip);
draw_line(l, t, r, t);
draw_set_color(c_black);
draw_set_alpha(0.5);
draw_rectangle(l, b - 6, r, b, false);
draw_set_alpha(1);
draw_set_color(c_white);
