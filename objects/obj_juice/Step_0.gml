// ---- clocks ----
if (global.hitstop_t > 0) global.hitstop_t -= 1;
if (global.slowmo_t > 0) {
    global.slowmo_t -= 1;
    if (game_get_speed(gamespeed_fps) != 30) game_set_speed(30, gamespeed_fps);   // bullet time
} else if (game_get_speed(gamespeed_fps) != 60) {
    game_set_speed(60, gamespeed_fps);
}
global.flash_a = max(0, global.flash_a - 0.04);

// ---- debug keys ----
if (keyboard_check_pressed(vk_f1) || keyboard_check_pressed(192)) menu = !menu;   // F1 or `
if (menu) {
    for (var k = 1; k <= 6; k++) {
        if (keyboard_check_pressed(ord(string(k)))) {
            menu = false;
            global.slowmo_t = 0;
            game_set_speed(60, gamespeed_fps);
            debug_jump(k);
        }
    }
}
if (keyboard_check_pressed(vk_backspace)) debug_skip();
