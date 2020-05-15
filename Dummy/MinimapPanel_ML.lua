-- =================================================================
-- AtAGlance - Extension for MinimapPanel Compatibility More-Lenses
-- This just imports the ML context since its overwrites AAG Context
-- This is necessary because we are not able to prevent loading via
-- .modinfo, so iam "replacing" AAG with this dummy to enable ML
-- =================================================================

-- Add a log event for loading this
print("Loading ML-DUMMY MinimapPanel_ML.lua");

-- Set variable to check if XP1/XP2 is active
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
