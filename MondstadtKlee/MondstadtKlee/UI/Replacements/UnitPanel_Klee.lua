-- Unit panel modification to prevent Pounding Surprises or other WMDs from displaying without any available warhead.
-- Written by Handsome Kai (PiPiKai), refactored by UzukiShimamura
--------------------------------------------------------------
local BaseUnitPanelScripts = {
    "UnitPanel_Expansion2.lua",
	"UnitPanel_Expansion1.lua",
    "UnitPanel.lua"
}

for _, file in ipairs(BaseUnitPanelScripts) do
    include(file)
    if Initialize then
        break
    end
end

local IsActionLimited_BASE = IsActionLimited;

function IsActionLimited(actionType : string, pUnit : table)
    IsActionLimited_BASE(self);
	for entry in GameInfo.WMDs() do
		if entry.WeaponType == actionType then return true; end
	end
	return false;
end
