part_system_destroy(ps);
var names = variable_struct_get_names(pt);
for (var i = 0; i < array_length(names); i++) part_type_destroy(pt[$ names[i]]);
