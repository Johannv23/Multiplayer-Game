// A sweeping sword arc (made by obj_weapon.make_slash, which sets damage, cx, cy, dir, r, half, col).
// It checks hits itself: every enemy whose feet are inside the arc is hit once.
damage = 10;
src = "sword";
hits = [];
cx = x;
cy = y;
dir = 0;            // the way the arc faces
r = 34;             // reach
half = 75;          // half the arc's angle
col = c_white;
t = 0;
life = 8;
depth = -10000;
