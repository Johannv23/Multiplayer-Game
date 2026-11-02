// sprite_index is set by obj_game when it converts the "Props" layer.
// Each prop sprite's collision mask covers only its base, so the player can walk
// behind the top of a tree; depth sorts by that base like the player does.
depth = -bbox_bottom;
