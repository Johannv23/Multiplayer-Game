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

// Slash sound
slash_sound_id = -1;
// red flash when hit (frames)
hurt_flash = 0;

invuln = 0;             // frames of invulnerability (dash, after a hit)

// ---- dash (player 1, unlocked after chamber 1) ----
dash_speed  = 4.5;
dash_frames = 9;        // ~40px
dash_timer  = 0;
dash_cd     = 0;
dash_cd_max = 36;
dash_dir    = 0;
ghosts = [];            // afterimages: [x, y, sprite, frame]

// ---- kick (player 1): shoves enemies; next to a pit it kills them ----
kick_range  = 30;
kick_force  = 5;
kick_damage = 3;
kick_cd     = 0;
kick_timer  = 0;        // > 0 while the kick arc is drawn
kick_dir    = 0;

// ---- cast (player 1, unlocked after chamber 2): charges when the weapon lands hits ----
cast_charge = 0;        // 0-100

// carry HP between chambers
if (global.player_hp > 0) hp = global.player_hp;

// player 2's weapon
if (!instance_exists(obj_weapon)) instance_create_layer(x, y, "Instances", obj_weapon);

// ---- called by obj_weapon when player 2 attacks while the weapon is held ----
function start_slash() {
    if (state != "move") return;
    // pick the closest diagonal: facing 1-3 is "up", face_x picks left or right
    var up = (facing >= 1 && facing <= 3);
    if (up) slash_dir = (face_x > 0) ? 0 : 1;
    else    slash_dir = (face_x > 0) ? 3 : 2;
    state = "slash";
    slash_hit = false;
    set_anim(slash_sprites[slash_dir]);   // ends in Animation End

    slash_sound_id = audio_play_sound(slash_sound, 1, false);
    audio_sound_set_track_position(slash_sound_id, 0);

    var hit_x = x + ((slash_dir == 0 || slash_dir == 3) ? 20 : -20);
    var hit_y = y + ((slash_dir <= 1) ? -20 : 20);
    // the hitbox sprite's origin is Top Left, so shift by half its size to centre it
    var half = sprite_get_width(slash_hitbox) / 2;
    var s = instance_create_layer(hit_x - half, hit_y - half, "Instances", obj_slash);
    s.damage = slash_damage;
}

function do_kick() {
    kick_cd = 30;
    kick_timer = 8;
    kick_dir = facing * 45;
    var fx = x, fy = bbox_bottom - 6, kdir = kick_dir;
    with (obj_enemy) {
        var ex = x, ey = bbox_bottom - 5;
        if (!dead && point_distance(fx, fy, ex, ey) < other.kick_range
            && abs(angle_difference(point_direction(fx, fy, ex, ey), kdir)) < 75) {
            interrupt();
            kb_dir = point_direction(fx, fy, ex, ey);
            kb_speed = other.kick_force;
            stun = max(stun, 30);
            take_damage(other.kick_damage);
        }
    }
}

function do_cast() {
    cast_charge = 0;
    // lands 110px ahead, or on the nearest enemy within 180px (aim assist)
    var tx = x + lengthdir_x(110, facing * 45), ty = y + lengthdir_y(110, facing * 45);
    var best = noone, bd = 180;
    with (obj_enemy) if (!dead && point_distance(x, y, other.x, other.y) < bd) { best = id; bd = point_distance(x, y, other.x, other.y); }
    if (best != noone) { tx = best.x; ty = best.bbox_bottom - 5; }
    instance_create_layer(x, bbox_bottom - 6, "Instances", obj_cast, { tx: tx, ty: ty });
}
