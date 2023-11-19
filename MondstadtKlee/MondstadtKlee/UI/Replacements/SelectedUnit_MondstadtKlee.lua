-- Written by Konomi, edited by UzukiShimamura
--------------------------------------------------------------

-- =================================================================================
-- Import base file
-- =================================================================================
local files = {
    "DL_SelectedUnit.lua", -- Harmony in Diversity. NOTE THAT THIS MOD IS NOT PROVEN TO BE COMPATIBLE WITH HiD AND ALL ISSUES ABOUT IT IS UNSUPPORTED
	--'SelectedUnit_Expansion2.lua' It cannot be loaded because it was not imported. Fuck Firaxis. For HiD compatibility something more should be done but this is not considered in this mod. A compatibility patch might be made by them.
    "SelectedUnit.lua",
}

local isSelectedUnitReplaced = 0;

for _, file in ipairs(files) do
    include(file)
    if Initialize then
        print("MondstadtKlee loading " .. file .. " as base file");
		if file ~= "SelectedUnit.lua" then
			isSelectedUnitReplaced = 1;
        break;
		end
    end
end
-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
GameEvents = ExposedMembers.GameEvents;

local COOLDOWN_TURN = GlobalParameters.SUMERU_RANGER_COOLDOWN_TURN or 50
-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_ForestInfo = GameInfo.Features['FEATURE_FOREST']
local m_JungleInfo = GameInfo.Features['FEATURE_JUNGLE']
-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
-- XP2 Code has been copied here
function XP2_RealizeGreatPersonLens(kUnit:table )
	UILens.ClearLayerHexes(m_HexColoringGreatPeople);
	if UILens.IsLayerOn( m_HexColoringGreatPeople ) then
		UILens.ToggleLayerOff(m_HexColoringGreatPeople);
	end
	if kUnit ~= nil and ( not UI.IsGameCoreBusy() ) then
		local playerID:number = kUnit:GetOwner();
		if playerID == Game.GetLocalPlayer() then
			local kUnitArchaeology:table = kUnit:GetArchaeology();
			local kUnitGreatPerson:table = kUnit:GetGreatPerson();
			local kUnitRockBand:table = kUnit:GetRockBand();
			local bCanCauseDisasters:boolean = false;
			local sUnitType = GameInfo.Units[kUnit:GetUnitType()].UnitType;
			if (sUnitType ~= nil and GameInfo.Units_XP2[sUnitType] ~= nil and GameInfo.Units_XP2[sUnitType].CanCauseDisasters ~= nil) then
				bCanCauseDisasters = GameInfo.Units_XP2[sUnitType].CanCauseDisasters;
			end
			if kUnitGreatPerson ~= nil and kUnitGreatPerson:IsGreatPerson() then
				local greatPersonInfo:table = GameInfo.GreatPersonIndividuals[kUnitGreatPerson:GetIndividual()];
				-- Highlight an area around the Great Person (if they have an area of effect trait)
				local areaHighlightPlots:table = {};
				if (greatPersonInfo ~= nil and greatPersonInfo.AreaHighlightRadius ~= nil) then
					areaHighlightPlots = kUnitGreatPerson:GetAreaHighlightPlots();
				end
				-- Highlight the plots the Great Person could use its action on
				local activationPlots:table = {};
				if (greatPersonInfo ~= nil and greatPersonInfo.ActionEffectTileHighlighting ~= nil and greatPersonInfo.ActionEffectTileHighlighting) then
					local rawActivationPlots:table = kUnitGreatPerson:GetActivationHighlightPlots();
					for _,plotIndex:number in ipairs(rawActivationPlots) do
						table.insert(activationPlots, {"Great_People", plotIndex});
					end
				end
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, areaHighlightPlots, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif( kUnitArchaeology ~= nil and GameInfo.Units[kUnit:GetUnitType()].ExtractsArtifacts == true) then 
				-- Highlight plots that can activated by Archaeologists
				local activationPlots:table = {};
				local rawActivationPlots:table = kUnitArchaeology:GetActivationHighlightPlots();
				for _,plotIndex:number in ipairs(rawActivationPlots) do
					table.insert(activationPlots, {"Great_People", plotIndex});
				end
					
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif GameInfo.Units[kUnit:GetUnitType()].ParkCharges > 0 and kUnit:GetParkCharges() > 0 then -- Highlight plots that can activated by Naturalists
				local parkPlots:table = {};
				local rawParkPlots:table = Game.GetNationalParks():GetPossibleParkTiles(playerID);
				for _,plotIndex:number in ipairs(rawParkPlots) do
					table.insert(parkPlots, {"Great_People", plotIndex});
				end
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, parkPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif kUnitRockBand ~= nil and GameInfo.Units[kUnit:GetUnitType()].UnitType == "UNIT_ROCK_BAND" then -- Highlight plots that can activated by RockBands
				-- Highlight the plots the RockBand could use its action on
				local activationPlots:table = {};
				local rawActivationPlots:table = kUnitRockBand:GetActivationHighlightPlots();
				for _,plotIndex:number in ipairs(rawActivationPlots) do
					table.insert(activationPlots, {"Great_People", plotIndex});
				end
					
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif bCanCauseDisasters then -- Highlight plots that this unit can trigger disasters on
				local activationPlots:table = {};
				local rawActivationPlots:table = GameClimate.GetLocationsForPossibleTriggerableEvents(playerID);
				for _,plotIndex:number in ipairs(rawActivationPlots) do
					table.insert(activationPlots, {"Great_People", plotIndex});
				end
					
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			end
		end
	end
end
-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
local ORIGINAL_RealizeGreatPersonLens = RealizeGreatPersonLens;
if Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68") and isSelectedUnitReplaced == 0 then -- Gathering Storm enabled and no other known modification enabled.
	ORIGINAL_RealizeGreatPersonLens = XP2_RealizeGreatPersonLens;
	print("unmodified XP2 SelectUnit detected")
end
-- ===========================================================================
--	OVERRIDES XP2 FUNCTIONS
-- ===========================================================================
function IsPlotMeet(playerID, pPlot)
	if m_ForestInfo == nil or m_JungleInfo == nil then
		return false
	end
	
	local pPlayer = Players[playerID]
	
	local featureType = pPlot:GetFeatureType()
	if featureType == m_ForestInfo.Index or featureType == m_JungleInfo.Index then
		local res = {}
		GameEvents.SumeruGetPlotProperty.Call(pPlot:GetIndex(), res)
		if res.Property and Game.GetCurrentGameTurn() - res.Property < COOLDOWN_TURN then
			return false
		end

		if featureType == m_ForestInfo.Index and m_ForestInfo.RemoveTech and not pPlayer:GetTechs():HasTech(m_ForestInfo.RemoveTechReference.Index) then
			return false
		elseif featureType == m_JungleInfo.Index and m_JungleInfo.RemoveTech and not pPlayer:GetTechs():HasTech(m_JungleInfo.RemoveTechReference.Index) then
			return false
		end

		return true
	end
	return false
	
end
-- ===========================================================================
function RealizeGreatPersonLens(kUnit:table)
	ORIGINAL_RealizeGreatPersonLens(kUnit)
	if kUnit ~= nil and ( not UI.IsGameCoreBusy() ) then
		local playerID:number = kUnit:GetOwner();
		if playerID == Game.GetLocalPlayer() then
			local unitInfo = GameInfo.Units[kUnit:GetType()]
			if unitInfo and unitInfo.UnitType == 'UNIT_SUMERU_FOREST_RANGER' and kUnit:GetBuildCharges() > 0 then
				local plots:table = {}
				local pPlayer:table = Players[playerID]
				local pPlayerCities:table = pPlayer:GetCities()
				for _, pLoopCity in pPlayerCities:Members() do
					local kCityPlots :table = Map.GetCityPlots():GetPurchasedPlots(pLoopCity)
					for _, plotId in pairs(kCityPlots) do
						local pPlot = Map.GetPlotByIndex(plotId)
						if pPlot and IsPlotMeet(playerID, pPlot) then
							table.insert(plots, {"Great_People", plotId})
						end
						
					end
				end

				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, plots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			end
		end
	end
end
