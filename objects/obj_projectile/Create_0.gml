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
dodged = false;        // Perfect Hop already triggered by this one

// Moon Jump Lv2: clearing an attack mid-jump slows time and feeds the soul mark
function perfect_hop() {
    dodged = true;
    if (blv(1, "moonjump") < 2) return;
    slowmo(30);
    flash(c_white, 0.15);
    if (instance_exists(obj_player)) {
        obj_player.cast_charge = min(100, obj_player.cast_charge + 15);
        dmg_number(obj_player.x, obj_player.y - 30, "PERFECT", true);
        fx("zap", obj_player.x, obj_player.y, 10);
    }
}
