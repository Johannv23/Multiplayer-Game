// Spawn timer
spawn_timer += 1;

// Spawn every 3 seconds (at 60 FPS)
if (spawn_timer >= spawn_interval) {

    spawn_timer = 0;

    // Maximum number of enemies
    if (instance_number(obj_enemy) < max_enemies) {

        if (instance_exists(obj_player)) {

            // Random spawn direction
            var dir = random(360);

            // Spawn around player
            var spawn_x = obj_player.x + lengthdir_x(100, dir);
            var spawn_y = obj_player.y + lengthdir_y(100, dir);

            // Keep enemies inside the room
            spawn_x = clamp(spawn_x, 16, room_width - 16);
            spawn_y = clamp(spawn_y, 16, room_height - 16);

            // Check for walls
            if (!position_meeting(spawn_x, spawn_y, obj_wall)) {

                // Randomly choose Enemy 1 or Enemy 2
                var enemy_type = choose(obj_enemy, obj_enemy_2);

                // Spawn enemy
                instance_create_layer(
                    spawn_x,
                    spawn_y,
                    "Instances",
                    enemy_type
                );
            }
        }
    }
}