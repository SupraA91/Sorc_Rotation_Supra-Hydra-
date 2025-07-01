local my_utility = require("my_utility/my_utility");

local menu_elements_familiars = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_familiars")),
}

local function menu()
    
    if menu_elements_familiars.tree_tab:push("Familiars")then
        menu_elements_familiars.main_boolean:render("Enable Spell", "")
 
        menu_elements_familiars.tree_tab:pop()
    end
end

local spell_id_familiars = 1627075
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = menu_elements_familiars.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_familiars);

    if not is_logic_allowed then
        return false;
    end;

    if not best_target then
        return false;
    end;

    local target_position = best_target:get_position();

    cast_spell.position(spell_id_familiars, target_position, 0.35) 
    local current_time = get_time_since_inject();
    next_time_allowed_cast = current_time + 5;
        
    console.print("Sorcerer Plugin, Familiars");
    return true;

end

return 
{
    menu = menu,
    logics = logics,   
}