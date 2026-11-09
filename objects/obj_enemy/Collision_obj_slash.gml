// a swing hits each enemy once (it can sweep through several)
if (!dead) {
    var s = other;
    if (!in_list(s.hits, id)) {
        array_push(s.hits, id);
        sword_hit(id, s.damage, s.src);
    }
}
