if (!dead && instance_exists(obj_player)) {

    var player = instance_nearest(x, y, obj_player);

    var dist = point_distance(x, y, player.x, player.y);

    // Attack cooldown
    if (attack_cooldown > 0) {
        attack_cooldown -= 1;
    }

    // Only move when not attacking
    if (!attacking) {

        // Chase player
        if (dist < chase_range && dist > attack_range) {

            // Walking animation
            if (sprite_index != walk_sprite) {
                sprite_index = walk_sprite;
                image_index = 0;
            }

			var dir = point_direction(x, y, player.x, player.y);

			var move_x = lengthdir_x(move_speed, dir);
			var move_y = lengthdir_y(move_speed, dir);

			if (object_index == obj_enemy_2) {

			    if (move_x > 0) {
			        image_xscale = -0.75;
			    }
			    else if (move_x < 0) {
			        image_xscale = 0.75;
			    }
			}

            if (!place_meeting(x + move_x, y, obj_wall)) {
                x += move_x;
            }

            if (!place_meeting(x, y + move_y, obj_wall)) {
                y += move_y;
            }
        }
        else {

            // Idle animation
            if (sprite_index != idle_sprite) {
                sprite_index = idle_sprite;
                image_index = 0;
            }
        }

        // Start attack
        if (dist <= attack_range && attack_cooldown <= 0) {

            attacking = true;

            sprite_index = attack_sprite;
            image_index = 0;

            attack_sound = audio_play_sound(enemy_attack, 1, false);

            audio_sound_set_track_position(attack_sound, 0.8);
        }
    }
}

// Stop attack sound
if (attack_sound != -1) {

    if (audio_is_playing(attack_sound)) {

        if (audio_sound_get_track_position(attack_sound) >= 2.7) {

            audio_stop_sound(attack_sound);
            attack_sound = -1;
        }
    }
}

depth = -bbox_bottom;