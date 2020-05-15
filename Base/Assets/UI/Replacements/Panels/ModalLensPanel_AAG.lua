-- ========================================
-- AtAGlance - Extension for ModalLensPanel
-- ========================================

-- Add a log event for loading this
print("Loading ModalLensPanel_AAG.lua");

-- Set variable to check if XP2 is active
local isExpansion1Active = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");

-- Check if xp1/xp2 is installed/active
if isExpansion1Active then
	-- Include xp1 context
	include("ModalLensPanel_Expansion1.lua");
else
	-- Include basegame context
	include("ModalLensPanel");
end

-- Since local variables dont exist on extension, c&p it from original context
local m_HexColoringAppeal = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level");

-- Our custom lens switch
local m_builderLensOn = false;

-- Bind included functions
AAG_OVERRIDE_ModalLensPanel_OnLensLayerOn = OnLensLayerOn;

-- Overridden functions
function OnLensLayerOn(layerNum:number)
	-- Call base lens-key in case its not appeal (we use that for builder lens)
	if layerNum ~= m_HexColoringAppeal then
		-- Call the base function
		AAG_OVERRIDE_ModalLensPanel_OnLensLayerOn(layerNum);
	else
		-- Check if the builder-lens has been activated
		if m_builderLensOn then
			-- ON...
			BuilderLensOn();
		else
			-- ...OFF!
			BuilderLensOff();
		end
	end
end

-- Custom functions
function ShowBuilderLensKey()
	-- Reset the key-stack (its a global, lucky we!)
	g_KeyStackIM: ResetInstances();

	-- Improvable
	AddKeyEntry("LOC_AAG_BUILDER_IMPROVABLE", UI.GetColorValue("COLOR_BREATHTAKING_APPEAL"));

	-- Improvement
	AddKeyEntry("LOC_AAG_BUILDER_IMPROVEMENT", UI.GetColorValue("COLOR_GOVERNMENT_CITYSTATE"));

	-- Repairable
	AddKeyEntry("LOC_AAG_BUILDER_REPAIR", UI.GetColorValue("COLOR_DISGUSTING_APPEAL"));

	-- Default
	AddKeyEntry("LOC_AAG_BUILDER_DEFAULT", UI.GetColorValue("COLOR_AVERAGE_APPEAL"));

	Controls.KeyPanel:SetHide(false);
	Controls.KeyScrollPanel:CalculateSize();
end

-- Enable builder-lens-key
function OnBuilderLensOn()
	m_builderLensOn = true;
end

-- Disable builder-lens key
function OnBuilderLensOff()
	m_builderLensOn = false;
end

-- Put the builder-lens-key on
function BuilderLensOn()
	Controls.LensText:SetText(Locale.ToUpper(Locale.Lookup("LOC_AAG_BUILDER_LENS")));
	ShowBuilderLensKey();
end

-- Put the builder-lens-key off
function BuilderLensOff()
	Controls.LensText:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_APPEAL_LENS")));
	ShowAppealLensKey();
end

function InitialzeNow()
	print("InitialzedNow");

	-- Remove ols binds ans add our own
	Events.LensLayerOn.Remove(AAG_OVERRIDE_ModalLensPanel_OnLensLayerOn);
	Events.LensLayerOn.Add(OnLensLayerOn);

	-- Events to toggle the builder-lens-key on appeal activation
	LuaEvents.MinimapPanelBuilderLensOn.Add(OnBuilderLensOn);
	LuaEvents.MinimapPanelBuilderLensOff.Add(OnBuilderLensOff);
end

InitialzeNow();
