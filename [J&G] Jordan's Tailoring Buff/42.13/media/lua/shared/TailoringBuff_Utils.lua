-- TailoringBuff_Utils
TailoringBuff_Utils = {}
TailoringBuff_Utils.FAVORITES_DIR = "TailoringBuff"
TailoringBuff_Utils.FAVORITES_FILE = "favoritergbs.txt"
TailoringBuff_Utils.PATH = TailoringBuff_Utils.FAVORITES_DIR .. "/" .. TailoringBuff_Utils.FAVORITES_FILE

function TailoringBuff_Utils.ensureFavoritesFile()
    if not fileExists(TailoringBuff_Utils.PATH) then
        local writer = getFileWriter(TailoringBuff_Utils.PATH, true, false)
        writer:write("0,0,0\n")
        writer:close()
    end
end

function TailoringBuff_Utils.loadFavoriteColors()
    TailoringBuff_Utils.ensureFavoritesFile()

    local colors = {}
    local reader = getFileReader(TailoringBuff_Utils.PATH, true)

    local line = reader:readLine()
    while line do
        local r, g, b = line:match("(%d+),(%d+),(%d+)")
        if r and g and b then
            table.insert(colors, { r = tonumber(r), g = tonumber(g), b = tonumber(b) })
        end
        line = reader:readLine()
    end

    reader:close()
    return colors
end

function TailoringBuff_Utils.useDrainable(player, itemFullType, usesNeeded)
    if not player or not itemFullType or not usesNeeded then return false end

    local inv = player:getInventory()
    local items = inv:getItemsFromType(itemFullType)
    if items:isEmpty() then return false end

    local useDelta = items:get(0):getUseDelta()
    local neededDelta = usesNeeded * useDelta

    local totalDelta = 0
    for i=0, items:size()-1 do
        totalDelta = totalDelta + items:get(i):getCurrentUsesFloat()
    end

    if totalDelta < neededDelta then return false end

    local remainingDelta = neededDelta

    for i=0, items:size()-1 do
        if remainingDelta <= 0 then break end

        local item = items:get(i)
        local available = item:getCurrentUsesFloat()

        if available <= remainingDelta then
            remainingDelta = remainingDelta - available
            inv:Remove(item)
            sendRemoveItemFromContainer(inv, item)
        else
            item:setUsedDelta(available - remainingDelta)
            remainingDelta = 0
            item:syncItemFields()
        end
    end
    return true
end

function TailoringBuff_Utils.hasDyePack(player)
    return player:getInventory():containsTypeRecurse("DyePack")
end

function TailoringBuff_Utils.hasThread(player)
    return player:getInventory():containsTypeRecurse("Thread")
end

function TailoringBuff_Utils.hasTailoringLevel(player)
    local requiredLevel = 6
    if SandboxVars.TailoringBuff and SandboxVars.TailoringBuff.RequiredTailoringLevel then
        requiredLevel = SandboxVars.TailoringBuff.RequiredTailoringLevel
    end
    return player:getPerkLevel(Perks.Tailoring) >= requiredLevel
end

-- function TailoringBuff_Utils.hexToRGBFloats(hex)
--     hex = hex:gsub("#", "")

--     if #hex == 8 then
--         hex = hex:sub(1, 6)
--     end

--     if #hex ~= 6 then return nil end

--     local r = tonumber(hex:sub(1, 2), 16) / 255
--     local g = tonumber(hex:sub(3, 4), 16) / 255
--     local b = tonumber(hex:sub(5, 6), 16) / 255

--     return r, g, b
-- end

function TailoringBuff_Utils.applyClothingTint(pickedTarget, pickedRGB, mouseUp, player, item)
    if not (item and pickedRGB and player) then return end
    -- local color = Color.new(pickedRGB.r, pickedRGB.g, pickedRGB.b)

    -- ISTimedActionQueue.add(TailoringBuff_DyeClothingAction:new(player, item, color))
    ISTimedActionQueue.add(TailoringBuff_DyeClothingAction:new(player, item, pickedRGB.r, pickedRGB.g, pickedRGB.b))
end

function TailoringBuff_Utils.getClothingColor(item)
    if not item then return nil end

    local visual = item:getVisual()
    if not visual then return nil end

    local clothingItem = visual:getClothingItem()
    local tint = visual:getTint(clothingItem)

    return ColorInfo.new(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1)
end

function TailoringBuff_Utils.applyTextureIndex(item, player, textureIndex)
    if not (item and player and textureIndex) then return end
    
    ISTimedActionQueue.add(TailoringBuff_ChangeClothingTextureAction:new(player, item, textureIndex))
end

function TailoringBuff_Utils.getTextureIndex(item)
    local visual = item and item:getVisual()
    return visual and visual:getTextureChoice() or 0
end

function TailoringBuff_Utils.clampRGB(value)
    if type(value) == "table" and value.getText then
        value = value:getText()
    end

    value = tonumber(value) or 0
    return math.max(0, math.min(255, value))
end

function TailoringBuff_Utils.colorInfoToColor(colorInfo)
    if not colorInfo then return nil end
    local c = colorInfo:toColor()
    return Color.new(c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat())
end

function TailoringBuff_Utils.applyPreviewColor(player, item, colorInfo)
    if not (player and item and colorInfo) then return end

    local color = TailoringBuff_Utils.colorInfoToColor(colorInfo)
    if not color then return end

    item:setColor(color)
    item:setCustomColor(true)

    if player:isEquipped(item) then
        player:resetModelNextFrame()
    end
end

function TailoringBuff_Utils.revertPreviewColor(player, item, initialColor)
    TailoringBuff_Utils.applyPreviewColor(player, item, initialColor)
end

function TailoringBuff_Utils.applyPreviewTexture(player, item, index)
    if not (player and item and index) then return end

    local visual = item:getVisual()
    if not visual then return end

    visual:setTextureChoice(index)
    item:synchWithVisual()

    if player:isEquipped(item) then
        player:resetModelNextFrame()
    end
end

function TailoringBuff_Utils.revertPreviewTexture(player, item, index)
    TailoringBuff_Utils.applyPreviewTexture(player, item, index)
end

function TailoringBuff_Utils.openClothingColorPicker(player, item, initialColor, dyeWindow)
    if not item or not initialColor then return end

    local x = getMouseX()
    local y = getMouseY()

    local picker = ISColorPickerHSB:new(x, y, ColorInfo.new())
    picker.pickedTarget = picker
    picker:setPickedFunc(function(_, pickedRGB, _, player, item, window)
        if not (pickedRGB and window) then return end
        window:setCurrentPreviewColor(ColorInfo.new(pickedRGB.r, pickedRGB.g, pickedRGB.b, 1))
    end, player, item, dyeWindow)


    function picker:onSave()
        if self.pickedFunc then
		    self.pickedFunc(self.pickedTarget, self.pickedRGB, false, self.pickedArgs[1], self.pickedArgs[2], self.pickedArgs[3], self.pickedArgs[4])
        end
        self:removeFromUIManager()
        return true
    end

    picker:addToUIManager()
    picker:setInitialColor(initialColor)

    local function onGlobalKeyPressed(key)
        if key == Keyboard.KEY_ESCAPE then
            picker:removeSelf()
        end
    end

    Events.OnKeyPressed.Add(onGlobalKeyPressed)
end

function TailoringBuff_Utils.openFavoritesColorPicker(initialColor, target, onPickedFunc)
    if not (initialColor and target and onPickedFunc) then return end

    local x = getMouseX()
    local y = getMouseY()

    local picker = ISColorPickerHSB:new(x, y, ColorInfo.new())
    picker.pickedTarget = target

    picker:setPickedFunc(function(_, pickedRGB, _, targetObj)
        if not (pickedRGB and targetObj) then return end
        onPickedFunc(targetObj, pickedRGB)
    end, target)

    function picker:onSave()
        if self.pickedFunc then
            self.pickedFunc(self.pickedTarget, self.pickedRGB, false, self.pickedArgs[1], self.pickedArgs[2], self.pickedArgs[3], self.pickedArgs[4])
        end
        self:removeFromUIManager()
        return true
    end

    picker:addToUIManager()
    picker:setInitialColor(initialColor)

    local function onGlobalKeyPressed(key)
        if key == Keyboard.KEY_ESCAPE then
            picker:removeSelf()
        end
    end

    Events.OnKeyPressed.Add(onGlobalKeyPressed)
end


return TailoringBuff_Utils