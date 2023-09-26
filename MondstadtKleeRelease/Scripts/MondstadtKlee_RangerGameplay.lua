-- Written by Konomi

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
ExposedMembers.GameEvents = GameEvents

GameEvents.MondstadtSetCityPlotProperty.Add(function(playerID, cityID, key, value)
    local pCity = CityManager.GetCity(playerID, cityID)
		for _, pPlot in pairs(pCity:GetOwnedPlots()) do
		pPlot:SetProperty(key, value)
		end	
end)

local KEY_SUMERU_RANGER = 'KEY_SUMERU_RANGER'
local YIELD_COLORS = {
	YIELD_SCIENCE = '[COLOR_FLOAT_SCIENCE]',
	YIELD_CULTURE = '[COLOR_FLOAT_CULTURE]',
	YIELD_PRODUCTION = '[COLOR_FLOAT_PRODUCTION]',
	--YIELD_FOOD = '[COLOR_FLOAT_FOOD]',
	YIELD_FAITH = '[COLOR_FLOAT_FAITH]',
	YIELD_GOLD = '[COLOR_FLOAT_GOLD]',
}
-- ===========================================================================
--	VARIABLES
-- ===========================================================================

-- ===========================================================================
function SumeruGetPlotProperty(plotIndex:number, res:table)
	local pPlot = Map.GetPlotByIndex(plotIndex)
	if pPlot then
		res.Property = pPlot:GetProperty(KEY_SUMERU_RANGER)
	end
end
-- ===========================================================================
function SumeruGetOwnedPlots(playerID:number, res:table)
	local pPlayer:table = Players[playerID]
	local pPlayerCities:table = pPlayer:GetCities()
	res.Plots = {}
	for _, pLoopCity in pPlayerCities:Members() do
		for _, plot in pairs(pLoopCity:GetOwnedPlots()) do
			table.insert(res.Plots, plot:GetIndex())
		end
	end
end
-- ===========================================================================
function SumeruRangerOperation(playerID:number, params:table)
	local pPlayer = Players[playerID]
	if pPlayer then
		local pPlot = Map.GetPlot(params.X, params.Y)
		if pPlot == nil then
			return
		end

		local pUnit = UnitManager.GetUnit(playerID, params.UnitID)
		if pUnit == nil then
			return
		end

		local pCity = Cities.GetPlotPurchaseCity(pPlot)
		if pCity == nil then
			return
		end

		for yieldType, yield in pairs(params.Yields) do
			if yieldType == 'YIELD_SCIENCE' then
				pPlayer:GetTechs():ChangeCurrentResearchProgress(yield)
			elseif yieldType == 'YIELD_CULTURE' then
				pPlayer:GetCulture():ChangeCurrentCulturalProgress(yield)
			elseif yieldType == 'YIELD_PRODUCTION' then
				pCity:GetBuildQueue():AddProgress(yield)
			elseif yieldType == 'YIELD_FAITH' then
				pPlayer:GetReligion():ChangeFaithBalance(yield)
			elseif yieldType == 'YIELD_GOLD' then
				pPlayer:GetTreasury():ChangeGoldBalance(yield)
			end
			Game.AddWorldViewText(0, YIELD_COLORS[yieldType] .. '+' .. tostring(yield) .. ' '.. GameInfo.Yields[yieldType].IconString .. '[ENDCOLOR]', params.X, params.Y)
		end
		pPlot:SetProperty(KEY_SUMERU_RANGER, Game.GetCurrentGameTurn())
		pUnitAbility = pUnit:GetAbility();
		for i = 1,10 do
			print("iteration==" .. i);
			if pUnitAbility:GetAbilityCount("ABILITY_BUILD_CHARGE_"..i.."_SUMERU") == 0 then
				pUnitAbility:ChangeAbilityCount("ABILITY_BUILD_CHARGE_"..i.."_SUMERU", 1);
				print("enable ability" .. i);
				break
			end
		end
		UnitManager.FinishMoves(pUnit)
	end
end
-- ===========================================================================
function Initialize()
	GameEvents.SumeruGetPlotProperty.Add(SumeruGetPlotProperty)
	GameEvents.SumeruGetOwnedPlots.Add(SumeruGetOwnedPlots)
	GameEvents.SumeruRangerOperation.Add(SumeruRangerOperation)
end

Events.LoadGameViewStateDone.Add(Initialize)
