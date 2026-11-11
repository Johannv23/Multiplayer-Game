event_inherited();
guarded = false;      // no guard

// Rat: weak and quick. Chamber 1 fodder.
move_speed = 1.1;
attack_damage = 5;
attack_range = 14;
max_hp = 20;
idle_sprite   = spr_rat_basic_outline_idle;
walk_sprite   = spr_rat_basic_outline_run;
attack_sprite = spr_rat_basic_outline_attack;
death_sprite  = spr_rat_basic_outline_death;
mask_index = spr_mask_small;

ranged_kind = "";                // rats just swarm

// fresh sprite + fixed feet hitbox (set after the parent picked the golem's)
sprite_index = idle_sprite;
image_index = 0;
art_scale = 1;
art_faces = 1;   // art looks right
image_xscale = 1;
image_yscale = 1;
hp = max_hp;
hp_shown = hp;
