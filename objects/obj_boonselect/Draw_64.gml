var gw = display_get_gui_width(), gh = display_get_gui_height();
draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(0, 0, gw, gh, false);
draw_set_alpha(1);

draw_set_halign(fa_center);
draw_set_color(make_color_rgb(150, 240, 255));
draw_text_transformed(gw / 2, 40, "THE RELIQUARY'S POWER", 3, 3, 0);
draw_set_color(c_white);
draw_text_transformed(gw / 4, 100, "P1  -  BODY", 2, 2, 0);
draw_text_transformed(3 * gw / 4, 100, "P2  -  BLADE", 2, 2, 0);
draw_set_color(make_color_rgb(170, 175, 190));
draw_text(gw / 2, 76, "FLAIR = a new move     BOND = helps your partner     STAT = base stats");

var cw = 190, chh = 300, gap = 12;
for (var s = 0; s < 2; s++) {
    var list = offers[s];
    var n = array_length(list);
    var half_x = (s == 0) ? 0 : gw / 2;
    var start = half_x + (gw / 2 - (n * cw + (n - 1) * gap)) / 2;
    for (var i = 0; i < n; i++) {
        var b = list[i];
        var lv_now = blv(s + 1, b.id);
        var is_sel = (sel[s] == i);
        var picked = chosen[s] && is_sel;
        var x1 = start + i * (cw + gap);
        var y1 = 140 - (is_sel && !chosen[s] ? 8 + 3 * sin(t / 8) : 0);
        // card
        draw_set_alpha((chosen[s] && !is_sel) ? 0.35 : 1);
        draw_set_color(make_color_rgb(18, 20, 30));
        draw_rectangle(x1, y1, x1 + cw, y1 + chh, false);
        draw_set_color(b.col);
        draw_rectangle(x1, y1, x1 + cw, y1 + chh, true);
        if (is_sel) {
            draw_rectangle(x1 - 2, y1 - 2, x1 + cw + 2, y1 + chh + 2, true);
            draw_rectangle(x1 - 3, y1 - 3, x1 + cw + 3, y1 + chh + 3, true);
        }
        draw_rectangle(x1, y1, x1 + cw, y1 + 6, false);
        // name, level, what the next level does
        draw_set_color(b.col);
        draw_text_ext_transformed(x1 + cw / 2, y1 + 20, b.name, 14, (cw - 16) / 1.5, 1.5, 1.5, 0);
        draw_set_color(c_white);
        var lvtxt = (lv_now == 0) ? "NEW" : ("Lv " + string(lv_now) + "  >  " + string(lv_now + 1));
        if (lv_now >= 3) lvtxt = "MAX";                       // just taken its last level (the card stays on screen)
        draw_text(x1 + cw / 2, y1 + 82, lvtxt);
        draw_set_color(make_color_rgb(210, 215, 230));
        draw_text_ext(x1 + cw / 2, y1 + 112, b.desc[min(lv_now, 2)], 18, cw - 20);
        // category tag: FLAIR (a new move) / BOND (helps your partner) / STAT (base numbers)
        var ctag = "STAT", ccol = make_color_rgb(170, 175, 190);
        if (b.cat == "flair") { ctag = "FLAIR"; ccol = make_color_rgb(255, 170, 80); }
        if (b.cat == "bond")  { ctag = "BOND";  ccol = make_color_rgb(255, 215, 120); }
        draw_set_color(ccol);
        draw_rectangle(x1 + cw / 2 - 34, y1 + chh - 54, x1 + cw / 2 + 34, y1 + chh - 36, true);
        draw_text(x1 + cw / 2, y1 + chh - 52, ctag);
        // pips for the 3 levels
        for (var k = 0; k < 3; k++) {
            var px = x1 + cw / 2 - 30 + k * 22;
            draw_set_color((k < lv_now) ? b.col : ((k == lv_now) ? c_white : make_color_rgb(60, 60, 70)));
            draw_rectangle(px, y1 + chh - 26, px + 16, y1 + chh - 18, false);
        }
        if (picked) {
            draw_set_color(b.col);
            draw_text_transformed(x1 + cw / 2, y1 + chh + 12, "CHOSEN", 2, 2, 0);
        }
        draw_set_alpha(1);
    }
    draw_set_color(make_color_rgb(180, 180, 190));
    var hint = (s == 0) ? "A / D to pick,  SPACE to take it" : "J / L to pick,  LEFT ARROW to take it";
    if (n == 0) hint = "Nothing left to learn here";
    if (!chosen[s] || n == 0) draw_text_transformed(half_x + gw / 4, 140 + chh + 50, hint, 1.5, 1.5, 0);
}
draw_set_halign(fa_left);
draw_set_color(c_white);
