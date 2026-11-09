var k = min(1, life / 30);                          // fades out at the end
var f = 0.8 + 0.2 * sin(current_time / 60 + x);
gpu_set_blendmode(bm_add);
draw_set_alpha(0.35 * k);
draw_set_color(make_color_rgb(255, 90, 20));
draw_ellipse(x - 10 * f, y - 4, x + 10 * f, y + 4, false);
draw_set_alpha(0.7 * k);
draw_set_color(make_color_rgb(255, 170, 60));
draw_ellipse(x - 5 * f, y - 7 * f, x + 5 * f, y + 2, false);
draw_set_color(make_color_rgb(255, 240, 180));
draw_ellipse(x - 2, y - 4 * f, x + 2, y + 1, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
