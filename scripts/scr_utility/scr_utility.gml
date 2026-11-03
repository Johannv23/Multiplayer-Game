// move a value toward a target by a fixed amount, without overshooting
function approach(_start, _end, _amount) {
    if (_start < _end) return min(_start + _amount, _end);
    return max(_start - _amount, _end);
}

// switch animation only if it's different, restarting it from _frame
function set_anim(_spr, _frame = 0) {
    if (sprite_index != _spr) {
        sprite_index = _spr;
        image_index = _frame;
        image_speed = 1;
    }
}

// ---- debug hitboxes (press B in game to toggle) ----
// script globals run once at game start, before any Create event
global.show_hitboxes = true;

// draws the calling instance's collision box: translucent fill + solid outline
function draw_hitbox(_col) {
    if (!global.show_hitboxes) return;
    draw_set_color(_col);
    draw_set_alpha(0.25);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(1);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_color(c_white);
}

// ---- run state (survives room changes; reset on death) ----
global.dash_unlocked = false;   // unlocked by clearing chamber 1
global.cast_unlocked = false;   // unlocked by clearing chamber 2
global.player_hp = -1;          // carried between chambers (-1 = start full)

function reset_run() {
    global.dash_unlocked = false;
    global.cast_unlocked = false;
    global.player_hp = -1;
}

// every hit on the character goes through here: respects i-frames (dash, recent hit) and death
function hurt_player(_p, _dmg) {
    if (_p.invuln > 0 || _p.state == "dead") return false;
    _p.hp -= _dmg;
    _p.hurt_flash = 12;
    _p.invuln = 40;                 // short grace period so a crowd can't chain-hit you
    return true;
}
