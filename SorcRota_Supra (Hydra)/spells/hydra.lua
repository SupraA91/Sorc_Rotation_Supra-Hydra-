local my_utility = require("my_utility/my_utility");

local menu_elements_hydra = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_hydra")),
    max_mana_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "max_mana_only_hydra")),
}

local function menu()
    
    if menu_elements_hydra.tree_tab:push("Hydra")then
        menu_elements_hydra.main_boolean:render("Enable Spell", "")
        menu_elements_hydra.max_mana_only:render("Cast on Max Mana only", "Only cast Hydra when mana is at 100%")
 
        menu_elements_hydra.tree_tab:pop()
    end
end

local spell_id_hydra = 146743
local next_time_allowed_cast = 0.0;
local function logics(target)
    
    local menu_boolean = menu_elements_hydra.main_boolean:get();
    local max_mana_only = menu_elements_hydra.max_mana_only:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_hydra);

    if not is_logic_allowed then
        return false;
    end;
    
    -- Check if player's mana is at 100% when max_mana_only is enabled
    if max_mana_only then
        local local_player = get_local_player();
        if not local_player then
            return false;
        end
        
        local current_mana = local_player:get_primary_resource_current();
        local max_mana = local_player:get_primary_resource_max();
        
        -- Only cast if mana is at 100%
        if current_mana < max_mana then
            return false;
        end
    end;

    local target_position = target:get_position();

    cast_spell.position(spell_id_hydra, target_position, 0.35) 
    local current_time = get_time_since_inject();
    next_time_allowed_cast = current_time + 5;
        
    console.print("Sorcerer Plugin, Hydra");
    return true;

end

return 
{
    menu = menu,
    logics = logics,   
}