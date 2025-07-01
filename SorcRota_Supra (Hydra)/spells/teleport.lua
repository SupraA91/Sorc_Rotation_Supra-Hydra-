local my_utility = require("my_utility/my_utility");

local menu_elements_sorc_base = 
{
    tree_tab              = tree_node:new(1),
    main_boolean          = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean_teleport_base")),
   
    enable_teleport       = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_teleport_base")),
    keybind_ignore_hits   = checkbox:new(true, get_hash(my_utility.plugin_label .. "keybind_ignore_min_hits_base_tp")),
    
    min_hits              = slider_int:new(1, 20, 6, get_hash(my_utility.plugin_label .. "min_hits_to_cast_base_tp")),
    
    soft_score            = slider_float:new(2.0, 15.0, 6.0, get_hash(my_utility.plugin_label .. "min_percentage_hits_soft_core_tp")),
    
    teleport_on_self      = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_on_self_base")),
    priority_target       = checkbox:new(false, get_hash(my_utility.plugin_label .. "teleport_priority_target_bool")),
    
    short_range_tele      = checkbox:new(false, get_hash(my_utility.plugin_label .. "short_range_tele_base")),
    
    tele_gtfo             = checkbox:new(false, get_hash(my_utility.plugin_label .. "gtfo"))
}

local function menu()
    if menu_elements_sorc_base.tree_tab:push("Teleport") then
        menu_elements_sorc_base.main_boolean:render("Enable Spell", "");
        
        if menu_elements_sorc_base.main_boolean:get() then
            -- Track previous states before rendering
            local prev_self = menu_elements_sorc_base.teleport_on_self:get()
            local prev_priority = menu_elements_sorc_base.priority_target:get()
            
            -- Render the checkboxes
            local self_clicked = menu_elements_sorc_base.teleport_on_self:render("Cast on Self", "Casts Teleport at where you stand")
            local priority_clicked = menu_elements_sorc_base.priority_target:render("Cast on Priority Target", "Targets Boss > Champion > Elite > Any")
            
            -- Get current states after rendering
            local curr_self = menu_elements_sorc_base.teleport_on_self:get()
            local curr_priority = menu_elements_sorc_base.priority_target:get()
            
            -- Check if either option was just enabled
            local self_just_enabled = not prev_self and curr_self
            local priority_just_enabled = not prev_priority and curr_priority
            
            -- Handle mutual exclusivity
            if self_just_enabled then
                -- Cast on Self was just enabled, disable Priority Target
                menu_elements_sorc_base.priority_target:set(false)
            elseif priority_just_enabled then
                -- Priority Target was just enabled, disable Cast on Self
                menu_elements_sorc_base.teleport_on_self:set(false)
            end
            
            -- Additional check for when clicking directly on an already disabled option
            if self_clicked and not prev_self then
                menu_elements_sorc_base.teleport_on_self:set(true)
                menu_elements_sorc_base.priority_target:set(false)
            elseif priority_clicked and not prev_priority then
                menu_elements_sorc_base.priority_target:set(true)
                menu_elements_sorc_base.teleport_on_self:set(false)
            end
            
            -- Final safety check
            if menu_elements_sorc_base.teleport_on_self:get() and menu_elements_sorc_base.priority_target:get() then
                if self_clicked then
                    menu_elements_sorc_base.priority_target:set(false)
                else
                    menu_elements_sorc_base.teleport_on_self:set(false)
                end
            end
            
            menu_elements_sorc_base.short_range_tele:render("Short Range Tele", "Stop teleport to random hill ufak");
            menu_elements_sorc_base.tele_gtfo:render("Tele Gtfo", "Gtfo at <90hp");
        end
        
        menu_elements_sorc_base.tree_tab:pop();
    end
end

local my_target_selector = require("my_utility/my_target_selector");

local spell_id_tp = 288106;

local spell_radius = 2.5;
local spell_max_range = 10.0;

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

local function logics(entity_list, target_selector_data, best_target)
    -- Make sure local_player is defined
    local local_player = get_local_player()
    if not local_player then
        return false
    end
    
    local menu_boolean = menu_elements_sorc_base.main_boolean:get();
    local priority_target = menu_elements_sorc_base.priority_target:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_tp);
                
    if not is_logic_allowed then
        return false;
    end

    if not local_player:is_spell_ready(spell_id_tp) then
        return false;
    end

    -- Tele Gtfo Logic
    if menu_elements_sorc_base.tele_gtfo:get() then
        local current_health = local_player:get_current_health();
        local max_health = local_player:get_max_health();
        local health_percentage = current_health / max_health;

        if health_percentage < 0.90 then
            local player_position = get_player_position();
            local safe_direction = vec3:new(1, 0, 0); -- Default safe direction
            local safe_distance = 10.0;  -- Distance Adjustments
            local safe_position = player_position + safe_direction * safe_distance;

            -- No utility module available, use the position as is
            -- We could potentially add a small height adjustment here if needed

            cast_spell.position(spell_id_tp, safe_position, 0.3);
            next_time_allowed_cast = get_time_since_inject() + 0.1;
            console.print("Sorcerer Plugin, Casted Teleport due to I need to GTFO");
            return true;
        end
    end

    local player_position = get_player_position();
    -- Default enable_teleport to true if no special modes are active
    local enable_teleport = menu_elements_sorc_base.enable_teleport:get() or 
                           (not menu_elements_sorc_base.teleport_on_self:get() and 
                            not menu_elements_sorc_base.priority_target:get() and
                            not menu_elements_sorc_base.tele_gtfo:get());
    
    -- Short Range Teleport Range
    local adjusted_spell_max_range = spell_max_range;
    if menu_elements_sorc_base.short_range_tele:get() then
        adjusted_spell_max_range = 5.0;
    end

    -- Cast on Self
    if menu_elements_sorc_base.teleport_on_self:get() then
        cast_spell.self(spell_id_tp, 0.3);  
        next_time_allowed_cast = get_time_since_inject() + 0.4;
        console.print("Sorcerer Plugin, Casted Teleport on Self");
        return true;
    end
    
    -- Priority target mode
    if menu_elements_sorc_base.priority_target:get() and target_selector_data then
        local best_target, target_type = get_priority_target(target_selector_data)
        
        if best_target then
            local target_position = best_target:get_position()
            if cast_spell.position(spell_id_tp, target_position, 0.3) then
                local current_time = get_time_since_inject()
                next_time_allowed_cast = current_time + 0.4

                console.print("Sorcerer Plugin, Casted Teleport on Priority Target: " .. target_type)
                return true
            end
        else
            console.print("No valid priority target found for Teleport")
        end
    end

    local keybind_ignore_hits = menu_elements_sorc_base.keybind_ignore_hits:get();
    local keybind_can_skip = keybind_ignore_hits and enable_teleport;

    local min_hits_menu = menu_elements_sorc_base.min_hits:get();

    -- Use my_target_selector for targeting instead of target_selector
    -- First check if we have a valid target from the passed parameters
    if not best_target then
        return false;
    end

    -- Use the best_target parameter that was passed to the function
    if not best_target:is_enemy() then
        return false;
    end
    
    -- Check if target is relevant (elite, champion, or boss)
    local is_relevant_target = best_target:is_elite() or best_target:is_champion() or best_target:is_boss();
    
    -- Only proceed if target is relevant or keybind_can_skip is true
    if not is_relevant_target and not keybind_can_skip then
        return false;
    end
    
    local cast_position = best_target:get_position();
    local cast_position_distance_sqr = cast_position:squared_dist_to_ignore_z(player_position);
    if cast_position_distance_sqr < 2.0 and not keybind_can_skip  then
        return false;
    end

    cast_spell.position(spell_id_tp, cast_position, 0.3);
    local current_time = get_time_since_inject();
    next_time_allowed_cast = current_time + 0.4;

    console.print("Sorcerer Plugin, Casted Tp");
    return true;

end

return 
{
    menu = menu,
    logics = logics,   
}

