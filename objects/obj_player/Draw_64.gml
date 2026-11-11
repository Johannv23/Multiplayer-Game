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

// ---- dash charges ----
if (global.dash_unlocked) {
    for (var i = 0; i < dash_charges_max; i++) {
        var px = bar_x + i * 22, py = bar_y + bar_height + (global.cast_unlocked ? 30 : 12);
        draw_set_colour(c_black);
        draw_rectangle(px - 2, py - 2, px + 16, py + 8, false);
        draw_set_colour((i < dash_charges) ? make_color_rgb(140, 200, 255) : make_color_rgb(40, 50, 70));
        draw_rectangle(px, py, px + 14, py + 6, false);
    }
}
// ---- shield ----
if (shield > 0) {
    draw_set_colour(make_color_rgb(120, 220, 255));
    draw_rectangle(bar_x, bar_y - 8, bar_x + bar_width * (shield / 25), bar_y - 4, false);
}
// ---- Frenzy combo ----
if (instance_exists(obj_weapon) && blv(2, "frenzy") > 0 && (obj_weapon.combo > 1 || obj_weapon.cleave_ready)) {
    draw_set_halign(fa_right);
    draw_set_colour(obj_weapon.cleave_ready ? make_color_rgb(255, 120, 80) : c_white);
    var ctxt = obj_weapon.cleave_ready ? "CLEAVE READY" : ("COMBO x" + string(obj_weapon.combo));
    draw_text_transformed(gw - 30, 110, ctxt, 2, 2, 0);
    draw_set_halign(fa_left);
}
// ---- owned boons (top right) ----
var by_ = 150;
draw_set_halign(fa_right);
for (var i = 0; i < array_length(global.BOON_LIST); i++) {
    var b = global.BOON_LIST[i];
    var l = blv(b.side, b.id);
    if (l > 0) {
        draw_set_colour(b.col);
        draw_text(gw - 30, by_, ((b.side == 1) ? "P1 " : "P2 ") + b.name + "  " + string_repeat("I", l));
        by_ += 18;
    }
}
draw_set_halign(fa_left);

// ---- Bond meter (bottom centre) ----
if (global.allow_bond) {
    var mw = 260, mx_ = gw / 2 - mw / 2, my_ = gh - 86;
    var full = (global.bond >= 100);
    draw_set_colour(c_black);
    draw_rectangle(mx_ - 3, my_ - 3, mx_ + mw + 3, my_ + 11, false);
    draw_set_colour(full ? merge_color(make_color_rgb(255, 215, 120), c_white, 0.5 + 0.5 * sin(current_time / 100)) : make_color_rgb(180, 140, 60));
    draw_rectangle(mx_, my_, mx_ + mw * (global.bond / 100), my_ + 8, false);
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    var bt = full ? "BOND READY - P1 F + P2 UP together" : "BOND";
    if (full && bond1_t > 0) bt = "P1 READY - P2 press UP!";
    if (full && bond2_t > 0) bt = "P2 READY - P1 press F!";
    draw_text(gw / 2, my_ - 20, bt);
    draw_set_halign(fa_left);
}

if (bond_hint_t > 0) {
    draw_set_halign(fa_center);
    draw_set_alpha(min(1, bond_hint_t / 30));
    draw_set_colour(make_color_rgb(255, 215, 120));
    var sc = 2 + 0.1 * sin(current_time / 80);
    draw_text_transformed(gw / 2, gh / 2 - 120, "BOND READY!", sc, sc, 0);
    draw_set_colour(c_white);
    draw_text_transformed(gw / 2, gh / 2 - 84, "P1 F  +  P2 UP  at the same time", 1.5, 1.5, 0);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}

// ---- controls ----
draw_set_colour(c_white);
draw_set_alpha(0.75);
var p1 = "P1 ";
if (global.allow_move) p1 += "  WASD move";
if (global.allow_jump) p1 += "   Space jump";
if (global.allow_kick) p1 += "   E kick";
if (global.allow_recall) p1 += "   R recall weapon";
if (global.dash_unlocked) p1 += "   Shift dash";
if (global.cast_unlocked) p1 += "   Q soul ascension";
if (global.allow_bond) p1 += "   F bond";
if (global.stomp_unlocked) p1 += "   E in mid-air: Meteor Fall";
var p2 = "P2 ";
if (global.allow_attack) p2 += "  LEFT attack";
if (global.allow_detach) p2 += "   RIGHT fly out / return   I J K L move sword";
if (global.allow_bond) p2 += "   UP bond";
if (!instance_exists(obj_dialogue)) {
    draw_text(20, gh - 48, p1);
    draw_text(20, gh - 28, p2);
}
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
