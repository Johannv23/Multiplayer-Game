// Boon choice inside a Reliquary. Left: player 1 (body) picks with A / D, confirms with Space.
// Right: player 2 (blade) picks with Left / Right, confirms with /. Play is frozen until both have chosen.
global.freeze = true;
offers = [roll_offers(1), roll_offers(2)];
sel = [0, 0];
chosen = [false, false];
t = 0;
done_t = 0;            // short beat after both chose
duo_msg = "";
// nothing left to take on a side: count it as chosen
for (var s = 0; s < 2; s++) if (array_length(offers[s]) == 0) chosen[s] = true;
