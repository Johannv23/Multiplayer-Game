if (!dead && instance_exists(obj_player)) {

    var player = instance_nearest(x, y, obj_player);

    var dist = point_distance(x, y, player.x, player.y);

    // Attack cooldown
    if (!dead && attack_cooldown > 0) {
        attack_cooldown -= 1;
    }

    // Only move when not attacking
    if (!attacking) {

        // Chase player
        if (dist < chase_range && dist > attack_range) {

            var dir = point_direction(x, y, player.x, player.y);

            var move_x = lengthdir_x(move_speed, dir);
            var move_y = lengthdir_y(move_speed, dir);

            if (!place_meeting(x + move_x, y, obj_wall)) {
                x += move_x;
            }

            if (!place_meeting(x, y + move_y, obj_wall)) {
                y += move_y;
            }
        }

        // Start attack
        if (dist <= attack_range && attack_cooldown <= 0) {

            attacking = true;

            sprite_index = spr_enemy_attack;
            image_index = 0;
			
			attack_sound = audio_play_sound(enemy_attack, 1, false);
			
			audio_sound_set_track_position(attack_sound, 0.8);
        }
    }
}

if (attack_sound != -1) {

    if (audio_is_playing(attack_sound)) {

        if (audio_sound_get_track_position(attack_sound) >= 2.7) {

            audio_stop_sound(attack_sound);
            attack_sound = -1;
        }
    }
}


depth = -bbox_bottom;