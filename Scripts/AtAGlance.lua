-- ===========================================================================
--	AtAGlance
--  Script for the actual "gifting"-action
-- ===========================================================================

-- Tracker for ending deals
local recourcesEndedOnNextTurn = {};

-- Callback for sending a info notification about remainung turns on deal
function OnSendInfoDealRemainingTurnsGameEvent(localPlayerID, params)
	-- Set some varaibles we need
	local newline = "";
	local notificationContent = "";
	local triggerNotification = false;

	-- The given deals that will end
	local notifyDeals = params.notifyDeals;

	-- Loop all deal notifications
	for _, notifyDeal in ipairs(notifyDeals) do
		-- Ending deal params we need to assign
		local resourceName = notifyDeal.resourceName;
		local dealRemainingTurns = notifyDeal.dealRemainingTurns;
		local dealPartnerPlayerId = notifyDeal.dealPartnerPlayerId;
		local dealPartnerPlayer = Players[dealPartnerPlayerId];

		-- Real and alive players count
		if (dealPartnerPlayerId ~= nil and dealPartnerPlayer:IsAlive()) then
			-- Load player data
			local dealPartnerPlayerConfiguration = PlayerConfigurations[dealPartnerPlayerId];
			local dealPartnerPlayerLeaderName = dealPartnerPlayerConfiguration:GetLeaderName();

			-- In case we have multiple ending notifications, aggregate them
			notificationContent = notificationContent..newline..Locale.Lookup("LOC_ATAGLANCE_DEAL_REMAINING_CONTENT", resourceName, dealPartnerPlayerLeaderName, dealRemainingTurns);

			-- Trigger the actual notification
			triggerNotification = true;

			-- For further loop-iterations we need a new-line for each message
			newline = "[NEWLINE]";

			-- Memorize the deal, send a ended-reminder next turn
			if dealRemainingTurns == 1 then
				-- Memorize the deals end next turn (req. for ending deal message)
				table.insert(recourcesEndedOnNextTurn[localPlayerID], {
					eResourceName = resourceName,
					eDealPartnerPlayerId = dealPartnerPlayerId
				});
			end
		end
	end

	-- Check if a notification has been triggered
	if triggerNotification then
		-- Fetch the notified players capital
		local localPlayerCapital = Players[localPlayerID]:GetCities():GetCapitalCity();

		-- Get the notification headline from locales
		local notificationHeadline = Locale.Lookup("LOC_ATAGLANCE_DEAL_REMAINING_HEADLINE");

		-- The actual notification we send out
		NotificationManager.SendNotification(localPlayerID, 30, notificationHeadline, notificationContent, localPlayerCapital:GetX(), localPlayerCapital:GetY());
	end
end

-- Callback for sending a info notification a deal ended
function OnSendInfoDealEndedGameEvent(localPlayerID, params)
	-- Set some varaibles we need
	local newline = "";
	local notificationContent = "";
	local triggerNotification = false;

	-- The given deals that will end
	local notifyDeals = params.notifyDeals;

	-- Loop all deal notifications
	for _, notifyDeal in ipairs(notifyDeals) do
		-- Ending deal params we need to assign
		local resourceName = notifyDeal.eResourceName;
		local dealPartnerPlayerId = notifyDeal.eDealPartnerPlayerId;
		local dealPartnerPlayer = Players[dealPartnerPlayerId];

		-- Real and alive players count
		if (dealPartnerPlayerId ~= nil and dealPartnerPlayer:IsAlive()) then
			-- Load player data
			local localPlayerCapital = Players[localPlayerID]:GetCities():GetCapitalCity();
			local dealPartnerPlayerConfiguration = PlayerConfigurations[dealPartnerPlayerId];
			local dealPartnerPlayerLeaderName = dealPartnerPlayerConfiguration:GetLeaderName();

			-- In case we have multiple ending notifications, aggregate them
			notificationContent = notificationContent..newline..Locale.Lookup("LOC_ATAGLANCE_DEAL_ENDED_CONTENT", resourceName, dealPartnerPlayerLeaderName);

			-- Trigger the actual notification
			triggerNotification = true;

			-- For further loop-iterations we need a new-line for each message
			newline = "[NEWLINE]";
		end
	end

	-- Check if a notification has been triggered
	if triggerNotification then
		-- Fetch the notified players capital
		local localPlayerCapital = Players[localPlayerID]:GetCities():GetCapitalCity();

		-- Get the notification headline from locales
		local notificationHeadline = Locale.Lookup("LOC_ATAGLANCE_DEAL_ENDED_HEADLINE");

		-- The actual notification we send out
		NotificationManager.SendNotification(localPlayerID, 96, notificationHeadline, notificationContent, localPlayerCapital:GetX(), localPlayerCapital:GetY());
	end
end

-- Handling for check deal-endings
function OnCheckDealEndedGameEvent(localPlayerID, params)
	-- Loop all players
	for playerId, recourceEndedOnNextTurn in ipairs(recourcesEndedOnNextTurn) do
		-- Wee need the local player
		if playerId == localPlayerID then
			-- Get his instance
			local player = Players[playerId];

			-- If hes alife, a human (ofcause, its local afterall) and has ending deals
			if (#recourceEndedOnNextTurn > 0 and player:IsAlive() and player:IsHuman()) then
				-- Trigger notification handling
				OnSendInfoDealEndedGameEvent(playerId, {notifyDeals = recourceEndedOnNextTurn});

				-- Reset the ending deals tracker
				ResetRecourcesEndedOnNextTurn(playerId);
			end
		end
	end
end

-- Reset the resource tracker
function ResetRecourcesEndedOnNextTurn(playerId)
	-- For a specific player?
	if playerId ~= nil then
		-- Not more done deals now
		recourcesEndedOnNextTurn[playerId] = {};
	else	-- Or all players
		-- Fetch all players
		local players = Game.GetPlayers();

		-- Loop them
		for i, player in ipairs(players) do
			-- This player
			local playerId = player:GetID();

			-- If hes real...
			if playerId ~= nil then
				-- Reset
				recourcesEndedOnNextTurn[player:GetID()] = {};
			end
		end
	end
end

-- Main function for initialization
function Initialize()
	-- Reset deal tracker
	ResetRecourcesEndedOnNextTurn();

	-- Trigger multiplayer synced game-event on notifications for a deal (see DiplomacyDealAllResources.lua::OnLocalPlayerTurnBegin)
	GameEvents.SendInfoDealRemainingTurns.Add(OnSendInfoDealRemainingTurnsGameEvent);
	GameEvents.SendInfoDealEndedGameEvent.Add(OnSendInfoDealEndedGameEvent);
	GameEvents.CheckDealEnded.Add(OnCheckDealEndedGameEvent);

	-- Communicate with UI context via exposed-members
	ExposedMembers.GameEvents = GameEvents;

	-- Init message log
	print("Initialized.");
end

-- Initialize the script
Initialize();
