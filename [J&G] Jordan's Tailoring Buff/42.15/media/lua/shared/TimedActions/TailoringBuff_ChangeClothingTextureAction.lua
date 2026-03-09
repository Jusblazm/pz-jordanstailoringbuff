-- TailoringBuff_ChangeClothingTextureAction
require "TimedActions/ISBaseTimedAction"

TailoringBuff_ChangeClothingTextureAction = ISBaseTimedAction:derive("TailoringBuff_ChangeClothingTextureAction")

function TailoringBuff_ChangeClothingTextureAction:isValid()
    return self.item and self.character 
        and self.character:getInventory():contains(self.item)
        and TailoringBuff_Utils.hasThread(self.character)
end

function TailoringBuff_ChangeClothingTextureAction:start()
    self:setActionAnim("Making")
    self:setOverrideHandModels(nil, "Thread")
end

function TailoringBuff_ChangeClothingTextureAction:stop()
    ISBaseTimedAction.stop(self)
end

function TailoringBuff_ChangeClothingTextureAction:perform()
    if self.character:isEquipped(self.item) then
        self.character:resetModelNextFrame()
    end

    ISBaseTimedAction.perform(self)
end

function TailoringBuff_ChangeClothingTextureAction:complete()
    local ok = TailoringBuff_Utils.useDrainable(self.character, "Base.Thread", 2)
    if not ok then return false end

    local visual = self.item:getVisual()
    if not visual then return false end

    visual:setTextureChoice(self.textureIndex)
    self.item:synchWithVisual()

    self.item:syncItemFields()
    syncItemModData(self.character, self.item)

    return true
end

function TailoringBuff_ChangeClothingTextureAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function TailoringBuff_ChangeClothingTextureAction:new(character, item, textureIndex)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.textureIndex = textureIndex
    o.maxTime = o:getDuration()
    return o
end