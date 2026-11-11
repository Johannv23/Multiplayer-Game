event_inherited();
guarded = false;      // no guard

// Slime: slow, tanky, hits hard.
move_speed = 0.6;
attack_damage = 10;
attack_range = 16;
max_hp = 35;
idle_sprite   = spr_slime_basic_outline_idle;
walk_sprite   = spr_slime_basic_outline_move;
attack_sprite = spr_slime_basic_outline_attack;
death_sprite  = spr_slime_basic_outline_death;
mask_index = spr_mask_wide;

// ranged: spits a fan of 3 slime bolts along the ground
ranged_kind = "bolt";
ranged_sprite = spr_slime_basic_outline_attack_b;
ranged_frame = 6;
ranged_min = 50;
ranged_max = 220;
ranged_damage = 10;
ranged_speed = 2.2;
ranged_count = 3;
ranged_spread = 16;
ranged_colour = make_color_rgb(80, 170, 255);
ranged_cooldown_max = 150;

// fresh sprite + fixed feet hitbox (set after the parent picked the golem's)
sprite_index = idle_sprite;
image_index = 0;
art_scale = 1;
art_faces = 1;   // art looks right
image_xscale = 1;
image_yscale = 1;
hp = max_hp;
hp_shown = hp;
