// Training sentinel inside a Reliquary: stands still, never attacks, can't die. Rooted / hit for the lessons.
event_inherited();
guarded = false;      // no guard
idle_sprite = spr_golem_idle_a;
walk_sprite = spr_golem_idle_a;
attack_sprite = spr_golem_idle_a;
death_sprite = spr_golem_idle_a;
sprite_index = idle_sprite;
image_speed = 1;
image_blend = make_color_rgb(150, 160, 190);    // pale stone
mask_index = spr_mask_small;
max_hp = 9999;
hp = max_hp;
hp_shown = hp;
ranged_kind = "";
drop_chance = 0;
art_faces = 0;
show_bar = false;
y -= 10;                 // feet on the cell
times_hit = 0;

function take_damage(_dmg, _crit = false) {
    _dmg = max(1, round(_dmg));
    hp = max(1, hp - _dmg);
    hit_flash = 6;
    times_hit += 1;
    dmg_number(x, bbox_bottom - 34, _dmg, _crit);
}
function interrupt() { }
