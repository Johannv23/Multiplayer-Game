// End Step: runs after the player has moved this frame, so the camera doesn't lag or jitter
if (instance_exists(obj_player)) {
    var tx = obj_player.x - view_w / 2;
    var ty = obj_player.y - view_h / 2;
    cam_x = lerp(cam_x, tx, follow_speed);
    cam_y = lerp(cam_y, ty, follow_speed);
}

// keep the view inside the room
cam_x = clamp(cam_x, 0, room_width  - view_w);
cam_y = clamp(cam_y, 0, room_height - view_h);

// no round(): at 4x zoom whole-pixel snapping makes the world step 4 screen pixels at a time,
// out of sync with the player, which looks like shaking
var sx = random_range(-shake_amt, shake_amt), sy = random_range(-shake_amt, shake_amt);
shake_amt = max(0, shake_amt - 0.4);
camera_set_view_pos(cam, cam_x + sx, cam_y + sy);
