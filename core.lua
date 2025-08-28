local E, L, V, P, G = unpack(ElvUI)
local GS = E:NewModule("ElvUI_GoldScaleFix", "AceEvent-3.0")
local EP = LibStub("LibElvUIPlugin-1.0")
local addon = ...

P["GoldScaleFix"] = {
    iconScale = 1.0,
    iconXOffset = 0,
    enabled = true,
}

-- Save the original FormatMoney function so we can restore it
local OriginalFormatMoney = E.FormatMoney

local function getIcon(tag, scale, xOffset)
    scale = scale or 1
    xOffset = xOffset or 0
    local size = math.floor(14 * scale)
    return ("|T%s:%d:%d:%d:0:64:64:4:60:4:60|t"):format(tag, size, size, xOffset)
end

-- Overwrite E:FormatMoney globally, with argument compatibility
local function CustomFormatMoney(amount, style, textonly, ...)
    -- Compatibility: Called as E:FormatMoney(self, amount, ...)
    if type(amount) == "table" and type(style) == "number" then
        amount, style, textonly = style, textonly, ...
    end
    amount = tonumber(amount) or 0

    local db = E.db and E.db.GoldScaleFix or { iconScale = 1, iconXOffset = 0 }
    local scale, xOffset = db.iconScale or 1, db.iconXOffset or 0
    local ICON_GOLD = getIcon("Interface\\MoneyFrame\\UI-GoldIcon", scale, xOffset)
    local ICON_SILVER = getIcon("Interface\\MoneyFrame\\UI-SilverIcon", scale, xOffset)
    local ICON_COPPER = getIcon("Interface\\MoneyFrame\\UI-CopperIcon", scale, xOffset)

    local coppername = textonly and L["copperabbrev"] or ICON_COPPER
    local silvername = textonly and L["silverabbrev"] or ICON_SILVER
    local goldname = textonly and L["goldabbrev"] or ICON_GOLD

    local value = math.abs(amount)
    local gold = math.floor(value / 10000)
    local silver = math.floor(math.fmod(value / 100, 100))
    local copper = math.floor(math.fmod(value, 100))

    if not style or style == "SMART" then
        local str = ""
        if gold > 0 then str = string.format("%d%s%s", gold, goldname, (silver > 0 or copper > 0) and " " or "") end
        if silver > 0 then str = string.format("%s%d%s%s", str, silver, silvername, copper > 0 and " " or "") end
        if copper > 0 or value == 0 then str = string.format("%s%d%s", str, copper, coppername) end
        return str
    elseif style == "FULL" then
        if gold > 0 then
            return string.format("%d%s %d%s %d%s", gold, goldname, silver, silvername, copper, coppername)
        elseif silver > 0 then
            return string.format("%d%s %d%s", silver, silvername, copper, coppername)
        else
            return string.format("%d%s", copper, coppername)
        end
    elseif style == "SHORT" then
        if gold > 0 then
            return string.format("%.1f%s", amount / 10000, goldname)
        elseif silver > 0 then
            return string.format("%.1f%s", amount / 100, silvername)
        else
            return string.format("%d%s", amount, coppername)
        end
    elseif style == "SHORTINT" then
        if gold > 0 then
            return string.format("%d%s", gold, goldname)
        elseif silver > 0 then
            return string.format("%d%s", silver, silvername)
        else
            return string.format("%d%s", copper, coppername)
        end
    elseif style == "CONDENSED" then
        if gold > 0 then
            return string.format("%d%s.%02d%s.%02d%s", gold, goldname, silver, silvername, copper, coppername)
        elseif silver > 0 then
            return string.format("%d%s.%02d%s", silver, silvername, copper, coppername)
        else
            return string.format("%d%s", copper, coppername)
        end
    elseif style == "BLIZZARD" then
        if gold > 0 then
            return string.format("%s%s %d%s %d%s", gold, goldname, silver, silvername, copper, coppername)
        elseif silver > 0 then
            return string.format("%d%s %d%s", silver, silvername, copper, coppername)
        else
            return string.format("%d%s", copper, coppername)
        end
    end
end

local function ConfigTable()
    E.Options.args.GoldScaleFix = {
        order = 500,
        type = "group",
        name = "|cffFFD700GoldScaleFix|r",
        args = {
            header = { order = 1, type = "header", name = L["GoldScaleFix"] },
            enabled = {
                order = 2, type = "toggle", name = L["Enable"],
                desc = L["Enable or disable GoldScaleFix tweaks."],
                get = function() return E.db.GoldScaleFix.enabled end,
                set = function(_, value)
                    E.db.GoldScaleFix.enabled = value
                    GS:ApplyHooks()           -- Apply or remove override instantly
                    GS:RefreshGoldDatatext()  -- Force update datatexts
                end,
            },
            iconScale = {
                order = 3, type = "range", min = 0.5, max = 2, step = 0.01,
                name = L["Icon Scale"], desc = L["Adjust the scale of gold/silver/copper icons."],
                get = function() return E.db.GoldScaleFix.iconScale end,
                set = function(_, value)
                    E.db.GoldScaleFix.iconScale = value
                    GS:ApplyHooks()
                    GS:RefreshGoldDatatext()
                end,
            },
            iconXOffset = {
                order = 4, type = "range", min = -20, max = 20, step = 1,
                name = L["Icon X-Offset"], desc = L["Adjust the horizontal offset of gold/silver/copper icons."],
                get = function() return E.db.GoldScaleFix.iconXOffset end,
                set = function(_, value)
                    E.db.GoldScaleFix.iconXOffset = value
                    GS:ApplyHooks()
                    GS:RefreshGoldDatatext()
                end,
            },
            info = { order = 10, type = "description", name = L["Adjust how the currency icons appear in the Gold Datatext panel."] },
        }
    }
end

function GS:ApplyHooks()
    if E.db.GoldScaleFix.enabled then
        E.FormatMoney = CustomFormatMoney
    else
        E.FormatMoney = OriginalFormatMoney
    end
end

function GS:RefreshGoldDatatext()
    local DT = E:GetModule("DataTexts")
    if DT and DT.LoadDataTexts then
        DT:LoadDataTexts()
    end
end

function GS:PLAYER_ENTERING_WORLD()
    GS:ApplyHooks()
    GS:RefreshGoldDatatext()
end

function GS:ELVUI_FORCE_RUN()
    GS:ApplyHooks()
    GS:RefreshGoldDatatext()
end

function GS:Initialize()
    EP:RegisterPlugin(addon, ConfigTable)
    GS:ApplyHooks()
    GS:RegisterEvent("PLAYER_ENTERING_WORLD")
    GS:RegisterEvent("ELVUI_FORCE_RUN")
end

E:RegisterModule(GS:GetName())