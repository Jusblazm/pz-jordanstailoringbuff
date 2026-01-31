local THREAD_ITEM = "Base.Thread"

-- Check if the player has at least 2 uses of thread
local function hasEnoughThread(player)
    local thread = player:getInventory():FindAndReturn(THREAD_ITEM)
    if thread and thread:getDrainableUsesInt() >= 2 then
        return true
    elseif thread and thread:getDrainableUsesInt() == 1 then
        player:Say("This is the last use of thread!")
        return true
    end
    return false
end

-- Consume 2 uses of thread or the last remaining use if only 1
local function consumeThread(player)
    local thread = player:getInventory():FindAndReturn(THREAD_ITEM)
    if thread then
        if thread:getDrainableUsesInt() > 1 then
            thread:Use() -- Consume 1 use of thread
            thread:Use() -- Consume 2nd use
        elseif thread:getDrainableUsesInt() == 1 then
            player:getInventory():Remove(thread) -- Remove item when last use is consumed
        end
    end
end

-- Function to update the item's visual and consume thread
local function setItemVisual(playerObj, item, textureIndex)
    -- Check if the player has enough thread
    if not hasEnoughThread(playerObj) then
        playerObj:Say("You need 2 uses of thread to change the skin.")
        return
    end

    local clothingItem = item:getClothingItem()
    if not clothingItem then return end -- Prevent errors if item has no clothing component

    local itemVisual = item:getVisual()

    -- Set the new texture based on the chosen index
    if clothingItem:hasModel() then
        itemVisual:setTextureChoice(textureIndex)
    else
        itemVisual:setBaseTexture(textureIndex)
    end

    item:synchWithVisual()

    -- If the item is equipped, reset the player's model to update the appearance
    if item:isEquipped() then
        playerObj:resetModelNextFrame()
        triggerEvent("OnClothingUpdated", playerObj)
    end

    -- Consume 2 uses of thread after changing the skin
    consumeThread(playerObj)
    playerObj:Say("2 uses of thread consumed to change the skin.")
end

-- Context menu listing all textures
local function onFillInventoryObjectContextMenu(player, context, items)
    local playerObj = getSpecificPlayer(player) -- Get the player object

    -- Check if the player has Tailoring level
    if playerObj:getPerkLevel(Perks.Tailoring) < 6 then
        return -- Exit if the player does not meet the Tailoring level requirement
    end

    local itemList = {}
    for _, compoundItem in pairs(items) do
        if compoundItem.items and #compoundItem.items >= 1 then
            local item = compoundItem.items[1]
            -- Only include items that are either clothing or inventory containers
            if item and (item:IsClothing() or item:IsInventoryContainer()) then
                local clothingItem = item:getClothingItem()
                if clothingItem and item:getVisual() then  -- Ensure item has visual data
                    local textureChoices = clothingItem:hasModel() and clothingItem:getTextureChoices() or clothingItem:getBaseTextures()
                    if textureChoices and textureChoices:size() > 1 then
                        table.insert(itemList, item)
                    end
                end
            end
        end
    end

    if #itemList > 0 then
        local firstItem = itemList[1]
        local clothingItem = firstItem:getClothingItem()
        local itemVisual = firstItem:getVisual()

        local textureChoices = clothingItem:hasModel() and clothingItem:getTextureChoices() or clothingItem:getBaseTextures()
        local choicesAmount = textureChoices:size()

        -- Only display if there are multiple textures
        if textureChoices and (choicesAmount > 1) then
            local mainOption = context:addOptionOnTop(getText("Modify Clothing (Texture)"))
            local mainMenu = ISContextMenu:getNew(context)
            context:addSubMenu(mainOption, mainMenu)

            -- List all skins in the submenu
            for i = 0, choicesAmount - 1 do
                local texturePath = textureChoices:get(i)
                local textureName = texturePath:match("([^/\\]+)$") or texturePath
                mainMenu:addOption(textureName, playerObj, setItemVisual, firstItem, i)
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
