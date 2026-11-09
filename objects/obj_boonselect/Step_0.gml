t += 1;
if (done_t > 0) {
    done_t -= 1;
    if (done_t == 0) {
        global.freeze = false;
        with (obj_player) apply_boons();
        with (obj_weapon) apply_boons();
        if (duo_msg != "") with (obj_game) { unlock_msg = other.duo_msg; unlock_t = 300; }
        instance_destroy();
    }
    exit;
}

// player 1
if (!chosen[0]) {
    var n1 = array_length(offers[0]);
    if (keyboard_check_pressed(ord("A"))) sel[0] = (sel[0] + n1 - 1) mod n1;
    if (keyboard_check_pressed(ord("D"))) sel[0] = (sel[0] + 1) mod n1;
    if (keyboard_check_pressed(vk_space)) {
        keyboard_clear(vk_space);
        chosen[0] = true;
        grant_boon(1, offers[0][sel[0]].id);
        flash(offers[0][sel[0]].col, 0.25);
        shake(3);
    }
}
// player 2
if (!chosen[1]) {
    var n2 = array_length(offers[1]);
    if (keyboard_check_pressed(vk_left)) sel[1] = (sel[1] + n2 - 1) mod n2;
    if (keyboard_check_pressed(vk_right)) sel[1] = (sel[1] + 1) mod n2;
    if (keyboard_check_pressed(191) || keyboard_check_pressed(vk_numpad0)) {
        chosen[1] = true;
        grant_boon(2, offers[1][sel[1]].id);
        flash(offers[1][sel[1]].col, 0.25);
        shake(3);
    }
}
if (chosen[0] && chosen[1]) {
    duo_msg = check_duos();
    done_t = 40;
    if (duo_msg != "") { flash(c_white, 0.6); slowmo(30); }
}
