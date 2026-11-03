// ---- boss room: one heal on arrival ----
if (boss_rest && instance_exists(obj_player)) {
    boss_rest = false;
    obj_player.hp = min(obj_player.max_hp, obj_player.hp + 30);
}

// ---- spawn warnings count down, then the enemy appears (waves and boss summons) ----
if (use_waves || boss_room) {
    for (var i = array_length(pending) - 1; i >= 0; i--) {
        var p = pending[i];
        p.t -= 1;
        if (p.t <= 0) {
            // chambers are bigger than the old chase range, so wave enemies always hunt the player
            with (instance_create_layer(p.x, p.y, "Instances", p.obj)) {
                y += (p.y + 12) - bbox_bottom;   // stand the enemy's feet on the spawn point
                chase_range = 2000;
            }
            array_delete(pending, i, 1);
        }
    }
}

if (use_waves) {
    // ---- next wave once this one is dead, then open the doors ----
    if (!cleared && array_length(pending) == 0 && instance_number(obj_enemy) == 0) {
        if (wave_delay > 0) {
            wave_delay -= 1;
        }
        else if (wave + 1 < array_length(waves)) {
            wave += 1;
            start_wave(waves[wave]);
            wave_delay = 60;
        }
        else {
            cleared = true;
            with (obj_door) open_door();
            // progression: chamber 1 teaches dash, chamber 2 teaches cast
            if (room == rm_chamber_1 && !global.dash_unlocked) {
                global.dash_unlocked = true;
                unlock_msg = "DASH UNLOCKED  -  Shift (invulnerable while dashing)";
                unlock_t = 300;
            }
            else if (room == rm_chamber_2 && !global.cast_unlocked) {
                global.cast_unlocked = true;
                unlock_msg = "CAST UNLOCKED  -  Q (charges as the weapon lands hits)";
                unlock_t = 300;
            }
        }
    }
}
else if (!boss_room) {
    // ---- old open-field spawner (rm_level) ----
    spawn_timer += 1;
    if (spawn_timer >= spawn_interval) {
        spawn_timer = 0;
        if (instance_number(obj_enemy) < max_enemies && instance_exists(obj_player)) {
            var dir = random(360);
            var spawn_x = clamp(obj_player.x + lengthdir_x(100, dir), 16, room_width - 16);
            var spawn_y = clamp(obj_player.y + lengthdir_y(100, dir), 16, room_height - 16);
            if (!position_meeting(spawn_x, spawn_y, obj_wall)) {
                instance_create_layer(spawn_x, spawn_y, "Instances", choose(obj_enemy, obj_enemy_2));
            }
        }
    }
}

// Toggle debug hitboxes
if (keyboard_check_pressed(ord("B"))) {
    global.show_hitboxes = !global.show_hitboxes;
}

// Toggle lighting
if (keyboard_check_pressed(ord("L")) && instance_exists(obj_lighting)) {
    obj_lighting.enabled = !obj_lighting.enabled;
}

if (unlock_t > 0) unlock_t -= 1;
