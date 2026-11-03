event_inherited();

// Skeleton: the steady melee threat.
move_speed = 0.9;
attack_damage = 12;
attack_range = 18;
max_hp = 40;
idle_sprite   = spr_skeleton_outline_idle;
walk_sprite   = spr_skeleton_outline_walk;
attack_sprite = spr_skeleton_outline_attack;
death_sprite  = spr_skeleton_outline_death;
mask_index = spr_mask_small;

// ranged: slams the ground, sending out a shockwave ring
ranged_kind = "wave";
ranged_sprite = spr_skeleton_outline_attack_b;
ranged_frame = 6;
ranged_min = 30;
ranged_max = 140;
ranged_damage = 12;
ranged_speed = 1.7;
ranged_colour = make_color_rgb(200, 220, 255);
ranged_cooldown_max = 180;

// fresh sprite + fixed feet hitbox (set after the parent picked the golem's)
sprite_index = idle_sprite;
image_index = 0;
art_scale = 1;
art_faces = 1;   // art looks right
image_xscale = 1;
image_yscale = 1;
hp = max_hp;
hp_shown = hp;
