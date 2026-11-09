// the current lesson goal at the top of the screen
if (instance_exists(obj_dialogue) || instance_exists(obj_boonselect) || step >= array_length(steps)) exit;
var s = steps[step];
if (s[0] != "task") exit;
var txt = "";
switch (s[1]) {
    case "runes":
        var lit_n = 0, all_n = 0;
        with (obj_rune) { all_n += 1; if (lit) lit_n += 1; }
        txt = "P1: Dash (Shift) through the runes  " + string(lit_n) + " / " + string(all_n);
        break;
    case "root":
        txt = (obj_player.cast_charge < 100) ? "P2: Strike the sentinels to charge the soul mark" : "P1: Press Q to throw the soul mark";
        break;
    case "stomp":
        txt = "P1: Jump (Space), then E in mid-air near a sentinel";
        break;
}
if (task_done_t > 0) txt = "Nice!";
var gw = display_get_gui_width();
draw_set_halign(fa_center);
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(gw / 2 - 380, 52, gw / 2 + 380, 92, false);
draw_set_alpha(1);
draw_set_color((task_done_t > 0) ? make_color_rgb(140, 255, 140) : make_color_rgb(255, 225, 140));
draw_text_transformed(gw / 2, 60, txt, 2, 2, 0);
draw_set_halign(fa_left);
draw_set_color(c_white);
