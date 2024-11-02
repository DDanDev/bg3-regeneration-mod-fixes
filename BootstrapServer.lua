-- -------------------------------------------------------------------------- --
--                               REGENERATION                                 --
-- -------------------------------------------------------------------------- --
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

local function giveResource(character, resourceName, resourceData, entity)
    -- Apply SORCERYPOINT_1 status when sorcery points regenerate from 0
    if resourceName == "SorceryPoint" and resourceData.Amount == 0 then
        Osi.ApplyStatus(GetCharacterId(character), "SORCERYPOINT_1", 100, -1)
    else
        resourceData.Amount = math.min(resourceData.Amount + 1, resourceData.MaxAmount)
    end
    entity:Replicate("ActionResources")
    if Vars["DebugMode"] == true then
        _P("+++Regenerated " .. character .. " : " .. resourceName)
    end
end

local function count(character, resourceName, resourceData, entity)
    local resourceCooldown = tonumber(Vars[resourceName])
    if resourceCooldown == nil or resourceCooldown == 0 then
        return
    end

    TurnCounter[character][resourceName] = TurnCounter[character][resourceName] or -1
    if TurnCounter[character][resourceName] == -1 then
        _P("Initialized " .. character .. " : " .. resourceName)
    end
    TurnCounter[character][resourceName] = TurnCounter[character][resourceName] + 1

    if resourceData == nil then
        return
    end
    if resourceData.Amount >= resourceData.MaxAmount then
        TurnCounter[character][resourceName] = 0
        return
    end
    if TurnCounter[character][resourceName] >= resourceCooldown then
        giveResource(character, resourceName, resourceData, entity)
        TurnCounter[character][resourceName] = 0
    end
end

local function tableToString(tableIn)
    local out = ""
    for k, v in pairs(tableIn) do
        out = out .. tostring(k) .. ": " .. tostring(v) .. " || "
    end
    return out
end

local function resetShortRestCooldowns(_character, _characterId)
    local characterId = _characterId or GetHostCharacter()
    local character = _character or "Currently controled character " .. characterId
    Osi.ApplyStatus(characterId, "REGENSHORT", 100, 0)
    if Vars["DebugMode"] == true then
        _P("+++Regenerated " .. character .. " : SHORT rest cooldowns")
    end
end
Ext.RegisterConsoleCommand("resetShortRestCooldowns", resetShortRestCooldowns)
local function resetLongRestCooldowns(_character, _characterId)
    local characterId = _characterId or GetHostCharacter()
    local character = _character or "Currently controled character " .. characterId
    Osi.ApplyStatus(characterId, "REGENLONG", 100, 0)
    if Vars["DebugMode"] == true then
        _P("+++Regenerated " .. character .. " : LONG rest cooldowns")
    end
end
Ext.RegisterConsoleCommand("resetLongRestCooldowns", resetLongRestCooldowns)
local function ApplyRestStatuses(character, characterId)
    if Vars["ShortRest"] ~= 0 and TurnCounter[character]["ShortRest"] >= tonumber(Vars["ShortRest"]) then
        resetShortRestCooldowns(character, characterId)
        TurnCounter[character]["ShortRest"] = 0
    end
    if Vars["LongRest"] ~= 0 and TurnCounter[character]["LongRest"] >= tonumber(Vars["LongRest"]) then
        resetLongRestCooldowns(character, characterId)
        TurnCounter[character]["LongRest"] = 0
    end
end

local function inspectAllResources(character)
    local characterId = GetCharacterId(character)
    local entity = Ext.Entity.Get(character)
    local resources = entity.ActionResources.Resources
    for UUID, resource in pairs(resources) do
        local resourceName = Ext.StaticData.Get(UUID, "ActionResource").Name

        if resourceName ~= "ActionPoint" and resourceName ~= "BonusActionPoint" and resourceName ~= "ReactionActionPoint" and resourceName ~= "Movement" and resourceName ~= "SneakAttack_Charge" then
            local out = ""
            if not Vars[resourceName] and resourceName ~= "SpellSlot" and resourceName ~= "WarlockSpellSlot" then
                out = "MISSING in mod >>>>>>>> "
            end

            out = out .. resourceName .. " => "
            for lvl, resourceData in pairs(resource) do
                out = out .. "lvl" .. lvl .. ": " .. resourceData.Amount .. "/" .. resourceData.MaxAmount .. ", "
            end

            _P(out)
        end
    end
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
local function inspectAllCharsResources()
    _P("Common Resources: ActionPoint BonusActionPoint ReactionActionPoint Movement")
    for _, character in ipairs(listPartyCharacters()) do
        _P(character)
        inspectAllResources(character)
        _P("\n")
    end
end
Ext.RegisterConsoleCommand("inspectAllCharsResources", inspectAllCharsResources) -- call with !inspectAllCharsResources

local function giveResourceXToChar(_, resourceTarget, _character)
    local character = _character or GetHostCharacter()
    local characterId = character:match(".*_(.*)") or character
    -- local characterId = GetCharacterId(character)
    local entity = Ext.Entity.Get(characterId)
    local resources = entity.ActionResources.Resources
    -- local resources = GetResources(entity)
    if not resources then
        _P("Did not find character's resources")
        return
    end

    local resourceTgtBaseName = resourceTarget:match("(WarlockSpellSlot)") or resourceTarget:match("(SpellSlot)") or resourceTarget
    local lvl = resourceTarget:match("SpellSlotsLvl(.*)") or 1

    for UUID, resource in pairs(resources) do
        local resourceName = Ext.StaticData.Get(UUID, "ActionResource").Name
        if resourceName == resourceTgtBaseName then
            giveResource(character, resourceName, resource[lvl], entity)
        end
    end
end
Ext.RegisterConsoleCommand("giveResourceXToChar", giveResourceXToChar)

local function CountATurn(character)
    local cleanCharacterId = GetCharacterId(character)
    if IsCharacter(cleanCharacterId) ~= 1 or IsPartyMember(cleanCharacterId, 1) ~= 1 or Osi.IsDead(cleanCharacterId) ~= 0 or Osi.HasActiveStatus(cleanCharacterId, "DOWNED") ~= 0 then
        return
    end

    TurnCounter[character] = TurnCounter[character] or {}
    local entity = Ext.Entity.Get(cleanCharacterId)
    local resources = GetResources(entity)
    if not resources then
        return
    end

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
    local defaultResources = {"ShortRest", "LongRest"}

    for _, resource in ipairs(defaultResources) do
        count(character, resource, nil, nil)
    end
    ApplyRestStatuses(character, cleanCharacterId)
    if Vars["DebugMode"] == true then
        _P("Count for " .. character .. " => " .. tableToString(TurnCounter[character]))
    end
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
    local inForceTurn = IsInForceTurnBasedMode(GetHostCharacter()) == 1
    if Vars["DebugMode"] == true then
        _P("-----tick ::: " .. tostring(incombat) .. tostring(inForceTurn) .. tostring(InDialogue) .. tostring(Vars["RegenerationButton"]) .. tostring(Vars["OutofCombatRegen"]) .. "------")
    end
    if incombat == false and inForceTurn == false and InDialogue ~= true and Vars["RegenerationButton"] == true and Vars["OutofCombatRegen"] == true then
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

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    local incombat = gameIsInCombat()
    if Vars["DebugMode"] == true then
        _P("TurnStarted " .. character .. " ::: " .. tostring(incombat) .. tostring(Vars["RegenerationButton"]) .. tostring(Vars["CombatRegen"]))
    end
    if incombat == true and Vars["RegenerationButton"] == true and Vars["CombatRegen"] == true then
        CountATurn(character)
    end
end)
Ext.Osiris.RegisterListener("DialogStarted", 2, "after", function(dialogueName, integerId)
    if Vars["DebugMode"] then _P("DialogStarted " .. dialogueName .. " : " .. integerId) end
    InDialogue = true
end)
Ext.Osiris.RegisterListener("DialogEnded", 2, "after", function(dialogueName, integerId)
    if Vars["DebugMode"] then _P("DialogEnded " .. dialogueName .. " : " .. integerId) end
    InDialogue = false
end)

Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end
    _P("Regeneration MCM settings saved " .. payload.settingId .. " : " .. tostring(payload.value))
    if Vars[payload.settingId] ~= nil then
        Vars[payload.settingId] = payload.value
    end
end)

-- Function to get MCM setting values
function MCMGet(settingID)
    return Mods.BG3MCM.MCMAPI:GetSettingValue(settingID, ModuleUUID)
end

local function OnSessionLoaded()
    _P("Regeneration - MCM Version")
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
        Interrupt_LuckOfTheFarRealms_Charge = MCMGet("Interrupt_LuckOfTheFarRealms_Charge"),
        Interrupt_EntropicWard_Charge = MCMGet("Interrupt_EntropicWard_Charge"),
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
        SpellPointsResource = MCMGet("SpellPointsResource"),
        DebugMode = MCMGet("DebugMode")
    }

    -- Initialize TurnCounter and other settings if needed
    TurnCounter = {}
    StartTimer()
end
Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
