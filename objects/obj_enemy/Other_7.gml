if (attacking) {

    if (instance_exists(obj_player)) {

        var player = instance_nearest(x, y, obj_player);

        var dist = point_distance(x, y, player.x, player.y);

        if (dist <= attack_range && player.z <= 0) {
            player.hp -= attack_damage;
        }
    }

    attacking = false;
    attack_cooldown = game_get_speed(gamespeed_fps);

    sprite_index = spr_enemy_golem;
    image_index = 0;
}