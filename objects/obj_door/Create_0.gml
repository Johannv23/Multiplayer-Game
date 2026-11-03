// Exit door. Child of obj_wall: solid while locked. obj_game calls open_door() when the room is clear.
event_inherited();
x1 = bbox_left;  y1 = bbox_top;
x2 = bbox_right + 1;  y2 = bbox_bottom + 1;
is_open = false;
glow = 0;           // 0 = locked look, 1 = open look (eased)
depth = -y2;

function open_door() {
    if (is_open) return;
    is_open = true;
    // no sprite + no mask = no collision, so the player can walk in. Draw uses x1..y2 instead.
    sprite_index = -1;
    mask_index = -1;
}
