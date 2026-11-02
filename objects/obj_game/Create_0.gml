// Props are painted as sprites on the "Props" asset layer in the Room Editor.
// At room start each one becomes a solid obj_prop, so the player collides with it
// and walks behind/in front of it. Sprites on the "Decor" layer are left as flat decoration.
var lay = layer_get_id("Props");
if (lay != -1) {
    var els = layer_get_all_elements(lay);
    for (var i = 0; i < array_length(els); i++) {
        var el = els[i];
        if (layer_get_element_type(el) != layerelementtype_sprite) continue;

        // the struct sets these before obj_prop's Create runs, so its depth uses the right mask
        instance_create_layer(layer_sprite_get_x(el), layer_sprite_get_y(el), "Instances", obj_prop, {
            sprite_index: layer_sprite_get_sprite(el),
            image_index:  layer_sprite_get_index(el),
            image_xscale: layer_sprite_get_xscale(el),
            image_yscale: layer_sprite_get_yscale(el)
        });
        layer_sprite_destroy(el);
    }
}

// Spawn timer for enemies
spawn_timer = 0;
spawn_interval = 180;
max_enemies = 6;

