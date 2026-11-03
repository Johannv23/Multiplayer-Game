// Enemy projectile. The spawn struct sets: kind ("bolt" / "wave"), dir, spd, dmg, col.
// Ground-level: it only hits a player standing on the ground (z < 6) -> jump over it.
life = 0;
radius = 6;            // wave: current ring radius
wave_max = 110;        // wave: the ring fades out at this radius
band = 6;              // wave: how thick the hitting edge is
hit_done = false;      // a wave hits once
trail = [];            // bolt: recent positions
// drawn after the lighting overlay, so projectiles glow and stay readable in the dark
depth = -15001;
