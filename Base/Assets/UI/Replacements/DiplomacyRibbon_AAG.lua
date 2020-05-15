-- =========================================
-- AtAGlance - Extension for DiplomacyRibbon
-- =========================================

-- Add a log event for loading this
print("Loading DiplomacyRibbon_AAG.lua");

-- Set variable to check if EDR is active
local isEDRActive = Modding.IsModActive("382a187f-c8ba-4094-a6a7-0d5315661f32");
local isEDRActive = false;	-- Until ARISTOS EDR is fixed it will not be compatible!

-- Set variable to check if XP2 is active
local isExpansion1Active = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9");
local isExpansion2Active = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68");

-- Check if EDR is installed/active
if isEDRActive then
	-- Also check if xp2 is installed/active
	if isExpansion2Active then
		-- Include EDR xp2 context
		include("EDR_DiplomacyRibbon_Expansion2.lua");
	else
		-- Include EDR context
		include("ExtendedDiplomacyRibbon.lua");
	end
else
	-- Also check if xp2 is installed/active
	if isExpansion2Active then
		-- Include xp2 context
		include("DiplomacyRibbon_Expansion2.lua");
	elseif isExpansion1Active then
		-- Include xp1 context
		include("DiplomacyRibbon_Expansion1.lua");
	else
		-- Include basegame context
		include("DiplomacyRibbon.lua");
	end
end

-- Bind included functions
AAG_OVERRIDE_AddLeader = AddLeader;

-- Our local variable for controlling the diplo-view
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	-- Create a new leader instance
	local leaderIcon, instance = AAG_OVERRIDE_AddLeader(iconName, playerID, isUniqueLeader);

	--- Collect stats
	local Score = Players[playerID]:GetScore();
	local Science = RoundNumber(Players[playerID]:GetTechs():GetScienceYield(), 0);
	local Military = Players[playerID]:GetStats():GetMilitaryStrengthWithoutTreasury();
	local MilitaryWithTreasury = Players[playerID]:GetStats():GetMilitaryStrength();
	local Faith = RoundNumber(Players[playerID]:GetReligion():GetFaithYield(), 0);
	local Culture = RoundNumber(Players[playerID]:GetCulture():GetCultureYield(), 0);

	--- Add stats to leader instance
	instance.Score:SetText("[ICON_Capital]"..Score);
  instance.Military:SetText("[ICON_Strength]"..Military);
  instance.Science:SetText("[ICON_Science]"..Science);
  instance.Culture:SetText("[ICON_Culture]"..Culture);
  instance.Faith:SetText("[ICON_Faith]"..Faith);

	-- Set tooltips
	instance.Score:SetToolTipString(Locale.Lookup("LOC_RIBBON_SCORE"));
	instance.Military:SetToolTipString(Locale.Lookup("LOC_RIBBON_MILITARY_STRENGTH_WITH_TREASURY_TOOLTIP", MilitaryWithTreasury));
	instance.Science:SetToolTipString(Locale.Lookup("LOC_RIBBON_SCIENCE"));
	instance.Culture:SetToolTipString(Locale.Lookup("LOC_RIBBON_CULTURE"));
	instance.Faith:SetToolTipString(Locale.Lookup("LOC_RIBBON_FAITH"));

	-- Recalculate
  instance.LeaderStackExtended:CalculateSize();

	-- Return for further modding
	return leaderIcon, instance;
end

-- Round numbers helper
function RoundNumber(num, numDecimalPlaces)
  if numDecimalPlaces and numDecimalPlaces>0 then
    local mult = 10^numDecimalPlaces
    return math.ceil(num * mult + 0.5) / mult
  end
  return math.ceil(num + 0.5)
end
