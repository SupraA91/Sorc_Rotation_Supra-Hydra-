local my_utility = require("my_utility/my_utility");

local menu_elements_firewall = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_firwall")),
    max_firewalls         = slider_int:new(1, 10, 7, get_hash(my_utility.plugin_label .. "max_firewalls_count")),
    min_targets           = slider_int:new(1, 10, 2, get_hash(my_utility.plugin_label .. "firewall_min_targets")),
}

local function menu()
    
    if menu_elements_firewall.tree_tab:push("Firewall")then
        menu_elements_firewall.main_boolean:render("Enable Spell", "")
        
        if menu_elements_firewall.main_boolean:get() then
            menu_elements_firewall.max_firewalls:render("Max Firewalls", "Maximum number of active Firewalls (1-10)")
            menu_elements_firewall.min_targets:render("Min Targets", "Minimum targets required to cast Firewall")
        end
 
        menu_elements_firewall.tree_tab:pop()
    end
end

local spell_id_firewall = 111422
local next_time_allowed_cast = 0.0;

-- Function to count active firewalls in the world
local function count_active_firewalls()
    if not actors_manager or not actors_manager.get_all_actors then
        return 0
    end
    
    local actors = actors_manager.get_all_actors()
    local firewall_count = 0
    
    for _, actor in ipairs(actors) do
        local actor_name = actor:get_skin_name()
        if actor_name and (
            actor_name == "Generic_Proxy_firewall" or
            actor_name:find("firewall") or
            actor_name:find("Firewall") or
            actor_name == "Sorcerer_Firewall"
        ) then
            firewall_count = firewall_count + 1
        end
    end
    
    return firewall_count
end

-- Function to check if there are enough targets in range
local function check_targets_in_range(player_position, target_position)
    local min_targets = menu_elements_firewall.min_targets:get()
    
    -- Get nearby enemies
    local nearby_enemies = target_selector.get_near_target_list(target_position, 8.0) -- 8 yard radius around target
    
    if #nearby_enemies >= min_targets then
        return true
    end
    
    return false
end

local function logics(target)
    
    local menu_boolean = menu_elements_firewall.main_boolean:get();
    local max_firewalls = menu_elements_firewall.max_firewalls:get();
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_firewall);

    if not is_logic_allowed then
        return false;
    end;
    
    if not target then
        return false;
    end;

    -- Count current active firewalls
    local current_firewalls = count_active_firewalls()
    
    console.print("[FIREWALL] Current Firewalls: " .. current_firewalls .. "/" .. max_firewalls)
    
    -- Don't cast if we're at the maximum
    if current_firewalls >= max_firewalls then
        return false;
    end
    
    local player_position = get_player_position()
    local target_position = target:get_position();
    
    -- Check if there are enough targets to justify casting
    if not check_targets_in_range(player_position, target_position) then
        return false;
    end
    
    -- Additional check: don't cast firewall too close to existing ones
    if current_firewalls > 0 then
        local actors = actors_manager.get_all_actors()
        for _, actor in ipairs(actors) do
            local actor_name = actor:get_skin_name()
            if actor_name == "Generic_Proxy_firewall" then
                local actor_position = actor:get_position()
                local distance = target_position:dist_to(actor_position)
                if distance < 4.0 then -- Don't cast within 4 yards of existing firewall
                    return false
                end
            end
        end
    end

    if cast_spell.position(spell_id_firewall, target_position, 0.35) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.5; -- Reduced cooldown for more frequent casting
        
        console.print("Sorcerer Plugin, Firewall cast (" .. (current_firewalls + 1) .. "/" .. max_firewalls .. ")");
        return true;
    end

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}