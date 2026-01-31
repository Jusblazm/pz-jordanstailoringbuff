require "ISUI/ISContextMenu"
require "ISUI/ISColorPicker"

Clothing_Tints = {}

if Clothing_Tints then
    Events.OnFillInventoryObjectContextMenu.Add(Clothing_Tints.contextMenuAdd)
end

-- List of valid paint items
local PAINT_ITEMS = {
    "Base.DyePack"
}

-- Check if the player has at least 1 use of dye
local function hasPaint(player)
    for _, paintItem in ipairs(PAINT_ITEMS) do
        local paint = player:getInventory():FindAndReturn(paintItem)
        if paint and paint:getDrainableUsesInt() >= 1 then -- Change condition to >= 1
            return true
        end
    end
    return false
end

-- Consume 1 use of dye
local function consumePaint(player)
    for _, paintItem in ipairs(PAINT_ITEMS) do
        local paint = player:getInventory():FindAndReturn(paintItem)
        if paint then
            paint:Use()
            if paint:getDrainableUsesInt() == 0 then
                player:getInventory():Remove(paint) -- Remove empty item if no uses left
            end
            return
        end
    end
end

-- update the item's visual
local function setItemVisual(playerObj, item)
    local clothingItem = item:getClothingItem()
    local itemVisual = item:getVisual()
    local color = item:getColor()

    -- Update the visual with the new color
    itemVisual:setTint(ImmutableColor.new(color))
    item:synchWithVisual()

    if item:isEquipped() then
        playerObj:resetModelNextFrame()
        triggerEvent("OnClothingUpdated", playerObj)
    end
end

-- Open the color picker and apply the selected tint
function Clothing_Tints.openTintDialog(item, player)
    if hasPaint(player) then
        local originalColor = item:getColorInfo()

        local function applyColor(inputText)
            if inputText then
                local r, g, b = inputText:match("(%d+),(%d+),(%d+)")
                if r and g and b then
                    local newColor = Color.new(tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255, 1)
                    item:setColor(newColor)
                    setItemVisual(player, item)

                    consumePaint(player)
                    player:Say("Tint changed using 1 use of dye!")
                end
            end
        end

        local function revertColor()
            item:setColor(Color.new(originalColor:getR(), originalColor:getG(), originalColor:getB(), originalColor:getA()))
            setItemVisual(player, item)
        end

        -- Create and display the modal dialog
        local modal = Clothing_Tints.MakeColorDialogPrompt("Pick a color for the item.", item, player, function(inputText)
            if inputText then
                applyColor(inputText)
            else
                revertColor()
                player:Say("Tint change canceled.")
            end
        end)()

        -- Set the initial color in the modal dialog
        modal.currentColor = ColorInfo.new(originalColor:getR(), originalColor:getG(), originalColor:getB(), 1)
        modal.colorBtn.backgroundColor = {r = originalColor:getR(), g = originalColor:getG(), b = originalColor:getB(), a = 1}
        modal.entry:setText(
            math.floor(originalColor:getR() * 255) .. "," ..
            math.floor(originalColor:getG() * 255) .. "," ..
            math.floor(originalColor:getB() * 255)
        )
    else
        player:Say("You need 1 use of dye to change the tint.")
    end
end


function Clothing_Tints.MakeShowDialogPrompt(message, callback)
    return function()
        local scale = getTextManager():MeasureStringY(UIFont.Small, "XXX") / 12

        local width = 200 * scale
        local height = 130 * scale
        local x = (getCore():getScreenWidth() / 2) - (width / 2)
        local y = (getCore():getScreenHeight() / 2) - (height / 2)
        local modal = ISTextBox:new(x, y, width, height, message, "", nil, function (_, button)
            if callback and button.internal == "OK" then
                callback(button.parent.entry:getText())
            elseif callback and button.internal == "CANCEL" then
                callback(nil)
            end
        end, nil)
        modal:initialise()
        modal:addToUIManager()
        return modal
    end
end

function Clothing_Tints.MakeColorDialogPrompt(message, item, player, callback)
    return function()
        local modal = Clothing_Tints.MakeShowDialogPrompt(message, callback)()
        modal.colorPicker.buttonSize = 14
        modal:enableColorPicker()
        modal.colorBtn.onclick = function (self, btn)
            local x = (getCore():getScreenWidth() / 2) - (self.colorPicker.width / 2)
            local y = (getCore():getScreenHeight() / 2) - (self.colorPicker.height / 2)
            self.colorPicker:setX(x)
            self.colorPicker:setY(y)
            self.colorPicker:setVisible(true)
            self.colorPicker:bringToTop()
            self.colorPicker.pickedFunc = modal.onPickedColor
        end
        modal.onPickedColor = function(self, color)
            self.currentColor = ColorInfo.new(color.r, color.g, color.b,1)
            self.colorBtn.backgroundColor = {r = color.r, g = color.g, b = color.b, a = 1}
            self.colorPicker:setVisible(false)
            local r = math.floor(color.r * 255)
            local g = math.floor(color.g * 255)
            local b = math.floor(color.b * 255)
            self.entry:setText(r .. "," .. g .. "," .. b)
            item:setColor(Color.new(color.r, color.g, color.b, 1))
            setItemVisual(player, item)
        end
        modal.entry.onTextChange = function ()
            local r,g,b = modal.entry.javaObject:getInternalText():match("(%d+),(%d+),(%d+)")
            if r and g and b then
                modal.currentColor = ColorInfo.new(r/255, g/255, b/255,1)
                modal.colorBtn.backgroundColor = {r = r/255, g = g/255, b = b/255, a = 1}
            end
        end
        return modal
    end
end

-- add the tinting option to the context menu
function Clothing_Tints.contextMenuAdd(playerIdx, context, items)
    items = ISInventoryPane.getActualItems(items)
    local player = getSpecificPlayer(playerIdx)

    -- Check if the player has Tailoring level
    if player:getPerkLevel(Perks.Tailoring) >= 6 then
        for _, item in ipairs(items) do
            if item and item:allowRandomTint() then
                -- Add the "Tint Clothing" option to the right-click menu
                context:addOption("Dye Clothing (Need Dye Pack)", item, function()
                    Clothing_Tints.openTintDialog(item, player)
                end)
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(Clothing_Tints.contextMenuAdd)