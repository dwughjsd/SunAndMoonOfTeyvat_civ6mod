-- Written by Konomi, edited by UzukiShimamura

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
GameEvents = ExposedMembers.GameEvents;

local GAME_SPEED = GameConfiguration.GetGameSpeedType()
local GAME_SPEED_MULTIPLIER = GameInfo.GameSpeeds[GAME_SPEED] and GameInfo.GameSpeeds[GAME_SPEED].CostMultiplier / 100 or 1
local COOLDOWN_TURN = math.floor(GlobalParameters.SUMERU_RANGER_COOLDOWN_TURN * GAME_SPEED_MULTIPLIER) or 50
local GAME_COST_ESCALATION = GameInfo.GlobalParameters["GAME_COST_ESCALATION"].Value or 1000
-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_BaseYields = {
	FEATURE_FOREST = {YIELD_PRODUCTION = 0},
	FEATURE_JUNGLE = {YIELD_PRODUCTION = 0},
}
local m_ForestInfo = GameInfo.Features['FEATURE_FOREST']
local m_JungleInfo = GameInfo.Features['FEATURE_JUNGLE']

 
-- ===========================================================================
function GetTechProgress(pPlayer)
	local pPlayerTechs = pPlayer:GetTechs()
	local i, total = 0, 0
	for row in GameInfo.Technologies() do
		if pPlayerTechs:HasTech(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end
-- ===========================================================================
function GetCivicProgress(pPlayer)
	local pPlayerCulture = pPlayer:GetCulture()
	local i, total = 0, 0
	for row in GameInfo.Civics() do
		if pPlayerCulture:HasCivic(row.Index) then
			i = i + 1
		end
		total = total + 1
	end
	return total ~= 0 and i / total or 0
end
-- ===========================================================================
function InitializeData()
	for row in GameInfo.Feature_Removes() do
		if m_BaseYields[row.FeatureType] then
			if row.YieldType == 'YIELD_FOOD' then
				m_BaseYields[row.FeatureType]['YIELD_PRODUCTION'] = m_BaseYields[row.FeatureType]['YIELD_PRODUCTION'] + row.Yield
			else
				m_BaseYields[row.FeatureType][row.YieldType] = row.Yield
			end
		end
	end
end
-- ===========================================================================
function Calculate(featureIndex)
	local playerID = Game.GetLocalPlayer()
	local pPlayer = Players[playerID]
	if pPlayer == nil then
		return
	end

	local featureType = GameInfo.Features[featureIndex].FeatureType
	if m_BaseYields[featureType] == nil then
		return
	end

	local techProgress = GetTechProgress(pPlayer)
	local civicProgress = GetCivicProgress(pPlayer)
	local costEscalation = (GAME_COST_ESCALATION / 100) -1
	local modifier = (1 + costEscalation * math.floor( math.max(techProgress, civicProgress) * 100 ) / 100) * GAME_SPEED_MULTIPLIER
	
	local yields = {}
	for yieldType, yield in pairs(m_BaseYields[featureType]) do
		yields[yieldType] = math.floor(yield * modifier)
	end
	
	if featureType == 'FEATURE_FOREST' then
		yields['YIELD_CULTURE'] = math.floor(m_BaseYields[featureType]['YIELD_PRODUCTION'] * modifier / 2)
	elseif featureType == 'FEATURE_JUNGLE' then
		yields['YIELD_SCIENCE'] = math.floor(m_BaseYields[featureType]['YIELD_PRODUCTION'] * modifier / 2)
	end
	
	local tooltips, tooltip = {}, ''
	for yieldType, yield in pairs(yields) do
		table.insert(tooltips, Locale.Lookup('LOC_SUMERU_RANGER_YIELD_TOOLTIP', yield, GameInfo.Yields[yieldType].IconString, Locale.Lookup('LOC_' .. yieldType .. '_NAME')))
	end
	if #tooltips >= 1 then
		tooltip = tooltips[1]
		for i = 2, #tooltips, 1 do
			tooltip = tooltip .. '[NEWLINE]' .. tooltips[i]
		end
	end
	
	return yields, tooltip
end
-- ===========================================================================
function IsButtonHide(pUnit)
    local unitInfo = GameInfo.Units[pUnit:GetType()]
	if unitInfo == nil or unitInfo.UnitType ~= 'UNIT_SUMERU_FOREST_RANGER' then
		return true
	end

	if pUnit:GetMovementMovesRemaining() == 0 then
		return true
	end
	
	if pUnit:GetBuildCharges() == 0 then
		return true
	end
	return false
end
-- ===========================================================================
function IsButtonDisabled(pUnit)
	if m_ForestInfo == nil or m_JungleInfo == nil then
		return true, ''
	end
	
	local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY())
	if pPlot == nil then
		return true, ''
	end

	local playerID = pUnit:GetOwner()
	local pPlayer = Players[playerID]
	
	local featureType = pPlot:GetFeatureType()
	if featureType == m_ForestInfo.Index or featureType == m_JungleInfo.Index then
		if pPlot:GetOwner() ~= playerID then
			return true, Locale.Lookup('LOC_SUMERU_RANGER_DISABLED_FEATURE_TOOLTIP')
		end

		local res = {}
		GameEvents.SumeruGetPlotProperty.Call(pPlot:GetIndex(), res)
		if res.Property and Game.GetCurrentGameTurn() - res.Property < COOLDOWN_TURN then
			return true, Locale.Lookup('LOC_SUMERU_RANGER_DISABLED_UNCOOLED_TOOLTIP', COOLDOWN_TURN - Game.GetCurrentGameTurn() + res.Property)
		end

		if featureType == m_ForestInfo.Index and m_ForestInfo.RemoveTech and not pPlayer:GetTechs():HasTech(m_ForestInfo.RemoveTechReference.Index) then
			return true, Locale.Lookup('LOC_SUMERU_RANGER_DISABLED_TECH_UNLOCK_TOOLTIP', Locale.Lookup(m_ForestInfo.Name), Locale.Lookup(m_ForestInfo.RemoveTechReference.Name))
		elseif featureType == m_JungleInfo.Index and m_JungleInfo.RemoveTech and not pPlayer:GetTechs():HasTech(m_JungleInfo.RemoveTechReference.Index) then
			return true, Locale.Lookup('LOC_SUMERU_RANGER_DISABLED_TECH_UNLOCK_TOOLTIP', Locale.Lookup(m_JungleInfo.Name), Locale.Lookup(m_JungleInfo.RemoveTechReference.Name))
		end

		return false, '', featureType
	end
	return true, Locale.Lookup('LOC_SUMERU_RANGER_DISABLED_FEATURE_TOOLTIP')
	
end
-- ===========================================================================
function Refresh()
	local pUnit = UI.GetHeadSelectedUnit()
	if pUnit == nil then
		return
	end

	if IsButtonHide(pUnit) then
		Controls.SumeruRangerGrid:SetHide(true)
	else
		Controls.SumeruRangerGrid:SetHide(false)
		
		local disabled, reason, featureIndex = IsButtonDisabled(pUnit)
		Controls.SumeruRangerButton:SetDisabled(disabled)

		local tooltip = Locale.Lookup('LOC_SUMERU_RANGER_OPERATION_TOOLTIP', COOLDOWN_TURN)
		
		if not disabled then
			local _, yieldTooltip = Calculate(featureIndex)
			Controls.SumeruRangerButton:SetToolTipString(tooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_SUMERU_RANGER_OPERATION_YIELD_TOOLTIP', yieldTooltip))
		else
			Controls.SumeruRangerButton:SetToolTipString(tooltip .. '[COLOR:Red]' .. reason .. '[ENDCOLOR]')
		end
	end  
end
-- ===========================================================================
function OnUnitMoveComplete(playerID, unitID, iX, iY)
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
	Refresh()
end
-- ===========================================================================
function OnUnitSelectionChanged(playerID, unitID, plotX, plotY, plotZ, bSelected, bEditable)
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
    if bSelected then
        Refresh()
    end
end
-- ===========================================================================
function OnButtonClicked_PatrolForest()
	local pUnit = UI.GetHeadSelectedUnit()
	local iX = pUnit:GetX()
	local iY = pUnit:GetY()
	local unitID = pUnit:GetID()
	local iPlayer = Game.GetLocalPlayer()
	local pPlot = Map.GetPlot(iX, iY)
	local featureType = pPlot:GetFeatureType()

	SimUnitSystem.SetAnimationState(pUnit, "ACTION_1", "IDLE")

	UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = 'SumeruRangerOperation',
		X = iX,
		Y = iY,
		UnitID = unitID,
		Yields = Calculate(featureType)
	})

	Controls.SumeruRangerGrid:SetHide(true)
end
-- ===========================================================================
function Initialize()
	local pContext = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
	if pContext ~= nil then
		Controls.SumeruRangerGrid:ChangeParent(pContext)
		Controls.SumeruRangerButton:RegisterCallback(Mouse.eLClick, OnButtonClicked_PatrolForest)
	end
	
	InitializeData()
end

Events.LoadGameViewStateDone.Add(Initialize)
Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
Events.UnitMoveComplete.Add(OnUnitMoveComplete)

-- ===========================================================================
-- Power Status Support by UzukiShimamura based on Nea Bajara's code
include("SupportFunctions")

function RefreshCityPowerProperty(playerID, cityID)
	if not Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68") then return end;-- Gathering Storm not enabled
	local player = Players[playerID]
    local pCity = CityManager.GetCity(playerID, cityID)
    if pCity == nil then 
    	return 
    end
    local cityX = pCity:GetX()
    local cityY = pCity:GetY()
    local CityPlot = Map.GetPlot(cityX, cityY)
    local plotID = CityPlot:GetIndex()
	local pPowerStatus = 0;
    if pCity:GetPower() ~= nil then 
		local pCityPower = pCity:GetPower();
		local freePower:number = pCityPower:GetFreePower();
		local temporaryPower:number = pCityPower:GetTemporaryPower();
		local requiredPower:number = pCityPower:GetRequiredPower();
		local PROP_FULL_POWER_STATUS = 'MONDSTADT_CITY_POWER_STATUS'
		if (freePower > 0 or temporaryPower > 0 or requiredPower > 0) and pCityPower:IsFullyPowered() then
			pPowerStatus = 1;
		end
		GameEvents.MondstadtSetCityPlotProperty.Call(playerID, cityID, PROP_FULL_POWER_STATUS, pPowerStatus)
    end
end

function HasTrait( traitName:string, playerId:number )
	if playerId == nil then playerId = Game.GetLocalPlayer(); end
	if playerId == -1 then return false; end	-- Autoplay.
	
	local config :table = PlayerConfigurations[playerId];
	if(config ~= nil) then
		local leaderType:string = config:GetLeaderTypeName();
		local civType	:string = config:GetCivilizationTypeName();
		if leaderType then
			for row in GameInfo.LeaderTraits() do
				if row.LeaderType==leaderType and row.TraitType == traitName then
					return true;
				end
			end
		end
		if civType then
			for row in GameInfo.CivilizationTraits() do
				if row.CivilizationType== civType then
					if row.TraitType == traitName then
						return true;
					end
				end
			end
		end
	end
	return false;
end

function OnTurnBegin_IllusoryHeart()
	if not Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68") then -- Gathering Storm not enabled
		Events.TurnBegin.Remove(OnTurnBegin_IllusoryHeart);
		return;
	end
	local players = Game.GetPlayers{Alive = true};
	for _, player in ipairs(players) do
		playerID = player:GetID();
		if HasTrait("TRAIT_LEADER_ILLUSORY_HEART",playerID) then
			for _, city in player:GetCities():Members() do
				RefreshCityPowerProperty(player:GetID(), city:GetID())
			end
		end
	end
end

Events.TurnBegin.Add(OnTurnBegin_IllusoryHeart);
Events.CityAddedToMap.Add(RefreshCityPowerProperty);
