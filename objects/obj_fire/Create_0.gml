// A burning patch on the ground (Afterburn Dash, Meteor Core). "lv" comes from the spawn struct.
if (!variable_instance_exists(id, "lv")) lv = 1;
life = 90 + 60 * lv;
life_max = life;
tick = 0;
dmg = 2 + lv;
radius = 12;
depth = 400;
