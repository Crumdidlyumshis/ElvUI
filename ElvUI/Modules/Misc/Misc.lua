local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule("Misc")
local B = E:GetModule("Bags")

local _G = _G
local next = next
local select = select
local format = format

local CreateFrame = CreateFrame
local AcceptGroup = AcceptGroup
local CanGuildBankRepair = CanGuildBankRepair
local CanMerchantRepair = CanMerchantRepair
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetInstanceInfo = GetInstanceInfo
local GetItemInfo = GetItemInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetQuestItemLink = GetQuestItemLink
local GetFriendInfo = GetFriendInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumQuestChoices = GetNumQuestChoices
local GetNumFriends = GetNumFriends
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetNumGuildMembers = GetNumGuildMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRepairAllCost = GetRepairAllCost
local GetCVarBool = GetCVarBool
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsShiftKeyDown = IsShiftKeyDown
local IsInInstance = IsInInstance
local RaidNotice_AddMessage = RaidNotice_AddMessage
local RepairAllItems = RepairAllItems
local SendChatMessage = SendChatMessage
local StaticPopup_Hide = StaticPopup_Hide
local UninviteUnit = UninviteUnit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitInRaid = UnitInRaid
local UnitName = UnitName
local IsInGuild = IsInGuild
local PlaySoundFile = PlaySoundFile
local GetNumFactions = GetNumFactions
local GetFactionInfo = GetFactionInfo
local GetWatchedFactionInfo = GetWatchedFactionInfo
local ExpandAllFactionHeaders = ExpandAllFactionHeaders
local SetWatchedFactionIndex = SetWatchedFactionIndex
local hooksecurefunc = hooksecurefunc

local LeaveParty = LeaveParty
local ERR_GUILD_NOT_ENOUGH_MONEY = ERR_GUILD_NOT_ENOUGH_MONEY
local ERR_NOT_ENOUGH_MONEY = ERR_NOT_ENOUGH_MONEY
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS

local INTERRUPT_MSG = L["Interrupted %s's |cff71d5ff|Hspell:%d:0|h[%s]|h|r!"]
INTERRUPT_MSG = INTERRUPT_MSG:gsub("|cff71d5ff|Hspell:%%d:0|h(%[%%s])|h|r","%1")


function M:ErrorFrameToggle(event)
	if not E.db.general.hideErrorFrame then return end

	if event == "PLAYER_REGEN_DISABLED" then
		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

function M:ZoneTextToggle()
	if E.db.general.hideZoneText then
		ZoneTextFrame:UnregisterAllEvents()
	else
		ZoneTextFrame:RegisterEvent("ZONE_CHANGED")
		ZoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
		ZoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	end
end

do
	function M:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, sourceGUID, _, _, _, destName, _, _, _, _, spellID, spellName)
		if not (event == "SPELL_INTERRUPT" and (sourceGUID == E.myguid or sourceGUID == UnitGUID("pet"))) then return end

		if E.db.general.interruptAnnounce == "SAY" then
			SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), "SAY")
		elseif E.db.general.interruptAnnounce == "EMOTE" then
			SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), "EMOTE")
		else
			local _, instanceType = IsInInstance()
			local battleground = instanceType == "pvp"

			if E.db.general.interruptAnnounce == "PARTY" then
				if GetNumPartyMembers() > 0 then
					SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), battleground and "BATTLEGROUND" or "PARTY")
				end
			elseif E.db.general.interruptAnnounce == "RAID" then
				if GetNumRaidMembers() > 0 then
					SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), battleground and "BATTLEGROUND" or "RAID")
				elseif GetNumPartyMembers() > 0 then
					SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), battleground and "BATTLEGROUND" or "PARTY")
				end
			elseif E.db.general.interruptAnnounce == "RAID_ONLY" then
				if GetNumRaidMembers() > 0 then
					SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), battleground and "BATTLEGROUND" or "RAID")
				end
			end
		end
	end
end

function M:COMBAT_TEXT_UPDATE(_, messagetype, faction, rep)
	if not E.db.general.autoTrackReputation then return end

	if messagetype == "FACTION" then
		if faction ~= GetWatchedFactionInfo() and rep > 0 then
			ExpandAllFactionHeaders()

			for i = 1, GetNumFactions() do
				if faction == GetFactionInfo(i) then
					SetWatchedFactionIndex(i)
					break
				end
			end
		end
	end
end

do -- Auto Repair Functions
	local STATUS, TYPE, COST, canRepair
	function M:AttemptAutoRepair(playerOverride)
		STATUS, TYPE, COST, canRepair = "", E.db.general.autoRepair, GetRepairAllCost()

		if canRepair and COST > 0 then
			local tryGuild = not playerOverride and TYPE == "GUILD" and IsInGuild()
			local useGuild = tryGuild and CanGuildBankRepair() and COST <= GetGuildBankWithdrawMoney()
			if not useGuild then TYPE = "PLAYER" end

			RepairAllItems(useGuild)

			--Delay this a bit so we have time to catch the outcome of first repair attempt
			E:Delay(0.5, M.AutoRepairOutput)
		end
	end

	function M:AutoRepairOutput()
		if TYPE == "GUILD" then
			if STATUS == "GUILD_REPAIR_FAILED" then
				M:AttemptAutoRepair(true) --Try using player money instead
			else
				E:Print(L["Your items have been repaired using guild bank funds for: "]..E:FormatMoney(COST, B.db.moneyFormat, not B.db.moneyCoins))
			end
		elseif TYPE == "PLAYER" then
			if STATUS == "PLAYER_REPAIR_FAILED" then
				E:Print(L["You don't have enough money to repair."])
			else
				E:Print(L["Your items have been repaired for: "]..E:FormatMoney(COST, B.db.moneyFormat, not B.db.moneyCoins))
			end
		end
	end

	function M:UI_ERROR_MESSAGE(_, messageType)
		if messageType == ERR_GUILD_NOT_ENOUGH_MONEY then
			STATUS = "GUILD_REPAIR_FAILED"
		elseif messageType == ERR_NOT_ENOUGH_MONEY then
			STATUS = "PLAYER_REPAIR_FAILED"
		end
	end
end

function M:MERCHANT_CLOSED()
	M:UnregisterEvent("UI_ERROR_MESSAGE")
	M:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
	M:UnregisterEvent("MERCHANT_CLOSED")
end

function M:MERCHANT_SHOW()
	if E.db.bags.vendorGrays.enable then E:Delay(0.5, B.VendorGrays, B) end

	if E.db.general.autoRepair == "NONE" or IsShiftKeyDown() or not CanMerchantRepair() then return end

	--Prepare to catch "not enough money" messages
	M:RegisterEvent("UI_ERROR_MESSAGE")

	--Use this to unregister events afterwards
	M:RegisterEvent("MERCHANT_CLOSED")

	M:AttemptAutoRepair()
end

function M:DisbandRaidGroup()
	if InCombatLockdown() then return end -- Prevent user error in combat

	if UnitInRaid("player") then
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if online and name ~= E.myname then
				UninviteUnit(name)
			end
		end
	else
		for i = MAX_PARTY_MEMBERS, 1, -1 do
			if UnitExists("party"..i) then
				UninviteUnit(UnitName("party"..i))
			end
		end
	end

	LeaveParty()
end

function M:PVPMessageEnhancement(_, msg)
	if not E.db.general.enhancedPvpMessages then return end
	local _, instanceType = GetInstanceInfo()
	if instanceType == "pvp" or instanceType == "arena" then
		RaidNotice_AddMessage(RaidBossEmoteFrame, msg, ChatTypeInfo.RAID_BOSS_EMOTE)
	end
end

function M:AutoInvite(_, leaderName)
	if not E.db.general.autoAcceptInvite then return end

	if MiniMapLFGFrame:IsShown() then return end
	if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then return end

	local numFriends = GetNumFriends()

	if numFriends > 0 then
		ShowFriends()

		for i = 1, numFriends do
			if GetFriendInfo(i) == leaderName then
				AcceptGroup()
				StaticPopup_Hide("PARTY_INVITE")
				return
			end
		end
	end

	if not IsInGuild() then return end

	GuildRoster()

	for i = 1, GetNumGuildMembers() do
		if GetGuildRosterInfo(i) == leaderName then
			AcceptGroup()
			StaticPopup_Hide("PARTY_INVITE")
			return
		end
	end
end

function M:ForceCVars(event)
	if not GetCVarBool("lockActionBars") then
		E:SetCVar("lockActionBars", 1)
	end

	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end

function M:RESURRECT_REQUEST(event)
	print(self, event)
	if E.db.general.resurrectSound then
		PlaySoundFile(E.Media.Sounds.Resurrect, "Master")
	end
end

function M:ADDON_LOADED(_, addon)
	if addon == "Blizzard_InspectUI" then
		M:SetupInspectPageInfo()
	end
end

local function SelectQuestReward(id)
	local btn = _G["QuestInfoItem"..id]

	if btn.type == "choice" then
		if E.private.skins.blizzard.enable and E.private.skins.blizzard.quest then
			_G[btn:GetName()]:SetBackdropBorderColor(1, 0.80, 0.10)
			_G[btn:GetName()].backdrop:SetBackdropBorderColor(1, 0.80, 0.10)
			_G[btn:GetName().."Name"]:SetTextColor(1, 0.80, 0.10)

			M.QuestRewardGoldIconFrame:ClearAllPoints()
			M.QuestRewardGoldIconFrame:Point('TOPRIGHT', btn, 'TOPRIGHT', -2, -2)
			M.QuestRewardGoldIconFrame:Show()
		else
			QuestInfoItemHighlight:ClearAllPoints()
			QuestInfoItemHighlight:SetAllPoints(btn)
			QuestInfoItemHighlight:Show()
		end

		QuestInfoFrame.itemChoice = btn:GetID()
	end
end

function M:QUEST_COMPLETE()
	if not E.db.general.questRewardMostValueIcon then return end

	local numItems = GetNumQuestChoices()
	if numItems <= 0 then return end

	local link, sellPrice
	local choiceID, maxPrice = 1, 0

	for i = 1, numItems do
		link = GetQuestItemLink("choice", i)

		if link then
			sellPrice = select(11, GetItemInfo(link))

			if sellPrice and sellPrice > maxPrice then
				maxPrice = sellPrice
				choiceID = i
			end
		end
	end

	SelectQuestReward(choiceID)
end

function M:Initialize()
	M.Initialized = true

	M:LoadRaidMarker()
	M:LoadLootRoll()
	M:LoadChatBubbles()
	M:LoadLoot()
	M:ToggleItemLevelInfo(true)
	M:ZoneTextToggle()

	M:RegisterEvent("MERCHANT_SHOW")
	M:RegisterEvent("RESURRECT_REQUEST")
	M:RegisterEvent("PLAYER_REGEN_DISABLED", "ErrorFrameToggle")
	M:RegisterEvent("PLAYER_REGEN_ENABLED", "ErrorFrameToggle")
	M:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "PVPMessageEnhancement")
	M:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "PVPMessageEnhancement")
	M:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL", "PVPMessageEnhancement")
	M:RegisterEvent("PARTY_INVITE_REQUEST", "AutoInvite")
	M:RegisterEvent("GROUP_ROSTER_UPDATE", "AutoInvite")
	M:RegisterEvent("COMBAT_TEXT_UPDATE")
	M:RegisterEvent("QUEST_COMPLETE")
	M:RegisterEvent("ADDON_LOADED")

	for _, addon in next, { "Blizzard_InspectUI" } do
		if IsAddOnLoaded(addon) then
			M:ADDON_LOADED(nil, addon)
		end
	end

	do	-- questRewardMostValueIcon
		local MostValue = CreateFrame("Frame", "ElvUI_QuestRewardGoldIconFrame", QuestInfoRewardsFrame)
		MostValue:SetFrameStrata("HIGH")
		MostValue:Size(19)
		MostValue:Hide()

		MostValue.Icon = MostValue:CreateTexture(nil, "OVERLAY")
		MostValue.Icon:SetAllPoints(MostValue)
		MostValue.Icon:SetTexture(E.Media.Textures.Coins)
		MostValue.Icon:SetTexCoord(0.33, 0.66, 0.022, 0.66)

		M.QuestRewardGoldIconFrame = MostValue

		hooksecurefunc(QuestFrameRewardPanel, "Hide", function()
			if M.QuestRewardGoldIconFrame then
				M.QuestRewardGoldIconFrame:Hide()
			end
		end)
	end

	if E.db.general.interruptAnnounce ~= "NONE" then
		M:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

E:RegisterModule(M:GetName())
