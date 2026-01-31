-- TailoringBuff_ContextMenu
local TailoringBuff_Utils = require("TailoringBuff_Utils")

local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    local hasTailoringLevel = TailoringBuff_Utils.hasTailoringLevel(player)
    -- local hasTailoringLevel = true

    for _, v in ipairs(items) do
        local item = v.items and v.items[1] or v
        if not item then return end

        local visual = item:getVisual()
        local clothingItem = visual and visual:getClothingItem()
        if not clothingItem then return end

        if clothingItem and clothingItem:getAllowRandomTint() and hasTailoringLevel then
            local option = context:addOption(getText("ContextMenu_TailoringBuff_Inventory_DyeClothing"), item, function()
                TailoringBuff_DyeUI.showUI(player, item)
            end)
            if not TailoringBuff_Utils.hasDyePack(player) then
                option.notAvailable = true
            end
        end

        local textures = clothingItem:getTextureChoices()
        if clothingItem and textures and textures:size() > 1 and hasTailoringLevel then
            local option = context:addOption(getText("ContextMenu_TailoringBuff_Inventory_ChangeTexture"), item, function()
                TailoringBuff_TextureUI.showUI(player, item)
            end)
            if not TailoringBuff_Utils.hasThread(player) then
                option.notAvailable = true
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)