-- -------------------------------------------------------------------------- --
--                               REGENERATION                                 --
-- -------------------------------------------------------------------------- --

-- Function to get MCM setting values
function MCMGet(settingID)
    return Mods.BG3MCM.MCMAPI:GetSettingValue(settingID, ModuleUUID)
end

local function OnSessionLoaded()
    print("Regeneration - MCM Version")
    Vars = {
        CombatRegen = MCMGet("CombatRegen"),
        OutofCombatRegen = MCMGet("OutofCombatRegen"),
        RegenerationButton = MCMGet("RegenerationButton"),
        SuperiorityDie = MCMGet("SuperiorityDie"),
        ChannelDivinity = MCMGet("ChannelDivinity"),
        Rage = MCMGet("Rage"),
        BardicInspiration = MCMGet("BardicInspiration"),
        KiPoint = MCMGet("KiPoint"),
        WildShape = MCMGet("WildShape"),
        ChannelOath = MCMGet("ChannelOath"),
        LayOnHandsCharge = MCMGet("LayOnHandsCharge"),
        FungalInfestationCharge = MCMGet("FungalInfestationCharge"),
        LuckPoint = MCMGet("LuckPoint"),
        ArcaneRecoveryPoint = MCMGet("ArcaneRecoveryPoint"),
        NaturalRecoveryPoint = MCMGet("NaturalRecoveryPoint"),
        SorceryPoint = MCMGet("SorceryPoint"),
        TidesOfChaos = MCMGet("TidesOfChaos"),
        WarPriestActionPoint = MCMGet("WarPriestActionPoint"),
        LongRest = MCMGet("LongRest"),
        ShortRest = MCMGet("ShortRest"),
        SpellSlotsLvl1 = MCMGet("SpellSlotsLvl1"),
        SpellSlotsLvl2 = MCMGet("SpellSlotsLvl2"),
        SpellSlotsLvl3 = MCMGet("SpellSlotsLvl3"),
        SpellSlotsLvl4 = MCMGet("SpellSlotsLvl4"),
        SpellSlotsLvl5 = MCMGet("SpellSlotsLvl5"),
        SpellSlotsLvl6 = MCMGet("SpellSlotsLvl6"),
        WarlockSpellSlotsLvl1 = MCMGet("WarlockSpellSlotsLvl1"),
        WarlockSpellSlotsLvl2 = MCMGet("WarlockSpellSlotsLvl2"),
        WarlockSpellSlotsLvl3 = MCMGet("WarlockSpellSlotsLvl3"),
        WarlockSpellSlotsLvl4 = MCMGet("WarlockSpellSlotsLvl4"),
        WarlockSpellSlotsLvl5 = MCMGet("WarlockSpellSlotsLvl5"),
        WarlockSpellSlotsLvl6 = MCMGet("WarlockSpellSlotsLvl6"),
        ArcaneShot = MCMGet("ArcaneShot"),
        PsiPoints = MCMGet("PsiPoints"),
        PsiLimit = MCMGet("PsiLimit"),
        PsionicStrike = MCMGet("PsionicStrike"),
        PsionicSurge = MCMGet("PsionicSurge"),
        SurgeOfHealth = MCMGet("SurgeOfHealth"),
        MemoryOfOneThousandSteps = MCMGet("MemoryOfOneThousandSteps"),
        PsionicMastery = MCMGet("PsionicMastery"),
        PsionicMasteryCooldown = MCMGet("PsionicMasteryCooldown"),
        MarkPoints = MCMGet("MarkPoints"),
        ProfaneSlots = MCMGet("ProfaneSlots"),
        BloodMaledict = MCMGet("BloodMaledict"),
        HybridTransformation = MCMGet("HybridTransformation"),
        BrandOfCastigation = MCMGet("BrandOfCastigation"),
        BladeDashResource = MCMGet("BladeDashResource"),
        ElementalBladeResource = MCMGet("ElementalBladeResource"),
        BondedMainHandResource = MCMGet("BondedMainHandResource"),
        BondedOffHandResource = MCMGet("BondedOffHandResource"),
        BondedSwapResource = MCMGet("BondedSwapResource"),
        EtherealEvasionResource = MCMGet("EtherealEvasionResource"),
        DarknessWithinPoint = MCMGet("DarknessWithinPoint"),
        DisruptiveTouchPoint = MCMGet("DisruptiveTouchPoint"),
        SB_ShamanSpellSlot = MCMGet("SB_ShamanSpellSlot"),
        SB_Shaman_EvilEyeCharge = MCMGet("SB_Shaman_EvilEyeCharge"),
        SB_Shaman_LifeCharge = MCMGet("SB_Shaman_LifeCharge"),
        SpellPointsResource = MCMGet("SpellPointsResource")
    }

    -- Initialize TurnCounter and other settings if needed
    TurnCounter = {}
end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)



local function GetResources(entity)
    if entity then
        local resources = entity.ActionResources.Resources 
        if resources then
            return resources
        end
    else
        return
    end
end

local function GetCharacterId(rawId)
    return rawId:match(".*_(.*)") or rawId
end

local function count(character, resource, resourceData, entity)
    local resourceCooldown = tonumber(Vars[resource])
    if resourceCooldown == nil or resourceCooldown == 0 then return end

    TurnCounter[character][resource] = TurnCounter[character][resource] or -1
    if TurnCounter[character][resource] == -1 then print("Initialized " .. character .. " : " .. resource) end
    TurnCounter[character][resource] = TurnCounter[character][resource] + 1

    if resourceData == nil then return end
    if resourceData.Amount >= resourceData.MaxAmount then
        TurnCounter[character][resource] = 0
        return
    end
    if TurnCounter[character][resource] >= resourceCooldown then
        -- Apply SORCERYPOINT_1 status when sorcery points regenerate from 0
        if resource == "SorceryPoint" and resourceData.Amount == 0 then
            Osi.ApplyStatus(character, "SORCERYPOINT_1", 100, -1)
        else
            resourceData.Amount = math.min(resourceData.Amount + 1, resourceData.MaxAmount)
        end
        TurnCounter[character][resource] = 0
        entity:Replicate("ActionResources")
        print("+++Regenerated " .. character .. " : " .. resource)
    end
end

local function tableToString(tableIn)
    local out = ""
    for k, v in pairs(tableIn) do
      out = out .. k .. ": " .. v .. " || "
    end
    return out
end

local function ApplyRestStatuses(character, characterId)
    if Vars["ShortRest"] ~= 0 and TurnCounter[character]["ShortRest"] >= tonumber(Vars["ShortRest"]) then
        Osi.ApplyStatus(characterId, "REGENSHORT", 100, 0)
        TurnCounter[character]["ShortRest"] = 0
        print("+++Regenerated " .. character .. " : SHORT rest cooldowns")
    end
    if Vars["LongRest"] ~= 0 and TurnCounter[character]["LongRest"] >= tonumber(Vars["LongRest"]) then
        Osi.ApplyStatus(characterId, "REGENLONG", 100, 0)  -- Apply REGENLONG status
        TurnCounter[character]["LongRest"] = 0
        print("+++Regenerated " .. character .. " : LONG rest cooldowns")
    end
end

local function CountATurn(character)
    local cleanCharacterId = GetCharacterId(character)
    if IsCharacter(cleanCharacterId) ~= 1 or IsPartyMember(cleanCharacterId, 1) ~= 1 or Osi.IsDead(cleanCharacterId) ~= 0 or Osi.HasActiveStatus(cleanCharacterId,"DOWNED") ~= 0 then return end
    
    TurnCounter[character] = TurnCounter[character] or {}
    local entity = Ext.Entity.Get(cleanCharacterId)
    local resources = GetResources(entity)
    if not resources then return end
    
    for UUID, resource in pairs(resources) do
        local resourceName = Ext.StaticData.Get(UUID, "ActionResource").Name
        
        for lvl, resourceData in pairs(resource) do
            if resourceData and resourceData.Amount then
                local resourceNameComplete = resourceName
                if resourceName == "SpellSlot" or resourceName == "WarlockSpellSlot" then
                    resourceNameComplete = resourceName .. "sLvl" .. lvl
                end
                count(character, resourceNameComplete, resourceData, entity)
            end
        end 
    end
    local defaultResources = {
        "ShortRest", "LongRest"
    }
    
    for _, resource in ipairs(defaultResources) do
        count(character, resource, nil, nil)
    end
    ApplyRestStatuses(character, cleanCharacterId)
    print("Count for " .. character .. " => " .. tableToString(TurnCounter[character]))
end

local function listPartyCharacters()
    local playerGuids = Osi.DB_Players:Get(nil)
    local partyCharacters = {}
    
    for _, guidTable in ipairs(playerGuids) do
        for _, character in ipairs(guidTable) do
            table.insert(partyCharacters, character)
        end
    end

    return partyCharacters
end

local function gameIsInCombat()
    local anyInCombat = false
    local partyCharacters = listPartyCharacters()
    
    for _, character in ipairs(partyCharacters) do
        local inCombat = IsInCombat(GetCharacterId(character))
        if inCombat == 1 then
            anyInCombat = true
            break
        end
    end

    return anyInCombat
end

local function OnTimerTick()
    local incombat = gameIsInCombat()
    print("-----tick ::: " .. tostring(incombat) .. tostring(Vars["RegenerationButton"]) .. tostring(Vars["OutofCombatRegen"]) .. "------")
    if incombat == false and Vars["RegenerationButton"] == true and Vars["OutofCombatRegen"] == true then
        local partyCharacters = listPartyCharacters()
        for _, character in ipairs(partyCharacters) do
                CountATurn(character)
        end
    end
end


local function StartTimer()
    if not timerId then -- This ensures that the timer will only get created once
        timerId = Ext.Timer.WaitFor(6000, OnTimerTick, 6000)
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, isEditorMode)
    StartTimer()
    print("LevelGameplayStarted started timer")
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    local incombat = gameIsInCombat()
    print("TurnStarted " .. character .. " ::: " .. tostring(incombat) .. tostring(Vars["RegenerationButton"]) .. tostring(Vars["CombatRegen"]))
    if incombat == true and Vars["RegenerationButton"] == true and Vars["CombatRegen"] == true then
        CountATurn(character)
    end
end)

Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end
    print("Mcm settings saved" .. payload.settingId .. " : " .. tostring(payload.value))
    if Vars[payload.settingId] ~= nil then
        Vars[payload.settingId] = payload.value
    end
end)