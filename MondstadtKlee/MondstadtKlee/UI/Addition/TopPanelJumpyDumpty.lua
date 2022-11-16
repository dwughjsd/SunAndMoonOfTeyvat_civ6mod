-- Written by Handsome Kai (PiPiKai), edited by UzukiShimamura
--------------------------------------------------------------
isAttached = false;
function kleeOnWMDUpdate(owner, WMDtype)
	local eLocalPlayer = Game.GetLocalPlayer();
	if ( eLocalPlayer ~= -1 and owner == eLocalPlayer ) then
		local player = Players[owner];
		local playerWMDs = player:GetWMDs();

		for entry in GameInfo.WMDs() do
			if (entry.WeaponType == "WMD_JUMPY_DUMPTY") then
				local count = playerWMDs:GetWeaponCount(entry.Index);
				if (count > 0) then
					Controls.JumpyDumpty:SetHide(false);
					Controls.JumpyDumptyCount:SetText(count);
				else
					Controls.JumpyDumpty:SetHide(true);
				end
			end
		end
	end
	ContextPtr:RequestRefresh();
end
function AttachToTopPanel()
	local infoStack = ContextPtr:LookUpControl("/InGame/TopPanel/InfoStack/StaticInfoStack")
    if not isAttached then
		Controls.JumpyDumpty:ChangeParent(infoStack)
		infoStack:AddChildAtIndex(Controls.JumpyDumpty, 3)
        infoStack:CalculateSize()
        infoStack:ReprocessAnchoring()
        isAttached = true
    end
    kleeWMD();
end
function kleeWMD()
	kleeOnWMDUpdate( Game.GetLocalPlayer() )
end
-- klee ---------------
function Initialize()
	Events.LocalPlayerChanged.Add(kleeWMD);
	Events.TurnBegin.Add(kleeWMD);
    Events.LoadGameViewStateDone.Add(AttachToTopPanel);
    Events.WMDCountChanged.Add(	kleeOnWMDUpdate );
    Events.LocalPlayerChanged.Add(kleeWMD);
end
Initialize()





