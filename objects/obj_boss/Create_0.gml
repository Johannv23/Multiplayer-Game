// THE STONE WARDEN - boss of the run (Enemy Galore golem, drawn 3x).
// Phase 1 (armored, takes 60% damage): Slam (1 ring), Tremor (3 rings in rhythm), Rockfall (2 radial bolt bursts).
// At 50% HP the armor shatters (invulnerable while it breaks), then
// Phase 2 (full damage, faster): Double slam (2 rings), Charge (telegraphed line rush), Spiral (4 rotating bolt bursts).
// Every ~10 s (8 s in phase 2) it calls 2 rats through the spawn points: kick them into the side pits.
// Rings and bolts hug the ground: jump them or dash through. Pillars block the bolts.
// Kicks don't move it; a cast staggers it for 1 s.
event_inherited();

boss_name = "THE STONE WARDEN";
phase = 1;
art_scale = 3;
art_faces = 1;                 // art looks right
image_xscale = 3;
image_yscale = 3;
mask_index = spr_mask_wide;    // scaled 3x: a 72x30 box at the feet
hit_h = 66;                    // hits land anywhere from its feet up to its head, not just at the feet

max_hp = 560;                  // tuned down: with two Reliquaries of boons it should be a medium fight
hp = max_hp;
hp_shown = hp;
armor_mult = 0.7;              // phase 1 damage taken
move_speed = 0.6;
ranged_kind = "";
drop_chance = 0;

idle_sprite = spr_golem_armored_idle;
walk_sprite = spr_golem_armored_run;
death_sprite = spr_golem_death_b;
sprite_index = idle_sprite;
image_speed = 1;

bstate = "intro";              // intro / chase / attack / aim / charge / recover / break
timer = 100;                   // intro length: the title card shows meanwhile
intro_max = timer;
attack_cycle = 0;
atk = "";
fire_frames = [];
fi = 0;
loops_left = 0;
spiral_off = 0;
summon_cd = 420;
charge_dir = 0;
charge_hit = false;
col_fx = make_color_rgb(150, 190, 255);

function face_player() {
    if (instance_exists(obj_player)) image_xscale = art_scale * art_faces * ((obj_player.x >= x) ? 1 : -1);
}
function ring(_spd, _dmg, _max, _delay) {
    with (instance_create_layer(x, bbox_bottom - 4, "Instances", obj_projectile,
          { kind: "wave", dir: 0, spd: _spd, dmg: _dmg, col: col_fx })) {
        wave_max = _max;
        band = 7;
        radius = 6 - _spd * _delay;      // a delay starts the ring "below zero"
    }
}
function radial(_n, _off, _spd, _dmg) {
    var fx0 = x, fy = bbox_bottom - 4;
    for (var i = 0; i < _n; i++) {
        var a = _off + i * 360 / _n;
        instance_create_layer(fx0 + lengthdir_x(20, a), fy + lengthdir_y(20, a), "Instances", obj_projectile,
            { kind: "bolt", dir: a, spd: _spd, dmg: _dmg, col: col_fx });
    }
}
function begin_attack(_name, _spr, _frames, _loops) {
    bstate = "attack";
    atk = _name;
    sprite_index = _spr;
    image_index = 0;
    image_speed = 1;
    fire_frames = _frames;
    fi = 0;
    loops_left = _loops;
    face_player();
}
function attack_effect() {
    switch (atk) {
        case "slam":    ring(2.0, 15, 170, 0); shake(5); break;
        case "tremor":  ring(1.8, 12, 150, 0); shake(3); break;
        case "rockfall": radial(12, (loops_left mod 2) * 15 + fi * 15, 2.0, 10); shake(2); break;
        case "slam2":   ring(2.2, 18, 190, 0); ring(2.2, 18, 190, 24); shake(6); break;
        case "spiral":  radial(8, spiral_off, 2.4, 10); spiral_off += 22; break;
    }
}
function choose_attack() {
    var pick = attack_cycle mod 3;
    attack_cycle += 1;
    if (phase == 1) {
        if (pick == 0)      begin_attack("slam", spr_golem_armored_attack_a, [4], 1);
        else if (pick == 1) begin_attack("tremor", spr_golem_armored_attack_b, [5], 3);
        else                begin_attack("rockfall", spr_golem_armored_ability, [5, 8], 1);
    } else {
        if (pick == 0)      begin_attack("slam2", spr_golem_attack_a, [7], 1);
        else if (pick == 1) {
            bstate = "aim";                     // charge: a red line shows where it will rush
            timer = 40;
            sprite_index = spr_golem_attack_c;
            image_index = 0;
            image_speed = 0;
            charge_dir = instance_exists(obj_player) ? point_direction(x, bbox_bottom, obj_player.x, obj_player.bbox_bottom) : 270;
            face_player();
        }
        else                begin_attack("spiral", spr_golem_attack_b, [3], 4);
    }
}
function start_break() {
    bstate = "break";
    hp = max_hp * 0.5;
    sprite_index = spr_golem_armored_armor_break;
    image_index = 0;
    image_speed = 1;
    with (obj_projectile) instance_destroy();
    with (obj_game) { unlock_msg = "ITS ARMOR SHATTERS"; unlock_t = 150; }
    shake(6);
}
function die() {
    dead = true;
    hp = 0;
    bstate = "dead";
    sprite_index = death_sprite;
    image_index = 0;
    image_speed = 1;
    var me = id;
    // its summons die with it (call each one's OWN take_damage: inside this method a bare
    // take_damage() would run the Warden's version on the rat and crash)
    var minions = [];
    with (obj_enemy) if (id != me && !dead) array_push(minions, id);
    for (var i = 0; i < array_length(minions); i++) minions[i].take_damage(999);
    with (obj_projectile) instance_destroy();
    with (obj_game) {
        pending = [];
        cleared = true;
        unlock_msg = "THE STONE WARDEN FALLS";
        unlock_t = 600;
    }
    global.cleared[$ "rm_boss"] = true;
    // the Warden kept a Reliquary inside itself: the pillar wakes up
    with (obj_reliquary) active = true;
    start_dialogue([
        ["SWORD", "It's over. It's actually over..."],
        ["SWORD", "Look at the pillar. The Warden was guarding a Reliquary with its own body. Something of yours is in there - go claim it."]
    ]);
    fx("shard", x, bbox_bottom - 20, 40);
    fx("soul", x, bbox_bottom - 20, 30);
    flash(c_white, 0.6);
    slowmo(60);
    shake(10);
}

// override obj_enemy's versions
function take_damage(_dmg, _crit = false) {
    if (dead || bstate == "break" || bstate == "intro") return;
    var d = max(1, round(_dmg * ((phase == 1) ? armor_mult : 1)));
    hp -= d;
    hit_flash = 4;
    dmg_number(x + random_range(-20, 20), bbox_bottom - 80, d, _crit);
    if (phase == 1 && hp <= max_hp * 0.5) start_break();
    else if (hp <= 0) die();
}
function interrupt() { }       // attacks can't be cancelled; a cast still staggers it (stun)

guarded = false;         // its armor phase already soaks damage; a kick staggers it (every 4 s at most)
