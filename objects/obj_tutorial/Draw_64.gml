// the current goal, under the wave banner
if (instance_exists(obj_dialogue) || step >= array_length(steps)) exit;
var s = steps[step];
if (s[0] != "task") exit;
var w_ = instance_exists(obj_weapon) ? obj_weapon.state : "held";
var txt = "";
switch (s[1]) {
    case "move":
        txt = "P1: Move with  "
            + (moved.w ? "[W]" : " W ") + (moved.a ? "[A]" : " A ")
            + (moved.s ? "[S]" : " S ") + (moved.d ? "[D]" : " D ");
        break;
    case "jump":   txt = "P1: Press SPACE to jump  (" + string(min(jumps, 2)) + "/2)"; break;
    case "attack": txt = "P2: Press  /  to swing the sword - defeat the rat"; break;
    case "detach": txt = "P2: Press  .  to fly out, then ARROWS to move the sword"; break;
    case "recall": txt = (w_ == "held") ? "P2: Press  .  to fly out again" : "P1: Press  R  to recall the sword"; break;
    case "kick":   txt = obj_player.kick_landed ? "Finish them off!" : "P1: Press  E  to kick a rat (near a ledge, kick it off)"; break;
}
if (task_done_t > 0) txt = "Nice!";

var gw = display_get_gui_width();
draw_set_halign(fa_center);
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(gw / 2 - 360, 52, gw / 2 + 360, 92, false);
draw_set_alpha(1);
draw_set_color((task_done_t > 0) ? make_color_rgb(140, 255, 140) : make_color_rgb(255, 225, 140));
draw_text_transformed(gw / 2, 60, txt, 2, 2, 0);
draw_set_halign(fa_left);
draw_set_color(c_white);
