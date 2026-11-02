// move a value toward a target by a fixed amount, without overshooting
function approach(_start, _end, _amount) {
    if (_start < _end) return min(_start + _amount, _end);
    return max(_start - _amount, _end);
}

// switch animation only if it's different, restarting it from _frame
function set_anim(_spr, _frame = 0) {
    if (sprite_index != _spr) {
        sprite_index = _spr;
        image_index = _frame;
        image_speed = 1;
    }
}
