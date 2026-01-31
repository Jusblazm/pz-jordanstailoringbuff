-- TailoringBuff_FavoritesUI
TailoringBuff_FavoritesUI = {}

local TailoringBuff_Utils = require("TailoringBuff_Utils")

local ISCollapsableWindow = ISCollapsableWindow

TailoringBuff_FavoritesUI.RGBModule = ISPanel:derive("RGBModule")

function TailoringBuff_FavoritesUI.RGBModule:new(x, y, width, colorData, parent)
    local o = ISPanel:new(x, y, width, 70)
    setmetatable(o, self)
    self.__index = self

    o.colorData = colorData or { r = 0, g = 0, b = 0 }
    o.parentWindow = parent

    return o
end

function TailoringBuff_FavoritesUI.RGBModule:createChildren()
    ISPanel.createChildren(self)

    local padding = 10
    local y = 5
    local boxWidth = 40

    self.rgbLabel = ISLabel:new(padding, y, 20, getText("UI_TailingBuff_UI_RGB"), 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.rgbLabel)

    y = y + 20

    self.rEntry = ISTextEntryBox:new(tostring(self.colorData.r), padding, y, boxWidth, 20)
    self.gEntry = ISTextEntryBox:new(tostring(self.colorData.g), padding * 2 + boxWidth, y, boxWidth, 20)
    self.bEntry = ISTextEntryBox:new(tostring(self.colorData.b), padding + (boxWidth + padding) * 2, y, boxWidth, 20)

    for _, entry in ipairs({ self.rEntry, self.gEntry, self.bEntry }) do
        entry:initialise()
        entry:instantiate()
        entry:setOnlyNumbers(true)
        entry:setMaxTextLength(3)
        self:addChild(entry)
    end

    self.colorButton = ISButton:new(200, y, 20, 20, "", self, self.onColorButton)
    self.colorButton:initialise()
    self.colorButton.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    self:addChild(self.colorButton)

    local function hookEntry(entry)
        entry.onTextChange = function()
            self:updatePreviewFromRGB()
        end
    end

    hookEntry(self.rEntry)
    hookEntry(self.gEntry)
    hookEntry(self.bEntry)
end

function TailoringBuff_FavoritesUI.RGBModule:updatePreviewFromRGB()

    local r = TailoringBuff_Utils.clampRGB(self.rEntry:getText())
    local g = TailoringBuff_Utils.clampRGB(self.gEntry:getText())
    local b = TailoringBuff_Utils.clampRGB(self.bEntry:getText())

    self.colorButton.backgroundColor = {
        r = r / 255,
        g = g / 255,
        b = b / 255,
        a = 1
    }
    self.colorButton.backgroundColorMouseOver = self.colorButton.backgroundColor

    self.colorData = { r = r, g = g, b = b }
end

function TailoringBuff_FavoritesUI.RGBModule:onColorButton()
    local c = self.colorData
    local colorInfo = ColorInfo.new(c.r / 255, c.g / 255, c.b / 255, 1)

    TailoringBuff_Utils.openFavoritesColorPicker(colorInfo, self, TailoringBuff_FavoritesUI.RGBModule.onColorPicked)
end

function TailoringBuff_FavoritesUI.RGBModule:onColorPicked(pickedRGB)
    local r = math.floor(pickedRGB.r * 255)
    local g = math.floor(pickedRGB.g * 255)
    local b = math.floor(pickedRGB.b * 255)

    self.colorData = { r = r, g = g, b = b }

    self.rEntry:setText(tostring(r))
    self.gEntry:setText(tostring(g))
    self.bEntry:setText(tostring(b))

    self:updatePreviewFromRGB()
end

TailoringBuff_FavoritesUI.Window = ISCollapsableWindow:derive("Window")

function TailoringBuff_FavoritesUI.Window:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o._updatingFromRGB = false
    return o
end

function TailoringBuff_FavoritesUI.Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.modules = {}
    local colors = TailoringBuff_Utils.loadFavoriteColors()

    local y = 35
    local moduleHeight = 70

    for _, color in ipairs(colors) do
        local module = TailoringBuff_FavoritesUI.RGBModule:new(10, y, self.width - 20, color, self)
        module:initialise()
        self:addChild(module)

        table.insert(self.modules, module)
        y = y + moduleHeight + 5
    end
end

function TailoringBuff_FavoritesUI.Window:saveToFile()
    local writer = getFileWriter(TailoringBuff_Utils.PATH, true, false)

    for _, module in ipairs(self.modules) do
        local c = module.colorData
        writer:write(string.format("%d,%d,%d\n", c.r, c.g, c.b))
    end

    writer:close()
end

function TailoringBuff_FavoritesUI.showUI()
    if TailoringBuff_FavoritesUI.instance and TailoringBuff_FavoritesUI.instance:isVisible() then
        return
    end

    local width = 300
    local height = 200
    local x = getCore():getScreenWidth() / 2 - width / 2
    local y = getCore():getScreenHeight() / 2 - height / 2

    local panel = TailoringBuff_FavoritesUI.Window:new(x, y, width, height)

    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    panel:setResizable(false)
    panel:setTitle(getText("UI_TailoringBuff_FavoritesUI_Title"))

    TailoringBuff_FavoritesUI.instance = panel
end

return TailoringBuff_FavoritesUI