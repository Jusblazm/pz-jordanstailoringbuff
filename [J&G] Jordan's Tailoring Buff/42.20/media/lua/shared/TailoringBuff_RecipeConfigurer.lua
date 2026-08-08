-- TailoringBuff_RecipeConfigurer
local function configureMixDyePackRecipe()
    local recipe = getScriptManager():getCraftRecipe("MixDyePack")
    local requiredLevel = TailoringBuff_Utils.getTailoringLevel()

    if requiredLevel == 0 then
        recipe:clearRequiredSkills()
    else
        recipe:clearRequiredSkills()
        recipe:addRequiredSkill(Perks.Tailoring, requiredLevel)
    end
end

Events.OnInitGlobalModData.Add(configureMixDyePackRecipe)