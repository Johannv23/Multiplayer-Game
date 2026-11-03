if (dead) {                         // lie on the last death frame
    image_index = image_number - 1;
    image_speed = 0;
    exit;
}
if (bstate == "attack") {
    loops_left -= 1;
    if (loops_left > 0) {
        image_index = 0;
        fi = 0;
        face_player();
    } else {
        bstate = "recover";
        timer = (phase == 1) ? 45 : 30;
        sprite_index = idle_sprite;
        image_index = 0;
    }
}
else if (bstate == "break") {
    if (sprite_index == spr_golem_armored_armor_break) {
        sprite_index = spr_golem_upgrade;           // the stone body rises out of the armor
        image_index = 0;
    } else {
        phase = 2;
        idle_sprite = spr_golem_idle_a;
        walk_sprite = spr_golem_run;
        move_speed = 0.9;
        col_fx = make_color_rgb(255, 150, 70);
        ring(2.4, 15, 200, 0);                      // the armor bursts outward
        shake(8);
        bstate = "recover";
        timer = 40;
        sprite_index = idle_sprite;
        image_index = 0;
    }
}
