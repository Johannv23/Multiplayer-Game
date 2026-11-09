// Enemy death
if (dead) {

    instance_destroy();

}
else if (attacking) {

    // Damage player
    if (instance_exists(obj_player)) {

        var player = instance_nearest(x, y, obj_player);

        var dist = point_distance(x, y, player.x, player.y);

        if (!attack_is_ranged && dist <= attack_range && player.z <= 0) {
            hurt_player(player, attack_damage);
        }
    }

    // End attack
    stop_attack_sound();
    if (attack_is_ranged) ranged_cooldown = ranged_cooldown_max + irandom(60);
    attack_is_ranged = false;
    attacking = false;
    attack_cooldown = game_get_speed(gamespeed_fps);

    // Return to idle
    sprite_index = idle_sprite;
    image_index = 0;
}