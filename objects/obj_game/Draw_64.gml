if (use_waves) {
    var txt = "";
    if (cleared) txt = "Chamber clear - take a door";
    else if (wave >= 0) txt = "Wave " + string(wave + 1) + " / " + string(array_length(waves));
    if (txt != "") {
        draw_set_halign(fa_center);
        draw_set_color(c_black);
        draw_text_transformed(display_get_gui_width() / 2 + 2, 26, txt, 2, 2, 0);
        draw_set_color(c_white);
        draw_text_transformed(display_get_gui_width() / 2, 24, txt, 2, 2, 0);
        draw_set_halign(fa_left);
    }
}

if (unlock_t > 0) {
    var a = min(1, unlock_t / 30);
    draw_set_halign(fa_center);
    draw_set_alpha(a);
    draw_set_color(c_black);
    draw_text_transformed(display_get_gui_width() / 2 + 2, display_get_gui_height() / 2 - 118, unlock_msg, 2, 2, 0);
    draw_set_color(make_color_rgb(255, 215, 120));
    draw_text_transformed(display_get_gui_width() / 2, display_get_gui_height() / 2 - 120, unlock_msg, 2, 2, 0);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
}
