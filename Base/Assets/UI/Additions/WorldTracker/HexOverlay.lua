-- =============================================================================
--	AtAGlance
--  Author: fampat
--	UI implementation of our hex-overlay
-- =============================================================================

-- Includes
include("PlotIterator.lua");

-- Constants
local COLOR_WHITE = UI.GetColorValueFromHexLiteral(0x28FFFFFF);
local COLOR_GREEN = UI.GetColorValueFromHexLiteral(0x2800FF00);
local COLOR_RED = UI.GetColorValueFromHexLiteral(0x28005EFF);
local COLOR_BLUE = UI.GetColorValueFromHexLiteral(0x28FF5E00);
local DEFAULT_HEX_RANGE = 6;
local INDUSTRIAL_DISTRICT = 9;
local ENTERTAINMENT_DISTRICT = 6;
local WATER_PARK_DISTRICT = 24;
local MIN_RANGE = 1;
local MAX_RANGE = 12;

-- Variables
local isLoading:boolean	= false;
local isAttached:boolean = false;
local hideHexOverlayPanel:boolean = false;
local hexOverlayPanelIsOpen:boolean = false;
local lastPlotId = nil;
local hexOverlay:object = nil;
local hexRange = DEFAULT_HEX_RANGE;

-- This is the artist who colors the plots!
function SetHexOverlay()
	-- Plot under cursor
	local plotId = UI.GetCursorPlotID();

	-- Assign the actual overlay
	hexOverlay = UILens.GetOverlay("MapSearch");

  -- No plot no deal... no overlay
	if (not Map.IsPlot(plotId)) then
			if (hexOverlay ~= nil) then
				hexOverlay:ClearAll();
			end

			return;
	end

	-- Memorize if the plot has changed since last tick
	-- No need to re-render if nothing changed
	if (lastPlotId == nil or lastPlotId ~= plotId) then
		lastPlotId = plotId;

		-- Variables
		local pPlot = Map.GetPlotByIndex(plotId);
		local localPlayer = Game.GetLocalPlayer();
		local localPlayerVis:table = PlayersVisibility[localPlayer];
		local cityPlot:table = {};
		local districtPlot:table = {};
		local normalPlot:table = {};

		-- Create a list of all plots in a range
		for pAdjacentPlot in PlotAreaSpiralIterator(pPlot, hexRange, SECTOR_NONE, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_EXCLUDE) do
			if localPlayerVis:IsRevealed(pAdjacentPlot:GetX(), pAdjacentPlot:GetY()) then
				-- Fetch the adjecenst district type
				local pAdjacentType = pAdjacentPlot:GetDistrictType();

				-- Split the plots to normal, districts and cities
				if (pAdjacentPlot:GetOwner() == localPlayer and pAdjacentPlot:IsCity()) then
					table.insert(cityPlot, pAdjacentPlot:GetIndex());
				elseif (pAdjacentPlot:GetOwner() == localPlayer and (pAdjacentType == INDUSTRIAL_DISTRICT or pAdjacentType == ENTERTAINMENT_DISTRICT or pAdjacentType == WATER_PARK_DISTRICT)) then
					table.insert(districtPlot, pAdjacentPlot:GetIndex());
				else
					table.insert(normalPlot, pAdjacentPlot:GetIndex());
				end
			end
		end

		-- If we successfully have created a overlay
		if (hexOverlay ~= nil) then
			hexOverlay:ClearAll();	-- Reset it
			hexOverlay:SetPlotChannel(normalPlot, 0);	-- Assign normal plots to channel 0
			hexOverlay:SetPlotChannel(cityPlot, 1);	-- Assign city plots to channel 1
			hexOverlay:SetPlotChannel(districtPlot, 2);	-- Assign district plots to channel 2
			hexOverlay:SetBorderColors(0, COLOR_WHITE, COLOR_WHITE);	-- Assign normal border color
			hexOverlay:SetHighlightColor(0, COLOR_GREEN);	-- Assign normal plots color
			hexOverlay:SetBorderColors(1, COLOR_RED, COLOR_RED);	-- Assign city border color
			hexOverlay:SetHighlightColor(1, COLOR_GREEN);	-- Assign city plot color
			hexOverlay:SetBorderColors(2, COLOR_BLUE, COLOR_BLUE);	-- Assign district border color
			hexOverlay:SetHighlightColor(2, COLOR_GREEN);	-- Assign district plot color
			hexOverlay:SetVisible(true);	-- Make it visible
			hexOverlay:ShowHighlights(true);	-- Show the hightlight-color
		end
	end
end

-- Bigger radius
local function IncreseHexRange()
		if (hexRange < MAX_RANGE) then
        hexRange = hexRange + 1;
    end

    Controls.HexPanelRangeLabel:SetText(hexRange);
end

-- Smaller radius
local function DecreaseHexRange()
    if (hexRange > MIN_RANGE) then
        hexRange = hexRange - 1;
    end

    Controls.HexPanelRangeLabel:SetText(hexRange);
end

-- Attaches the panel-toggler to the world-tracker
function AttachPanelToWorldTracker()
	if (isLoading) then
		return;
	end

	if (not isAttached) then
		local worldTrackerPanel:table = ContextPtr:LookUpControl("/InGame/WorldTracker/PanelStack");
		if (worldTrackerPanel ~= nil) then
			Controls.HexOverlayPanel:ChangeParent(worldTrackerPanel);
			worldTrackerPanel:AddChildAtIndex(Controls.HexOverlayPanel, 1);
			worldTrackerPanel:CalculateSize();
			worldTrackerPanel:ReprocessAnchoring();
			isAttached = true;
		end
	end
end

-- Remove our hex-overlay from the world
function ClearHexOverlay()
	if (hexOverlay ~= nil) then
		hexOverlay:ClearAll();
	end
end

-- After world-loading, attach our world-tracker-panel
function OnLoadGameViewStateDone()
	AttachPanelToWorldTracker();
	InitWorldTrackerDropdown();
end

-- Toggle the word-tracker-panel visiblity
function UpdateHexOverlayPanel(hideHexOverlayPanelValue:boolean)
	hideHexOverlayPanel = hideHexOverlayPanelValue;
	Controls.HexOverlayPanel:SetHide(hideHexOverlayPanel);
	Controls.ToggleHexOverlayPanel:SetCheck(not hideHexOverlayPanel);
	if hideHexOverlayPanel then
		ClosePanel();
	end
end

-- Bind the clicky-controls to elements
local function InitializeControls()
	Controls.HeaderTitle:RegisterCallback(Mouse.eLClick, OnPanelTitleClicked);
	Controls.ToggleHexOverlayPanel:RegisterCheckHandler(function() UpdateHexOverlayPanel(not hideHexOverlayPanel); end);
	Controls.ToggleHexOverlayPanel:SetCheck(true);

	UpdateHexOverlayPanel(true);
end

-- Open the panel (hex-overlay will be visible due to hexOverlayPanelIsOpen)
function OpenPanel()
	CloseMapSearchPanel();
	UI.PlaySound("Tech_Tray_Slide_Open");
	Controls.HexOverlayPanel:SetSizeY(60);
	Controls.HexPanelRangeSelector:SetHide(false);
	Controls.ButtonSeparatorOpenState:SetHide(false);
	hexOverlayPanelIsOpen = true;
	LuaEvents.HexOverlayStatusChange(true);
	Controls.HexPanelRangeLabel:SetText(hexRange);
end

-- Close the panel and clear the hex-overlay
function ClosePanel()
	UI.PlaySound("Tech_Tray_Slide_Closed");
	Controls.HexOverlayPanel:SetSizeY(25);
	Controls.HexPanelRangeSelector:SetHide(true);
	Controls.ButtonSeparatorOpenState:SetHide(true);
	hexOverlayPanelIsOpen = false;
	LuaEvents.HexOverlayStatusChange(false);
	ClearHexOverlay();
end

-- Toggle panel
function OnPanelTitleClicked()
  if not hexOverlayPanelIsOpen then
		UI.DeselectAllUnits();
		OpenPanel();
	else
		ClosePanel();
	end
end

-- Add our hex-overlay as togglable option to the world-tracker dropdown
function InitWorldTrackerDropdown()
	-- Fetch the world-tracker dropdown-ui-instance
	local dropdownGrid = ContextPtr:LookUpControl("/InGame/WorldTracker/DropdownGrid");

 -- Is it real?
	if dropdownGrid ~= nil then
		-- YES! It is, now get us the kids!
		local dropdownGridChildren = dropdownGrid:GetChildren();

		-- Kids are real?
		if dropdownGridChildren ~= nil then
			-- Loop the kids!
			for i,dropdownGridChild in ipairs(dropdownGridChildren) do
				-- This kid (the first one) gets a brand new parent and vice versa!
				Controls.HexOverlayPanelButton:ChangeParent(dropdownGridChild);
				dropdownGridChild:CalculateSize();
				dropdownGridChild.ReprocessAnchoring();

				-- Dont trigger this again!
				Events.LoadGameViewStateDone.Remove(InitWorldTrackerDropdown);

				-- We break it now (end the loop)
				break;
			end
		end
	end
end

-- Handle input action like mouse-movement and key-pressing
function OnInputHandler(inputStruct)
	if hexOverlayPanelIsOpen then
		local inputMessage = inputStruct:GetMessageType();

		if (inputMessage == MouseEvents.RButtonDown) then
			ClosePanel();
			return;
		end

		if (inputMessage ~= MouseEvents.LButtonDown and inputMessage ~= MouseEvents.PointerDown) then
			SetHexOverlay();
		end
	end
end

-- Close our panel in case the map-search has been opened
function OnMapSearchPanelOpened()
	ClosePanel();
end

-- Close our panel in case a lens has been activated
function OnLensLayerOn()
	ClosePanel();
end

-- Close the map-search panel in case it is open (and maybe active)
-- Hex-Overlay an map-search cannot be used in parallel
function CloseMapSearchPanel()
	local mapSearchPanel = ContextPtr:LookUpControl("/InGame/HUD/MinimapPanel/MapSearchPanel");
	local mapSearchButton = ContextPtr:LookUpControl("/InGame/HUD/MinimapPanel/MapSearchButton");

	if (mapSearchPanel ~= nil) then
		if (not mapSearchPanel:IsHidden()) then
			mapSearchPanel:SetHide(true);
			if mapSearchButton ~= nil then mapSearchButton:SetSelected(false); end
			LuaEvents.MapSearch_PanelClosed();
		end
	end
end

-- Initialize!
function Initialize()
	isLoading = true;

	-- Initially close the panel (hot-seat for example)
	ClosePanel();

	-- Loading gameview is done
	Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);

  -- Initialize our stuff
	InitializeControls();
	InitWorldTrackerDropdown();

  -- Our stuff is loaded
	isLoading = false;
	UpdateHexOverlayPanel(false);

  -- Bind our OnInputHandler (must triggered by an implemented ui-script)
  LuaEvents.PlotInfoInputHandler.Add(OnInputHandler);

	-- Close the hex-overlay on map-search usage
	LuaEvents.MapSearch_PanelOpened.Add(OnMapSearchPanelOpened);

	-- Close the hex-overlay on lense usage
	Events.LensLayerOn.Add(OnLensLayerOn);

  -- Add hex range-change callbacks
	Controls.HexPanelRangeDown:RegisterCallback(Mouse.eLClick, DecreaseHexRange);
	Controls.HexPanelRangeUp:RegisterCallback(Mouse.eLClick, IncreseHexRange);

	-- Init message log
	print("Initialized.");
end

-- Fire!
Initialize();
