event_inherited();

// Different enemy stats
move_speed = 1.2;
chase_range = 200;

attack_damage = 15;
attack_range = 20;

max_hp = 50;
hp = max_hp;
hp_shown = hp;


// Enemy 2 sprites
idle_sprite = spr_enemy_demon;
walk_sprite = spr_enemy_demon_walk;
attack_sprite = spr_enemy_demon_attack;
death_sprite = spr_enemy_demon_death;

sprite_index = idle_sprite;
image_index = 0;

// Scale (the demon art faces left)
art_scale = 0.75;
art_faces = -1;
image_xscale = 0.75;
image_yscale = 0.75;



// fixed collision box at the feet (the attack frames were ~140px wide)
mask_index = spr_mask_demon;

// demon: a big slow shockwave
ranged_sprite = spr_enemy_demon_attack;
ranged_frame = 10;
ranged_damage = 18;
