if (paused()) exit;
if (hit_flash > 0) hit_flash -= 1;
kb_speed = 0;                            // rooted to the floor
if (stun > 0) stun -= 1;
if (root_t > 0) {
    root_t -= 1;
    if (root_t == 0 && root_bloom) explode(x, bbox_bottom - 5, 34, 12, make_color_rgb(210, 130, 255));
}
depth = -bbox_bottom;
