// Reliquary: a pillar in each chamber holding a sealed fragment of the hero's power.
// Dormant while the room is fought over; once it's cleared it shines - walk into it to enter its shrine.
event_inherited();
cx = x + 16;
by = y + 32;                     // the pillar stands on the cell's bottom edge
idx = (room == rm_chamber_1) ? 1 : ((room == rm_chamber_2) ? 2 : 3);
target = (idx == 1) ? rm_shrine_1 : ((idx == 2) ? rm_shrine_2 : rm_shrine_3);
spent = global.shrine_done[idx];
active = false;
entering = 0;
t = 0;
depth = -by;
