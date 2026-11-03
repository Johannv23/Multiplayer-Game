if (hit_flash > 0) hit_flash -= 1;

// ---- falling into the void (kicked off an edge) ----
if (falling) {
    fall_t -= 1;
    image_xscale *= 0.94;
    image_yscale *= 0.94;
    y += 1.5;
    image_alpha = fall_t / 40;
    if (fall_t <= 0) instance_destroy();
    exit;
}

// ---- knockback ----
if (kb_speed > 0) {
    var nx = x + lengthdir_x(kb_speed, kb_dir), ny = y + lengthdir_y(kb_speed, kb_dir);
    if (!blocked_at(nx, y)) x = nx;
    if (!blocked_at(x, ny)) y = ny;
    kb_speed = max(0, kb_speed - 0.3);
    if (!dead && over_void()) {
        dead = true;
        falling = true;
        fall_t = 40;
        kb_speed = 0;
        image_speed = 0;
        if (random(1) < drop_chance) instance_create_layer(x, bbox_bottom - 4, "Instances", obj_pickup);
    }
    depth = -bbox_bottom;
    exit;
}

// ---- stunned (kicked or rooted by a cast) ----
if (stun > 0 && !dead) {
    stun -= 1;
    depth = -bbox_bottom;
    exit;
}

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

			// face the way we walk
			if (art_faces != 0 && move_x != 0) image_xscale = art_scale * art_faces * sign(move_x);

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

        // Start a melee attack when close
        if (dist <= attack_range && attack_cooldown <= 0) {

            attacking = true;
            attack_is_ranged = false;
            if (art_faces != 0) image_xscale = art_scale * art_faces * ((player.x >= x) ? 1 : -1);

            sprite_index = attack_sprite;
            image_index = 0;

            attack_sound = audio_play_sound(enemy_attack, 1, false);

            audio_sound_set_track_position(attack_sound, 0.8);
        }
        // ...or a ranged attack from mid range (projectiles hug the ground: jump over them)
        else if (ranged_kind != "" && ranged_cooldown <= 0 && dist >= ranged_min && dist <= ranged_max) {

            attacking = true;
            attack_is_ranged = true;
            fired = false;
            if (art_faces != 0) image_xscale = art_scale * art_faces * ((player.x >= x) ? 1 : -1);

            sprite_index = ranged_sprite;
            image_index = 0;
        }
    }
    // ranged attack: release the projectile on the right animation frame
    else if (attack_is_ranged && !fired && image_index >= ranged_frame) {
        fired = true;
        var fx = x, fy = bbox_bottom - 2;                 // from the feet, on the ground
        var aim = point_direction(fx, fy, player.x, player.bbox_bottom - 6);
        if (ranged_kind == "bolt") {
            for (var i = 0; i < ranged_count; i++) {
                var a = aim + (i - (ranged_count - 1) / 2) * ranged_spread;
                instance_create_layer(fx + lengthdir_x(10, a), fy + lengthdir_y(10, a), "Instances", obj_projectile,
                    { kind: "bolt", dir: a, spd: ranged_speed, dmg: ranged_damage, col: ranged_colour });
            }
        } else {
            instance_create_layer(fx, fy, "Instances", obj_projectile,
                { kind: "wave", dir: 0, spd: ranged_speed, dmg: ranged_damage, col: ranged_colour });
        }
    }

    if (ranged_cooldown > 0) ranged_cooldown -= 1;
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