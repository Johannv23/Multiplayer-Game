var gw = display_get_gui_width(), gh = display_get_gui_height();

// ---- health bar ----
var bar_x = 20, bar_y = 20, bar_width = 200, bar_height = 20, border = 4;
draw_set_colour(c_black);
draw_rectangle(bar_x - border, bar_y - border, bar_x + bar_width + border, bar_y + bar_height + border, false);
draw_set_colour(c_red);
draw_rectangle(bar_x, bar_y, bar_x + bar_width * (hp / max_hp), bar_y + bar_height, false);

// ---- cast charge (fills as the weapon lands hits) ----
if (global.cast_unlocked) {
    var cy = bar_y + bar_height + 12;
    draw_set_colour(c_black);
    draw_rectangle(bar_x - 2, cy - 2, bar_x + bar_width + 2, cy + 10, false);
    draw_set_colour((cast_charge >= 100) ? make_color_rgb(220, 140, 255) : make_color_rgb(120, 70, 170));
    draw_rectangle(bar_x, cy, bar_x + bar_width * (cast_charge / 100), cy + 8, false);
    if (cast_charge >= 100) {
        draw_set_colour(c_white);
        draw_text(bar_x + bar_width + 12, cy - 4, "CAST READY (Q)");
    }
}

// ---- controls ----
draw_set_colour(c_white);
draw_set_alpha(0.75);
var p1 = "P1  WASD move   Space jump   E kick   R recall weapon";
if (global.dash_unlocked) p1 += "   Shift dash";
if (global.cast_unlocked) p1 += "   Q cast";
draw_text(20, gh - 48, p1);
draw_text(20, gh - 28, "P2  Arrows move weapon   / attack   . detach / return");
draw_set_alpha(1);

// ---- death ----
if (state == "dead") {
    draw_set_halign(fa_center);
    draw_set_colour(c_black);
    draw_set_alpha(0.5);
    draw_rectangle(0, 0, gw, gh, false);
    draw_set_alpha(1);
    draw_set_colour(c_red);
    draw_text_transformed(gw / 2, gh / 2 - 40, "YOU DIED", 4, 4, 0);
    draw_set_colour(c_white);
    draw_text_transformed(gw / 2, gh / 2 + 30, "Press Enter to start a new run", 2, 2, 0);
    draw_set_halign(fa_left);
}
draw_set_colour(c_white);
