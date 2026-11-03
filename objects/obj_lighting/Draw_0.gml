if (!enabled) exit;

var cam = view_camera[0];
var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam);
var cw = camera_get_view_width(cam), ch = camera_get_view_height(cam);
if (!surface_exists(surf)) surf = surface_create(cw, ch);

// ---- build the light map
surface_set_target(surf);
draw_clear(ambient);
gpu_set_blendmode(bm_add);
draw_set_circle_precision(32);

// player: a warm pool around them
with (obj_player) draw_circle_colour(x - cx, y - cy, 120, make_color_rgb(150, 135, 115), c_black, false);

// crystals and landmarks, with a slow flicker
for (var i = 0; i < array_length(lights); i++) {
    var L = lights[i];
    var k = 0.9 + 0.1 * sin(current_time / 400 + L.flick);
    draw_circle_colour(L.x - cx, L.y - cy, L.r * k, L.col, c_black, false);
}

// doors: dim red while locked, bright gold when open
with (obj_door) {
    var c = merge_color(make_color_rgb(70, 10, 10), make_color_rgb(255, 190, 100), glow);
    draw_circle_colour((x1 + x2) / 2 - cx, y2 - 14 - cy, 60 + 50 * glow, c, c_black, false);
}

// the boss: cold blue while armored, molten orange after the armor breaks
with (obj_boss) if (!dead) draw_circle_colour(x - cx, y - cy, 110, (phase == 1) ? make_color_rgb(70, 90, 140) : make_color_rgb(150, 80, 40), c_black, false);

// player 2's weapon carries its own light while detached
with (obj_weapon) if (state != "held") draw_circle_colour(x - cx, y - hover - cy, 60, make_color_rgb(110, 140, 190), c_black, false);
with (obj_pickup) draw_circle_colour(x - cx, y - cy, 26, make_color_rgb(120, 30, 50), c_black, false);
with (obj_cast) draw_circle_colour(x - cx, y - cy, landed ? radius * 1.4 : 30, make_color_rgb(110, 60, 150), c_black, false);
with (obj_projectile) if (kind == "bolt") draw_circle_colour(x - cx, y - cy, 30, merge_color(col, c_black, 0.5), c_black, false);

// spawn warnings glow red so you can spot them in the dark
if (instance_exists(obj_game)) {
    for (var i = 0; i < array_length(obj_game.pending); i++) {
        var p = obj_game.pending[i];
        if (p.t <= obj_game.warn_frames) draw_circle_colour(p.x - cx, p.y - cy, 40, make_color_rgb(140, 20, 20), c_black, false);
    }
}

gpu_set_blendmode(bm_normal);
draw_set_circle_precision(24);
surface_reset_target();

// ---- multiply the world by it
gpu_set_blendmode_ext(bm_dest_colour, bm_zero);
draw_surface(surf, cx, cy);
gpu_set_blendmode(bm_normal);
