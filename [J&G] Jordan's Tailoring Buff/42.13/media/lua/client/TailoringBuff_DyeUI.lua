-- TailoringBuff_DyeUI
TailoringBuff_DyeUI = {}

local TailoringBuff_Utils = require("TailoringBuff_Utils")

local ISCollapsableWindow = ISCollapsableWindow

TailoringBuff_DyeUI.Window = ISCollapsableWindow:derive("Window")

function TailoringBuff_DyeUI.Window:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o._updatingFromRGB = false
    return o
end

function TailoringBuff_DyeUI.Window:setPlayer(player)
    self.player = player
end

function TailoringBuff_DyeUI.Window:setItem(item)
    self.item = item
end

function TailoringBuff_DyeUI.Window:setInitialColor(item)
    self.initialColor = TailoringBuff_Utils.getClothingColor(item)
    self.currentPreviewColor = self.initialColor
end

function TailoringBuff_DyeUI.Window:setCurrentPreviewColor(colorInfo, updateRGB)
    if not colorInfo then return end
    self.currentPreviewColor = colorInfo
    self:updateColorButton(colorInfo)

    TailoringBuff_Utils.applyPreviewColor(self.player, self.item, self.currentPreviewColor)

    if updateRGB ~= false and not self._updatingFromRGB then
        local c = colorInfo:toColor()
        self.rEntry:setText(tostring(math.floor(c:getRedFloat() * 255)))
        self.gEntry:setText(tostring(math.floor(c:getGreenFloat() * 255)))
        self.bEntry:setText(tostring(math.floor(c:getBlueFloat() * 255)))
    end
end

function TailoringBuff_DyeUI.Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local padding = 10
    local y = 35

    self.rgbLabel = ISLabel:new(padding, y, 20, getText("UI_TailingBuff_UI_RGB"), 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.rgbLabel)

    y = y + 25

    local boxWidth = 40

    self.rEntry = ISTextEntryBox:new("", padding, y, boxWidth, 20)
    self.gEntry = ISTextEntryBox:new("", padding * 2 + boxWidth, y, boxWidth, 20)
    self.bEntry = ISTextEntryBox:new("", padding + (boxWidth + padding) * 2, y, boxWidth, 20)

    -- self.rEntry:initialise()
    -- self.rEntry:instantiate()
    -- self.rEntry:setOnlyNumbers(true)
    -- self.rEntry:setMaxTextLength(3)
    -- self.gEntry:initialise()
    -- self.gEntry:instantiate()
    -- self.gEntry:setOnlyNumbers(true)
    -- self.gEntry:setMaxTextLength(3)
    -- self.bEntry:initialise()
    -- self.bEntry:instantiate()
    -- self.bEntry:setOnlyNumbers(true)
    -- self.bEntry:setMaxTextLength(3)

    -- self:addChild(self.rEntry)
    -- self:addChild(self.gEntry)
    -- self:addChild(self.bEntry)
    for _, entry in ipairs({ self.rEntry, self.gEntry, self.bEntry }) do
        entry:initialise()
        entry:instantiate()
        entry:setOnlyNumbers(true)
        entry:setMaxTextLength(3)
        self:addChild(entry)
    end

    self.currentColorButton = ISButton:new(200, y, 20, 20, "", self, TailoringBuff_DyeUI.Window.onColorButton)
    self.currentColorButton:initialise()
    self:addChild(self.currentColorButton)
    if self.initialColor then
        local c = self.initialColor:toColor()
        self:updateColorButton(self.initialColor)
        self.rEntry:setText(tostring(math.floor(c:getRedFloat() * 255)))
        self.gEntry:setText(tostring(math.floor(c:getGreenFloat() * 255)))
        self.bEntry:setText(tostring(math.floor(c:getBlueFloat() * 255)))
    end
    self.currentColorButton.borderColor = { r = 1, g = 1, b = 1, a = 1 }

    buttonWidth = 80
    bottomY = self.height - 35
    rightX = self.width - buttonWidth - padding

    self.acceptButton = ISButton:new(padding, bottomY, buttonWidth, 25, getText("UI_TailoringBuff_UI_AcceptButton"), self, TailoringBuff_DyeUI.Window.onAccept)
    self.acceptButton:initialise()
    self:addChild(self.acceptButton)
    self.acceptButton.backgroundColor = { r = 0, g = 1, b = 0, a = 0.2 }
    self.acceptButton.backgroundColorMouseOver = { r = 0, g = 1, b = 0, a = 0.4 }
    self.acceptButton.borderColor = { r = 0, g = 1, b = 0, a = 1 }
    if not TailoringBuff_Utils.hasDyePack(self.player) then
        self.acceptButton.enable = false
        self.acceptButton:setTooltip(getText("Tooltip_TailoringBuff_DyeUI_AcceptButton_NoDye"))

        self.acceptButton.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
        self.acceptButton.backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
        self.acceptButton.borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }
    end

    self.closeButton = ISButton:new(padding * 2 + buttonWidth, bottomY, buttonWidth, 25, getText("UI_TailoringBuff_UI_CancelButton"), self, TailoringBuff_DyeUI.Window.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    self.closeButton.backgroundColor = { r = 1, g = 0, b = 0, a = 0.2 }
    self.closeButton.backgroundColorMouseOver = { r = 1, g = 0, b = 0, a = 0.4 }
    self.closeButton.borderColor = { r = 1, g = 0, b = 0, a = 1 }

    -- self.favoritesButton = ISButton:new(rightX, bottomY, buttonWidth, 25, getText("Favorites"), self, TailoringBuff_FavoritesUI.showUI)
    -- self.favoritesButton:initialise()
    -- self:addChild(self.favoritesButton)
    -- self.favoritesButton.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }
    -- self.favoritesButton.backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    -- self.favoritesButton.borderColor = { r = 1, g = 1, b = 1, a = 1 }

    local function hookEntry(entry)
        entry.onTextChange = function()
            self:updatePreviewFromRGB()
        end
    end

    hookEntry(self.rEntry)
    hookEntry(self.gEntry)
    hookEntry(self.bEntry)
end

function TailoringBuff_DyeUI.Window:updatePreviewFromRGB()
    if not self.initialColor then return end

    local r = TailoringBuff_Utils.clampRGB(self.rEntry:getText())
    local g = TailoringBuff_Utils.clampRGB(self.gEntry:getText())
    local b = TailoringBuff_Utils.clampRGB(self.bEntry:getText())

    local rf = r / 255
    local gf = g / 255
    local bf = b / 255

    local colorInfo = ColorInfo.new(rf, gf, bf, 1)

    self:setCurrentPreviewColor(colorInfo, false)
end

function TailoringBuff_DyeUI.Window:updateColorButton(colorInfo)
    if not colorInfo or not self.currentColorButton then return end
    self.currentColorButton.backgroundColor = {
        r = colorInfo:toColor():getRedFloat(),
        g = colorInfo:toColor():getGreenFloat(),
        b = colorInfo:toColor():getBlueFloat(),
        a = 1
    }
    self.currentColorButton.backgroundColorMouseOver = self.currentColorButton.backgroundColor
end

function TailoringBuff_DyeUI.Window:onAccept()
    if self.currentPreviewColor ~= self.initialColor then
        if self.item and self.player then
            local newColor = { r = self.currentPreviewColor:toColor():getRedFloat(), g = self.currentPreviewColor:toColor():getGreenFloat(), b = self.currentPreviewColor:toColor():getBlueFloat() }
            TailoringBuff_Utils.applyClothingTint(nil, newColor, true, self.player, self.item)
        end
    end

    self:setVisible(false)
    self:removeFromUIManager()
    TailoringBuff_DyeUI.instance = nil
end

function TailoringBuff_DyeUI.Window:close()
    self:onClose()
end

function TailoringBuff_DyeUI.Window:onClose()
    TailoringBuff_Utils.revertPreviewColor(self.player, self.item, self.initialColor)
    self:setVisible(false)
    self:removeFromUIManager()
    TailoringBuff_DyeUI.instance = nil
end

function TailoringBuff_DyeUI.Window:onColorButton()
    if not self.currentPreviewColor then return end
    TailoringBuff_Utils.openClothingColorPicker(self.player, self.item, self.currentPreviewColor, self)
end

function TailoringBuff_DyeUI.showUI(player, item)
    if TailoringBuff_DyeUI.instance and TailoringBuff_DyeUI.instance:isVisible() then
        return
    end

    local width = 300
    local height = 200
    local x = getCore():getScreenWidth() / 2 - width / 2
    local y = getCore():getScreenHeight() / 2 - height / 2

    local panel = TailoringBuff_DyeUI.Window:new(x, y, width, height)
    
    panel:setPlayer(player)
    panel:setItem(item)
    panel:setInitialColor(item)
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    panel:setResizable(false)
    panel:setTitle(getText("UI_TailoringBuff_DyeUI_Title"))

    TailoringBuff_DyeUI.instance = panel
end

return TailoringBuff_DyeUI