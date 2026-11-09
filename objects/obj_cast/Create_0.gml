// Player 1's cast: a soul shard lobbed at (tx, ty). On landing it roots every enemy nearby.
sx = x;
sy = y;
t = 0;
dur = 22;                // flight frames
h = 0;                   // arc height
landed = false;
burst_t = 0;
if (!variable_instance_exists(id, "rscale")) rscale = 1;   // Soul Bloom makes it bigger
radius = 46 * rscale;
root_frames = 150;       // 2.5 s
damage = 6;
depth = -15001;
