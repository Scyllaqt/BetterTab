local ADDON_NAME = ...
local ACTION     = "TARGETNEARESTENEMY"
local PVP_ACTION = "TARGETNEARESTENEMYPLAYER"
local ALTERAC_VALLEY = 30

local owner = CreateFrame("Frame")
local db
local pending
local category

local function ShouldSwap()
    if not db.enabled then return false end
    local _, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType ~= "pvp" and instanceType ~= "arena" then return false end
    if instanceID == ALTERAC_VALLEY and db.disableInAV then return false end
    return true
end

local function Apply(on)
    if InCombatLockdown() then
        pending = on
        return
    end
    pending = nil

    ClearOverrideBindings(owner)
    if on then
        for _, key in ipairs({ GetBindingKey(ACTION) }) do
            SetOverrideBinding(owner, false, key, PVP_ACTION)
        end
    end
end

local function Refresh()
    Apply(ShouldSwap())
end

local function RegisterSettings()
    category = Settings.RegisterVerticalLayoutCategory("BetterTab")

    local enabled = Settings.RegisterAddOnSetting(category, "BetterTab_Enabled", "enabled",
        db, Settings.VarType.Boolean, "Enable BetterTab", true)
    enabled:SetValueChangedCallback(Refresh)
    local enabledInit = Settings.CreateCheckbox(category, enabled, "Temporarily swaps your Target Nearest Enemy keybind to Target Nearest Enemy Player while in INSTANCED pvp")

    local av = Settings.RegisterAddOnSetting(category, "BetterTab_DisableInAV", "disableInAV",
        db, Settings.VarType.Boolean, "Disable in Alterac Valley", false)
    av:SetValueChangedCallback(Refresh)
    local avInit = Settings.CreateCheckbox(category, av)
    avInit:SetParentInitializer(enabledInit, function() return db.enabled end)

    Settings.RegisterAddOnCategory(category)
end

owner:RegisterEvent("ADDON_LOADED")
owner:RegisterEvent("PLAYER_ENTERING_WORLD")
owner:RegisterEvent("PLAYER_REGEN_ENABLED")
owner:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        BetterTab_DB = BetterTab_DB or {}
        db = BetterTab_DB
        if db.enabled == nil then db.enabled = true end
        if db.disableInAV == nil then db.disableInAV = false end
        RegisterSettings()
        owner:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        Refresh()
    elseif pending ~= nil then
        Apply(pending)
    end
end)

SLASH_BETTERTAB1 = "/bettertab"
SlashCmdList.BETTERTAB = function()
    Settings.OpenToCategory(category:GetID())
end