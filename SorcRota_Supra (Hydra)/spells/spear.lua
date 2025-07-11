local my_utility = require("my_utility/my_utility");

local menu_elements_spear_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_lightning_spear")),
    crackling_energy_snapshot = checkbox:new(false, get_hash(my_utility.plugin_label .. "crackling_energy_snapshot_spear")),
}

local function menu()
    
    if menu_elements_spear_base.tree_tab:push("Lightning Spear") then
        menu_elements_spear_base.main_boolean:render("Enable Spell", "")
        
        if menu_elements_spear_base.main_boolean:get() then
            menu_elements_spear_base.crackling_energy_snapshot:render("Crackling Energy Snapshot", "Enables special casting logic for Crackling Energy optimization")
        end
 
        menu_elements_spear_base.tree_tab:pop()
    end
end

local spell_id_spear = 292074
local next_time_allowed_cast = 0.0;
local function logics(target)

    local menu_boolean = menu_elements_spear_base.main_boolean:get();
    local crackling_energy_snapshot_enabled = menu_elements_spear_base.crackling_energy_snapshot:get();
    
    -- Check if we're in Crackling Energy loop and need to end it after casting spear
    local is_in_crackling_energy_loop = crackling_energy_snapshot_enabled and my_utility.is_crackling_energy_loop_active();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_spear);

    if not is_logic_allowed then
        return false;
    end;

    local target_position = target:get_position();

    cast_spell.position(spell_id_spear, target_position, 0.02)
    local current_time = get_time_since_inject();
    next_time_allowed_cast = current_time + 0.1;
    
    -- If we were in Crackling Energy loop, end it after casting spear
    if is_in_crackling_energy_loop then
        my_utility.end_crackling_energy_loop();
        console.print("Sorcerer Plugin, Casted Spear - Crackling Energy Snapshot Complete");
    else
        console.print("Sorcerer Plugin, Casted Spear");
    end
    
    return true;

end

local function get_crackling_energy_snapshot_enabled()
    return menu_elements_spear_base.crackling_energy_snapshot:get()
end

return 
{
    menu = menu,
    logics = logics,
    get_crackling_energy_snapshot_enabled = get_crackling_energy_snapshot_enabled
}