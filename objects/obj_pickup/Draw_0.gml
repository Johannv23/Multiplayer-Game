if (life > life_max - 120 && (life div 6) mod 2 == 0) exit;     // blink before vanishing
var yy = y - 6 + sin((current_time / 200) + bob) * 2;
draw_set_color(c_black);
draw_set_alpha(0.3);
draw_ellipse(x - 3, y - 1, x + 3, y + 1, false);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.5);
draw_set_color(make_color_rgb(255, 80, 110));
draw_circle(x, yy, 5, false);
draw_set_alpha(1);
draw_circle(x, yy, 3, false);
draw_set_color(c_white);
draw_circle(x, yy, 1.5, false);
gpu_set_blendmode(bm_normal);
draw_set_color(c_white);
