// Lighting: the room is drawn, then multiplied by a light map.
// The light map is the ambient colour plus soft additive circles (player, crystals, landmarks, open doors).
// Created by obj_game in chambers. Press L to toggle.
depth = -15000;                                // after every world object, before the GUI
surf = -1;
enabled = true;
ambient = make_color_rgb(62, 72, 104);         // cold blue cave light
if (instance_exists(obj_game) && obj_game.shrine_room) ambient = make_color_rgb(70, 92, 120);   // shrines: a calmer teal

// fixed lights from the props obj_game created from the "Props" layer
lights = [];                                   // { x, y, r, col, flick }
with (obj_prop) {
    var n = sprite_get_name(sprite_index);
    if (string_pos("crystal", n) > 0)      array_push(other.lights, { x: x, y: y - 14, r: 70, col: make_color_rgb(80, 170, 110), flick: random(100) });
    else if (string_pos("shrine", n) > 0 || string_pos("throne", n) > 0 || string_pos("totem", n) > 0 || string_pos("lich", n) > 0)
                                           array_push(other.lights, { x: x, y: y - 30, r: 110, col: make_color_rgb(70, 130, 110), flick: random(100) });
}
