-- ======================================
-- AtAGlance - Extension for PlotInfo
-- ======================================

-- Add a log event for loading this
print("Loading PlotInfo_AAG.lua");

-- Include basegame context
include("PlotInfo.lua");

-- Bind original function we want to execute here
AAG_OVERRIDE_PlotInfo_Initialize = Initialize;

-- Since local variables dont exist on extension, c&p it from original context
local CITIZEN_BUTTON_HEIGHT:number = 64;

-- Restores the little citizens to original size and visibility
function RestoreCitizenIcons()
	local pSelectedCity :table = UI.GetHeadSelectedCity();
	if pSelectedCity == nil then
		-- Add error message here
		return;
	end

	local tParameters :table = {};
	tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

	local tResults	:table = CityManager.GetCommandTargets( pSelectedCity, CityCommandTypes.MANAGE, tParameters );
	if tResults == nil then
		-- Add error message here
		return;
	end

	local tPlots		:table = tResults[CityCommandResults.PLOTS];
	local tUnits		:table = tResults[CityCommandResults.CITIZENS];
	local tMaxUnits		:table = tResults[CityCommandResults.MAX_CITIZENS];
	local tLockedUnits	:table = tResults[CityCommandResults.LOCKED_CITIZENS];

	if tPlots ~= nil and (table.count(tPlots) > 0) then
		for i,plotId in pairs(tPlots) do
			local kPlot	:table = Map.GetPlotByIndex(plotId);
			local index:number = kPlot:GetIndex();
			local pInstance:table = GetInstanceAt( index );
			if pInstance ~= nil then
				-- Restore default button values (check PlotInfo.xml for defaults)
				pInstance.CitizenButton:SetSizeX(64);
				pInstance.CitizenButton:SetSizeY(64);
				pInstance.CitizenButton:SetOffsetY(-50);
				pInstance.CitizenButton:SetOffsetX(0);
				pInstance.CitizenButton:SetAlpha(1);
				pInstance.CitizenButton:SetHide(true);
				pInstance.CitizenMeterBG:SetHide(true);
			end
		end
	end
end

-- Interface mode change hook (switching between city-views for example)
function OnInterfaceModeChanged(oldMode:number, newMode:number)
  -- Restore the default citizen-icons (we do modify them afterall!)
	RestoreCitizenIcons();

  -- Handle the different views
	if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT or newMode == InterfaceModeTypes.BUILDING_PLACEMENT) then	-- AtAGlance
		ShowCitizensInDisctrictMode();	-- Here we add our lovely little citizens
	elseif newMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		if oldMode == InterfaceModeTypes.DISTRICT_PLACEMENT or
			oldMode == InterfaceModeTypes.BUILDING_PLACEMENT then
			OnClearDistrictPlacementShadowHexes();
			RealizeShadowMask();
		end
	end
end

-- Catch the ongoing input (if you can)
function OnInputHandler()
	print('MOEPLLLllll');
	if hexOverlayPanelIsOpen then
		local inputMessage = inputStruct:GetMessageType();

		if (inputMessage ~= MouseEvents.LButtonDown and inputMessage ~= MouseEvents.PointerDown) then
			local plotId = UI.GetCursorPlotID();
			if (plotId == nil or not Map.IsPlot(plotId)) then
					return;
			end
			local pPlot = Map.GetPlotByIndex(plotId);
			print("plotId:")
			print(plotId)
		end
	end
end

-- Our custom function to add little citizens
function ShowCitizensInDisctrictMode()
	local pSelectedCity :table = UI.GetHeadSelectedCity();
	if pSelectedCity == nil then
		-- Add error message here
		return;
	end

	local tParameters :table = {};
	tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

	local tResults	:table = CityManager.GetCommandTargets( pSelectedCity, CityCommandTypes.MANAGE, tParameters );
	if tResults == nil then
		-- Add error message here
		return;
	end

	local tPlots		:table = tResults[CityCommandResults.PLOTS];
	local tUnits		:table = tResults[CityCommandResults.CITIZENS];
	local tMaxUnits		:table = tResults[CityCommandResults.MAX_CITIZENS];
	local tLockedUnits	:table = tResults[CityCommandResults.LOCKED_CITIZENS];

	if tPlots ~= nil and (table.count(tPlots) > 0) then
		for i,plotId in pairs(tPlots) do
			local kPlot	:table = Map.GetPlotByIndex(plotId);
			local index:number = kPlot:GetIndex();
			local pInstance:table = GetInstanceAt( index );

			if pInstance ~= nil then
				pInstance.CitizenButton:SetVoid1( index );
				pInstance.CitizenButton:SetSizeX(40);
				pInstance.CitizenButton:SetSizeY(40);
				pInstance.CitizenButton:SetOffsetY(0);
				pInstance.CitizenButton:SetOffsetX(-60);
				pInstance.CitizenButton:SetAlpha(0.50);
				pInstance.CitizenButton:SetHide(false);
				pInstance.CitizenButton:SetDisabled( true );

				local numUnits:number = tUnits[i];
				local maxUnits:number = tMaxUnits[i];

				if(numUnits >= 1) then
					pInstance.CitizenButton:SetTextureOffsetVal(0, CITIZEN_BUTTON_HEIGHT*4);
				else
					pInstance.CitizenButton:SetTextureOffsetVal(0, 0);
				end

				if(maxUnits > 1) then
					pInstance.CitizenMeterBG:SetHide(false);
					pInstance.CurrentAmount:SetText(numUnits);
					pInstance.TotalAmount:SetText(maxUnits);
					pInstance.CitizenMeter:SetPercent(numUnits / maxUnits);
				else
					pInstance.CitizenMeterBG:SetHide(true);
				end

				pInstance.LockedIcon:SetHide(true)
			end
		end
	end
end

function OnInputHandler(inputStruct)
	LuaEvents.PlotInfoInputHandler(inputStruct);
end

-- INIT IT!
function Initialize()
	-- Call original function
	AAG_OVERRIDE_PlotInfo_Initialize();

  -- Hook into the interface-change event
	Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);

	-- Hook into the input functionality
	ContextPtr:SetInputHandler(OnInputHandler, true);
end

-- Finally
Initialize()
