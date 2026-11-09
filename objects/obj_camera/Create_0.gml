cam = view_camera[0];
view_w = camera_get_view_width(cam);    // 320x180 from the room's camera settings,
view_h = camera_get_view_height(cam);   // scaled up 4x to the 1280x720 viewport

follow_speed = 0.1;   // 0-1: lower = lazier camera, 1 = locked to player

// start centered on the player so the first frame doesn't swoop
if (instance_exists(obj_player)) {
    cam_x = obj_player.x - view_w / 2;
    cam_y = obj_player.y - view_h / 2;
} else {
    cam_x = 0;
    cam_y = 0;
}

shake_amt = 0;        // pixels of random offset, fades out (set through shake() in scr_utility)
