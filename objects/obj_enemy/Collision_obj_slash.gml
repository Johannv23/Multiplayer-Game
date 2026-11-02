if (!dead) {

    hp -= other.damage;

    with (other) {
        instance_destroy();
    }

    if (hp <= 0) {

        dead = true;
        attacking = false;

        sprite_index = spr_enemy_death;
        image_index = 0;
        image_speed = 1;
    }
}