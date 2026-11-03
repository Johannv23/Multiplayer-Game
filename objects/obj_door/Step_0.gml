glow = lerp(glow, is_open ? 1 : 0, 0.08);

// walk into an open door -> next chamber
if (is_open && collision_rectangle(x1, y1, x2, y2 - 8, obj_player, false, true) != noone) {
    obj_game.go_next();
}
