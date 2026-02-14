-- TailoringBuff_FavoritesUI
TailoringBuff_FavoritesUI = {}

local TailoringBuff_Utils = require("TailoringBuff_Utils")

local ISCollapsableWindow = ISCollapsableWindow

TailoringBuff_FavoritesUI.RGBModule = ISPanel:derive("RGBModule")

function TailoringBuff_FavoritesUI.RGBModule:new(x, y, width, colorData, parent)
    local o = ISPanel:new(x, y, width, 85)
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

    self.colorButton = ISButton:new(190, y, 20, 20, "", self, self.onColorButton)
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

    local buttonX = 10
    local buttonY = y + 30
    local buttonWidth = 60
    local buttonHeight = 20

    self.selectButton = ISButton:new(buttonX, buttonY, buttonWidth, buttonHeight, getText("UI_TailoringBuff_FavoritesUI_SelectButton"), self, self.onSelect)
    self.saveButton = ISButton:new(buttonX + buttonWidth + padding, buttonY, buttonWidth, buttonHeight, getText("UI_TailoringBuff_FavoritesUI_SaveButton"), self, self.onSave)
    self.deleteButton = ISButton:new(buttonX + (buttonWidth + padding) * 2, buttonY, buttonWidth, buttonHeight, getText("UI_TailoringBuff_FavoritesUI_DeleteButton"), self, self.onDelete)

    for _, button in ipairs({ self.selectButton, self.saveButton, self.deleteButton }) do
        button:initialise()
        self:addChild(button)
    end
    self:updatePreviewFromRGB()
end

function TailoringBuff_FavoritesUI.RGBModule:onSelect()
    if TailoringBuff_DyeUI.instance then
        TailoringBuff_DyeUI.instance:setColorFromFavorites(self.colorData)
    else
        print("[TailoringBuff] Error: DyeUI is not open")
    end
end

function TailoringBuff_FavoritesUI.RGBModule:onSave()
    if self.parentWindow and self.parentWindow.saveToFile then
        self.parentWindow:saveToFile()
    end
end

function TailoringBuff_FavoritesUI.RGBModule:onDelete()
    if self.parentWindow and self.parentWindow.deleteModule then
        self.parentWindow:deleteModule(self)
    end
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
    local moduleHeight = 85

    for _, color in ipairs(colors) do
        self:addModule(color)
    end
    self:updateDeleteButtons()
    self:updateWindowSize()
    self:createBottomButtons()
end

function TailoringBuff_FavoritesUI.Window:updateDeleteButtons()
    local canDelete = (#self.modules > 1)

    for _, module in ipairs(self.modules) do
        if module.deleteButton then
            module.deleteButton:setEnable(canDelete)
        end
    end
end

function TailoringBuff_FavoritesUI.Window:createBottomButtons()
    local buttonWidth = 80
    local buttonHeight = 25
    local padding = 10
    local x = self.width / 2 - buttonWidth - 5
    local x2 = self.width / 2 + 5
    local y = self.height - buttonHeight - padding

    self.newColorButton = ISButton:new(x, y, buttonWidth, buttonHeight, getText("UI_TailoringBuff_FavoritesUI_NewColorButton"), self, self.onNewColorClick)
    self.closeButton = ISButton:new(x2, y, buttonWidth, buttonHeight, getText("UI_TailoringBuff_FavoritesUI_CloseButton"), self, self.onClose)

    for _, button in ipairs({ self.newColorButton, self.closeButton }) do
        button:initialise()
        self:addChild(button)
    end
end

function TailoringBuff_FavoritesUI.Window:onNewColorClick()
    self:addModule({ r = 0, g = 0, b = 0 })
    self:saveToFile()
end

function TailoringBuff_FavoritesUI.Window:close()
    self:onClose()
end

function TailoringBuff_FavoritesUI.Window:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    TailoringBuff_FavoritesUI.instance = nil
end

function TailoringBuff_FavoritesUI.Window:saveToFile()
    local writer = getFileWriter(TailoringBuff_Utils.PATH, true, false)

    for _, module in ipairs(self.modules) do
        local c = module.colorData
        writer:write(string.format("%d,%d,%d\n", c.r, c.g, c.b))
    end

    writer:close()
end

function TailoringBuff_FavoritesUI.Window:addModule(colorData)
    local moduleWidth = 220
    local moduleHeight = 85
    local padding = 10
    local maxRows = 5
    
    local index = #self.modules
    local col = math.floor(index / maxRows)
    local row = index % maxRows

    local x = 10 + col * (moduleWidth + padding)
    local y = 35 + row * (moduleHeight + padding)

    local module = TailoringBuff_FavoritesUI.RGBModule:new(x, y, moduleWidth, colorData or { r = 0, g = 0, b = 0 }, self)
    module:initialise()
    self:addChild(module)
    table.insert(self.modules, module)

    self:updateWindowSize()
    self:updateDeleteButtons()
    
    return module
end

function TailoringBuff_FavoritesUI.Window:deleteModule(module)
    self:removeChild(module)

    for i, m in ipairs(self.modules) do
        if m == module then
            table.remove(self.modules, i)
            break
        end
    end

    self:reflowModules()
    self:saveToFile()
end

function TailoringBuff_FavoritesUI.Window:reflowModules()
    local moduleWidth = 220
    local moduleHeight = 85
    local padding = 10
    local maxRows = 5

    for i, module in ipairs(self.modules) do
        local index = i-1
        local col = math.floor(index / maxRows)
        local row = index % maxRows

        local x = 10 + col * (moduleWidth + padding)
        local y = 35 + row * (moduleHeight + padding)
        module:setX(x)
        module:setY(y)
    end

    self:updateWindowSize()
    self:updateDeleteButtons()
end

function TailoringBuff_FavoritesUI.Window:updateWindowSize()
    local headerHeight = self:titleBarHeight() or 32
    local paddingTop = 35
    local paddingBottom = 35
    local moduleHeight = 85
    local padding = 10
    local maxRows = 5

    local rows = math.min(#self.modules, maxRows)
    local totalHeight = headerHeight + paddingTop + (rows * moduleHeight) + ((rows - 1) * padding) + paddingBottom

    local cols = math.ceil(#self.modules / maxRows)
    local moduleWidth = 220
    local totalWidth = 10 + cols * (moduleWidth + padding)
    self:setWidth(totalWidth)

    local maxHeight = getCore():getScreenHeight() - 40
    totalHeight = math.min(totalHeight, maxHeight)
    self:setHeight(totalHeight)

    if self.newColorButton and self.closeButton then
        local buttonY = self.height - 25 - 10
        self.newColorButton:setY(buttonY)
        self.closeButton:setY(buttonY)
    end
end

function TailoringBuff_FavoritesUI.showUI()
    if TailoringBuff_FavoritesUI.instance and TailoringBuff_FavoritesUI.instance:isVisible() then
        return
    end

    local width = 240
    local height = 300
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