-- ======================================
-- AtAGlance - Extension for MinimapPanel
-- ======================================

-- Add a log event for loading this
print("Loading MinimapPanel_AAG.lua");

-- Set variable to check if XP2 is active
local isExpansion1Active = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");
local isExpansion2Active = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68");

-- Also check if xp2 is installed/active
if isExpansion2Active then
	-- Include xp2 context
	include("MinimapPanel_Expansion2.lua");
elseif isExpansion1Active then
	-- Include xp1 context
	include("MinimapPanel_Expansion1.lua");
else
	-- Include basegame context
	include("MinimapPanel.lua");
end

-- Since local variables dont exist on extension, c&p it from original context
local m_HexColoringAppeal = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level");

-- Bind included functions
AAG_OVERRIDE_MinimapPanel_OnToggleLensList = OnToggleLensList;
AAG_OVERRIDE_MinimapPanel_CloseLensList = CloseLensList;
AAG_OVERRIDE_MinimapPanel_ToggleAppealLens = ToggleAppealLens;
AAG_OVERRIDE_MinimapPanel_OnInterfaceModeChanged = OnInterfaceModeChanged;
AAG_OVERRIDE_MinimapPanel_OnLensLayerOn = OnLensLayerOn;
AAG_OVERRIDE_MinimapPanel_LateInitialize = LateInitialize;

-- Function overrides
function OnToggleLensList()
	AAG_OVERRIDE_MinimapPanel_OnToggleLensList();

	if not Controls.LensPanel:IsHidden() then
		Controls.BuilderLensButton:SetHide(not GameCapabilities.HasCapability("CAPABILITY_LENS_BUILDER"));
	end
end

function CloseLensList()
	AAG_OVERRIDE_MinimapPanel_CloseLensList();
	Controls.BuilderLensButton:SetCheck(false);
end

function ToggleAppealLens()
	AAG_OVERRIDE_MinimapPanel_ToggleAppealLens();
	UILens.ClearLayerHexes(m_HexColoringAppeal);

	if Controls.AppealLensButton:IsChecked() then
		LuaEvents.MinimapPanelBuilderLensOff();
		SetAppealHexes();
		RefreshInterfaceMode();
	end
end

function ToggleBuilderLens()
	UILens.ClearLayerHexes(m_HexColoringAppeal);

	if Controls.BuilderLensButton:IsChecked() then
		LuaEvents.MinimapPanelBuilderLensOn();
		SetBuilderHexes();
		UILens.SetActive("Appeal");
		RefreshInterfaceMode();
  else
		-- Call the builder key (legend)
		LuaEvents.MinimapPanelBuilderLensOff();

		-- Keep the lens list open (its a global, lucky we!)
		g_shouldCloseLensMenu = false;

    if UI.GetInterfaceMode() == InterfaceModeTypes.VIEW_MODAL_LENS then
		    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
		end
	end
end

function OnLensLayerOn(layerNum:number)
	if layerNum ~= m_HexColoringAppeal then
		AAG_OVERRIDE_MinimapPanel_OnLensLayerOn(layerNum);
	else
		UI.PlaySound("UI_Lens_Overlay_On");
	end
end

function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	AAG_OVERRIDE_MinimapPanel_OnInterfaceModeChanged(eOldMode, eNewMode);

	if eOldMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		if not Controls.LensPanel:IsHidden() then
			Controls.BuilderLensButton:SetCheck(false);
		end
	end
end

function LateInitialize()
	AAG_OVERRIDE_MinimapPanel_LateInitialize();

	Controls.BuilderLensButton:RegisterCallback(Mouse.eLClick, ToggleBuilderLens);
end

-- Custom functions
function SetBuilderHexes()
	-- Tables for relevant plots
	local ImprovementPlots:table = {};
	local ImprovablePlots:table = {};
	local RepairPlots:table = {};
	local DefaultPlots:table = {};

	-- Map and local player variables
	local mapWidth, mapHeight = Map.GetGridSize();
	local localPlayer:number  = Game.GetLocalPlayer();

	-- Define colors
	local ImprovementColor	:number = UI.GetColorValue("COLOR_GOVERNMENT_CITYSTATE");
	local ImprovableColor	:number = UI.GetColorValue("COLOR_BREATHTAKING_APPEAL");
	local RepairColor		:number = UI.GetColorValue("COLOR_DISGUSTING_APPEAL");
	local DefaultColor		:number = UI.GetColorValue("COLOR_AVERAGE_APPEAL");

	-- Loop all plots
	for plotIndex = 0, (mapWidth * mapHeight) - 1, 1 do
		-- Condition variables
		local plotAnalyzed = false;
		local isNationalpark = false;

		-- Fetch plot
		local pPlot:table = Map.GetPlotByIndex(plotIndex);

		-- In expansion2 nationalpark plots cannot be improved
		if Game.GetNationalParks() ~= nil then
			isNationalpark = Game.GetNationalParks():IsNationalPark(plotIndex);
		end

		-- Consider only plot beloging to local player
		if pPlot:GetOwner() == Game.GetLocalPlayer() then
			-- Improvements that require repairs
			if pPlot:GetImprovementType() ~= -1 then
				if pPlot:IsImprovementPillaged() then
					table.insert(RepairPlots, plotIndex);
					plotAnalyzed = true;
				else
					table.insert(ImprovementPlots, plotIndex);
					plotAnalyzed = true;
				end
			end

			-- If the plot is not categorized yet, try again
			if not plotAnalyzed then
				-- Improvable resources
				if pPlot:GetResourceType() ~= -1 then
					if (ResourceOnPlotIsImprovableByLocalPlayer(pPlot) and not isNationalpark) then
						table.insert(ImprovablePlots, plotIndex);
						plotAnalyzed = true;
					end
				else
					table.insert(DefaultPlots, plotIndex);
					plotAnalyzed = true;
				end
			end

			-- Mark all uncategorized plots as default non-resource
			if not plotAnalyzed then table.insert(DefaultPlots, plotIndex); end;
		end
	end

	if table.count(ImprovementPlots) > 0 then
		UILens.SetLayerHexesColoredArea(m_HexColoringAppeal, localPlayer, ImprovementPlots, ImprovementColor);
	end

	if table.count(ImprovablePlots) > 0 then
		UILens.SetLayerHexesColoredArea(m_HexColoringAppeal, localPlayer, ImprovablePlots, ImprovableColor);
	end

	if table.count(RepairPlots) > 0 then
		UILens.SetLayerHexesColoredArea(m_HexColoringAppeal, localPlayer, RepairPlots, RepairColor);
	end

	if table.count(DefaultPlots) > 0 then
		UILens.SetLayerHexesColoredArea(m_HexColoringAppeal, localPlayer, DefaultPlots, DefaultColor);
	end
end

function ResourceOnPlotIsImprovableByLocalPlayer(pPlot)
	-- Only uninproved resources
	if pPlot:GetImprovementType() == -1 then
		local plotIndex = pPlot:GetIndex();
		local playerID = Game.GetLocalPlayer();

		if ResourceAvailableToPlayer(playerID, plotIndex) then
			local rInfo = GameInfo.Resources[pPlot:GetResourceType()];

			if rInfo ~= nil then
				local iType;

				for vResInfo in GameInfo.Improvement_ValidResources() do
					if (vResInfo ~= nil and vResInfo.ResourceType == rInfo.ResourceType) then
						iType = vResInfo.ImprovementType;
						local iInfo = GameInfo.Improvements[iType];
						if (PlayerHasPrereqTech(playerID, iInfo.PrereqTech) or PlayerHasPrereqCivic(playerID, PrereqCivic)) then return true; end;
					end
				end
			end

			return false;
		end
	end
end

function ResourceAvailableToPlayer(playerID, plotIndex)
	local lPlayerVis = PlayerVisibilityManager.GetPlayerVisibility(Game.GetLocalObserver());
	local pPlot = Map.GetPlotByIndex(plotIndex);

	local oResource = lPlayerVis:GetLayerValue(VisibilityLayerTypes.RESOURCES, plotIndex);
	local bHidoResource = (pPlot ~= nil and (pPlot:IsCity() or pPlot:GetDistrictType() > 0));

	if (oResource ~= nil and oResource ~= -1 and not bHidoResource ) then
		return true;
	end

	return false;
end

function PlayerHasPrereqTech(playerID, prereqTech)
	local pPlayer = Players[playerID]

	if prereqTech ~= nil then
		local playerTech:table = pPlayer:GetTechs();
		local pTech = GameInfo.Technologies[prereqTech];

		if pTech ~= nil and (not playerTech:HasTech(pTech.Index)) then
			return false;
		end
	end

	return true;
end

function PlayerHasPrereqCivic(playerID, prereqCivic)
	local pPlayer = Players[playerID]

	if prereqCivic ~= nil then
		local pCulture = pPlayer:GetCulture();
		local pCivic = GameInfo.Civics[prereqCivic];

		if pCivic ~= nil and (not pCulture:HasCivic(pCivic.Index)) then
			return false;
		end
	end

	return true;
end
