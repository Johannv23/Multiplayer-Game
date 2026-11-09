var gw = display_get_gui_width(), gh = display_get_gui_height();

// full-screen flash
if (global.flash_a > 0) {
    draw_set_alpha(global.flash_a);
    draw_set_color(global.flash_col);
    draw_rectangle(0, 0, gw, gh, false);
    draw_set_alpha(1);
}

// debug room menu
if (menu) {
    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(gw / 2 - 260, 140, gw / 2 + 260, 470, false);
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(255, 215, 120));
    draw_set_halign(fa_center);
    draw_text_transformed(gw / 2, 160, "SKIP TO ROOM", 2, 2, 0);
    draw_set_color(c_white);
    var names = ["1  Chamber 1", "2  Reliquary 1 (Shadowstep)", "3  Chamber 2", "4  Reliquary 2 (Soul Mark)", "5  The Stone Warden", "6  Reliquary 3 (Meteor Fall)"];
    for (var i = 0; i < 6; i++) draw_text_transformed(gw / 2, 210 + i * 36, names[i], 2, 2, 0);
    draw_text(gw / 2, 440, "Skipped Reliquaries hand out random boons.  F1 / ` closes.");
    draw_set_halign(fa_left);
}
draw_set_color(c_white);
