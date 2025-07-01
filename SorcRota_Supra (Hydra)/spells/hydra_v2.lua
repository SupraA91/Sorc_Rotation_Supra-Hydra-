local my_utility = require("my_utility/my_utility");

local menu_elements_hydra = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_hydra")),
    max_hydras            = slider_int:new(1, 3, 2, get_hash(my_utility.plugin_label .. "max_hydras_count")),
}

local function menu()
    
    if menu_elements_hydra.tree_tab:push("Hydra")then
        menu_elements_hydra.main_boolean:render("Enable Spell", "")
        
        if menu_elements_hydra.main_boolean:get() then
            menu_elements_hydra.max_hydras:render("Max Hydras", "Maximum number of Hydras to maintain (1-3)")
        end
 
        menu_elements_hydra.tree_tab:pop()
    end
end

local spell_id_hydra = 146743
local next_time_allowed_cast = 0.0;

-- Function to count active hydras by checking player buffs
local function count_active_hydras()
    local local_player = get_local_player()
    if not local_player then return 0 end
    
    local buffs = local_player:get_buffs()
    if not buffs then return 0 end
    
    local hydra_count = 0
    -- Check for Hydra buff - you may need to adjust the buff name/hash
    -- Common Hydra buff names: "Sorcerer_Hydra", "Enchant_Hydra", or similar
    for _, buff in ipairs(buffs) do
        local buff_name = buff:name()
        -- Check for various possible Hydra buff names
        if buff_name and (
            buff_name:find("Hydra") or 
            buff_name:find("hydra") or
            buff.name_hash == 146743 or  -- spell ID as hash
            buff.name_hash == 1050328 or -- possible buff hash
            buff_name == "Sorcerer_Hydra"
        ) then
            hydra_count = hydra_count + 1
            console.print("[HYDRA DEBUG] Found Hydra buff: " .. buff_name .. " (Hash: " .. buff.name_hash .. ")")
        end
    end
    
    return hydra_count
end

-- Alternative method: Count Hydra entities in the world
local function count_hydra_entities()
    if not actors_manager or not actors_manager.get_ally_npcs then
        return 0
    end
    
    local allies = actors_manager.get_ally_npcs()
    local hydra_count = 0
    
    for _, ally in ipairs(allies) do
        local skin_name = ally:get_skin_name()
        if skin_name and (
            skin_name:find("Hydra") or 
            skin_name:find("hydra") or
            skin_name == "Sorcerer_Hydra" or
            skin_name == "Generic_Proxy_Hydra"
        ) then
            hydra_count = hydra_count + 1
            console.print("[HYDRA DEBUG] Found Hydra entity: " .. skin_name)
        end
    end
    
    return hydra_count
end

local function logics(target)
    
    local menu_boolean = menu_elements_hydra.main_boolean:get();
    local max_hydras = menu_elements_hydra.max_hydras:get();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_hydra);

    if not is_logic_allowed then
        return false;
    end;
    
    if not target then
        return false;
    end;

    -- Count active hydras using both methods for reliability
    local hydra_count_buffs = count_active_hydras()
    local hydra_count_entities = count_hydra_entities()
    
    -- Use the higher count for safety (in case one method fails)
    local current_hydras = math.max(hydra_count_buffs, hydra_count_entities)
    
    console.print("[HYDRA] Current Hydras: " .. current_hydras .. "/" .. max_hydras .. " (Buffs: " .. hydra_count_buffs .. ", Entities: " .. hydra_count_entities .. ")")
    
    -- Only cast if we have fewer hydras than the maximum
    if current_hydras >= max_hydras then
        return false;
    end

    local target_position = target:get_position();

    if cast_spell.position(spell_id_hydra, target_position, 0.35) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.5; -- Short cooldown to prevent spam
        
        console.print("Sorcerer Plugin, Hydra cast (" .. (current_hydras + 1) .. "/" .. max_hydras .. ")");
        return true;
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}