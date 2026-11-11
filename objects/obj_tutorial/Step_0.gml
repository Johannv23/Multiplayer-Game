if (instance_exists(obj_dialogue) || global.freeze) exit;
if (step >= array_length(steps)) exit;
if (!instance_exists(obj_player)) exit;
var p = obj_player;
if (step >= array_length(steps)) exit;
var s = steps[step];

switch (s[0]) {
    case "say":
        start_dialogue(s[1]);
        step += 1;
        break;

    case "allow":
        var names = s[1];
        for (var i = 0; i < array_length(names); i++) {
            switch (names[i]) {
                case "move":   global.allow_move = true; break;
                case "jump":   global.allow_jump = true; break;
                case "attack": global.allow_attack = true; break;
                case "detach": global.allow_detach = true; break;
                case "recall": global.allow_recall = true; break;
                case "kick":   global.allow_kick = true; break;
            }
        }
        step += 1;
        break;

    case "spawn":
        var list = [];
        var kind_ = (array_length(s) > 2) ? s[2] : obj_rat;
        repeat (s[1]) array_push(list, kind_);
        with (obj_game) start_wave(list);
        spawned = true;
        step += 1;
        break;

    case "task":
        if (task_done_t > 0) {           // brief "done" moment, then move on
            task_done_t -= 1;
            if (task_done_t == 0) { step += 1; spawned = false; }
            break;
        }
        var done = false;
        var no_enemies = instance_number(obj_enemy) == 0 && array_length(obj_game.pending) == 0;
        switch (s[1]) {
            case "move":
                if (keyboard_check(ord("W"))) moved.w = true;
                if (keyboard_check(ord("A"))) moved.a = true;
                if (keyboard_check(ord("S"))) moved.s = true;
                if (keyboard_check(ord("D"))) moved.d = true;
                done = moved.w && moved.a && moved.s && moved.d;
                break;
            case "dodge":
                // a harmless practice ring rolls out near the hero every 2 seconds; clear two of them
                wave_t -= 1;
                if (wave_t <= 0 && !instance_exists(obj_projectile)) {
                    wave_t = 120;
                    var a = irandom(359);
                    var wx = p.x + lengthdir_x(60, a), wy = p.bbox_bottom - 6 + lengthdir_y(40, a);
                    instance_create_depth(wx, wy, -15001, obj_projectile, { kind: "wave", dir: 0, spd: 1.6, dmg: 0, col: make_color_rgb(255, 120, 200) });
                    fx_ring(wx, wy, 14, make_color_rgb(255, 120, 200));
                }
                with (obj_projectile) if (dodged && !variable_instance_exists(id, "counted")) { counted = true; other.dodges += 1; }
                done = (dodges >= 2 && p.state != "jump");
                break;
            case "attack":
                done = spawned && no_enemies;
                break;
            case "detach":
                done = instance_exists(obj_weapon) && obj_weapon.state == "out"
                       && point_distance(obj_weapon.x, obj_weapon.y, p.x, p.y) > 50;
                break;
            case "recall":
                done = instance_exists(obj_weapon) && obj_weapon.state == "recall" && obj_weapon.recall_hurts;
                break;
            case "kick":
                done = p.kick_landed && spawned && no_enemies;
                // the sword killed them before a kick landed: send another rat
                if (spawned && no_enemies && !p.kick_landed) with (obj_game) start_wave([obj_rat]);
                break;
        }
        if (done) task_done_t = 40;
        break;

    case "end":
        set_allow_all(true);
        global.tutorial_done = true;
        with (obj_game) { tutorial_running = false; wave_delay = 90; }
        instance_destroy();
        break;
}
