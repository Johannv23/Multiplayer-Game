var gw = display_get_gui_width(), gh = display_get_gui_height();

// title card during the intro
if (bstate == "intro") {
    var a = min(1, (intro_max - timer) / 20) * min(1, timer / 20 + 0.3);
    draw_set_halign(fa_center);
    draw_set_alpha(a);
    draw_set_color(c_black);
    draw_text_transformed(gw / 2 + 3, gh / 2 - 157, boss_name, 4, 4, 0);
    draw_set_color(make_color_rgb(190, 210, 255));
    draw_text_transformed(gw / 2, gh / 2 - 160, boss_name, 4, 4, 0);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}

if (dead) exit;

// boss health bar: top centre, with a notch where the armor breaks
hp_shown = lerp(hp_shown, hp, 0.08);
var bw = 600, bh = 16, bx = gw / 2 - bw / 2, by = 70;
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(gw / 2, by - 20, boss_name + ((phase == 1) ? "" : "  (ENRAGED)"));
draw_set_halign(fa_left);
draw_set_color(c_black);
draw_rectangle(bx - 3, by - 3, bx + bw + 3, by + bh + 3, false);
draw_set_color(make_color_rgb(255, 230, 230));
draw_rectangle(bx, by, bx + bw * (hp_shown / max_hp), by + bh, false);
draw_set_color((phase == 1) ? make_color_rgb(110, 140, 210) : make_color_rgb(230, 110, 50));
draw_rectangle(bx, by, bx + bw * (max(0, hp) / max_hp), by + bh, false);
draw_set_color(c_black);
draw_line_width(bx + bw / 2, by - 3, bx + bw / 2, by + bh + 3, 2);
draw_set_color(c_white);
