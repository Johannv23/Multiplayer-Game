// Runs a Reliquary (rm_shrine_N): lore, restore a power and teach it, then the boon choice, then the way out.
// Steps (like obj_tutorial):  ["say", lines]  ["unlock", "dash"/"cast"/"stomp"]  ["task", id]  ["select"]  ["finish"]
n = obj_game.shrine_n;
step = 0;
task_done_t = 0;

pruned = false;          // first Step: keep only the runes or sentinels this lesson needs

switch (n) {
case 1:
    steps = [
        ["say", [
            ["HERO",  "Where... are we? It's so quiet in here."],
            ["SWORD", "Inside the Reliquary. Listen to that hum - that's you. A piece of you, anyway."],
            ["SWORD", "When the Demon King broke you, erasing your memories wasn't enough. He tore your power out by the roots - every technique, every scar you earned - and sealed the pieces in stone."],
            ["SWORD", "Then he scattered them through his domain, one in every chamber, and set his creatures to guard them."],
            ["HERO",  "So every pillar like this one is..."],
            ["SWORD", "A part of you he was afraid to leave lying around. Reach for it."]
        ]],
        ["unlock", "dash"],
        ["say", [
            ["HERO",  "My legs... I can see where I'm going to step before I take it. Like a shadow running ahead of me."],
            ["SWORD", "The Shadowstep. You were untouchable with it. Press Shift - for that instant, nothing can hit you."],
            ["SWORD", "The old masters carved runes into the floor here. Cut straight through all three."]
        ]],
        ["task", "runes"],
        ["say", [
            ["SWORD", "Just like old times."],
            ["SWORD", "And the Reliquary holds more than memories. Raw power leaks out of it - enough to sharpen both of us."],
            ["SWORD", "Choose. You take what makes your body stronger. I'll take what makes my edge sharper. Pick the same power again later and it grows."]
        ]],
        ["select"],
        ["say", [
            ["SWORD", "Feel that? We're getting stronger, and he knows it. The way back is open - let's go."]
        ]],
        ["finish"]
    ];
    break;
case 2:
    steps = [
        ["say", [
            ["SWORD", "Another Reliquary. The air's heavier here - this fragment is older. Closer to your heart."],
            ["HERO",  "There's a light... in my hand. No - inside it."],
            ["SWORD", "Your soul mark. Heroes of the old order carried a piece of their soul in their palm. It's the one thing the Demon King ever feared."]
        ]],
        ["unlock", "cast"],
        ["say", [
            ["SWORD", "It feeds on battle. Every strike I land charges it. When it's full, throw it with Q - whatever it touches is rooted where it stands."],
            ["SWORD", "These sentinels won't fight back. I'll hit them to charge your mark, then you throw it."]
        ]],
        ["task", "root"],
        ["say", [
            ["SWORD", "Rooted, they're helpless. Hit them while they're stuck - I'll make sure it counts."],
            ["SWORD", "There's power here too. Choose again."]
        ]],
        ["select"],
        ["say", [
            ["SWORD", "Past this chamber waits the one who dragged you down here. Now we're ready for it."]
        ]],
        ["finish"]
    ];
    break;
default:
    steps = [
        ["say", [
            ["SWORD", "The Warden guarded this one with its own body. Whatever is in here, the Demon King really didn't want you to have it."],
            ["HERO",  "It's heavy. Like falling from a great height... and landing on purpose."]
        ]],
        ["unlock", "stomp"],
        ["say", [
            ["SWORD", "Meteor Fall. You used to drop out of the sky onto whole battalions."],
            ["SWORD", "Jump, then press E in mid-air. Hit one of the sentinels with it."]
        ]],
        ["task", "stomp"],
        ["say", [
            ["SWORD", "The Demon King will have felt that one. Choose your power."]
        ]],
        ["select"],
        ["say", [
            ["SWORD", "This was only the first layer of his domain. Every fragment we take back makes him weaker..."],
            ["SWORD", "...and brings you closer to remembering why he fears you. Let's keep going."]
        ]],
        ["finish"]
    ];
    break;
}

function do_unlock(_what) {
    var msg = "";
    switch (_what) {
        case "dash":  global.dash_unlocked = true;  msg = "SHADOWSTEP RESTORED  -  Shift to dash"; break;
        case "cast":  global.cast_unlocked = true;  msg = "SOUL MARK RESTORED  -  Q to cast (charged by the sword's hits)"; break;
        case "stomp": global.stomp_unlocked = true; msg = "METEOR FALL RESTORED  -  E in mid-air"; break;
    }
    with (obj_game) { unlock_msg = msg; unlock_t = 300; }
    with (obj_player) { apply_boons(); fx("mote", x, y, 40); fx("soul", x, y, 20); }
    flash(make_color_rgb(150, 240, 255), 0.6);
    shake(4);
}

// debug skip (Backspace): restore the power and go straight to the boon choice
function skip() {
    var sel = -1;
    for (var i = 0; i < array_length(steps); i++) if (steps[i][0] == "select") { sel = i; break; }
    if (sel < 0 || step > sel) return;
    for (var i = step; i < sel; i++) if (steps[i][0] == "unlock") do_unlock(steps[i][1]);
    step = sel;
    task_done_t = 0;
}
