// ---- tuning ----
// (the camera shows 320x180 at 4x, so 1 world pixel = 4 screen pixels)
max_speed = 1.5;        // pixels per frame at full speed
accel     = 0.25;       // how fast we speed up (~6 frames to full speed)
fric      = 0.2;        // how fast we slow down with no input

jump_grav  = 0.19;      // pulls z back down each frame
jump_speed = 3;         // peak = v*v / (2*grav) = ~24px (3/4 of the character), ~16 frames up + 16 down
slash_fric = 0.15;      // how fast we stop while swinging

scale = 1;              // art size multiplier (1 = pixel-perfect with the 16px tiles)

// ---- state ----
hsp = 0;                // horizontal speed
vsp = 0;                // vertical speed
z = 0;                  // height above the ground (drawn as an upward offset; walls still block)
zspd = 0;               // vertical speed of the jump, positive = rising
air_time = 2 * jump_speed / jump_grav;  // frames from takeoff to landing, times the flip
jump_timer = 0;         // frames since takeoff
state = "move";         // "move", "jump" or "slash"
facing = 6;             // 0-7, one step per 45 degrees: 0 right, 2 up, 4 left, 6 down
face_x = 1;             // last horizontal direction (1 or -1), picks the slash side when facing straight up/down
slash_dir = 3;          // index into slash_sprites / sword_sprites

// ---- sprites, indexed by facing (counter-clockwise from right, like point_direction) ----
walk_sprites = [spr_player_right, spr_player_upright, spr_player_up, spr_player_upleft,
            spr_player_left, spr_player_downleft, spr_player_down, spr_player_downright];
// the roll strip doubles as the jump's front flip
flip_sprites = [spr_player_roll_right, spr_player_roll_upright, spr_player_roll_up, spr_player_roll_upleft,
            spr_player_roll_left, spr_player_roll_downleft, spr_player_roll_down, spr_player_roll_downright];

// slash art only exists for the 4 diagonals: 0 up-right, 1 up-left, 2 down-left, 3 down-right
slash_sprites = [spr_player_slash_upright, spr_player_slash_upleft, spr_player_slash_downleft, spr_player_slash_downright];
sword_sprites = [spr_sword_upright, spr_sword_upleft, spr_sword_downleft, spr_sword_downright];

// fixed 12x12 hitbox at the feet so animation frames never change collision
mask_index = spr_player_mask;
image_xscale = scale;
image_yscale = scale;
sprite_index = walk_sprites[facing];
image_index = 0;
image_speed = 0;

// Health bar
max_hp = 100;
hp = max_hp;

// Slash damage
slash_damage = 10;
slash_hit = false;