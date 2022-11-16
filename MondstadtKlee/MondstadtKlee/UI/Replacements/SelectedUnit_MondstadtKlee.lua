-- Written by Konomi, edited by UzukiShimamura
--------------------------------------------------------------

-- =================================================================================
-- Import base file
-- =================================================================================
local files = {
	"DL_SelectedUnit.lua",  -- Harmony in Diversity. NOTE THAT THIS MOD IS NOT PROVEN TO BE COMPATIBLE WITH HiD AND ALL ISSUES ABOUT IT IS UNSUPPORTED
    --"SelectedUnit_Expansion2.lua",
    "SelectedUnit.lua",
}

for _, file in ipairs(files) do
    include(file)
    if Initialize then
        print("SelectedUnit_MondstadtKlee: Loading " .. file .. " as base file");
        break
    end
end
-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
GameEvents = ExposedMembers.GameEvents;

local COOLDOWN_TURN = GlobalParameters.SUMERU_RANGER_COOLDOWN_TURN or 10
-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_ForestInfo = GameInfo.Features['FEATURE_FOREST']
local m_JungleInfo = GameInfo.Features['FEATURE_JUNGLE']
-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
-- 'SelectedUnit_Expansion2.lua' cannot be loaded because it was not be imported.
-- Its code has been copied here
-- Fuck Firaxis
function RealizeGreatPersonLens(kUnit:table )
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
			if unitInfo and unitInfo.UnitType == 'UNIT_SUMERU_FOREST_RANGER' and kUnit:GetActionCharges() > 0 then
				local res = {
					Plots = {}
				}
				GameEvents.SumeruGetOwnedPlots.Call(playerID, res)

				local plots:table = {}
				for _, plotIndex in ipairs(res.Plots) do
					local pPlot = Map.GetPlotByIndex(plotIndex)
					if pPlot and IsPlotMeet(playerID, pPlot) then
						table.insert(plots, {"Great_People", plotIndex});
					end
				end

				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, plots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			end
		end
	end
end
