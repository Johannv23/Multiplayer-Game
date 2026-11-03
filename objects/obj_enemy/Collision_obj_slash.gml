if (!dead) {
    take_damage(other.damage);
    with (other) instance_destroy();
    // the weapon's hits charge player 1's cast
    if (instance_exists(obj_player)) with (obj_player) cast_charge = min(100, cast_charge + 12);
}
