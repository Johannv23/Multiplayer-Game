// The fighting areas in play order, top/bottom in world pixels (rm_level is built by _tools/build_level.py).
// Each obj_spawn looks itself up here, so a wave system can ask for "spawns in arena 1".
arenas = [
    { name: "Ruins",     top: 1024, bottom: 1376 },
    { name: "Graveyard", top: 464,  bottom: 944  },
    { name: "Throne",    top: 0,    bottom: 384  }
];

// Props are painted as sprites on the "Props" asset layer in the Room Editor.
// At room start each one becomes a solid obj_prop, so the player collides with it
// and walks behind/in front of it. Sprites on the "Decor" layer are left as flat decoration.
var lay = layer_get_id("Props");
if (lay != -1) {
    var els = layer_get_all_elements(lay);
    for (var i = 0; i < array_length(els); i++) {
        var el = els[i];
        if (layer_get_element_type(el) != layerelementtype_sprite) continue;

        // the struct sets these before obj_prop's Create runs, so its depth uses the right mask
        instance_create_layer(layer_sprite_get_x(el), layer_sprite_get_y(el), "Instances", obj_prop, {
            sprite_index: layer_sprite_get_sprite(el),
            image_index:  layer_sprite_get_index(el),
            image_xscale: layer_sprite_get_xscale(el),
            image_yscale: layer_sprite_get_yscale(el),
            image_blend:  layer_sprite_get_blend(el)    // foreground silhouettes are tinted dark
        });
        layer_sprite_destroy(el);
    }
}

// Spawn timer for enemies
spawn_timer = 0;
spawn_interval = 180;
max_enemies = 6;

// Background music
if (!audio_is_playing(background_music)) {
    audio_play_sound(background_music, 0, true);
}
// ---------------------------------------------------------------- chambers (Hades-style rooms)
// Rooms are built from ASCII blockouts by _tools/build_chambers.py. Each chamber runs its waves;
// when the last wave is dead the doors open and walking into one goes to the next chamber.
chambers = [rm_chamber_1, rm_chamber_2, rm_boss];   // the boss arena ends the run

// one array of enemy objects per wave, keyed by room name
wave_table = {
    rm_chamber_1: [                                  // rats swarm, slimes shoot from range
        [obj_rat, obj_rat, obj_rat, obj_rat, obj_slime],
        [obj_rat, obj_rat, obj_rat, obj_rat, obj_slime, obj_slime],
        [obj_rat, obj_rat, obj_rat, obj_skeleton, obj_slime, obj_slime]
    ],
    rm_chamber_2: [                                  // shockwaves + bolt fans at the same time
        [obj_skeleton, obj_skeleton, obj_slime, obj_slime],
        [obj_skeleton, obj_skeleton, obj_slime, obj_slime, obj_rat, obj_rat, obj_rat],
        [obj_skeleton, obj_skeleton, obj_slime, obj_slime, obj_enemy, obj_rat, obj_rat]
    ]
};

var key = room_get_name(room);
waves = variable_struct_exists(wave_table, key) ? wave_table[$ key] : [];
use_waves = array_length(waves) > 0;   // false in rm_level: it keeps the old timed spawner
boss_room = (room == rm_boss);         // no waves: obj_boss runs the fight and opens the doors
boss_rest = boss_room;                 // heal once on arrival (Hades-style breather before the boss)
wave = -1;              // index of the current wave (-1 = not started)
wave_delay = 60;        // frames of calm before the first wave and between waves
warn_frames = 45;       // a red ring shows where an enemy will appear, this long before it does
pending = [];           // enemies waiting to appear: { x, y, obj, t }
cleared = false;
if (use_waves || boss_room) depth = 500;   // above the floor tiles and decor, below everyone standing

// queue one wave: spread enemies over the spawn points that aren't right next to the player
function start_wave(_list) {
    var pts = [];
    var plx = instance_exists(obj_player) ? obj_player.x : -9999;
    var ply = instance_exists(obj_player) ? obj_player.y : -9999;
    with (obj_spawn) {
        if (point_distance(x, y, plx, ply) > 120) array_push(pts, [x, y]);
    }
    if (array_length(pts) == 0) with (obj_spawn) array_push(pts, [x, y]);
    if (array_length(pts) == 0) return;

    // shuffle so waves don't always come from the same corner
    for (var i = array_length(pts) - 1; i > 0; i--) {
        var j = irandom(i);
        var tmp = pts[i]; pts[i] = pts[j]; pts[j] = tmp;
    }
    for (var i = 0; i < array_length(_list); i++) {
        var p = pts[i mod array_length(pts)];
        var spread = (i >= array_length(pts)) ? 14 : 0;   // second enemy at the same point steps aside
        array_push(pending, {
            x: p[0] + irandom_range(-spread, spread),
            y: p[1] + irandom_range(-spread, spread),
            obj: _list[i],
            t: warn_frames + i * 12        // stagger arrivals
        });
    }
}

// next chamber in the list, looping back to the first after the last
function go_next() {
    if (instance_exists(obj_player)) global.player_hp = obj_player.hp;   // HP carries over
    if (room == rm_boss) {           // run won: start a fresh run
        reset_run();
        room_goto(rm_chamber_1);
        return;
    }
    var nxt = chambers[0];
    for (var i = 0; i < array_length(chambers) - 1; i++) {
        if (chambers[i] == room) nxt = chambers[i + 1];
    }
    room_goto(nxt);
}

// lighting overlay in chambers (created last, so it can find the props made above)
if (use_waves || boss_room) instance_create_depth(0, 0, -15000, obj_lighting);

// unlock banner ("DASH UNLOCKED")
unlock_msg = "";
unlock_t = 0;
