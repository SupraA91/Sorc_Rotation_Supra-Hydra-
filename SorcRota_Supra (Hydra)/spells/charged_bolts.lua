local my_utility = require("my_utility/my_utility")

local charged_bolt_menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fire_bolt_main_boolean")),
}

local function menu()
    
    if charged_bolt_menu_elements.tree_tab:push("Charged Bolt")then
        charged_bolt_menu_elements.main_boolean:render("Enable Spell", "")
 
        charged_bolt_menu_elements.tree_tab:pop()
    end
end

local spell_id_charge_bolt = 171937;

local charge_bolt_spell_data = spell_data:new(
    1.2,                        -- radius
    0.7,                        -- range
    1.0,                        -- cast_delay
    2.0,                        -- projectile_speed
    true,                      -- has_collision
    spell_id_charge_bolt,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(best_target, target_selector_data)
    
    local menu_boolean = charged_bolt_menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_charge_bolt);

    if not is_logic_allowed then
        return false;
    end;
    
    if not best_target then
        return false;
    end;

    local player_local = get_local_player();
    
    local player_position = get_player_position();
    local target_position = best_target:get_position();

    if cast_spell.target(best_target, charge_bolt_spell_data, false) then

        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.7;

        console.print("Druid Plugin, Casted Charged Bolts");
        return true;
    end;
            
    return false;
end


return 
{
    menu = menu,
    logics = logics,   
}