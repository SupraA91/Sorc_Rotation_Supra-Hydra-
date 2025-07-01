-- Hydra Sorceress Spell Priority
-- Optimized for maintaining Hydras, battlefield control, and positioning

local spell_priority_hydra = {
    -- Defensive spells (highest priority when needed)
    "flame_shield",
    "ice_armor",
    
    -- Core damage and utility summons
    "familiars",     -- Keep active for damage boost
    "hydra",         -- Maintain 2 active for consistent damage
    
    -- Positioning and mobility
    "teleport",      -- For optimal positioning and safety
    "teleport_ench", -- Enhanced teleport if available
    
    -- Battlefield control
    "firewall",      -- Area denial and damage
    
    -- Additional spells (lower priority, used when others are on cooldown)
    "unstable_current",
    "frost_nova",
    "meteor",
    "inferno",
    "blizzard",
    "frozen_orb",
    "chain_lightning",
    "ice_shards",
    "fireball",
    "ball",
    "spear",
    "ice_blade",
    "charged_bolts",
    "arc_lash",
    "incinerate",
    "fire_bolt",
    "frost_bolt",
    "spark",
    "deep_freeze"
}

return spell_priority_hydra