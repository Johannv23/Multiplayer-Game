if (array_length(lines) == 0) { global.freeze = false; instance_destroy(); exit; }
var txt = lines[idx][1];
shown = min(string_length(txt), shown + type_speed);

if (keyboard_check_pressed(vk_space)) {
    keyboard_clear(vk_space);           // this press must not also make the hero jump
    if (shown < string_length(txt)) {
        shown = string_length(txt);     // finish the line
    } else {
        idx += 1;
        shown = 0;
        if (idx >= array_length(lines)) {
            global.freeze = false;
            instance_destroy();
        }
    }
}
