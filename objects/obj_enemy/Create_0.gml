move_speed = 0.7;

attack_damage = 10;
attack_range = 15;
attack_cooldown = 0;

chase_range = 150;

attacking = false;

dead = false;

sprite_index = spr_enemy_golem;
image_speed = 1;

attack_sound = -1;

// Enemy health
max_hp = 50;
hp = max_hp;

idle_sprite = spr_enemy_golem;
walk_sprite = spr_enemy_golem;
attack_sprite = spr_enemy_attack;
death_sprite = spr_enemy_death;

sprite_index = idle_sprite;
// health bar lag value (drains toward hp in Draw)
hp_shown = hp;

// fixed collision box at the feet, so attack/death frames never change the hitbox
mask_index = spr_mask_golem;

// facing: art_faces = 1 if the art looks right, -1 if it looks left, 0 = never flip
art_scale = 1;
art_faces = 0;

// ---- ranged attack (children override). kind "" = melee only.
// "wave": a ground shockwave ring that expands from the feet.  "bolt": a low shot along the ground.
// Both only hit while the player is on the ground (z < 6), so jumping clears them.
ranged_kind = "wave";
ranged_sprite = attack_sprite;
ranged_frame = 5;              // animation frame that releases the projectile
ranged_min = 40;               // only from this far...
ranged_max = 150;              // ...to this far
ranged_damage = 14;
ranged_speed = 1.6;            // wave: radius growth per frame. bolt: pixels per frame
ranged_count = 1;              // bolts per shot
ranged_spread = 18;            // degrees between bolts
ranged_colour = make_color_rgb(255, 150, 60);
ranged_cooldown_max = 200;
ranged_cooldown = 90 + irandom(90);   // don't all fire the moment they spawn
attack_is_ranged = false;
fired = false;

// ---- knockback / stun / falling (kick, cast, recall) ----
kb_speed = 0;
kb_dir = 0;
stun = 0;               // frames unable to move or attack
falling = false;        // kicked into the void
fall_t = 0;
recall_mark = -1;       // last weapon recall that hit us (each recall hits once)
hit_flash = 0;
drop_chance = 0.35;     // chance to drop a soul orb (heals) on death

function take_damage(_dmg, _crit = false) {
    if (dead) return;
    if (root_t > 0 && blv(1, "soulbloom") >= 2) _dmg *= 1.25;     // Soul Bloom: rooted enemies take more
    _dmg = max(1, round(_dmg));
    hp -= _dmg;
    hit_flash = 6;
    dmg_number(x, bbox_bottom - 34, _dmg, _crit);
    if (hp <= 0) {
        stop_attack_sound();
        dead = true;
        attacking = false;
        sprite_index = death_sprite;
        image_index = 0;
        image_speed = 1;
        // death burst
        fx("soul", x, bbox_bottom - 10, 16);
        fx("shard", x, bbox_bottom - 8, 10);
        fx("spark", x, bbox_bottom - 10, 8);
        fx_ring(x, bbox_bottom - 6, 22, make_color_rgb(220, 190, 255));
        shake(3);
        hitstop(3);
        if (random(1) < drop_chance) instance_create_layer(x, bbox_bottom - 4, "Instances", obj_pickup);
    }
}

// cancel a windup (kicked, rooted)
function interrupt() {
    stop_attack_sound();
    if (attacking) {
        attacking = false;
        attack_is_ranged = false;
        attack_cooldown = 30;
        sprite_index = idle_sprite;
        image_index = 0;
    }
}

// overlapping the void (plain obj_wall, not a block/prop/door child)?
function over_void() {
    var lst = ds_list_create();
    var n = instance_place_list(x, y, obj_wall, lst, false);
    var res = false;
    for (var i = 0; i < n; i++) if (lst[| i].object_index == obj_wall) res = true;
    ds_list_destroy(lst);
    return res;
}

// solid things that stop a knockback (the void doesn't: that's how you kick enemies off)
function blocked_at(_x, _y) {
    return place_meeting(_x, _y, obj_block) || place_meeting(_x, _y, obj_prop) || place_meeting(_x, _y, obj_door);
}

// the attack sound is a 10 s file: we play 0.8 s - 2.7 s of it and must always stop it ourselves
function stop_attack_sound() {
    if (attack_sound != -1) {
        audio_stop_sound(attack_sound);
        attack_sound = -1;
    }
}

// ---- boon hooks ----
root_t = 0;              // rooted by a cast (Soul Bloom watches it)
root_bloom = false;      // Soul Bloom Lv3: burst when the root ends
missile = 0;             // Cannon Kick level while flying from a kick
missile_mark = noone;    // last flying enemy that hit us
phantom_mark = -1;       // last Phantom Step dash that sliced us
orbit_cd = 0;            // Whirling Return hit cooldown
hit_h = 0;               // how tall the body is above the feet for hits (0 = feet only; the Warden is tall)
lash_cd = 0;             // Tether Lash burn cooldown
skewer_cd = 0;           // Skewer cooldown
show_bar = true;

// ---- guard & stagger ----
// A GUARDED enemy blocks most sword damage. A kick STAGGERS it: guard down, and every enemy
// takes 1.5x sword damage while staggered. So the hero sets enemies up and the sword finishes them.
guarded = true;          // the golem is guarded; children set their own
stagger = 0;             // frames left
stagger_max = 120;
stagger_cd = 0;          // the boss can only be staggered every few seconds

// ---- pathfinding around walls (obj_game builds the grid) ----
mypath = path_add();
path_t = irandom(20);    // re-plan timer (staggered so enemies don't all plan on one frame)
path_i = 1;
path_ok = false;
