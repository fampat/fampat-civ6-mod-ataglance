-- =============================================================================
--	AtAGlance
--  Author: fampat
--	UI implementation of our loyalty-tooltip
-- =============================================================================

-- Enabled mods check
local isExpansion2Active = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68");

-- Memo for the last mouse-over plot
local lastPlotId = nil;

-- Attach our Loyalty-Tool-Tip
function AttachToPlotToolTip()
	-- Plot under cursor
	local plotId = UI.GetCursorPlotID();

	-- Memorize if the plot has changed since last tick
	-- No need to re-render if nothing changed
	if (lastPlotId == nil or lastPlotId ~= plotId) then
		lastPlotId = plotId;

		-- Fetch the plot
		local plot =  Map.GetPlotByIndex(plotId);

		-- Check if the plot is real
		if plot ~= nil then
			-- Get its loyalty value
			local loyaltyValue = getPlotLoyalty(plotId);

			-- If there is a loyalty value, go on
			if loyaltyValue ~= nil and loyaltyValue < 0 then
				-- Here we wanna dock on :)
				local infoStack = ContextPtr:LookUpControl("/InGame/HUD/PlotToolTip/InfoStack");

				-- If the infostack is present, go on
				if (infoStack ~= nil) then
					-- Append our tool-tip
					Controls.LoyaltyTxt:SetHide(false);
					Controls.LoyaltyTxt:SetText(Locale.Lookup("LOC_AAG_LOYALTY_TOOLTIP", loyaltyValue));
					Controls.LoyaltyTxt:ChangeParent(infoStack);
					infoStack:CalculateSize();
					infoStack:ReprocessAnchoring();
				end
			else
				Controls.LoyaltyTxt:SetHide(true);
			end
		end
	end
end

-- Handle input action like mouse-movement and key-pressing
function OnInputHandler(inputStruct)
	-- Fetch message type
	local message	= inputStruct:GetMessageType();

	-- If we have a mouse-move
	if message == MouseEvents.MouseMove then
		-- Attach our tool-tip
		AttachToPlotToolTip();
	end
end

-- Fetch the plots loyalty value
function getPlotLoyalty(plotId)
	-- This fecthes all current available loyalty-plots
	local plots = Map.GetContinentPlotsLoyalty();

	-- Loop them
	for continentPlotId, plotLoyaltyValue in pairs(plots) do
		-- Identify the plot under the mouse
		if continentPlotId == plotId then
			-- Return its value
			return plotLoyaltyValue;
		end
	end

	-- Zero if nothing was found
	return 0;
end

-- INIT IT!
function Initialize()
	-- At the moment we only need this when GS is enabled
	if isExpansion2Active then
		-- Bind our OnInputHandler (must triggered by an implemented ui-script)
	  LuaEvents.PlotInfoInputHandler.Add(OnInputHandler);
	end

	-- Init message log
	print("Initialized.");
end

-- Finally
Initialize();
