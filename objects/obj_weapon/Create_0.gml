// Player 2: the weapon.
//  held   - follows the character; "/" makes the character swing it (full damage)
//  out    - "." detaches it: arrows fly it anywhere within the tether, over pits; "/" swings it on its own (less damage)
//  recall - "." again flies it home. Player 1's R also recalls it, and that recall hits everything on its path.
//  orbit  - Whirling Return boon: after a recall it circles the hero for a while, cutting what it touches.
// It also collects soul orbs (heals) wherever they are, even over the void.
state = "held";
tether = 90;                 // 5 m: the 32px character is ~1.8 m tall, so ~18 px per metre
move_speed = 2.4;
accel = 0.4;
hsp = 0;
vsp = 0;
detached_mult = 0.6;         // detached swings deal 60% damage (Long Leash raises it)
swing_cd = 0;
swing_cd_max = 20;
swing_t = 0;                 // > 0 while the detached swing arc is drawn
swing_dir = 270;
recall_speed = 7;
recall_damage = 15;
recall_hurts = false;
recall_id = 0;
float_t = 0;
hover = 12;                  // drawn this high above its ground point
orbit_t = 0;
orbit_ang = 0;
combo = 0;                   // Frenzy
combo_t = 0;
cleave_ready = false;
depth = -9000;               // above props, still lit by the lighting overlay

// P2 keys: / and . (US layout keycodes 191 / 190), or numpad 0 / numpad .
function p2_attack() { return keyboard_check_pressed(191) || keyboard_check_pressed(vk_numpad0); }
function p2_detach() { return keyboard_check_pressed(190) || keyboard_check_pressed(vk_decimal); }

function apply_boons() {
    var l = blv(2, "leash");
    tether = 90 + 30 * l;
    var mults = [0.6, 0.75, 0.9, 1.05];
    detached_mult = mults[l];
    swing_cd_max = round(20 * (1 - 0.15 * l));
    recall_damage = 15 + 10 * blv(2, "orbit");
}
apply_boons();

function start_recall(_hurts) {
    if (state != "out") return;
    state = "recall";
    recall_hurts = _hurts;
    recall_id += 1;
}

// every swing (held or detached) makes its hitbox here: Keen Edge size, Frenzy's CLEAVE
function make_slash(_cx, _cy, _dmg) {
    var k = 1 + 0.15 * blv(2, "edge");
    var dmg = _dmg;
    if (cleave_ready) {
        cleave_ready = false;
        k *= 2.2;
        dmg *= 3;
        shake(6);
        hitstop(5);
        flash(make_color_rgb(255, 200, 150), 0.2);
        fx_ring(_cx, _cy, 44, make_color_rgb(255, 120, 80));
        fx("spark", _cx, _cy, 24);
    }
    var half = sprite_get_width(slash_hitbox) * k / 2;
    var s = instance_create_layer(_cx - half, _cy - half, "Instances", obj_slash);
    s.damage = dmg;
    s.image_xscale = k;
    s.image_yscale = k;
    return s;
}

// Frenzy: hits in quick succession build a combo; at the threshold the next swing is a CLEAVE
function add_combo() {
    var lv = blv(2, "frenzy");
    if (lv <= 0) return;
    combo += 1;
    combo_t = 75;
    var need = [99, 10, 8, 6];
    if (!cleave_ready && combo >= need[lv]) {
        cleave_ready = true;
        combo = 0;
        fx("ember", x, y - hover, 12);
    }
}
