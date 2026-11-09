// Slash hitbox. damage / src are set by whoever swings (obj_weapon.make_slash).
damage = 10;
src = "sword";
hits = [];               // enemies already hit by this swing

alarm[0] = 6;
// draw on top of everything so the debug box is never hidden
depth = -10000;
