spawn_timer += 1;

if (spawn_timer >= spawn_interval) {

    spawn_timer = 0;

    if (instance_number(obj_enemy) < max_enemies) {

        if (instance_exists(obj_player)) {

            var dir = random(360);

            var spawn_x = obj_player.x + lengthdir_x(100, dir);
            var spawn_y = obj_player.y + lengthdir_y(100, dir);

            spawn_x = clamp(spawn_x, 16, room_width - 16);
            spawn_y = clamp(spawn_y, 16, room_height - 16);

            if (!position_meeting(spawn_x, spawn_y, obj_wall)) {

                instance_create_layer(
                    spawn_x,
                    spawn_y,
                    "Instances",
                    obj_enemy
                );
            }
        }
    }
}