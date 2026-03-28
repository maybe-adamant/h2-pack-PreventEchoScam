local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-ModpackLib']

config = chalk.auto('config.lua')
public.config = config

local backup, revert = lib.createBackupSystem()

-- =============================================================================
-- UTILITIES
-- =============================================================================


local function DeepCompare(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end
    for key, value in pairs(a) do
        if not DeepCompare(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function ListContainsEquivalent(list, template)
    if type(list) ~= "table" then return false end
    for _, entry in ipairs(list) do
        if DeepCompare(entry, template) then return true end
    end
    return false
end

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "PreventEchoScam",
    name     = "Prevent Echo Scam",
    category = "Run Modifiers",
    group    = "NPCs & Routing",
    tooltip  = "Prevents Echo scam by blocking both minibosses from spawning at room 3.",
    default  = false,
    dataMutation = true,
    modpack = "speedrun",
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
    backup(RoomData["H_MiniBoss01"], "GameStateRequirements")
    backup(RoomData["H_MiniBoss02"], "GameStateRequirements")
    local newReq = {
        Path = { "CurrentRun", "BiomeDepthCache" },
        Comparison = "!=",
        Value = 3,
    }
    for _, roomName in ipairs({ "H_MiniBoss01", "H_MiniBoss02" }) do
        local reqs = RoomData[roomName].GameStateRequirements
        if reqs and not ListContainsEquivalent(reqs, newReq) then
            table.insert(reqs, newReq)
        end
    end
end

local function registerHooks()
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config, public.definition.modpack) then apply() end
        if public.definition.dataMutation and not lib.isCoordinated(public.definition.modpack) then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
