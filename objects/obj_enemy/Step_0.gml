if (paused()) exit;   // dialogue open or hit-stop

// ---- attack sound: cut it at 2.7 s (checked first, before any early exit) ----
if (attack_sound != -1 && (!audio_is_playing(attack_sound) || audio_sound_get_track_position(attack_sound) >= 2.7)) {
    stop_attack_sound();
}

if (hit_flash > 0) hit_flash -= 1;
if (stagger > 0) stagger -= 1;

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
    var hit_wall = false;
    if (!blocked_at(nx, y)) x = nx; else hit_wall = true;
    if (!blocked_at(x, ny)) y = ny; else hit_wall = true;

    // Cannon Kick: a kicked enemy becomes a missile that bowls over the others
    if (missile > 0 && kb_speed > 1.5) {
        var me = id, md = 4 + 8 * (missile - 1), kd = kb_dir;
        with (obj_enemy) {
            if (id != me && !dead && missile_mark != me && point_distance(x, bbox_bottom - 5, me.x, me.bbox_bottom - 5) < 18) {
                missile_mark = me;
                take_damage(md, false);
                stagger = max(stagger, 60);          // bowled-over enemies are staggered too
                kb_dir = kd;
                kb_speed = max(kb_speed, 3);
                fx("spark", x, bbox_bottom - 10, 8);
                shake(2);
            }
        }
        if (hit_wall && missile >= 3) {         // Cannon Kick Lv2: they explode on impact
            explode(x, bbox_bottom - 5, 34, 6 * missile, make_color_rgb(255, 170, 60));
            kb_speed = 0;
        }
    }

    kb_speed = max(0, kb_speed - 0.3);
    if (kb_speed <= 0) missile = 0;
    if (kb_speed > 1) fx("smoke", x, bbox_bottom - 2, 1);
    if (!dead && over_void()) {
        dead = true;
        falling = true;
        fall_t = 40;
        kb_speed = 0;
        image_speed = 0;
        dmg_number(x, bbox_bottom - 34, "BYE", false);
        if (random(1) < drop_chance) instance_create_layer(x, bbox_bottom - 4, "Instances", obj_pickup);
    }
    depth = -bbox_bottom;
    exit;
}

// ---- stunned (kicked, struck by lightning, or rooted by a cast) ----
if (stun > 0 && !dead) {
    stun -= 1;
    if (root_t > 0) {
        root_t -= 1;
        if (root_t == 0 && root_bloom) explode(x, bbox_bottom - 5, 34, 12, make_color_rgb(210, 130, 255));
    }
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

            // ---- follow a path around walls, re-planned about twice a second ----
            var fx_ = x, fy_ = bbox_bottom - 4;                  // our feet
            var tx = player.x, ty = player.bbox_bottom - 4;
            path_t -= 1;
            if (path_t <= 0 && instance_exists(obj_game) && obj_game.grid != -1) {
                path_t = 25 + irandom(10);
                path_ok = mp_grid_path(obj_game.grid, mypath, fx_, fy_, tx, ty, true);
                path_i = 1;
            }
            if (path_ok && path_i < path_get_number(mypath)) {
                tx = path_get_point_x(mypath, path_i);
                ty = path_get_point_y(mypath, path_i);
                if (point_distance(fx_, fy_, tx, ty) < 6) path_i += 1;
            }
            var dir = point_direction(fx_, fy_, tx, ty);
            var move_x = lengthdir_x(move_speed, dir);
            var move_y = lengthdir_y(move_speed, dir);

            // face the way we walk
            if (art_faces != 0 && move_x != 0) image_xscale = art_scale * art_faces * sign(move_x);

            var moved = false;
            if (!place_meeting(x + move_x, y, obj_wall)) { x += move_x; moved = true; }
            if (!place_meeting(x, y + move_y, obj_wall)) { y += move_y; moved = true; }
            // wedged on a corner: slide along the wall instead of standing still
            if (!moved) {
                for (var k = -1; k <= 1; k += 2) {
                    var sxm = lengthdir_x(move_speed, dir + 90 * k), sym = lengthdir_y(move_speed, dir + 90 * k);
                    if (!place_meeting(x + sxm, y + sym, obj_wall)) { x += sxm; y += sym; path_t = 0; break; }
                }
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
        var fx0 = x, fy = bbox_bottom - 2;                 // from the feet, on the ground
        var aim = point_direction(fx0, fy, player.x, player.bbox_bottom - 6);
        if (ranged_kind == "bolt") {
            for (var i = 0; i < ranged_count; i++) {
                var a = aim + (i - (ranged_count - 1) / 2) * ranged_spread;
                instance_create_layer(fx0 + lengthdir_x(10, a), fy + lengthdir_y(10, a), "Instances", obj_projectile,
                    { kind: "bolt", dir: a, spd: ranged_speed, dmg: ranged_damage, col: ranged_colour });
            }
        } else {
            instance_create_layer(fx0, fy, "Instances", obj_projectile,
                { kind: "wave", dir: 0, spd: ranged_speed, dmg: ranged_damage, col: ranged_colour });
        }
    }

    if (ranged_cooldown > 0) ranged_cooldown -= 1;
}

depth = -bbox_bottom;