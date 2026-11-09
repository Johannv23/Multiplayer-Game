if (!pruned) {
    pruned = true;
    if (n != 1) with (obj_rune) instance_destroy();
    if (n == 1) with (obj_dummy) instance_destroy();
}
if (instance_exists(obj_dialogue) || instance_exists(obj_boonselect) || global.freeze) exit;
if (!instance_exists(obj_player) || step >= array_length(steps)) exit;
var p = obj_player;
var s = steps[step];

switch (s[0]) {
    case "say":
        start_dialogue(s[1]);
        step += 1;
        break;
    case "unlock":
        do_unlock(s[1]);
        step += 1;
        break;
    case "task":
        if (task_done_t > 0) {
            task_done_t -= 1;
            if (task_done_t == 0) step += 1;
            break;
        }
        var done = false;
        switch (s[1]) {
            case "runes":
                done = true;
                with (obj_rune) if (!lit) done = false;
                break;
            case "root":
                with (obj_dummy) if (root_t > 0) done = true;
                break;
            case "stomp":
                done = (p.stomp_hits > 0);
                break;
        }
        if (done) task_done_t = 50;
        break;
    case "select":
        instance_create_depth(0, 0, -16000, obj_boonselect);
        step += 1;
        break;
    case "finish":
        global.shrine_done[n] = true;
        with (obj_door) open_door();
        with (obj_game) { cleared = true; unlock_msg = "The way out is open"; unlock_t = 200; }
        step += 1;
        break;
}
