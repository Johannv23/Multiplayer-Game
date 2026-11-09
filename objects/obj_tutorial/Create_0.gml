// Chamber 1 tutorial (wave 1). A list of steps run in order:
//   ["say", lines]      dialogue (play frozen, Space between lines)
//   ["allow", [names]]  unlock controls: move / jump / attack / detach / recall / kick
//   ["spawn", n]        n rats through the spawn points (red rings first)
//   ["task", id]        wait until the players do it; the goal is shown at the top of the screen
//   ["end"]             everything unlocked, the normal waves begin
// Nothing can be used until the tutorial allows it.
set_allow_all(false);

steps = [
    ["say", [
        ["SWORD", "...Hey. HEY. Wake up!"],
        ["HERO",  "Ugh... Where am I? Who's talking?"],
        ["SWORD", "Down here. In your hand. It's me - your sword."],
        ["HERO",  "My... sword? I don't remember a sword. I don't remember anything."],
        ["SWORD", "I know. The Demon King captured you and tore your memories out. You were a hero once - the best there was."],
        ["SWORD", "There's no time for the rest. I can feel them coming. First things first: can you still walk?"]
    ]],
    ["allow", ["move"]],
    ["task", "move"],
    ["say", [
        ["SWORD", "Good. Your legs remember, even if you don't."],
        ["SWORD", "Their magic crawls along the ground. When it comes for you, jump over it."]
    ]],
    ["allow", ["jump"]],
    ["task", "jump"],
    ["say", [
        ["SWORD", "Now my turn. You carry me, but I fight on my own."],
        ["HERO",  "A sword that fights on its own?"],
        ["SWORD", "You'll get used to it. Here comes one now - leave it to me."]
    ]],
    ["allow", ["attack"]],
    ["spawn", 1],
    ["task", "attack"],
    ["say", [
        ["SWORD", "Ha! Still got it."],
        ["SWORD", "I can also leave your hand and fly out on my own. Not too far, though - I'm still bound to you."]
    ]],
    ["allow", ["detach"]],
    ["task", "detach"],
    ["say", [
        ["SWORD", "Out here I hit a little softer. When you need me back, call me - hard."],
        ["SWORD", "Pull me back and I'll cut through anything on the way to you."]
    ]],
    ["allow", ["recall"]],
    ["task", "recall"],
    ["say", [
        ["HERO",  "And what am I supposed to do while you do all the fighting?"],
        ["SWORD", "Kick them. Push them off me, and if one's standing near a ledge... kick it right off."]
    ]],
    ["allow", ["kick"]],
    ["spawn", 2],
    ["task", "kick"],
    ["say", [
        ["SWORD", "That's all I can teach you right now. More will come back to you - I'll tell you what I can as we find things."],
        ["HERO",  "Then let's go find them."],
        ["SWORD", "They're here. Get ready!"]
    ]],
    ["end"]
];
step = 0;
task_done_t = 0;         // short pause after a task before the next step
spawned = false;
moved = { w: false, a: false, s: false, d: false };
jumps = 0;
was_jumping = false;
detach_start = false;

// debug skip (Backspace): jump straight to the end of the tutorial
function skip() {
    for (var i = 0; i < array_length(steps); i++) if (steps[i][0] == "end") step = i;
    task_done_t = 0;
}
