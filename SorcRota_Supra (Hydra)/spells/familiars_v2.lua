local my_utility = require("my_utility/my_utility");

local menu_elements_familiars = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_familiars")),
    auto_maintain         = checkbox:new(true, get_hash(my_utility.plugin_label .. "auto_maintain_familiars")),
}

local function menu()
    
    if menu_elements_familiars.tree_tab:push("Familiars")then
        menu_elements_familiars.main_boolean:render("Enable Spell", "")
        
        if menu_elements_familiars.main_boolean:get() then
            menu_elements_familiars.auto_maintain:render("Auto Maintain", "Automatically maintain familiar active")
        end
 
        menu_elements_familiars.tree_tab:pop()
    end
end

local spell_id_familiars = 1627075
local next_time_allowed_cast = 0.0;

-- Function to check if familiar is active
local function is_familiar_active()
    local local_player = get_local_player()
    if not local_player then return false end
    
    local buffs = local_player:get_buffs()
    if not buffs then return false end
    
    -- Check for familiar buffs
    for _, buff in ipairs(buffs) do
        local buff_name = buff:name()
        if buff_name and (
            buff_name:find("Familiar") or 
            buff_name:find("familiar") or
            buff.name_hash == 1627075 or  -- spell ID as hash
            buff_name == "Sorcerer_Familiar" or
            buff_name == "Enchant_Familiar"
        ) then
            return true
        end
    end
    
    return false
end

-- Alternative: Check for familiar entities in the world
local function count_familiar_entities()
    if not actors_manager or not actors_manager.get_ally_npcs then
        return 0
    end
    
    local allies = actors_manager.get_ally_npcs()
    local familiar_count = 0
    
    for _, ally in ipairs(allies) do
        local skin_name = ally:get_skin_name()
        if skin_name and (
            skin_name:find("Familiar") or 
            skin_name:find("familiar") or
            skin_name == "Sorcerer_Familiar"
        ) then
            familiar_count = familiar_count + 1
        end
    end
    
    return familiar_count
end

local function logics()
    
    local menu_boolean = menu_elements_familiars.main_boolean:get();
    local auto_maintain = menu_elements_familiars.auto_maintain:get();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_familiars);

    if not is_logic_allowed then
        return false;
    end;

    -- If auto maintain is enabled, check if familiar is already active
    if auto_maintain then
        local has_familiar_buff = is_familiar_active()
        local familiar_entities = count_familiar_entities()
        
        -- If we have the buff or entities, don't cast
        if has_familiar_buff or familiar_entities > 0 then
            return false;
        end
        
        console.print("[FAMILIAR] No familiar detected, casting...");
    end

    -- Cast at player position since familiars follow the player
    local player_position = get_player_position();

    if cast_spell.position(spell_id_familiars, player_position, 0.35) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 2.0; -- Reduced cooldown for more responsive casting
        
        console.print("Sorcerer Plugin, Familiars summoned");
        return true;
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}