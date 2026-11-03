// Enemy spawn point for the wave system. Invisible in game (Visible is off);
// the red ring only shows in the Room Editor so you can move spawns around.

// which arena this spawn belongs to (index into obj_game.arenas, -1 = none)
arena = -1;
for (var i = 0; i < array_length(obj_game.arenas); i++) {
    if (y >= obj_game.arenas[i].top && y < obj_game.arenas[i].bottom) arena = i;
}
