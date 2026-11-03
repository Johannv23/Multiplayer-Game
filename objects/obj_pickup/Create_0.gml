// Soul orb dropped by enemies: heals the character. The character collects it by walking over it,
// the weapon by flying through it (also over the void).
heal = 6;
life = 0;
life_max = 720;          // 12 s, blinks for the last 2
bob = random(100);
depth = -15001;          // glows above the lighting

function collect() {
    if (instance_exists(obj_player)) with (obj_player) hp = min(max_hp, hp + other.heal);
    instance_destroy();
}
