-- =========================================
-- AtAGlance - Extension for DiplomacyRibbon
-- =========================================

-- Add a log event for loading this
print("Loading DiplomacyRibbon_AAG_XP1.lua");

-- Including the base-context file
include("DiplomacyRibbon_AAG.lua");

-- Bind included functions to extend them
BASE_AAG_AddLeader = AddLeader;

-- Our local variable for controlling the diplo-view
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	-- Create a new leader instance
	local leaderIcon, instance = BASE_AAG_AddLeader(iconName, playerID, isUniqueLeader);

	--- Hide the era score if no expansion1 is enabled
	instance.GameEra:SetHide(false);
	instance.Favor:SetHide(true);

  -- Fetch eras
	local GameEras:table = Game.GetEras();

	--- Set the current era icon as text
	if GameEras:HasHeroicGoldenAge(playerID) then
		instance.GameEra:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]");
	elseif GameEras:HasGoldenAge(playerID) then
		instance.GameEra:SetText("[ICON_GLORY_GOLDEN_AGE]");
	elseif GameEras:HasDarkAge(playerID) then
		instance.GameEra:SetText("[ICON_GLORY_DARK_AGE]");
	else
		instance.GameEra:SetText("[ICON_GLORY_NORMAL_AGE]");
	end

	-- Tooltip for era
	instance.GameEra:SetToolTipString(Locale.Lookup("LOC_RIBBON_ERA"));

	-- Recalculate
  instance.LeaderStackExtended:CalculateSize();

	-- Return for further modding
	return leaderIcon, instance;
end
