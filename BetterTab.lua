local ADDON_NAME   = ...
local ACTION_NAME  = "TARGETNEARESTENEMY"
local BUTTON_NAME  = "BetterTab_Button"
local FALLBACK_KEY = "TAB"

BetterTab_DB = BetterTab_DB or {}

local state = {
    originalKeys = nil,
    isSwapped    = false,
    pendingSwap  = nil
}

local swapButton = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
swapButton:SetAttribute("type", "macro")
swapButton:SetAttribute("macrotext", "/targetenemyplayer")
swapButton:Hide()


local function GetKeysForAction(action)
    local keys = {}
    local key1, key2 = GetBindingKey(action)
    if key1 then table.insert(keys, key1) end
    if key2 then table.insert(keys, key2) end
    return keys
end

local function ApplySwap(swapOn)
    if InCombatLockdown() then
        state.pendingSwap = swapOn
        return
    end
    state.pendingSwap = nil

    if swapOn then
        if not state.originalKeys then
            state.originalKeys = GetKeysForAction(ACTION_NAME)
            if #state.originalKeys == 0 then
                state.originalKeys = { FALLBACK_KEY }
            end
        end

        for _, key in ipairs(state.originalKeys) do
            SetBindingClick(key, BUTTON_NAME)
        end
        state.isSwapped = true

    else
        if state.originalKeys and #state.originalKeys > 0 then
            for _, key in ipairs(state.originalKeys) do
                SetBinding(key, ACTION_NAME)
            end
        end
        state.isSwapped = false
    end
end

local function IsInstancedPVP()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return true
    end
    return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- combat ended

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        local wantSwap = IsInstancedPVP()
        if wantSwap ~= state.isSwapped then
            ApplySwap(wantSwap)
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if state.pendingSwap ~= nil then
            ApplySwap(state.pendingSwap)
        end
    end
end)
