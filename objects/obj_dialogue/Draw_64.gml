if (idx >= array_length(lines)) exit;
var gw = display_get_gui_width(), gh = display_get_gui_height();
var who = lines[idx][0], txt = lines[idx][1];
var bx1 = 140, bx2 = gw - 140, by1 = gh - 200, by2 = gh - 50;

// box
draw_set_alpha(0.85);
draw_set_color(make_color_rgb(10, 12, 20));
draw_rectangle(bx1, by1, bx2, by2, false);
draw_set_alpha(1);
var col = (who == "SWORD") ? make_color_rgb(255, 210, 120) : make_color_rgb(160, 200, 255);
draw_set_color(col);
draw_rectangle(bx1, by1, bx2, by2, true);

// speaker + typed text
draw_text_transformed(bx1 + 20, by1 + 14, who, 2, 2, 0);
draw_set_color(c_white);
draw_text_ext_transformed(bx1 + 20, by1 + 52, string_copy(txt, 1, floor(shown)), 18, (bx2 - bx1 - 40) / 2, 2, 2, 0);

// prompt once the line is fully shown
if (shown >= string_length(txt) && (current_time div 400) mod 2 == 0) {
    draw_set_halign(fa_right);
    draw_set_color(col);
    draw_text_transformed(bx2 - 20, by2 - 30, "SPACE  >", 2, 2, 0);
    draw_set_halign(fa_left);
}
draw_set_color(c_white);
