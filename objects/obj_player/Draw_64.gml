// Health bar
var bar_x = 20;
var bar_y = 20;

var bar_width = 200;
var bar_height = 20;

var border = 4

// Background
draw_set_colour(c_black);
draw_rectangle(bar_x - border, bar_y - border, bar_x + bar_width + border, bar_y + bar_height + border, false);

// Health
draw_set_colour(c_red);
draw_rectangle(bar_x, bar_y, bar_x + bar_width * (hp / max_hp), bar_y + bar_height, false);