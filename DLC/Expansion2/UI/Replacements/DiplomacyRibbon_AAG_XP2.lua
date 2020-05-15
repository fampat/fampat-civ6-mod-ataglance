-- =========================================
-- AtAGlance - Extension for DiplomacyRibbon
-- =========================================

-- Add a log event for loading this
print("Loading DiplomacyRibbon_AAG_XP2.lua");

-- Determine which expensions are active
local isExpansion1Active = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");

-- Including the base-context file
if isExpansion1Active then
	include("DiplomacyRibbon_AAG_XP1.lua");
else
	include("DiplomacyRibbon_AAG.lua");
end

-- Bind included functions to extend them
XP1_AAG_AddLeader = AddLeader;

-- Our local variable for controlling the diplo-view
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	-- Create a new leader instance
	local leaderIcon, instance = XP1_AAG_AddLeader(iconName, playerID, isUniqueLeader);

	-- Fetch favor yield
	local Favor = RoundNumber(Players[playerID]:GetFavorPerTurn(), 0);

	-- Set instance data
	instance.Favor:SetText("[ICON_Favor] "..Favor);
	instance.Favor:SetColorByName("ResFavorLabelCS");
	instance.Favor:SetHide(false);
	instance.Favor:SetToolTipString(Locale.Lookup("LOC_RIBBON_FAVOR"));

	-- Recalculate
  instance.LeaderStackExtended:CalculateSize();

	-- Return for further modding
	return leaderIcon, instance;
end
