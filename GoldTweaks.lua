local E = unpack(ElvUI)

-- Save the original FormatMoney BEFORE hooking!
local OriginalFormatMoney = E.FormatMoney

local function getIcon(tag, scale, xOffset)
    scale = scale or 1
    xOffset = xOffset or 0
    local size = math.floor(14 * scale)
    return ("|T%s:%d:%d:%d:0:64:64:4:60:4:60|t"):format(tag, size, size, xOffset)
end

function ElvUI_GoldScaleFix_CustomFormatMoney(amount, style, textonly)
    local db = E.db and E.db.GoldScaleFix or { iconScale = 1, iconXOffset = 0 }
    local scale, xOffset = db.iconScale or 1, db.iconXOffset or 0
    local ICON_GOLD = getIcon("Interface\\MoneyFrame\\UI-GoldIcon", scale, xOffset)
    local ICON_SILVER = getIcon("Interface\\MoneyFrame\\UI-SilverIcon", scale, xOffset)
    local ICON_COPPER = getIcon("Interface\\MoneyFrame\\UI-CopperIcon", scale, xOffset)

    local value = math.abs(amount)
    local gold = math.floor(value / 10000)
    local silver = math.floor(math.fmod(value / 100, 100))
    local copper = math.floor(math.fmod(value, 100))

    if not style or style == "SMART" then
        local str = ""
        if gold > 0 then str = string.format("%d%s%s", gold, ICON_GOLD, (silver > 0 or copper > 0) and " " or "") end
        if silver > 0 then str = string.format("%s%d%s%s", str, silver, ICON_SILVER, copper > 0 and " " or "") end
        if copper > 0 or value == 0 then str = string.format("%s%d%s", str, copper, ICON_COPPER) end
        return str
    else
        -- fallback to the original, NOT the hooked one!
        if OriginalFormatMoney then
            return OriginalFormatMoney(E, amount, style, textonly)
        else
            return tostring(amount)
        end
    end
end