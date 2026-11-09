// adding a Draw event replaces default drawing, so draw the sprite ourselves
draw_self();
if (hit_flash > 0) {                   // white flash on hit
    gpu_set_fog(true, c_white, 0, 0);
    draw_self();
    gpu_set_fog(false, c_white, 0, 0);
}

if (!dead && show_bar) {
    // ---- health bar above the head ----
    // anchored to the idle sprite's top so it doesn't jump around as animation frames change size
    var bar_w = 20;
    var bar_h = 3;
    var head_y = y + (sprite_get_bbox_top(idle_sprite) - sprite_get_yoffset(idle_sprite)) * abs(image_yscale);
    var bx = round(x - bar_w / 2);
    var by = round(head_y - 6);

    // the lag bar drains slowly behind the real hp so each hit reads as a chunk
    hp_shown = lerp(hp_shown, hp, 0.08);

    draw_set_color(c_black);
    draw_rectangle(bx - 1, by - 1, bx + bar_w, by + bar_h, false);              // border
    draw_set_color(make_color_rgb(255, 230, 230));
    draw_rectangle(bx, by, bx + bar_w * (hp_shown / max_hp) - 1, by + bar_h - 1, false); // damage taken (lag)
    draw_set_color(make_color_rgb(220, 40, 40));
    if (hp > 0) draw_rectangle(bx, by, bx + bar_w * (hp / max_hp) - 1, by + bar_h - 1, false);
    draw_set_color(c_white);

    // stunned: little stars circling above the head
    if (stun > 0) {
        draw_set_color(make_color_rgb(230, 200, 255));
        for (var i = 0; i < 3; i++) {
            var a = current_time / 4 + i * 120;
            draw_circle(x + lengthdir_x(8, a), by - 6 + lengthdir_y(3, a), 1.5, false);
        }
        draw_set_color(c_white);
    }

    // ---- debug: body hitbox (red) and attack range (orange circle) ----
    draw_hitbox(c_red);
    if (global.show_hitboxes) {
        draw_set_color(c_orange);
        draw_circle(x, y, attack_range, true);
        draw_circle(x, y, 1, false);
        draw_set_color(c_white);
    }
}
