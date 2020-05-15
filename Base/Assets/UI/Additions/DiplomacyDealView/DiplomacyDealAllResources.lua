-- ============================================
--	AtAGlance
--	UI implementation of our All-Resources-View
-- ============================================

-- Includes
include( "InstanceManager" );

-- Debugging mode switch
local debugMode = false;

-- UI controls
local ms_IconOnlyDimmedIM = InstanceManager:new( "IconOnlyDimmed",  "SelectButton", Controls.IconOnlyContainerDimmed );
local ms_LeftRightListIM	= InstanceManager:new( "LeftRightListDimmed",  "List", Controls.LeftRightListContainerDimmed);

-- Right now we only have a single group, might grow...
local AvailableDealItemGroupTypes = {
	ALL_RESOURCES	= 1
};

-- ...with more group types
local ms_AvailableGroups = {
	[AvailableDealItemGroupTypes.ALL_RESOURCES] = {}
};

-- Is deal-view active?
local b_DealView = false;

-- Local player
local ms_LocalPlayer = nil;

-- End turn tracker
local b_LocalPlayerEndedTurn = false;

-- Check XP2 availability
local isExpansion2Active = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68");

-- Constants (things that really NEVER CHANGE! _NEVER_)
local OTHER_PLAYER = 0;
local LOCAL_PLAYER = 1;

-- Trigger player panel creation (horizontal group)
function CreatePanels()
	-- Maybe we should not have this wrapped an extra time oO
	CreatePlayerAvailablePanel(LOCAL_PLAYER, Controls.MyInventoryStackDimmed);
end

-- Create the player panel (horizontal group)
function CreatePlayerAvailablePanel(playerType, rootControl)
	-- XP2 installed/active?
	if isExpansion2Active then
		-- We only want to show luxuries
		ms_AvailableGroups[AvailableDealItemGroupTypes.ALL_RESOURCES][playerType]	= CreateHorizontalGroup(rootControl, "LOC_DIPLOMACY_DEAL_ALL_LUXURY_RESOURCES");
	else
		-- On older rulesets we also want to show strategic resources
		ms_AvailableGroups[AvailableDealItemGroupTypes.ALL_RESOURCES][playerType]	= CreateHorizontalGroup(rootControl, "LOC_DIPLOMACY_DEAL_ALL_RESOURCES");
	end

	-- Recalculate UI stuffz
	rootControl:CalculateSize();
	rootControl:ReprocessAnchoring();
end

-- Add resources to the player panel
function PopulatePlayerAvailablePanel(rootControl, player)
	local iAvailableItemCount = 0;

	-- For real players only
	if (player ~= nil) then
		local playerType = GetPlayerType(player);
		iAvailableItemCount = iAvailableItemCount + PopulateKeptAllResources(player, ms_AvailableGroups[AvailableDealItemGroupTypes.ALL_RESOURCES][playerType]);
		rootControl:CalculateSize();
		rootControl:ReprocessAnchoring();
	end

	-- Return count
	return iAvailableItemCount;
end

-- Trade-deal-view showed up
function OnShow()
	-- Initialize the counter for resources
	local resourcesCount = 0;

	-- Log message
	WriteToLog("OnShow");

	-- Reset the dimmed icons instances
	ms_IconOnlyDimmedIM:ResetInstances();

	-- Fill up the panel with our resources
	resourcesCount = PopulatePlayerAvailablePanel(Controls.MyInventoryStackDimmed, ms_LocalPlayer);

	-- In case we have resources...
	if resourcesCount > 0 then
  	-- Attach the icons to the trade-deal-view
		AttachAllResourcesToDiplomacyTradeDealView();
	end
end

-- Create a trade-deal conform horizontal group
function CreateHorizontalGroup(rootStack, title)
	local iconList = ms_LeftRightListIM:GetInstance(rootStack);

	if (title == nil or title == "") then
		iconList.Title:SetHide(true);		-- No title
	else
		iconList.TitleText:LocalizeAndSetText(title);
	end

	-- Recalculation stuff on the UI
	iconList.List:CalculateSize();
	iconList.List:ReprocessAnchoring();

	return iconList;
end

-- Helper function for determine player type
function GetPlayerType(player)
	if (player:GetID() == ms_LocalPlayer:GetID()) then
		return LOCAL_PLAYER;
	end

	return OTHER_PLAYER;
end

-- Helper function setting icon sizes
function SetIconToSize(iconControl, iconName, iconSize)
	if iconSize == nil then
		iconSize = 50;
	end

	local x, y, szIconName, iconSize = IconManager:FindIconAtlasNearestSize(iconName, iconSize, true);

	iconControl:SetTexture(x, y, szIconName);
	iconControl:SetSizeVal(iconSize, iconSize);
end

-- Count all available resources
function PopulateKeptAllResources(player, iconList)
	local iAvailableItemCount = 0;
	iAvailableItemCount = iAvailableItemCount + PopulateAllResources(player, iconList);
	return iAvailableItemCount;
end

-- Displays all luxury and strategic resources to the player on trade screen
function PopulateAllResources(player, iconList)
	local iAvailableItemCount = 0;

	-- Check if player is a local (human) player
	if (player:GetID() == ms_LocalPlayer:GetID()) then
		-- Get the players resources table
		local playerResources = player:GetResources();

		-- Loop games available resources
		for resource in GameInfo.Resources() do
			-- Only luxury and strategic resources are shown
			if (resource.ResourceClassType ~= nil and
			   (resource.ResourceClassType == "RESOURCECLASS_LUXURY" or
				 (not isExpansion2Active and resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"))) then

				-- Fetch the amount of resources the player have
				local amountKept = playerResources:GetResourceAmount(resource.ResourceType);
				local amountExported = playerResources:GetExportedResourceAmount(resource.ResourceType);
				local amount = amountKept + amountExported;

				-- Only proceed if the player have resources
				if (amount > 0) then
					-- Fetch remaining deal durations
					local remainingOutgoingDealDurationForResource, dealOutgoingPartnerId = GetRemainingOutgoingDealDurationForResource(player, resource);
					local remainingIncomingDealDurationForResource, dealIncomingPartnerId = GetRemainingIncomingDealDurationForResource(player, resource);
					local icon = ms_IconOnlyDimmedIM:GetInstance(iconList.ListStack);

					-- Set the icon size and text
					SetIconToSize(icon.Icon, "ICON_" .. resource.ResourceType, 16);
					icon.AmountText:SetText(tostring(amount));
					icon.AmountText:SetHide(false);

					-- Disable the button
					icon.SelectButton:SetDisabled(true);

					-- Init resource tool-tips
					local dOutgoingDealTooltip = "";
					local dIncomingDealTooltip = "";

					-- Set a tool tip for the outgoing deal
					if (remainingOutgoingDealDurationForResource > 0) then
						dOutgoingDealTooltip = Locale.Lookup(resource.Name).."[NEWLINE]"..Locale.Lookup("LOC_DIPLOMACY_DEAL_ALL_SHORTEST_OUTGOING_DURATION")..": "..remainingOutgoingDealDurationForResource.." "..Locale.Lookup("LOC_TURNS_REMAINING");
					else
						dOutgoingDealTooltip = Locale.Lookup(resource.Name).."[NEWLINE]"..Locale.Lookup("LOC_DIPLOMACY_DEAL_ALL_NOT_OUTGOING");
					end

					-- Set a tool tip for the incoming deal
					if (remainingIncomingDealDurationForResource > 0) then
						dIncomingDealTooltip = Locale.Lookup("LOC_DIPLOMACY_DEAL_ALL_SHORTEST_INCOMING_DURATION")..": "..remainingIncomingDealDurationForResource.." "..Locale.Lookup("LOC_TURNS_REMAINING")
					else
						dIncomingDealTooltip = Locale.Lookup("LOC_DIPLOMACY_DEAL_ALL_NOT_INCOMING");
					end

					icon.SelectButton:SetToolTipString(dOutgoingDealTooltip.."[NEWLINE]"..dIncomingDealTooltip);
					icon.SelectButton:ReprocessAnchoring();

					iAvailableItemCount = iAvailableItemCount + 1;
				end
			end
		end

		-- Recalculate UI stuffz
		iconList.ListStack:CalculateSize();
		iconList.List:ReprocessAnchoring();
	end

	-- Hide if empty
	iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0);

	-- Return what we have counted
	return iAvailableItemCount;
end

-- Fetch the remaining deal (export) duration if a resource-deal
function GetRemainingOutgoingDealDurationForResource (player, resource)
	local playerID = player:GetID();
	local kPlayers = PlayerManager.GetAliveMajors();
	local shortestRemainingTurns = 0;
	local dealPartnerId = nil;

	-- Check if player is a local (human) player
	if (player:GetID() == ms_LocalPlayer:GetID()) then
		-- Loop al alive players who have at least one city
		for _, pOtherPlayer in ipairs(kPlayers) do
			local otherID = pOtherPlayer:GetID();
			local currentGameTurn = Game.GetCurrentGameTurn();

			-- Filter for players other than the human player
			if otherID ~= playerID then
				-- Get export deals								  Exporter  Importer
				local pDeals = DealManager.GetPlayerDeals(playerID, otherID);

				if pDeals ~= nil then
					-- Iterate through all deals
					for i,pDeal in ipairs(pDeals) do
						local pOutgoingDeal :table	= pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, playerID);

						if pOutgoingDeal ~= nil then
							for i,pDealItem in ipairs(pOutgoingDeal) do
								-- Load resource type of dealt (exported) resource
								local dealResource = GameInfo.Resources[pDealItem:GetValueType()];

								-- If dealt resource matches the checked (requested) resource, go on
								if dealResource.ResourceType == resource.ResourceType then
									-- Fetch duration of deal
									local duration : number = pDealItem:GetDuration();
									local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());

									-- Keep only the shortest remaining deal time
									if (duration ~= nil and remainingTurns ~= 0) then
										if (remainingTurns < shortestRemainingTurns or shortestRemainingTurns == 0) then
											shortestRemainingTurns = remainingTurns;
											dealPartnerId = otherID;
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

  -- This is what we have been looking for
	return shortestRemainingTurns, dealPartnerId;
end

-- Fetch the remaining deal (import) duration if a resource-deal
function GetRemainingIncomingDealDurationForResource (player, resource)
	local playerID = player:GetID();
	local kPlayers = PlayerManager.GetAliveMajors();
	local shortestRemainingTurns = 0;
	local dealPartnerId = nil;

	-- Check if player is a local (human) player
	if (player:GetID() == ms_LocalPlayer:GetID()) then
		-- Loop al alive players who have at least one city
		for _, pOtherPlayer in ipairs(kPlayers) do
			local otherID = pOtherPlayer:GetID();
			local currentGameTurn = Game.GetCurrentGameTurn();

			-- Filter for players other than the human player
			if otherID ~= playerID then
				-- Get export deals								  Exporter  Importer
				local pDeals : table = DealManager.GetPlayerDeals(otherID, playerID);

				if pDeals ~= nil then
					-- Iterate through all deals
					for i,pDeal in ipairs(pDeals) do
						local pIncomingDeal	= pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, otherID);

						if pIncomingDeal ~= nil then
							for i,pDealItem in ipairs(pIncomingDeal) do
								-- Load resource type of dealt (exported) resource
								local dealResource = GameInfo.Resources[pDealItem:GetValueType()];

								-- If dealt resource matches the checked (requested) resource, go on
								if dealResource.ResourceType == resource.ResourceType then
									-- Fetch duration of deal
									local duration : number = pDealItem:GetDuration();
									local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());

									-- Keep only the shortest remaining deal time
									if (duration ~= nil and remainingTurns ~= 0) then
										if (remainingTurns < shortestRemainingTurns or shortestRemainingTurns == 0) then
											shortestRemainingTurns = remainingTurns;
											dealPartnerId = otherID;
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- This is what we have been looking for
	return shortestRemainingTurns, dealPartnerId;
end

-- Attach our all-resources UI to the trade-deal window
function AttachAllResourcesToDiplomacyTradeDealView ()
	-- Log message
	WriteToLog("Triggered");

	-- Get the existing stack
	local MyInventoryStack = ContextPtr:LookUpControl("/InGame/DiplomacyDealView/MyInventoryStack");

	-- If it exist, attach our recources
	if MyInventoryStack ~= nil then
		-- Log message
		WriteToLog("MyInventoryStack found");

		-- Get my stack a new parent
		Controls.MyInventoryStackDimmed:ChangeParent(MyInventoryStack);

		-- Make the birth of the child official, iam now a daddy!
		MyInventoryStack:AddChildAtIndex(Controls.MyInventoryStackDimmed, 3);
		MyInventoryStack:CalculateSize();
		MyInventoryStack:ReprocessAnchoring();
	end
end

-- Debug function for logging
function WriteToLog(message)
	if (debugMode and message ~= nil) then
		print(message);
	end
end

-- Diplomay interaction happend
function OnDiplomacyStatement(actingPlayer, reactingPlayer, values)
	-- If its a trade deal interaction and we havent already started...
	if (values["StatementType"] == -2065048438 and not b_DealView) then
		-- Start one and set local deal-view state
		b_DealView = true;

		-- Handle deal-view start now
		OnShow();
	end
end

-- Diplomacy session has been closed
function OnDiplomacySessionClosed()
	-- If we had a deal open...
	if b_DealView then
		-- Remember we need to start a new one on request
		b_DealView = false;
	end
end

-- Handling for turn-start
function OnLocalPlayerTurnBegin()
	-- Log message
	WriteToLog("OnLocalPlayerTurnBegin");

	-- Check if he does not pressed end before this turn (and unreadied)
	if not b_LocalPlayerEndedTurn then
		-- Memorizer for notification
		local notifyAboutThisDeals = {};

		-- Assign local player
		local player = ms_LocalPlayer;

		-- Trigger ended deals notification (if there are any)
		UI.RequestPlayerOperation(player, PlayerOperations.EXECUTE_SCRIPT, {OnStart = "CheckDealEnded"});

		-- Get his resources
		local playerResources = player:GetResources();

		-- Loop games available resources
		for resource in GameInfo.Resources() do
			-- Only luxury and strategic resources are shown
			if (resource.ResourceClassType ~= nil and
				 (resource.ResourceClassType == "RESOURCECLASS_LUXURY" or
				 (not isExpansion2Active and resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"))) then
				 -- Determine the shortes deal incoming duration
			 	 local shortestRemainingIncomingDeal, dealIncomingPartnerId = GetRemainingIncomingDealDurationForResource(player, resource);

				 -- If its the last turn, dipsplay the player a notification
				 if shortestRemainingIncomingDeal == 1 then
					  -- Fetch localized resource name
				 		local incomingResourceName = Locale.Lookup(resource.Name);

						-- Collect deals to notify about
						table.insert(notifyAboutThisDeals, {
							resourceName = incomingResourceName;
							dealRemainingTurns = shortestRemainingIncomingDeal;
							dealPartnerPlayerId = dealIncomingPartnerId;
						});
				 end
		  end
		end

		-- If we have notifications, continue
		if #notifyAboutThisDeals > 0 then
			-- Call the gameplay script to trigger notifications
			UI.RequestPlayerOperation(player, PlayerOperations.EXECUTE_SCRIPT, {
				OnStart = "SendInfoDealRemainingTurns",
				notifyDeals = notifyAboutThisDeals
			});
		end
	end
end

-- Handling for turn-end
function OnLocalPlayerTurnEnd()
	-- Log message
	WriteToLog("OnLocalPlayerTurnEnd");

	-- Disabled "turn start" event triggered twice
	b_LocalPlayerEndedTurn = true;
end

-- Handling for global turn-end
function OnTurnEnd()
	-- Log message
	WriteToLog("OnTurnEnd");

	-- Enable "turn start" event triggering again
	b_LocalPlayerEndedTurn = false;
end

-- Handling for global turn-begin
function OnTurnBegin()
	-- Log message
	WriteToLog("OnTurnBegin");
end

-- Trigger init
function OnInit(isHotload)
  -- Log message
	WriteToLog("OnInit");

	-- Set the local player
	ms_LocalPlayer = Players[Game.GetLocalPlayer()];

	-- Create the panel
	CreatePanels();

  -- Trigger show on hotload
	if (isHotload and not ContextPtr:IsHidden()) then
		OnShow();
	end
end

-- Initial loading
function OnLoadGameViewStateDone()
	-- Log message
	WriteToLog("OnLoadGameViewStateDone");

	-- Trigger turn-begin event the first time
	OnLocalPlayerTurnBegin();
end

-- Init function, uknow...
function Initialize()
	-- Context is ready?
	ContextPtr:SetInitHandler(OnInit);

	-- Loading is done
	Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);

	-- Diplomacy actions triggered
	Events.DiplomacyStatement.Add(OnDiplomacyStatement);

	-- Diplomacy session ended
	Events.DiplomacySessionClosed.Add(OnDiplomacySessionClosed);

	-- Turn starts
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

	-- Turn ends
	Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd);

	-- Global turn begins
	Events.TurnBegin.Add(OnTurnBegin);

	-- Global turn ends
	Events.TurnEnd.Add(OnTurnEnd);

	-- Init message log
	print("Initialized.");
end

-- GOGOGO!!!111eleven
Initialize();
