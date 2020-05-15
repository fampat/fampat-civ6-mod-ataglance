-- ==================================================================
-- AtAGlance - Extension for ModalLensPanel Compatibility More-Lenses
-- This just imports the ML context since its overwrites AAG Context
-- This is necessary because we are not able to prevent loading via
-- .modinfo, so iam "replacing" AAG with this dummy to enable ML
-- ==================================================================

-- Add a log event for loading this
print("Loading ML-DUMMY ModalLensPanel_ML.lua");

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
