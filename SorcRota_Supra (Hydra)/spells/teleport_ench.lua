local my_utility = require("my_utility/my_utility")

local menu_elements_teleport_ench =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "base_teleport_ench_base_main_bool")),
    cast_on_self        = checkbox:new(false, get_hash(my_utility.plugin_label .. "base_teleport_ench_cast_on_self_bool")),
    short_range_tp      = checkbox:new(false, get_hash(my_utility.plugin_label .. "base_teleport_ench_short_range_tp_bool")),
    priority_target     = checkbox:new(false, get_hash(my_utility.plugin_label .. "base_teleport_ench_priority_target_bool")),
}

local function menu()
    
    if menu_elements_teleport_ench.tree_tab:push("teleport_ench") then
        menu_elements_teleport_ench.main_boolean:render("Enable Spell", "")
        
        if menu_elements_teleport_ench.main_boolean:get() then
            -- Track previous states before rendering
            local prev_self = menu_elements_teleport_ench.cast_on_self:get()
            local prev_priority = menu_elements_teleport_ench.priority_target:get()
            
            -- Render the checkboxes
            local self_clicked = menu_elements_teleport_ench.cast_on_self:render("Cast on Self", "Casts Teleport at where you stand")
            local priority_clicked = menu_elements_teleport_ench.priority_target:render("Cast on Priority Target", "Targets Boss > Champion > Elite > Any")
            
            -- Get current states after rendering
            local curr_self = menu_elements_teleport_ench.cast_on_self:get()
            local curr_priority = menu_elements_teleport_ench.priority_target:get()
            
            -- Check if either option was just enabled
            local self_just_enabled = not prev_self and curr_self
            local priority_just_enabled = not prev_priority and curr_priority
            
            -- Handle mutual exclusivity
            if self_just_enabled then
                -- Cast on Self was just enabled, disable Priority Target
                menu_elements_teleport_ench.priority_target:set(false)
            elseif priority_just_enabled then
                -- Priority Target was just enabled, disable Cast on Self
                menu_elements_teleport_ench.cast_on_self:set(false)
            end
            
            -- Additional check for when clicking directly on an already disabled option
            if self_clicked and not prev_self then
                menu_elements_teleport_ench.cast_on_self:set(true)
                menu_elements_teleport_ench.priority_target:set(false)
            elseif priority_clicked and not prev_priority then
                menu_elements_teleport_ench.priority_target:set(true)
                menu_elements_teleport_ench.cast_on_self:set(false)
            end
            
            -- Final safety check
            if menu_elements_teleport_ench.cast_on_self:get() and menu_elements_teleport_ench.priority_target:get() then
                if self_clicked then
                    menu_elements_teleport_ench.priority_target:set(false)
                else
                    menu_elements_teleport_ench.cast_on_self:set(false)
                end
            end
            
            menu_elements_teleport_ench.short_range_tp:render("Short Range Tele", "Stop teleport to random hill ufak")
        end
        
        menu_elements_teleport_ench.tree_tab:pop()
    end
end

local spell_id_teleport_ench = 959728

local spell_data_teleport_ench = spell_data:new(
    5.0,                        -- radius
    8.0,                        -- range
    1.0,                        -- cast_delay
    0.7,                        -- projectile_speed
    false,                      -- has_collision
    spell_id_teleport_ench,     -- spell_id
    spell_geometry.circular,    -- geometry_type
    targeting_type.skillshot    -- targeting_type
)

local next_time_allowed_cast = 0.0
local_player = get_local_player()

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

local function logics(target, target_selector_data)
    local_player = get_local_player()
    local menu_boolean = menu_elements_teleport_ench.main_boolean:get()
    local cast_on_self = menu_elements_teleport_ench.cast_on_self:get()
    local priority_target = menu_elements_teleport_ench.priority_target:get()
    local short_range_tp = menu_elements_teleport_ench.short_range_tp:get()

    -- Short Range Teleport Range
    if short_range_tp then
        spell_data_teleport_ench.range = 5.0
    else
        spell_data_teleport_ench.range = 8.0
    end
    
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean, 
                next_time_allowed_cast, 
                spell_id_teleport_ench)

    -- Check if logic is allowed first - this prevents excessive calls
    if not is_logic_allowed then
        return false
    end

    local current_orb_mode = orbwalker.get_orb_mode()

    if not menu_boolean then
        return false
    end

    if current_orb_mode == orb_mode.none then
        return false
    end

    if not local_player:is_spell_ready(spell_id_teleport_ench) then
        return false
    end

    -- Cast on self mode
    if cast_on_self then
        if cast_spell.self(spell_id_teleport_ench, 0.5) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + 0.5

            console.print("Casted Teleport Enchantment on Self")
            return true
        end
    -- Priority target mode
    elseif priority_target and target_selector_data then
        local best_target, target_type = get_priority_target(target_selector_data)
        
        if best_target then
            if cast_spell.target(best_target, spell_data_teleport_ench, false) then
                local current_time = get_time_since_inject()
                next_time_allowed_cast = current_time + 0.5

                console.print("Casted Teleport Enchantment on Priority Target: " .. target_type)
                return true
            end
        else
            console.print("No valid priority target found for Teleport Enchantment")
        end
    -- Regular target mode (using the target passed from main.lua)
    else
        if target and cast_spell.target(target, spell_data_teleport_ench, false) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + 0.75

            console.print("Casted Teleport Enchantment on Target")
            return true
        end
    end
            
    return false
end

return 
{
    menu = menu,
    logics = logics,   
    menu_elements_teleport_ench = menu_elements_teleport_ench,
}
