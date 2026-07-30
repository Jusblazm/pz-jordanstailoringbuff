-- TailoringBuff_DyeClothingAction
require "TimedActions/ISBaseTimedAction"

TailoringBuff_DyeClothingAction = ISBaseTimedAction:derive("TailoringBuff_DyeClothingAction")

function TailoringBuff_DyeClothingAction:isValid()
    return self.item and self.character 
        and self.character:getInventory():contains(self.item)
        and TailoringBuff_Utils.hasDyePack(self.character)
end

function TailoringBuff_DyeClothingAction:start()
    self:setActionAnim("Making")
end

function TailoringBuff_DyeClothingAction:stop()
    ISBaseTimedAction.stop(self)
end

function TailoringBuff_DyeClothingAction:perform()
    if self.character:isEquipped(self.item) then
        self.character:resetModelNextFrame()
    end

    ISBaseTimedAction.perform(self)
end

function TailoringBuff_DyeClothingAction:complete()
    local ok = TailoringBuff_Utils.useDrainable(self.character, "Base.DyePack", 1)
    if not ok then return false end
    
    -- local color = Color.new(self.r, self.g, self.b, 1)
    -- self.item:setColor(color)
    -- self.item:setCustomColor(true)

    local color2 = ImmutableColor.new(self.r, self.g, self.b, 1)
    self.item:getVisual():setTint(color2)
    -- self.item:synchWithVisual()

    self.item:syncItemFields()
    syncItemModData(self.character, self.item)

    return true
end

function TailoringBuff_DyeClothingAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function TailoringBuff_DyeClothingAction:new(character, item, r, g, b)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.r = r
    o.g = g
    o.b = b
    o.maxTime = o:getDuration()
    return o
end