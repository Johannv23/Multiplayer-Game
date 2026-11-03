// Player 2: the weapon.
//  held   - follows the character; "/" makes the character swing it (full damage)
//  out    - "." detaches it: arrows fly it anywhere within the tether, over pits; "/" swings it on its own (less damage)
//  recall - "." again flies it home. Player 1's R also recalls it, and that recall hits everything on its path.
// It also collects soul orbs (heals) wherever they are, even over the void.
state = "held";
tether = 90;                 // 5 m: the 32px character is ~1.8 m tall, so ~18 px per metre
move_speed = 2.4;
accel = 0.4;
hsp = 0;
vsp = 0;
detached_mult = 0.6;         // detached swings deal 60% damage
swing_cd = 0;
swing_t = 0;                 // > 0 while the detached swing arc is drawn
swing_dir = 270;
recall_speed = 7;
recall_damage = 15;
recall_hurts = false;
recall_id = 0;
float_t = 0;
hover = 12;                  // drawn this high above its ground point
depth = -9000;               // above props, still lit by the lighting overlay

// P2 keys: / and . (US layout keycodes 191 / 190), or numpad 0 / numpad .
function p2_attack() { return keyboard_check_pressed(191) || keyboard_check_pressed(vk_numpad0); }
function p2_detach() { return keyboard_check_pressed(190) || keyboard_check_pressed(vk_decimal); }

function start_recall(_hurts) {
    if (state != "out") return;
    state = "recall";
    recall_hurts = _hurts;
    recall_id += 1;
}
