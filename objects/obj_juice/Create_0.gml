// Juice controller (one per room, made by obj_game): particle types, hit-stop / slow-mo clocks,
// the full-screen flash, and the debug keys (F1 or ` = room menu, Backspace = skip dialogue / lessons).
ps = part_system_create();
part_system_depth(ps, -15002);          // above the lighting: particles glow
pt = {};

var t;
t = part_type_create();                 // spark: hot, fast, short
part_type_shape(t, pt_shape_disk);
part_type_size(t, 0.03, 0.07, -0.002, 0);
part_type_colour3(t, c_white, make_color_rgb(255, 220, 120), make_color_rgb(255, 120, 40));
part_type_alpha2(t, 1, 0);
part_type_speed(t, 1.5, 3.5, -0.12, 0);
part_type_direction(t, 0, 360, 0, 0);
part_type_life(t, 10, 20);
part_type_blend(t, true);
pt.spark = t;

t = part_type_create();                 // ember: rising fire bits
part_type_shape(t, pt_shape_disk);
part_type_size(t, 0.025, 0.06, -0.0008, 0);
part_type_colour3(t, make_color_rgb(255, 230, 140), make_color_rgb(255, 120, 30), make_color_rgb(150, 30, 10));
part_type_alpha2(t, 1, 0);
part_type_speed(t, 0.4, 1.6, -0.01, 0);
part_type_direction(t, 50, 130, 0, 6);
part_type_life(t, 25, 45);
part_type_blend(t, true);
pt.ember = t;

t = part_type_create();                 // smoke / dust
part_type_shape(t, pt_shape_smoke);
part_type_size(t, 0.08, 0.2, 0.004, 0);
part_type_colour1(t, make_color_rgb(120, 120, 130));
part_type_alpha2(t, 0.45, 0);
part_type_speed(t, 0.2, 0.7, -0.01, 0);
part_type_direction(t, 0, 360, 0, 0);
part_type_life(t, 25, 45);
pt.smoke = t;

t = part_type_create();                 // shard: falling stone chips
part_type_shape(t, pt_shape_square);
part_type_size(t, 0.025, 0.05, 0, 0);
part_type_colour2(t, make_color_rgb(170, 170, 180), make_color_rgb(90, 90, 100));
part_type_alpha2(t, 1, 0);
part_type_speed(t, 1.5, 3.2, -0.05, 0);
part_type_direction(t, 30, 150, 0, 0);
part_type_gravity(t, 0.15, 270);
part_type_orientation(t, 0, 360, 8, 0, false);
part_type_life(t, 25, 40);
pt.shard = t;

t = part_type_create();                 // soul: violet wisps
part_type_shape(t, pt_shape_disk);
part_type_size(t, 0.03, 0.07, -0.001, 0);
part_type_colour3(t, make_color_rgb(255, 200, 255), make_color_rgb(200, 110, 255), make_color_rgb(90, 40, 160));
part_type_alpha2(t, 1, 0);
part_type_speed(t, 0.5, 1.8, -0.02, 0);
part_type_direction(t, 0, 360, 0, 4);
part_type_life(t, 30, 50);
part_type_blend(t, true);
pt.soul = t;

t = part_type_create();                 // zap: electric blue specks
part_type_shape(t, pt_shape_disk);
part_type_size(t, 0.02, 0.05, -0.002, 0);
part_type_colour2(t, c_white, make_color_rgb(120, 190, 255));
part_type_alpha2(t, 1, 0);
part_type_speed(t, 2, 4, -0.2, 0);
part_type_direction(t, 0, 360, 0, 20);
part_type_life(t, 8, 16);
part_type_blend(t, true);
pt.zap = t;

t = part_type_create();                 // mote: slow cyan light rising off a Reliquary
part_type_shape(t, pt_shape_disk);
part_type_size(t, 0.015, 0.035, 0, 0);
part_type_colour2(t, make_color_rgb(200, 255, 255), make_color_rgb(80, 200, 255));
part_type_alpha3(t, 0, 1, 0);
part_type_speed(t, 0.3, 0.8, 0, 0);
part_type_direction(t, 80, 100, 0, 4);
part_type_life(t, 50, 90);
part_type_blend(t, true);
pt.mote = t;

menu = false;           // debug room menu
