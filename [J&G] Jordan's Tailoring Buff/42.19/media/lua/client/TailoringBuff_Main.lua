-- TailoringBuff_Main
require "TailoringBuff_DyeUI"

-- unified ESC key handler
local function onGlobalKeyPressed(key)
    if key == Keyboard.KEY_ESCAPE then
        -- close DyeUI
        local ui = TailoringBuff_DyeUI.instance
        if ui and ui:isVisible() then
            ui:onClose()
        end
        
        -- close TextureUI
        local ui = TailoringBuff_TextureUI.instance
        if ui and ui:isVisible() then
            ui:onClose()
        end

        -- close FavoritesUI
        local ui = TailoringBuff_FavoritesUI.instance
        if ui and ui:isVisible() then
            ui:onClose()
        end
    end
end

Events.OnKeyPressed.Add(onGlobalKeyPressed)