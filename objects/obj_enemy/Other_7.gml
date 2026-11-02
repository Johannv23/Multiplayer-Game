// Enemy death
if (dead) {

    instance_destroy();

}
else if (attacking) {

    // Damage player
    if (instance_exists(obj_player)) {

        var player = instance_nearest(x, y, obj_player);

        var dist = point_distance(x, y, player.x, player.y);

        if (dist <= attack_range && player.z <= 0) {
            player.hp -= attack_damage;
        }
    }

    // End attack
    attacking = false;
    attack_cooldown = game_get_speed(gamespeed_fps);

    // Return to idle
    sprite_index = spr_enemy_golem;
    image_index = 0;
}