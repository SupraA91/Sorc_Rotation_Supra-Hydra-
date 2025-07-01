local my_utility = require("my_utility/my_utility");

local menu_elements = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_ball_lightning")),
    priority_target       = checkbox:new(false, get_hash(my_utility.plugin_label .. "ball_priority_target_bool")),
}

local function menu()
    
    if menu_elements.tree_tab:push("Lightning Ball") then
       menu_elements.main_boolean:render("Enable Spell", "")
       
       if menu_elements.main_boolean:get() then
           menu_elements.priority_target:render("Priority Targeting", "Targets Boss > Champion > Elite > Any")
       end

       menu_elements.tree_tab:pop()
    end
end

local spell_id_ball = 514030

local ball_spell_data = spell_data:new(
    0.6,           -- radius
    12.0,          -- range
    0.3,           -- cast_delay
    2.5,           -- projectile_speed
    true,          -- has_collision
    spell_id_ball, -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    -- targeting_type
)

local next_time_allowed_cast = 0.0;
-- Function to get the best target based on priority (Boss > Champion > Elite > Any)
local function get_priority_target(target_selector_data)
    local best_target = nil
    local target_type = "none"
    
    -- Check for boss targets first (highest priority)
    if target_selector_data and target_selector_data.has_boss then
        best_target = target_selector_data.closest_boss
        target_type = "Boss"
        return best_target, target_type
    end
    
    -- Then check for champion targets
    if target_selector_data and target_selector_data.has_champion then
        best_target = target_selector_data.closest_champion
        target_type = "Champion"
        return best_target, target_type
    end
    
    -- Then check for elite targets
    if target_selector_data and target_selector_data.has_elite then
        best_target = target_selector_data.closest_elite
        target_type = "Elite"
        return best_target, target_type
    end
    
    -- Finally, use any available target
    if target_selector_data and target_selector_data.closest_unit then
        best_target = target_selector_data.closest_unit
        target_type = "Regular"
        return best_target, target_type
    end
    
    return nil, "none"
end

local function logics(best_target, target_selector_data)
    local menu_boolean = menu_elements.main_boolean:get();
    local priority_target = menu_elements.priority_target:get();
    
    -- Check if Crackling Energy Snapshot is active and enabled in spear.lua
    local spear_module = require("spells/spear")
    local crackling_energy_snapshot_enabled = spear_module.get_crackling_energy_snapshot_enabled()
    local is_in_crackling_energy_loop = crackling_energy_snapshot_enabled and my_utility.is_crackling_energy_loop_active()
    
    -- If Crackling Energy Snapshot is enabled and active, check if we've reached the cast threshold
    if is_in_crackling_energy_loop then
        -- If we have enough ball casts, we should not cast ball anymore
        if my_utility.has_enough_ball_casts() then
            console.print("[CRACKLING ENERGY] Threshold reached (" .. my_utility.get_ball_cast_count() .. "/" .. my_utility.ball_cast_threshold .. ") - Skipping Ball Lightning")
            return false
        end
        
        -- Attempt to track the ball cast
        -- The tracking function has its own cooldown and debug messages
        my_utility.track_ball_cast()
    end
    
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_ball);

    if not is_logic_allowed then
        return false;
    end;
    
    -- If priority targeting is enabled and we have target data, use that instead
    if priority_target and target_selector_data then
        local priority_best_target, target_type = get_priority_target(target_selector_data)
        if priority_best_target then
            if cast_spell.target(priority_best_target, ball_spell_data, false) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + 0.1;
                console.print("[SKILL-ATTACK], Ball Lightning on Priority Target: " .. target_type);
                return true;
            end
        end
        return false;
    end

    -- Continue with normal targeting if priority targeting is disabled or failed
    if not best_target then
        -- No valid target, fallback: cast at self
        if cast_spell.self(spell_id_ball, 0.0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1;
            console.print("Sorcerer Plugin, Casted Ball at self (no target found)");
            return true;
        end
        return false;
    end
    local player_position = get_player_position();
    local target_position = best_target:get_position();
    if cast_spell.target(best_target, ball_spell_data, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.1;
        console.print("[SKILL-ATTACK], Ball Lightning");
        
        -- Ball cast was already tracked before the cast attempt
        -- No need to track it again here
        
        return true;
    end;

    return false;
end

return 
{
    menu = menu,
    logics = logics,   
}