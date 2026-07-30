-- TailoringBuff_TextureUI
TailoringBuff_TextureUI = {}

local TailoringBuff_Utils = require("TailoringBuff_Utils")

local ISCollapsableWindow = ISCollapsableWindow

TailoringBuff_TextureUI.Window = ISCollapsableWindow:derive("Window")

function TailoringBuff_TextureUI.Window:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function TailoringBuff_TextureUI.Window:setPlayer(player)
    self.player = player
end

function TailoringBuff_TextureUI.Window:setItem(item)
    self.item = item
end

function TailoringBuff_TextureUI.Window:setInitialTexture(item)
    self.initialTextureIndex = TailoringBuff_Utils.getTextureIndex(item)
    self.currentPreviewTextureIndex = self.initialTextureIndex
end

function TailoringBuff_TextureUI.Window:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.textureButtons = {}

    local padding = 10
    local y = 35

    local visual = self.item:getVisual()
    local clothingItem = visual:getClothingItem()
    local textures = clothingItem:getTextureChoices()

    local buttonSize = 40
    local buttonsPerRow = 5

    local textureCount = textures and textures:size()

    for i=0, textureCount - 1 do
        local col = i % buttonsPerRow
        local row = math.floor(i / buttonsPerRow)

        local button = ISButton:new(padding + col * (buttonSize + 5), y + row * (buttonSize + 5), buttonSize, buttonSize, tostring(i + 1), self, TailoringBuff_TextureUI.Window.onTextureButton)

        button.textureIndex = i
        button:initialise()
        self:addChild(button)

        self.textureButtons[i] = button
    end

    local bottomY = self.height - 35

    self.acceptButton = ISButton:new(padding, bottomY, 80, 25, getText("UI_TailoringBuff_UI_AcceptButton"), self, TailoringBuff_TextureUI.Window.onAccept)
    self.acceptButton:initialise()
    self:addChild(self.acceptButton)

    self.closeButton = ISButton:new(padding * 2 + 80, bottomY, 80, 25, getText("UI_TailoringBuff_UI_CancelButton"), self, TailoringBuff_TextureUI.Window.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
end

function TailoringBuff_TextureUI.Window:onTextureButton(button)
    if not button.textureIndex then return end

    self.currentPreviewTextureIndex = button.textureIndex
    TailoringBuff_Utils.applyPreviewTexture(self.player, self.item, self.currentPreviewTextureIndex)
end

function TailoringBuff_TextureUI.Window:onAccept()
    if self.currentPreviewTextureIndex ~= self.initialTextureIndex then
        if self.item and self.player then
            TailoringBuff_Utils.applyTextureIndex(self.item, self.player, self.currentPreviewTextureIndex)
        end
    end

    self:setVisible(false)
    self:removeFromUIManager()
    TailoringBuff_TextureUI.instance = nil
end

function TailoringBuff_TextureUI.Window:onClose()
    TailoringBuff_Utils.revertPreviewTexture(self.player, self.item, self.initialTextureIndex)
    self:setVisible(false)
    self:removeFromUIManager()
    TailoringBuff_TextureUI.instance = nil
end

function TailoringBuff_TextureUI.showUI(player, item)
    if TailoringBuff_TextureUI.instance then return end


    local visual = item:getVisual()
    local clothingItem = visual and visual:getClothingItem()
    local textures = clothingItem and clothingItem:getTextureChoices()
    local textureCount = textures and textures:size()

    local buttonsPerRow = 5
    local rows = math.ceil(textureCount / buttonsPerRow)

    local padding = 10
    local topOffset = 35
    local buttonSize = 40
    local buttonSpacing = 5
    local bottomControlsHeight = 35 + 25 + padding

    local buttonsHeight = rows * buttonSize + math.max(0, rows - 1) * buttonSpacing

    local contentHeight = topOffset + buttonsHeight + bottomControlsHeight

    
    local width = 300
    local height = math.max(200, contentHeight)
    local x = getCore():getScreenWidth() / 2 - width / 2
    local y = getCore():getScreenHeight() / 2 - height / 2

    local panel = TailoringBuff_TextureUI.Window:new(x, y, width, height)

    panel:setPlayer(player)
    panel:setItem(item)
    panel:setInitialTexture(item)
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    panel:setResizable(false)
    panel:setTitle(getText("UI_TailoringBuff_TextureUI_Title"))

    TailoringBuff_TextureUI.instance = panel
end

return TailoringBuff_TextureUI