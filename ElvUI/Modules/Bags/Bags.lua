local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule('Bags')
local TT = E:GetModule('Tooltip')
local S = E:GetModule('Skins')
local AB = E:GetModule('ActionBars')

local LSM = E.Libs.LSM
local LIS = E.Libs.ItemSearch
local LC = E.Libs.Compat

local _G = _G
local gsub = string.gsub
local tinsert, tremove, wipe = tinsert, tremove, wipe
local type, pairs, ipairs, unpack, select = type, pairs, ipairs, unpack, select
local ceil, next, max, floor, format, strsub = ceil, next, max, floor, format, strsub
local pcall = pcall

local BreakUpLargeNumbers = LC.BreakUpLargeNumbers
local CreateFrame = CreateFrame
local CursorHasItem = CursorHasItem
local DepositReagentBank = DepositReagentBank
local EasyMenu = EasyMenu
local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide
local GetBindingKey = GetBindingKey
local GetCursorMoney = GetCursorMoney
local GetCVarBool = GetCVarBool
local GetInventoryItemTexture = GetInventoryItemTexture
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetItemSpell = GetItemSpell
local GetKeyRingSize = GetKeyRingSize
local GetMoney = GetMoney
local GetNumBankSlots = GetNumBankSlots
local GetPlayerTradeMoney = GetPlayerTradeMoney
local PickupBagFromSlot = PickupBagFromSlot
local PlaySound = PlaySound
local PutItemInBackpack = PutItemInBackpack
local PutItemInBag = PutItemInBag
local PutKeyInKeyRing = PutKeyInKeyRing
local SetItemButtonCount = SetItemButtonCount
local SetItemButtonDesaturated = SetItemButtonDesaturated
local SetItemButtonTexture = SetItemButtonTexture
local SetItemButtonTextureVertexColor = SetItemButtonTextureVertexColor
local StaticPopup_Show = StaticPopup_Show
local ToggleFrame = ToggleFrame
local UnitAffectingCombat = UnitAffectingCombat

local GetCurrentGuildBankTab = GetCurrentGuildBankTab
local GetGuildBankItemLink = GetGuildBankItemLink
local GetGuildBankTabInfo = GetGuildBankTabInfo

local IsBagOpen, IsOptionFrameOpen = IsBagOpen, IsOptionFrameOpen
local IsShiftKeyDown, IsControlKeyDown = IsShiftKeyDown, IsControlKeyDown
local CloseBag, CloseBackpack, CloseBankFrame = CloseBag, CloseBackpack, CloseBankFrame

local EditBox_HighlightText = EditBox_HighlightText
local BankFrameItemButton_Update = BankFrameItemButton_Update
local BankFrameItemButton_UpdateLocked = BankFrameItemButton_UpdateLocked

local ContainerIDToInventoryID = ContainerIDToInventoryID
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerNumSlots = GetContainerNumSlots
local UseContainerItem = UseContainerItem

local CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y = CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y

local BACKPACK_TOOLTIP = BACKPACK_TOOLTIP
local BINDING_NAME_TOGGLEKEYRING = BINDING_NAME_TOGGLEKEYRING
local CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y = CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y
local CONTAINER_SCALE = CONTAINER_SCALE
local CONTAINER_SPACING, VISIBLE_CONTAINER_SPACING = CONTAINER_SPACING, VISIBLE_CONTAINER_SPACING
local CONTAINER_WIDTH = CONTAINER_WIDTH
local ITEM_ACCOUNTBOUND = ITEM_ACCOUNTBOUND
local ITEM_BIND_ON_EQUIP = ITEM_BIND_ON_EQUIP
local ITEM_BIND_ON_USE = ITEM_BIND_ON_USE
local ITEM_BNETACCOUNTBOUND = ITEM_BNETACCOUNTBOUND
local ITEM_SOULBOUND = ITEM_SOULBOUND
local NUM_BANKGENERIC_SLOTS = NUM_BANKGENERIC_SLOTS
local MAX_WATCHED_TOKENS = MAX_WATCHED_TOKENS
local NUM_BAG_FRAMES = NUM_BAG_FRAMES
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES
local SEARCH = SEARCH

local BANK_CONTAINER = BANK_CONTAINER
local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local KEYRING_CONTAINER = KEYRING_CONTAINER

local READY_TEX = [[Interface\RaidFrame\ReadyCheck-Ready]]
local NOT_READY_TEX = [[Interface\RaidFrame\ReadyCheck-NotReady]]

do
	local GetContainerItemInfo = GetContainerItemInfo
	local GetContainerItemQuestInfo = GetContainerItemQuestInfo
	local GetBackpackCurrencyInfo = GetBackpackCurrencyInfo

	function B:GetBackpackCurrencyInfo(index)
		if _G.GetBackpackCurrencyInfo then
			local info = {}
			info.name, info.quantity, info.currencyTypesID, info.iconFileID, info.itemID = GetBackpackCurrencyInfo(index)
			return info
		else
			return GetBackpackCurrencyInfo(index)
		end
	end

	function B:GetContainerItemInfo(containerIndex, slotIndex)
		if _G.GetContainerItemInfo then
			local info = {}
			info.iconFileID, info.stackCount, info.isLocked, _, info.isReadable, info.hasLoot, info.hyperlink = GetContainerItemInfo(containerIndex, slotIndex)
			info.itemID = B:GetItemID(containerIndex, slotIndex)
			if info.itemID then
				_, _, info.quality, info.itemLevel, _, info.itemType, info.itemSubType, _, _, _, info.itemPrice = GetItemInfo(info.itemID)
				info.hasNoValue = (info.itemPrice and info.itemPrice == 0)
			end
			return info
		else
			return GetContainerItemInfo(containerIndex, slotIndex) or {}
		end
	end

	function B:GetContainerItemQuestInfo(containerIndex, slotIndex)
		if _G.GetContainerItemQuestInfo then
			local info = {}
			info.isQuestItem, info.questID, info.isActive = GetContainerItemQuestInfo(containerIndex, slotIndex)
			return info
		else
			return GetContainerItemQuestInfo(containerIndex, slotIndex)
		end
	end
end

-- GLOBALS: ElvUIBags, ElvUIBagMover, ElvUIBankMover

local MAX_CONTAINER_ITEMS = 36
local CONTAINER_WIDTH = 192
local CONTAINER_SPACING = 0
local VISIBLE_CONTAINER_SPACING = 3
local CONTAINER_SCALE = 0.75
local BIND_START, BIND_END

B.numTrackedTokens = 0
B.QuestSlots = {}
B.ItemLevelSlots = {}

B.IsEquipmentSlot = {
	INVTYPE_HEAD = true,
	INVTYPE_NECK = true,
	INVTYPE_SHOULDER = true,
	INVTYPE_BODY = true,
	INVTYPE_CHEST = true,
	INVTYPE_WAIST = true,
	INVTYPE_LEGS = true,
	INVTYPE_FEET = true,
	INVTYPE_WRIST = true,
	INVTYPE_HAND = true,
	INVTYPE_FINGER = true,
	INVTYPE_TRINKET = true,
	INVTYPE_WEAPON = true,
	INVTYPE_SHIELD = true,
	INVTYPE_RANGED = true,
	INVTYPE_CLOAK = true,
	INVTYPE_2HWEAPON = true,
	INVTYPE_TABARD = true,
	INVTYPE_ROBE = true,
	INVTYPE_WEAPONMAINHAND = true,
	INVTYPE_WEAPONOFFHAND = true,
	INVTYPE_HOLDABLE = true,
	INVTYPE_THROWN = true,
	INVTYPE_RANGEDRIGHT = true,
	INVTYPE_RELIC = true
}

local bagIDs, bankIDs = {0, 1, 2, 3, 4}, { -1 }
local bankOffset, maxBankSlots = 4, 11
local bankEvents = {'BAG_UPDATE', 'PLAYERBANKBAGSLOTS_CHANGED', 'PLAYERBANKSLOTS_CHANGED'}
local bagEvents = {'BAG_UPDATE', 'ITEM_LOCK_CHANGED', 'QUEST_ACCEPTED', 'QUEST_REMOVED', 'QUEST_LOG_UPDATE'}
local presistentEvents = {
	PLAYERBANKSLOTS_CHANGED = true,
	BAG_UPDATE = true,
}

for bankID = bankOffset + 1, maxBankSlots do
	tinsert(bankIDs, bankID)
end

tinsert(bagIDs, KEYRING_CONTAINER)

function B:SetItemSearch(query)
	local empty = (gsub(query, '%s+', '')) == ''

	for _, bagFrame in pairs(B.BagFrames) do
		for _, bagID in ipairs(bagFrame.BagIDs) do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local info = B:GetContainerItemInfo(bagID, slotID)
				local button = bagFrame.Bags[bagID][slotID]
				local success, result = pcall(LIS.Matches, LIS, info.hyperlink, query)

				if empty or (success and result) then
					SetItemButtonDesaturated(button, button.locked or button.junkDesaturate)
					button.searchOverlay:Hide()
					button:SetAlpha(1)
				else
					SetItemButtonDesaturated(button, 1)
					button.searchOverlay:Show()
					button:SetAlpha(0.5)
				end
			end
		end
	end

	B:SetGuildBankSearch(query)
end

function B:SetGuildBankSearch(query)
	if _G.GuildBankFrame and _G.GuildBankFrame:IsShown() then
		local tab = GetCurrentGuildBankTab()
		local _, _, isViewable = GetGuildBankTabInfo(tab)

		if isViewable then
			local empty = (gsub(query, '%s+', '')) == ''

			for slotID = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				local link = GetGuildBankItemLink(tab, slotID)
				--A column goes from 1-14, e.g. GuildBankColumn1Button14 (slotID 14) or GuildBankColumn2Button3 (slotID 17)
				local col = ceil(slotID / 14)
				local btn = (slotID % 14)
				if col == 0 then col = 1 end
				if btn == 0 then btn = 14 end

				local button = _G['GuildBankColumn'..col..'Button'..btn]
				local success, result = pcall(LIS.Matches, LIS, link, query)

				if empty or (success and result) then
					SetItemButtonDesaturated(button, button.locked or button.junkDesaturate)
					button:SetAlpha(1)
				else
					SetItemButtonDesaturated(button, 1)
					button:SetAlpha(0.5)
				end
			end
		end
	end
end

function B:GetContainerFrame(arg)
	if arg == true then
		return B.BankFrame
	elseif type(arg) == 'number' then
		for _, bagID in next, B.BankFrame.BagIDs do
			if bagID == arg then
				return B.BankFrame
			end
		end
	end

	return B.BagFrame
end


function B:Tooltip_Show()
	GameTooltip:SetOwner(self)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(self.ttText)

	if self.ttText2 then
		if self.ttText2desc then
			GameTooltip:AddLine(' ')
			GameTooltip:AddDoubleLine(self.ttText2, self.ttText2desc, 1, 1, 1)
		else
			GameTooltip:AddLine(self.ttText2)
		end
	end

	if self.ttValue and self.ttValue() > 0 then
		GameTooltip:AddLine(E:FormatMoney(self.ttValue(), B.db.moneyFormat, not B.db.moneyCoins), 1, 1, 1)
	end

	GameTooltip:Show()
end

do
	local function DisableFrame(frame)
		if not frame then return end

		frame:UnregisterAllEvents()
		frame:SetScript('OnShow', nil)
		frame:SetScript('OnHide', nil)
		frame:SetParent(E.HiddenFrame)
		frame:ClearAllPoints()
		frame:Point('BOTTOM')
	end

	function B:DisableBlizzard()
		DisableFrame(_G.BankFrame)

		for i = 1, NUM_CONTAINER_FRAMES do
			_G['ContainerFrame'..i]:Kill()
		end
	end
end

do
	local MIN_REPEAT_CHARACTERS = 3
	function B:SearchUpdate()
		local search = self:GetText()
		if #search > MIN_REPEAT_CHARACTERS then
			local repeating = true
			for i = 1, MIN_REPEAT_CHARACTERS, 1 do
				local x, y = 0-i, -1-i
				if strsub(search, x, x) ~= strsub(search, y, y) then
					repeating = false
					break
				end
			end

			if repeating then
				B:SearchClear()
				return
			end
		end

		B:SetItemSearch(search)
	end
end

function B:SearchRefresh()
	local text = B.BagFrame.editBox:GetText()

	B:SearchClear()

	B.BagFrame.editBox:SetText(text)
end

function B:SearchClear()
	B.BagFrame.editBox:SetText('')
	B.BagFrame.editBox:ClearFocus()

	B.BankFrame.editBox:SetText('')
	B.BankFrame.editBox:ClearFocus()

	B:SetItemSearch('')
end

function B:UpdateItemDisplay()
	if not E.private.bags.enable then return end

	for _, bagFrame in next, B.BagFrames do
		for _, bag in next, bagFrame.Bags do
			for _, slot in ipairs(bag) do
				if B.db.itemLevel then
					B:UpdateItemLevel(slot)
				else
					slot.itemLevel:SetText('')
				end

				slot.itemLevel:ClearAllPoints()
				slot.itemLevel:Point(B.db.itemLevelPosition, B.db.itemLevelxOffset, B.db.itemLevelyOffset)
				slot.itemLevel:FontTemplate(LSM:Fetch('font', B.db.itemLevelFont), B.db.itemLevelFontSize, B.db.itemLevelFontOutline)

				if B.db.itemLevelCustomColorEnable then
					slot.itemLevel:SetTextColor(B.db.itemLevelCustomColor.r, B.db.itemLevelCustomColor.g, B.db.itemLevelCustomColor.b)
				else
					local r, g, b = B:GetItemQualityColor(slot.rarity)
					slot.itemLevel:SetTextColor(r, g, b)
				end

				slot.bindType:FontTemplate(LSM:Fetch('font', B.db.itemLevelFont), B.db.itemLevelFontSize, B.db.itemLevelFontOutline)

				slot.Count:ClearAllPoints()
				slot.Count:Point(B.db.countPosition, B.db.countxOffset, B.db.countyOffset)
				slot.Count:FontTemplate(LSM:Fetch('font', B.db.countFont), B.db.countFontSize, B.db.countFontOutline)
			end
		end
	end
end

function B:UpdateAllSlots(frame, first)
	for _, bagID in next, frame.BagIDs do
		local holder = first and frame.isBank and (bagID and bagID ~= BANK_CONTAINER) and frame.ContainerHolderByBagID[bagID]
		if holder then -- updates the slot icons on first open
			B:SetBagAssignments(holder)
		end

		B:UpdateBagSlots(frame, bagID)
	end
end

function B:UpdateAllBagSlots()
	if not E.private.bags.enable then return end

	for _, bagFrame in pairs(B.BagFrames) do
		B:UpdateAllSlots(bagFrame)
	end
end

function B:IsItemEligibleForItemLevelDisplay(itemType, subType, equipLoc, rarity)
	return (B.IsEquipmentSlot[equipLoc] or (itemType == 'Miscellaneous' and subType == 'Quiver')) and (rarity and rarity > 1)
end

function B:GetItemQualityColor(rarity)
	if rarity then
		return GetItemQualityColor(rarity)
	else
		return 1, 1, 1
	end
end

function B:UpdateSlotColors(slot, isQuestItem, questId, isActiveQuest)
	local questColors, r, g, b, a = B.db.qualityColors and (questId or isQuestItem) and B.QuestColors[not isActiveQuest and 'questStarter' or 'questItem']
	local qR, qG, qB = B:GetItemQualityColor(slot.rarity)

	if slot.itemLevel then
		if B.db.itemLevelCustomColorEnable then
			slot.itemLevel:SetTextColor(B.db.itemLevelCustomColor.r, B.db.itemLevelCustomColor.g, B.db.itemLevelCustomColor.b)
		else
			slot.itemLevel:SetTextColor(qR, qG, qB)
		end
	end

	if slot.bindType then
		slot.bindType:SetTextColor(qR, qG, qB)
	end

	if questColors then
		r, g, b, a = unpack(questColors)
	elseif B.db.qualityColors and (slot.rarity and slot.rarity > 1) then
		r, g, b = qR, qG, qB
	else
		local bag = slot.bagFrame.Bags[slot.BagID]
		local colors = bag and (B.db.specialtyColors and B.ProfessionColors[bag.type])
		if colors then
			r, g, b, a = colors.r, colors.g, colors.b, colors.a
		end
	end

	if not a then a = 1 end
	slot.forcedBorderColors = r and {r, g, b, a}
	if not r then r, g, b = unpack(E.media.bordercolor) end

	slot:SetBackdropBorderColor(r, g, b, a)

	if B.db.colorBackdrop then
		local fadeAlpha = B.db.transparent and E.media.backdropfadecolor[4]
		slot:SetBackdropColor(r, g, b, fadeAlpha or a)
	else
		slot:SetBackdropColor(unpack(B.db.transparent and E.media.backdropfadecolor or E.media.backdropcolor))
	end
end

function B:GetItemQuestInfo(itemLink, itemType)
	if itemType == 'Quest' then
		return true, true
	else
		E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		E.ScanTooltip:SetHyperlink(itemLink)
		E.ScanTooltip:Show()

		local isQuestItem, isStarterItem
		for i = BIND_START, BIND_END do
			local line = _G['ElvUI_ScanTooltipTextLeft'..i]:GetText()

			if not line or line == '' then break end
			if not isQuestItem and line == _G.ITEM_BIND_QUEST then isQuestItem = true end
			if not isStarterItem and line == _G.ITEM_STARTS_QUEST then isStarterItem = true end
		end

		E.ScanTooltip:Hide()

		return isQuestItem or isStarterItem, not isStarterItem
	end
end

function B:UpdateItemLevel(slot)
	if slot.itemLink and B.db.itemLevel then
		local canShowItemLevel = B:IsItemEligibleForItemLevelDisplay(slot.itemType, slot.itemSubType, slot.itemEquipLoc, slot.rarity)
		local iLvl = canShowItemLevel and slot.iLvL
		local isShown = iLvl and iLvl >= B.db.itemLevelThreshold

		B.ItemLevelSlots[slot] = isShown or nil

		if isShown then
			slot.itemLevel:SetText(iLvl)
		end
	else
		B.ItemLevelSlots[slot] = nil
	end
end

function B:UpdateSlot(frame, bagID, slotID)
	local bag = frame.Bags[bagID]
	local slot = bag and bag[slotID]
	if not slot then return end

	local keyring = bagID == KEYRING_CONTAINER

	local info = B:GetContainerItemInfo(bagID, slotID)

	slot.name, slot.spellID, slot.itemID, slot.rarity, slot.locked, slot.readable, slot.itemLink = nil, nil, info.itemID, info.quality, info.isLocked, info.isReadable, info.hyperlink
	slot.isJunk = (slot.rarity and slot.rarity == 0) and not info.hasNoValue
	slot.isEquipment, slot.junkDesaturate = nil, slot.isJunk and B.db.junkDesaturate
	slot.hasItem = (info.iconFileID and 1) or nil -- used for ShowInspectCursor

	SetItemButtonTexture(slot, info.iconFileID)
	SetItemButtonCount(slot, info.stackCount)
	SetItemButtonDesaturated(slot, slot.locked or slot.junkDesaturate)

	slot.Count:SetTextColor(B.db.countFontColor.r, B.db.countFontColor.g, B.db.countFontColor.b)
	slot.itemLevel:SetText('')
	slot.bindType:SetText('')

	if keyring then
		slot.keyringTexture:SetShown(not info.iconFileID)
	end

	local isQuestItem, questId, isActiveQuest
	if slot.itemLink then
		local _, spellID = GetItemSpell(slot.itemLink)
		local name, _, _, iLvL, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(slot.itemLink)
		slot.name, slot.spellID, slot.isEquipment, slot.itemEquipLoc, slot.itemType, slot.itemSubType, slot.iLvL = name, spellID, B.IsEquipmentSlot[itemEquipLoc], itemEquipLoc, itemType, itemSubType, iLvL

		local questInfo = B:GetContainerItemQuestInfo(bagID, slotID)
		isQuestItem, questId, isActiveQuest = questInfo.isQuestItem, questInfo.questID, questInfo.isActive
		local r, g, b

		if slot.rarity then
			r, g, b = GetItemQualityColor(slot.rarity)
		end

		if B.db.showBindType and (slot.rarity and slot.rarity > 1) then
			local bindTypeLines = B:GetBindLines()
			local BoE, BoU
			for i = 2, bindTypeLines do
				local line = _G['ElvUI_ScanTooltipTextLeft'..i]:GetText()
				if (not line or line == '') or (line == ITEM_SOULBOUND or line == ITEM_ACCOUNTBOUND or line == ITEM_BNETACCOUNTBOUND) then break end

				BoE, BoU = line == ITEM_BIND_ON_EQUIP, line == ITEM_BIND_ON_USE

				if not B.db.showBindType and (slot.rarity and slot.rarity > 1) or (BoE or BoU) then break end
			end

			if BoE or BoU then
				slot.bindType:SetText(BoE and L["BoE"] or L["BoU"])
				slot.bindType:SetVertexColor(r, g, b)
			end
		end
	end

	if slot.spellID then
		B:UpdateCooldown(slot)
		slot:RegisterEvent('BAG_UPDATE_COOLDOWN')
		slot:RegisterEvent('SPELL_UPDATE_COOLDOWN')
	else
		slot.Cooldown:Hide()
		slot:RegisterEvent('BAG_UPDATE_COOLDOWN')
		slot:UnregisterEvent('SPELL_UPDATE_COOLDOWN')
		SetItemButtonTextureVertexColor(slot, 1, 1, 1)
	end

	B:UpdateItemLevel(slot)
	B:UpdateSlotColors(slot, isQuestItem, questId, isActiveQuest)

	if slot.questIcon then slot.questIcon:SetShown(B.db.questIcon and ((isQuestItem or questId) and not isActiveQuest)) end
	if slot.JunkIcon then slot.JunkIcon:SetShown(slot.isJunk and B.db.junkIcon) end

	if not frame.isBank then
		B.QuestSlots[slot] = questId or nil
	end

	if not slot.hasItem and GameTooltip:GetOwner() == slot then
		GameTooltip:Hide()
	end
end

function B:GetContainerNumSlots(bagID)
	return bagID and (bagID == KEYRING_CONTAINER and GetKeyRingSize() or GetContainerNumSlots(bagID))
end

function B:UpdateBagButtons()
	local playerCombat = UnitAffectingCombat('player')
	B.BagFrame.bagsButton:SetEnabled(not playerCombat)
	B.BagFrame.bagsButton:GetNormalTexture():SetDesaturated(playerCombat)
end

function B:UpdateBagSlots(frame, bagID)
	local slotMax = B:GetContainerNumSlots(bagID)
	for slotID = 1, slotMax do
		B:UpdateSlot(frame, bagID, slotID)
	end
end

function B:SortingFadeBags(bagFrame, sortingSlots)
	if not (bagFrame and bagFrame.BagIDs) then return end
	bagFrame.sortingSlots = sortingSlots

	if bagFrame.spinnerIcon and B.db.spinner.enable then
		local color = E:UpdateClassColor(B.db.spinner.color)
		E:StartSpinner(bagFrame.spinnerIcon, nil, nil, nil, nil, B.db.spinner.size, color.r, color.g, color.b)
	end

	for _, bagID in next, bagFrame.BagIDs do
		local slotMax = B:GetContainerNumSlots(bagID)
		for slotID = 1, slotMax do
			bagFrame.Bags[bagID][slotID].searchOverlay:SetShown(true)
		end
	end
end

function B:Slot_OnEvent(event)
	if event == 'SPELL_UPDATE_COOLDOWN' or event == 'BAG_UPDATE_COOLDOWN' then
		B:UpdateCooldown(self)
	end
end

function B:Slot_OnEnter()
	-- bag keybind support from actionbar module
	if E.private.actionbar.enable then
		AB:BindUpdate(self, 'BAG')
	end
end

function B:Slot_OnLeave() end

function B:Holder_OnReceiveDrag()
	PutItemInBag(self.isBank and self:GetInventorySlot() or self:GetID())
end

function B:Holder_OnDragStart()
	PickupBagFromSlot(self.isBank and self:GetInventorySlot() or self:GetID())
end

function B:Holder_OnClick()
	if self.BagID == BACKPACK_CONTAINER then
		B:BagItemAction(self, PutItemInBackpack)
	elseif self.BagID == KEYRING_CONTAINER then
		B:BagItemAction(self, PutKeyInKeyRing)
	elseif self.isBank then
		B:BagItemAction(self, PutItemInBag, self:GetInventorySlot())
	else
		B:BagItemAction(self, PutItemInBag, self:GetID())
	end
end

function B:Holder_OnEnter()
	if not self.bagFrame then return end

	B:SetSlotAlphaForBag(self.bagFrame, self.BagID)

	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')

	if self.BagID == BACKPACK_CONTAINER then
		local kb = GetBindingKey('TOGGLEBACKPACK')
		GameTooltip:AddLine(kb and format('%s |cffffd200(%s)|r', BACKPACK_TOOLTIP, kb) or BACKPACK_TOOLTIP, 1, 1, 1)
	elseif self.BagID == BANK_CONTAINER then
		GameTooltip:AddLine(L["Bank"], 1, 1, 1)
	elseif self.BagID == KEYRING_CONTAINER then
		GameTooltip:AddLine(_G.KEYRING, 1, 1, 1)
	elseif self.bag.numSlots == 0 then
		GameTooltip:AddLine(_G.EQUIP_CONTAINER, 1, 1, 1)
	elseif self.isBank then
		GameTooltip:SetInventoryItem('player', self:GetInventorySlot())
	else
		GameTooltip:SetInventoryItem('player', self:GetID())
	end

	GameTooltip:AddLine(' ')
	GameTooltip:AddLine(L["Shift + Left Click to Toggle Bag"], .8, .8, .8)
	GameTooltip:Show()
end

function B:Holder_OnLeave()
	if not self.bagFrame then return end

	B:ResetSlotAlphaForBags(self.bagFrame)

	GameTooltip:Hide()
end

function B:Cooldown_OnHide()
	self.start = nil
	self.duration = nil
end

function B:UpdateCooldown(slot)
	local start, duration, enabled = GetContainerItemCooldown(slot.BagID, slot.SlotID)
	if duration and duration > 0 and enabled == 0 then
		SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4)
	else
		SetItemButtonTextureVertexColor(slot, 1, 1, 1)
	end

	local cd = slot.Cooldown
	if duration and duration > 0 and enabled == 1 then
		local newStart, newDuration = not cd.start or cd.start ~= start, not cd.duration or cd.duration ~= duration
		if newStart or newDuration then
			cd:SetCooldown(start, duration)

			cd.start = start
			cd.duration = duration
		end
	else
		cd:Hide()
	end
end

function B:SetSlotAlphaForBag(f, bag)
	for _, bagID in next, f.BagIDs do
		f.Bags[bagID]:SetAlpha(bagID == bag and 1 or .1)
	end
end

function B:ResetSlotAlphaForBags(f)
	for _, bagID in next, f.BagIDs do
		f.Bags[bagID]:SetAlpha(1)
	end
end

function B:Layout(isBank)
	if not E.private.bags.enable then return end

	local f = B:GetContainerFrame(isBank)
	if not f then return end

	local lastButton, lastRowButton, newBag
	local buttonSpacing = isBank and B.db.bankButtonSpacing or B.db.bagButtonSpacing
	local buttonSize = E:Scale(isBank and B.db.bankSize or B.db.bagSize)
	local containerWidth = ((isBank and B.db.bankWidth) or B.db.bagWidth)
	local numContainerColumns = floor(containerWidth / (buttonSize + buttonSpacing))
	local holderWidth = ((buttonSize + buttonSpacing) * numContainerColumns) - buttonSpacing
	local numContainerRows, numBags, numBagSlots = 0, 0, 0
	local bagSpacing = isBank and B.db.split.bankSpacing or B.db.split.bagSpacing
	local isSplit = B.db.split[isBank and 'bank' or 'player']
	local reverseSlots = B.db.reverseSlots

	f.totalSlots = 0
	f.holderFrame:SetWidth(holderWidth)

	if isBank and not f.fullBank then
		f.fullBank = select(2, GetNumBankSlots())
		f.purchaseBagButton:SetShown(not f.fullBank)
	end

	if not isBank then
		local currencies = f.currencyButton
		if B.numTrackedTokens == 0 then
			if f.bottomOffset > 8 then
				f.bottomOffset = 8
			end
		else
			local currentRow = 1

			local rowWidth = 0
			for i = 1, B.numTrackedTokens do
				local token = currencies[i]
				if not token then return end

				local tokenWidth = token.text:GetWidth() + 28
				rowWidth = rowWidth + tokenWidth
				if rowWidth > (B.db.bagWidth - (B.db.bagButtonSpacing * 4)) then
					currentRow = currentRow + 1
					rowWidth = tokenWidth
				end

				token:ClearAllPoints()

				if i == 1 then
					token:Point('TOPLEFT', currencies, 1, -3)
				elseif rowWidth == tokenWidth then
					token:Point('TOPLEFT', currencies, 1 , -3 -(24 * (currentRow - 1)))
				else
					token:Point('TOPLEFT', currencies, rowWidth - tokenWidth , -3 - (24 * (currentRow - 1)))
				end
			end

			local height = 24 * currentRow
			currencies:Height(height)

			local offset = height + 8
			if f.bottomOffset ~= offset then
				f.bottomOffset = offset
			end
		end
	end

	for _, bagID in next, f.BagIDs do
		if isSplit then
			newBag = (bagID ~= BANK_CONTAINER or bagID ~= BACKPACK_CONTAINER) and B.db.split['bag'..bagID] or false
		end

		--Bag Slots
		local bag = f.Bags[bagID]
		local numSlots = B:GetContainerNumSlots(bagID)
		local bagShown = numSlots > 0 and B.db.shownBags['bag'..bagID]

		bag.numSlots = numSlots
		bag:SetShown(bagShown)

		if bagShown then
			for slotID, slot in ipairs(bag) do
				slot:SetShown(slotID <= numSlots)
			end

			for slotID = 1, numSlots do
				f.totalSlots = f.totalSlots + 1

				local slot = bag[slotID]
				slot:SetID(slotID)
				slot:SetSize(buttonSize, buttonSize)

				slot.JunkIcon:SetSize(buttonSize * 0.4, buttonSize * 0.4)

				if slot:GetPoint() then
					slot:ClearAllPoints()
				end

				if lastButton then
					local anchorPoint, relativePoint = (reverseSlots and 'BOTTOM' or 'TOP'), (reverseSlots and 'TOP' or 'BOTTOM')
					if isSplit and newBag and slotID == 1 then
						slot:Point(anchorPoint, lastRowButton, relativePoint, 0, reverseSlots and (buttonSpacing + bagSpacing) or -(buttonSpacing + bagSpacing))
						lastRowButton = slot
						numContainerRows = numContainerRows + 1
						numBags = numBags + 1
						numBagSlots = 0
					elseif isSplit and numBagSlots % numContainerColumns == 0 then
						slot:Point(anchorPoint, lastRowButton, relativePoint, 0, reverseSlots and buttonSpacing or -buttonSpacing)
						lastRowButton = slot
						numContainerRows = numContainerRows + 1
					elseif (not isSplit) and (f.totalSlots - 1) % numContainerColumns == 0 then
						slot:Point(anchorPoint, lastRowButton, relativePoint, 0, reverseSlots and buttonSpacing or -buttonSpacing)
						lastRowButton = slot
						numContainerRows = numContainerRows + 1
					else
						anchorPoint, relativePoint = (reverseSlots and 'RIGHT' or 'LEFT'), (reverseSlots and 'LEFT' or 'RIGHT')
						slot:Point(anchorPoint, lastButton, relativePoint, reverseSlots and -buttonSpacing or buttonSpacing, 0)
					end
				else
					local anchorPoint = reverseSlots and 'BOTTOMRIGHT' or 'TOPLEFT'
					slot:Point(anchorPoint, f.holderFrame, anchorPoint, 0, reverseSlots and f.bottomOffset - 8 or 0)
					lastRowButton = slot
					numContainerRows = numContainerRows + 1
				end

				lastButton = slot
				numBagSlots = numBagSlots + 1
			end
		end
	end

	local buttonsHeight = (((buttonSize + buttonSpacing) * numContainerRows) - buttonSpacing)
	f:SetSize(containerWidth, buttonsHeight + f.topOffset + f.bottomOffset + (isSplit and (numBags * bagSpacing) or 0))
	f:SetFrameStrata(B.db.strata or 'HIGH')
end

function B:TotalSlotsChanged(bagFrame)
	local total = 0
	for _, bagID in next, bagFrame.BagIDs do
		total = total + B:GetContainerNumSlots(bagID)
	end

	return bagFrame.totalSlots ~= total
end

function B:PLAYER_ENTERING_WORLD(event)
	B:UpdateLayout(B.BagFrame)
	B:UnregisterEvent(event)
end

function B:UpdateLayouts()
	B:Layout()
	B:Layout(true)
end

function B:UpdateLayout(frame)
	for index in next, frame.BagIDs do
		if B:SetBagAssignments(frame.ContainerHolder[index]) then
			break
		end
	end
end

function B:UpdateBankBagIcon(holder)
	if not holder then return end

	BankFrameItemButton_Update(holder)

	local numSlots = GetNumBankSlots()
	local color = ((holder.index - 1) <= numSlots) and 1 or 0.1
	holder.icon:SetVertexColor(1, color, color)
end

function B:SetBagAssignments(holder, skip)
	if not holder then return true end

	local frame, bag = holder.frame, holder.bag
	holder:Size(frame.isBank and B.db.bankSize or B.db.bagSize)

	if holder.BagID == KEYRING_CONTAINER then
		bag.type = B.BagIndice.keyring
	else
		bag.type = select(2, GetContainerNumFreeSlots(holder.BagID))
	end

	if not skip and B:TotalSlotsChanged(frame) then
		B:Layout(frame.isBank)
	end

	if frame.isBank and frame:IsShown() then
		if holder.BagID ~= BANK_CONTAINER then
			print(holder:GetName())
			B:UpdateBankBagIcon(holder)
		end

		local containerID = holder.index - 1
		if containerID > GetNumBankSlots() then
			SetItemButtonTextureVertexColor(holder, 1, .1, .1)
			holder.tooltipText = _G.BANK_BAG_PURCHASE

			if not frame.notPurchased[containerID] then
				frame.notPurchased[containerID] = holder
			end
		else
			SetItemButtonTextureVertexColor(holder, 1, 1, 1)
			holder.tooltipText = ''
		end
	end
end

function B:UpdateDelayedContainer(frame)
	for bagID, container in next, frame.DelayedContainers do
		if bagID ~= BACKPACK_CONTAINER then
			B:SetBagAssignments(container)
		end

		local bag = frame.Bags[bagID]
		if bag and bag.needsUpdate then
			B:UpdateBagSlots(frame, bagID)
			bag.needsUpdate = nil
		end

		frame.DelayedContainers[bagID] = nil
	end
end

function B:DelayedContainer(bagFrame, bagID)
	local container = bagID and bagFrame.ContainerHolderByBagID[bagID]
	if container then
		bagFrame.DelayedContainers[bagID] = container

		if not bagFrame:IsShown() then -- let it call layout
			bagFrame.totalSlots = 0
		else
			bagFrame.Bags[bagID].needsUpdate = true
		end
	end
end

function B:OnEvent(event, ...)
	if event == 'PLAYERBANKBAGSLOTS_CHANGED' then
		local containerID, holder = next(self.notPurchased)
		if containerID then
			B:SetBagAssignments(holder, true)
			self.notPurchased[containerID] = nil
		end
	elseif event == 'PLAYERBANKSLOTS_CHANGED' then
		local slotID = ...
		local index = (slotID <= NUM_BANKGENERIC_SLOTS) and BANK_CONTAINER or (slotID - NUM_BANKGENERIC_SLOTS)
		local default = index == BANK_CONTAINER
		local bagID = self.BagIDs[default and 1 or index+1]
		if not bagID then return end

		if self:IsShown() then -- when its shown we only want to update the default bank bags slot
			if default then -- the other bags are handled by BAG_UPDATE
				B:UpdateSlot(B.BankFrame, bagID, slotID)
			end
		else
			local bag = self.Bags[bagID]
			self.staleBags[bagID] = bag

			if default then
				bag.staleSlots[slotID] = true
			end
		end
	elseif event == 'BAG_UPDATE' then
		B:UpdateContainerIcons()
		B:UpdateBagSlots(self, ...)

		-- if not self.isBank or self:IsShown() then
		-- 	local bagID = ...
		-- 	B:DelayedContainer(self, event, bagID)
		-- end
		E:Delay(0.5, function()
			B:UpdateDelayedContainer(self)
		end)
	elseif (event == 'QUEST_ACCEPTED' or event == 'QUEST_REMOVED' or event == 'QUEST_LOG_UPDATE') and self:IsShown() then
		for slot in next, B.QuestSlots do
			B:UpdateSlot(self, slot.BagID, slot.SlotID)
		end
	elseif event == 'ITEM_LOCK_CHANGED' or event == 'ITEM_UNLOCKED' then
		B:UpdateSlot(self, ...)
	end
end

function B:UpdateTokensIfVisible()
	if B.BagFrame:IsVisible() then
		B:UpdateTokens()
	end
end

function B:UpdateTokens()
	local bagFrame = B.BagFrame
	local currencies = bagFrame.currencyButton
	for _, button in ipairs(currencies) do
		button:Hide()
	end

	local currencyFormat = B.db.currencyFormat
	local numCurrencies = currencyFormat ~= 'NONE' and MAX_WATCHED_TOKENS or 0

	local numTokens = 0
	for i = 1, numCurrencies do
		local info = B:GetBackpackCurrencyInfo(i)
		if not (info and info.name) then break end

		local button = currencies[i]
		button.currencyID = info.currencyTypesID
		button:Show()

		if button.currencyID and E.Wrath then
			local tokens = _G.TokenFrameContainer.buttons
			if tokens then
				for _, token in next, tokens do
					if token.itemID == button.currencyID then
						button.index = token.index
						break
					end
				end
			end
		end

		local icon = button.icon or button.Icon
		icon:SetTexture(info.iconFileID)

		if B.db.currencyFormat == 'ICON_TEXT' then
			button.text:SetText(info.name..': '..BreakUpLargeNumbers(info.quantity))
		elseif B.db.currencyFormat == 'ICON_TEXT_ABBR' then
			button.text:SetText(E:AbbreviateString(info.name)..': '..BreakUpLargeNumbers(info.quantity))
		elseif B.db.currencyFormat == 'ICON' then
			button.text:SetText(BreakUpLargeNumbers(info.quantity))
		end

		numTokens = numTokens + 1
	end

	if numTokens ~= B.numTrackedTokens then
		B.numTrackedTokens = numTokens
		B:Layout()
	end
end

function B:UpdateGoldText()
	B.BagFrame.goldText:SetShown(B.db.moneyFormat ~= 'HIDE')
	B.BagFrame.goldText:SetText(E:FormatMoney(GetMoney() - GetCursorMoney() - GetPlayerTradeMoney(), B.db.moneyFormat, not B.db.moneyCoins))
end

B.ExcludeGrays = {
	[3300] = "Rabbit's Foot",
	[3670] = "Large Slimy Bone",
	[6150] = "A Frayed Knot",
	[11406] = "Rotting Bear Carcass",
	[11944] = "Dark Iron Baby Booties",
	[25402] = "The Stoppable Force",
	[30507] = "Lucky Rock",
	[36812] = "Ground Gear",
	[32888] = "The Relics of Terokk",
	[28664] = "Nitrin's Instructions",
}

function B:GetGrays(vendor)
	local value = 0

	for bagID = 0, 4 do
		for slotID = 1, B:GetContainerNumSlots(bagID) do
			local info = B:GetContainerItemInfo(bagID, slotID)
			local itemLink = info.hyperlink
			if itemLink and not info.hasNoValue and not B.ExcludeGrays[info.itemID] then
				local _, _, rarity, _, _, itemType, _, _, _, _, itemPrice = GetItemInfo(itemLink)

				if (rarity and rarity == 0) and (itemType and itemType ~= 'Quest') and (itemPrice and itemPrice > 0) then
					local stackCount = info.stackCount or 1
					local stackPrice = itemPrice * stackCount

					if vendor then
						tinsert(B.SellFrame.Info.itemList, {bagID, slotID, itemLink, stackCount, stackPrice})
					elseif stackPrice > 0 then
						value = value + stackPrice
					end
				end
			end
		end
	end

	return value
end

function B:GetGraysValue()
	return B:GetGrays()
end

function B:VendorGrays(delete)
	if B.SellFrame:IsShown() then return end

	if not delete and (not _G.MerchantFrame or not _G.MerchantFrame:IsShown()) then
		E:Print(L["You must be at a vendor."])
		return
	end

	-- our sell grays
	B:GetGrays(true)

	local numItems = #B.SellFrame.Info.itemList
	if numItems < 1 then return end

	-- Resetting stuff
	B.SellFrame.Info.delete = delete or false
	B.SellFrame.Info.ProgressTimer = 0
	B.SellFrame.Info.SellInterval = 0.2
	B.SellFrame.Info.ProgressMax = numItems
	B.SellFrame.Info.goldGained = 0
	B.SellFrame.Info.itemsSold = 0

	B.SellFrame.statusbar:SetValue(0)
	B.SellFrame.statusbar:SetMinMaxValues(0, B.SellFrame.Info.ProgressMax)
	B.SellFrame.statusbar.ValueText:SetText('0 / '..B.SellFrame.Info.ProgressMax)

	if not delete then -- Time to sell
		B.SellFrame:Show()
	end
end

function B:VendorGrayCheck()
	local value = B:GetGraysValue()
	if value == 0 then
		E:Print(L["No gray items to delete."])
	elseif not _G.MerchantFrame:IsShown() then
		E.PopupDialogs.DELETE_GRAYS.Money = value
		E:StaticPopup_Show('DELETE_GRAYS')
	else
		B:VendorGrays()
	end
end

function B:SetButtonTexture(button, texture)
	button:SetNormalTexture(texture)
	button:SetPushedTexture(texture)
	button:SetDisabledTexture(texture)

	local Normal, Pushed, Disabled = button:GetNormalTexture(), button:GetPushedTexture(), button:GetDisabledTexture()

	local left, right, top, bottom = unpack(E.TexCoords)
	Normal:SetTexCoord(left, right, top, bottom)
	Normal:SetInside()

	Pushed:SetTexCoord(left, right, top, bottom)
	Pushed:SetInside()

	Disabled:SetTexCoord(left, right, top, bottom)
	Disabled:SetInside()
	Disabled:SetDesaturated(true)
end

function B:BagItemAction(holder, func, id)
	if CursorHasItem() then
		if func then func(id) end
	elseif IsShiftKeyDown() then
		B:ToggleBag(holder)
	end
end

function B:SetBagShownTexture(icon, shown)
	local texture = shown and (_G.READY_CHECK_READY_TEXTURE or READY_TEX) or (_G.READY_CHECK_NOT_READY_TEXTURE or NOT_READY_TEX)
	icon:SetTexture(texture)
end

function B:ToggleBag(holder)
	if not holder then return end

	local slotID = 'bag'..holder.BagID
	local swap = not B.db.shownBags[slotID]
	B.db.shownBags[slotID] = swap

	B:SetBagShownTexture(holder.shownIcon, swap)
	B:Layout(holder.isBank)
end

function B:UpdateContainerIcons()
	if not B.BagFrame then return end

	-- this only executes for the main bag, the bank bag doesn't use this
	for bagID, holder in next, B.BagFrame.ContainerHolderByBagID do
		B:UpdateContainerIcon(holder, bagID)
	end
end

function B:UpdateContainerIcon(holder, bagID)
	if not holder or not bagID or bagID == BACKPACK_CONTAINER or bagID == KEYRING_CONTAINER then return end

	holder.icon:SetTexture(GetInventoryItemTexture('player', holder:GetID()) or [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])
end

function B:UnregisterBagEvents(bagFrame)
	bagFrame:UnregisterAllEvents() -- Unregister to prevent unnecessary updates during sorting
end

function B:ConstructContainerFrame(name, isBank)
	local strata = B.db.strata or 'HIGH'

	local f = CreateFrame('Button', name, E.UIParent)
	f:SetTemplate('Transparent')
	f:SetFrameStrata(strata)

	f.events = (isBank and bankEvents) or bagEvents
	f.DelayedContainers = {}
	f.firstOpen = true
	f:Hide()

	f.isBank = isBank
	f.topOffset = 50
	f.bottomOffset = 8
	f.BagIDs = (isBank and bankIDs) or bagIDs
	f.staleBags = {} -- used to keep track of bank items that need update on next open
	f.Bags = {}

	local mover = (isBank and _G.ElvUIBankMover) or _G.ElvUIBagMover
	if mover then
		f:Point(mover.POINT, mover)
		f.mover = mover
	end

	--Allow dragging the frame around
	f:SetMovable(true)
	f:RegisterForDrag('LeftButton', 'RightButton')
	f:RegisterForClicks('AnyUp')
	f:SetScript('OnEvent', B.OnEvent)
	f:SetScript('OnShow', B.ContainerOnShow)
	f:SetScript('OnHide', B.ContainerOnHide)
	f:SetScript('OnDragStart', function(frame) if IsShiftKeyDown() then frame:StartMoving() end end)
	f:SetScript('OnDragStop', function(frame) frame:StopMovingOrSizing() end)
	f:SetScript('OnClick', function(frame) if IsControlKeyDown() then B.PostBagMove(frame.mover) end end)

	f.closeButton = CreateFrame('Button', name..'CloseButton', f, 'UIPanelCloseButton')
	f.closeButton:Point('TOPRIGHT', 5, 5)

	f.helpButton = CreateFrame('Button', name..'HelpButton', f)
	f.helpButton:Point('RIGHT', f.closeButton, 'LEFT', 0, 0)
	f.helpButton:Size(16)
	B:SetButtonTexture(f.helpButton, E.Media.Textures.Help)
	f.helpButton:SetScript('OnLeave', GameTooltip_Hide)
	f.helpButton:SetScript('OnEnter', function(frame)
		GameTooltip:SetOwner(frame, 'ANCHOR_TOPLEFT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Hold Shift + Drag:"], L["Temporary Move"], 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Hold Control + Right Click:"], L["Reset Position"], 1, 1, 1)
		GameTooltip:Show()
	end)

	S:HandleCloseButton(f.closeButton)

	f.holderFrame = CreateFrame('Frame', nil, f)
	f.holderFrame:Point('TOP', f, 'TOP', 0, -f.topOffset)
	f.holderFrame:Point('BOTTOM', f, 'BOTTOM', 0, 8)

	f.ContainerHolder = CreateFrame('Button', name..'ContainerHolder', f)
	f.ContainerHolder:Point('BOTTOMLEFT', f, 'TOPLEFT', 0, 1)
	f.ContainerHolder:SetTemplate('Transparent')
	f.ContainerHolder:Hide()
	f.ContainerHolder.totalBags = #f.BagIDs
	f.ContainerHolderByBagID = {}

	for i, bagID in next, f.BagIDs do
		local bagNum = isBank and (bagID == BANK_CONTAINER and 0 or (bagID - bankOffset)) or (bagID - 1)
		local holderName = bagID == BACKPACK_CONTAINER and 'ElvUIMainBagBackpack' or bagID == KEYRING_CONTAINER and 'ElvUIKeyRing' or format('ElvUI%sBag%d%s', isBank and 'Bank' or 'Main', bagNum, 'Slot')
		local inherit = isBank and 'BankItemButtonBagTemplate' or (bagID == BACKPACK_CONTAINER or bagID == KEYRING_CONTAINER) and 'ItemButtonTemplate' or 'BagSlotButtonTemplate'

		local holder = CreateFrame('CheckButton', holderName, f.ContainerHolder, inherit)
		f.ContainerHolderByBagID[bagID] = holder
		f.ContainerHolder[i] = holder

		holder.model = CreateFrame('Model', '$parentItemAnim', holder, 'ItemAnimTemplate')
		holder.model:SetPoint('BOTTOMRIGHT', -10, 0)

		holder.name = holderName
		holder.isBank = isBank
		holder.bagFrame = f
		holder.UpdateTooltip = nil -- This is needed to stop constant updates. It will still get updated by OnEnter.

		holder:SetTemplate(B.db.transparent and 'Transparent', true)
		holder:StyleButton()

		holder:SetNormalTexture(E.ClearTexture)
		holder:SetPushedTexture(E.ClearTexture)
		if holder.SetCheckedTexture then
			holder:SetCheckedTexture(E.ClearTexture)
		end

		holder:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		holder:SetScript('OnEnter', B.Holder_OnEnter)
		holder:SetScript('OnLeave', B.Holder_OnLeave)
		holder:SetScript('OnClick', B.Holder_OnClick)

		holder.icon = holder:CreateTexture(nil, 'ARTWORK')
		holder.icon:SetTexCoord(unpack(E.TexCoords))
		holder.icon:SetTexture(bagID == KEYRING_CONTAINER and [[Interface\ICONS\INV_Misc_Key_03]] or E.Media.Textures.Backpack)
		holder.icon:SetInside()

		holder.shownIcon = holder:CreateTexture(nil, 'OVERLAY')
		holder.shownIcon:Size(16)
		holder.shownIcon:Point('BOTTOMLEFT', 1, 1)

		B:SetBagShownTexture(holder.shownIcon, B.db.shownBags['bag'..bagID])

		if bagID == BACKPACK_CONTAINER then
			holder:SetScript('OnReceiveDrag', PutItemInBackpack)
		elseif bagID == KEYRING_CONTAINER then
			holder:SetScript('OnReceiveDrag', PutKeyInKeyRing)
		else
			holder:RegisterForDrag('LeftButton')
			holder:SetScript('OnDragStart', B.Holder_OnDragStart)
			holder:SetScript('OnReceiveDrag', B.Holder_OnReceiveDrag)
			if isBank then
				holder:SetID(i == 1 and BANK_CONTAINER or (bagID - bankOffset))
				holder:RegisterEvent('PLAYERBANKSLOTS_CHANGED')
				holder:SetScript('OnEvent', BankFrameItemButton_UpdateLocked)
			else
				holder:SetID(ContainerIDToInventoryID(bagID))

				B:UpdateContainerIcon(holder, bagID)
			end
		end

		if i == 1 then
			holder:Point('BOTTOMLEFT', f, 'TOPLEFT', 4, 5)
		else
			holder:Point('LEFT', f.ContainerHolder[i - 1], 'RIGHT', 4, 0)
		end

		if i == f.ContainerHolder.totalBags then
			f.ContainerHolder:Point('TOPRIGHT', holder, 4, 4)
		end

		local bagName = format('%sBag%d', name, bagNum)
		local bag = CreateFrame('Frame', bagName, f.holderFrame)
		bag.holder = holder
		bag.name = bagName
		bag:SetID(bagID)

		holder.BagID = bagID
		holder.bag = bag
		holder.frame = f
		holder.index = i

		f.Bags[bagID] = bag

		if bagID == BANK_CONTAINER then
			bag.staleSlots = {}
		end

		for slotID = 1, MAX_CONTAINER_ITEMS do
			bag[slotID] = B:ConstructContainerButton(f, bagID, slotID)
		end
	end

	f.stackButton = CreateFrame('Button', name..'StackButton', f.holderFrame)
	f.stackButton:Size(18)
	f.stackButton:SetTemplate()
	B:SetButtonTexture(f.stackButton, E.Media.Textures.Planks)
	f.stackButton:StyleButton(nil, true)
	f.stackButton:SetScript('OnEnter', B.Tooltip_Show)
	f.stackButton:SetScript('OnLeave', GameTooltip_Hide)

	--Sort Button
	f.sortButton = CreateFrame('Button', name..'SortButton', f)
	f.sortButton:Point('RIGHT', f.stackButton, 'LEFT', -5, 0)
	f.sortButton:Size(18)
	f.sortButton:SetTemplate()
	B:SetButtonTexture(f.sortButton, E.Media.Textures.PetBroom)
	f.sortButton:StyleButton(nil, true)
	f.sortButton.ttText = L["Sort Bags"]
	f.sortButton:SetScript('OnEnter', B.Tooltip_Show)
	f.sortButton:SetScript('OnLeave', GameTooltip_Hide)

	if isBank and B.db.disableBankSort or (not isBank and B.db.disableBagSort) then
		f.sortButton:Disable()
	end

	--Toggle Bags Button
	f.bagsButton = CreateFrame('Button', name..'BagsButton', f.holderFrame)
	f.bagsButton:Size(18)
	f.bagsButton:Point('RIGHT', f.sortButton, 'LEFT', -5, 0)
	f.bagsButton:SetTemplate()
	B:SetButtonTexture(f.bagsButton, E.Media.Textures.Backpack)
	f.bagsButton:StyleButton(nil, true)
	f.bagsButton.ttText = L["Toggle Bags"]
	f.bagsButton:SetScript('OnEnter', B.Tooltip_Show)
	f.bagsButton:SetScript('OnLeave', GameTooltip_Hide)

	--Search
	f.editBox = CreateFrame('EditBox', name..'EditBox', f)
	S:HandleEditBox(f.editBox, nil, true)
	f.editBox:FontTemplate()
	f.editBox:Height(16)
	f.editBox:SetAutoFocus(false)
	f.editBox:SetFrameLevel(10)
	f.editBox:SetScript('OnEditFocusGained', EditBox_HighlightText)
	f.editBox:HookScript('OnTextChanged', B.SearchUpdate)
	f.editBox:SetScript('OnEscapePressed', B.SearchClear)
	f.editBox.clearButton:HookScript('OnClick', B.SearchClear)

	--Spinner
	f.spinnerIcon = CreateFrame('Frame', name..'SpinnerIcon', f.holderFrame)
	f.spinnerIcon:SetFrameLevel(20)
	f.spinnerIcon:EnableMouse(false)
	f.spinnerIcon:Hide()

	if isBank then
		f.notPurchased = {}
		f.fullBank = select(2, GetNumBankSlots())

		--Bank Text
		f.bankText = f:CreateFontString(nil, 'OVERLAY')
		f.bankText:FontTemplate()
		f.bankText:Point('RIGHT', f.helpButton, 'LEFT', -5, -2)
		f.bankText:SetJustifyH('RIGHT')
		f.bankText:SetText(L["Bank"])

		-- Stack
		f.stackButton:Point('BOTTOMRIGHT', f.holderFrame, 'TOPRIGHT', -2, 4)
		f.stackButton.ttText = L["Stack Items In Bank"]
		f.stackButton.ttText2 = L["Hold Shift:"]
		f.stackButton.ttText2desc = L["Stack Items To Bags"]
		f.stackButton:SetScript('OnEnter', B.Tooltip_Show)
		f.stackButton:SetScript('OnLeave', GameTooltip_Hide)
		f.stackButton:SetScript('OnClick', function()
			if IsShiftKeyDown() then
				B:CommandDecorator(B.Stack, 'bank bags')()
			else
				B:CommandDecorator(B.Compress, 'bank')()
			end
		end)

		--Sort Button
		f.sortButton:SetScript('OnClick', function()
			if f.holderFrame:IsShown() then
				B:UnregisterBagEvents(f)

				if not f.sortingSlots then B:SortingFadeBags(f, true) end
				B:CommandDecorator(B.SortBags, 'bank')()
			end
		end)

		--Toggle Bags Button
		f.bagsButton:SetScript('OnClick', function()
			ToggleFrame(f.ContainerHolder)
			PlaySound(852) --IG_MAINMENU_OPTION
		end)

		f.purchaseBagButton = CreateFrame('Button', nil, f.holderFrame)
		f.purchaseBagButton:SetShown(not f.fullBank)
		f.purchaseBagButton:Size(18)
		f.purchaseBagButton:SetTemplate()
		f.purchaseBagButton:Point('RIGHT', f.bagsButton, 'LEFT', -5, 0)
		B:SetButtonTexture(f.purchaseBagButton, [[Interface\ICONS\INV_Misc_Coin_01]])
		f.purchaseBagButton:StyleButton(nil, true)
		f.purchaseBagButton.ttText = L["Purchase Bags"]
		f.purchaseBagButton:SetScript('OnEnter', B.Tooltip_Show)
		f.purchaseBagButton:SetScript('OnLeave', GameTooltip_Hide)
		f.purchaseBagButton:SetScript('OnClick', function()
			local _, full = GetNumBankSlots()
			if full then
				E:StaticPopup_Show('CANNOT_BUY_BANK_SLOT')
			else
				E:StaticPopup_Show('BUY_BANK_SLOT')
			end
		end)

		--Search
		f.editBox:Point('BOTTOMLEFT', f.holderFrame, 'TOPLEFT', E.Border, 4)
	else
		--Gold Text
		f.goldText = f:CreateFontString(nil, 'OVERLAY')
		f.goldText:FontTemplate()
		f.goldText:Point('RIGHT', f.helpButton, 'LEFT', -10, -2)
		f.goldText:SetJustifyH('RIGHT')

		f.pickupGold = CreateFrame('Button', nil, f)
		f.pickupGold:SetAllPoints(f.goldText)
		f.pickupGold:SetScript('OnClick', function()
			E:StaticPopup_Show('PICKUP_MONEY')
		end)

		-- Stack/Transfer Button
		f.stackButton.ttText = L["Stack Items In Bags"]
		f.stackButton.ttText2 = L["Hold Shift:"]
		f.stackButton.ttText2desc = L["Stack Items To Bank"]
		f.stackButton:Point('BOTTOMRIGHT', f.holderFrame, 'TOPRIGHT', 0, 3)
		f.stackButton:SetScript('OnClick', function()
			B:UnregisterBagEvents(f)

			if not f.sortingSlots then f.sortingSlots = true end
			if IsShiftKeyDown() then
				B:CommandDecorator(B.Stack, 'bags bank')()
			else
				B:CommandDecorator(B.Compress, 'bags')()
			end
		end)

		--Sort Button
		f.sortButton:SetScript('OnClick', function()
			B:UnregisterBagEvents(f)

			if not f.sortingSlots then B:SortingFadeBags(f, true) end
			B:CommandDecorator(B.SortBags, 'bags')()
		end)

		--Bags Button
		f.bagsButton:SetScript('OnClick', function() ToggleFrame(f.ContainerHolder) end)

		--Keyring Button
		f.keyButton = CreateFrame('Button', name..'KeyButton', f.holderFrame)
		f.keyButton:Size(18)
		f.keyButton:SetTemplate()
		f.keyButton:Point('RIGHT', f.bagsButton, 'LEFT', -5, 0)
		B:SetButtonTexture(f.keyButton, [[Interface\ICONS\INV_Misc_Key_03]])
		f.keyButton:StyleButton(nil, true)
		f.keyButton.ttText = BINDING_NAME_TOGGLEKEYRING
		f.keyButton:SetScript('OnEnter', B.Tooltip_Show)
		f.keyButton:SetScript('OnLeave', GameTooltip_Hide)
		f.keyButton:SetScript('OnClick', function() B:ToggleBag(f.ContainerHolderByBagID[KEYRING_CONTAINER]) end)

		--Vendor Grays
		f.vendorGraysButton = CreateFrame('Button', nil, f.holderFrame)
		f.vendorGraysButton:Size(18)
		f.vendorGraysButton:SetTemplate()
		f.vendorGraysButton:Point('RIGHT', f.keyButton, 'LEFT', -5, 0)
		B:SetButtonTexture(f.vendorGraysButton, [[Interface\ICONS\INV_Misc_Coin_01]])
		f.vendorGraysButton:StyleButton(nil, true)
		f.vendorGraysButton.ttText = L["Vendor / Delete Grays"]
		f.vendorGraysButton.ttValue = B.GetGraysValue
		f.vendorGraysButton:SetScript('OnEnter', B.Tooltip_Show)
		f.vendorGraysButton:SetScript('OnLeave', GameTooltip_Hide)
		f.vendorGraysButton:SetScript('OnClick', B.VendorGrayCheck)

		--Search
		f.editBox:Point('BOTTOMLEFT', f.holderFrame, 'TOPLEFT', E.Border, 4)
		f.editBox:Point('RIGHT', f.vendorGraysButton, 'LEFT', -5, 0)

		--Currency
		f.currencyButton = CreateFrame('Frame', nil, f)
		f.currencyButton:Point('BOTTOM', 0, -6)
		f.currencyButton:Point('BOTTOMLEFT', f.holderFrame, 'BOTTOMLEFT', 0, -6)
		f.currencyButton:Point('BOTTOMRIGHT', f.holderFrame, 'BOTTOMRIGHT', 0, -6)
		f.currencyButton:Height(22)

		for i = 1, MAX_WATCHED_TOKENS do
			local currency = CreateFrame('Button', format('%sCurrencyButton%d', name, i), f.currencyButton, 'BackpackTokenTemplate')
			currency:Size(18)
			currency:SetTemplate()
			currency:SetID(i)

			local icon = currency.icon
			icon:SetInside()
			icon:SetTexCoord(unpack(E.TexCoords))
			icon:SetDrawLayer('ARTWORK', 7)

			currency.text = currency:CreateFontString(nil, 'OVERLAY')
			currency.text:Point('LEFT', currency, 'RIGHT', 2, 0)
			currency.text:FontTemplate()
			currency:Hide()

			f.currencyButton[i] = currency
		end
	end

	tinsert(_G.UISpecialFrames, name)
	tinsert(B.BagFrames, f)

	return f
end

function B:ConstructContainerButton(f, bagID, slotID)
	local bag = f.Bags[bagID]
	local slotName = bag.name..'Slot'..slotID
	local parent = bag
	local inherit = bagID == BANK_CONTAINER and 'BankItemButtonGenericTemplate' or 'ContainerFrameItemButtonTemplate'

	local slot = CreateFrame('CheckButton', slotName, parent, inherit)
	slot:StyleButton()
	slot:SetTemplate(B.db.transparent and 'Transparent', true)
	slot:SetScript('OnEvent', B.Slot_OnEvent)
	slot:HookScript('OnEnter', B.Slot_OnEnter)
	slot:HookScript('OnLeave', B.Slot_OnLeave)
	slot:SetID(slotID)

	slot:SetNormalTexture(E.ClearTexture)
	if slot.SetCheckedTexture then
		slot:SetCheckedTexture(E.ClearTexture)
	end

	slot.bagFrame = f
	slot.BagID = bagID
	slot.SlotID = slotID
	slot.name = slotName

	slot.Count = _G[slotName..'Count']
	slot.Count:ClearAllPoints()
	slot.Count:Point(B.db.countPosition, B.db.countxOffset, B.db.countyOffset)
	slot.Count:FontTemplate(LSM:Fetch('font', B.db.countFont), B.db.countFontSize, B.db.countFontOutline)

	if not slot.questIcon then
		slot.questIcon = _G[slotName..'IconQuestTexture'] or _G[slotName].IconQuestTexture
		slot.questIcon:SetTexture(E.Media.Textures.BagQuestIcon)
		slot.questIcon:SetTexCoord(0, 1, 0, 1)
		slot.questIcon:SetInside()
		slot.questIcon:Hide()
	end

	if not slot.JunkIcon then
		slot.JunkIcon = slot:CreateTexture(nil, 'OVERLAY')
		slot.JunkIcon:SetTexture(E.Media.Textures.BagJunkIcon)
		slot.JunkIcon:Point('TOPRIGHT', -1, -1)
		slot.JunkIcon:Hide()
	end

	if bagID == KEYRING_CONTAINER then
		slot.keyringTexture = slot:CreateTexture(nil, 'BORDER')
		slot.keyringTexture:SetAlpha(0.5)
		slot.keyringTexture:SetInside(slot)
		slot.keyringTexture:SetTexture([[Interface\ContainerFrame\KeyRing-Bag-Icon]])
		slot.keyringTexture:SetTexCoord(unpack(E.TexCoords))
		slot.keyringTexture:SetDesaturated(true)
	end

	if not slot.searchOverlay then
		slot.searchOverlay = slot:CreateTexture(nil, 'OVERLAY')
		slot.searchOverlay:SetTexture(0, 0, 0, 0.6)
		slot.searchOverlay:SetVertexColor(0, 0, 0)
		slot.searchOverlay:SetAllPoints()
		slot.searchOverlay:Hide()
	end

	slot.Cooldown = _G[slotName..'Cooldown']
	slot.Cooldown:HookScript('OnHide', B.Cooldown_OnHide)
	E:RegisterCooldown(slot.Cooldown, 'bags')

	slot.icon = _G[slotName..'IconTexture']
	slot.icon:SetInside()
	slot.icon:SetTexCoord(unpack(E.TexCoords))

	slot.itemLevel = slot:CreateFontString(nil, 'ARTWORK', nil, 1)
	slot.itemLevel:Point(B.db.itemLevelPosition, B.db.itemLevelxOffset, B.db.itemLevelyOffset)
	slot.itemLevel:FontTemplate(LSM:Fetch('font', B.db.itemLevelFont), B.db.itemLevelFontSize, B.db.itemLevelFontOutline)

	slot.bindType = slot:CreateFontString(nil, 'ARTWORK', nil, 1)
	slot.bindType:Point('TOP', 0, -2)
	slot.bindType:FontTemplate(LSM:Fetch('font', B.db.itemLevelFont), B.db.itemLevelFontSize, B.db.itemLevelFontOutline)

	return slot
end

function B:ToggleBags(bagID)
	if E.private.bags.bagBar and bagID == KEYRING_CONTAINER then
		local closed = not B.BagFrame:IsShown()
		B.ShowKeyRing = closed or not B.ShowKeyRing

		B:Layout()

		if closed then
			B:OpenBags()
		end
	elseif bagID and B:GetContainerNumSlots(bagID) ~= 0 then
		if B.BagFrame:IsShown() then
			B:CloseBags()
		else
			B:OpenBags()
		end
	end
end

function B:ToggleBackpack()
	if IsOptionFrameOpen() then return end

	if IsBagOpen(0) then
		B:OpenBags()
	else
		B:CloseBags()
	end
end

function B:OpenAllBags(frame)
	local mail = frame == _G.MailFrame and frame:IsShown()
	local vendor = frame == _G.MerchantFrame and frame:IsShown()

	if (not mail and not vendor) or (mail and B.db.autoToggle.mail) or (vendor and B.db.autoToggle.vendor) then
		B:OpenBags()
	else
		B:CloseBags()
	end
end

function B:ToggleSortButtonState(isBank)
	local button = (isBank and B.BankFrame.sortButton) or B.BagFrame.sortButton
	button:SetEnabled(not B.db[isBank and 'disableBankSort' or 'disableBagSort'])
end

function B:ContainerOnShow()
	B:SetListeners(self)
end

function B:ContainerOnHide()
	B:ClearListeners(self)

	if self.isBank then
		CloseBankFrame()
	else
		CloseBackpack()

		for i = 1, NUM_BAG_FRAMES do
			CloseBag(i)
		end
	end

	if B.db.clearSearchOnClose and (B.BankFrame.editBox:GetText() ~= '' or B.BagFrame.editBox:GetText() ~= '') then
		B:SearchClear()
	end
end

function B:SetListeners(frame)
	for _, event in next, frame.events do
		frame:RegisterEvent(event)
	end
end

function B:ClearListeners(frame)
	for _, event in next, frame.events do
		if not presistentEvents[event] then
			frame:UnregisterEvent(event)
		end
	end
end

function B:OpenBags()
	if B.BagFrame:IsShown() then return end

	if B.BagFrame.firstOpen then
		B:UpdateAllSlots(B.BagFrame)
		B.BagFrame.firstOpen = nil
	end

	B.BagFrame:Show()
	B:UpdateTokensIfVisible()

	PlaySound(862) -- igBackPackOpen

	TT:GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:CloseBags()
	local bag, bank = B.BagFrame:IsShown(), B.BankFrame:IsShown()
	if bag or bank then
		if bag then B.BagFrame:Hide() end
		if bank then B.BankFrame:Hide() end

		PlaySound(863) -- igBackPackClose
	end

	TT:GameTooltip_SetDefaultAnchor(GameTooltip)
end

function B:ShowBankTab(f)
	B.BankTab = 1

	f.holderFrame:Show()
	f.editBox:Point('RIGHT', f.fullBank and f.bagsButton or f.purchaseBagButton, 'LEFT', -5, 0)

	if _G.BankFrame:IsShown() then
		B:Layout(true)
	else
		B:UpdateLayout(f)
	end
end

function B:OpenBank()
	B.BankFrame:Show()
	_G.BankFrame:Show()

	B:ShowBankTab(B.BankFrame)

	if B.BankFrame.firstOpen then
		B:UpdateAllSlots(B.BankFrame)

		B.BankFrame.firstOpen = nil
	elseif next(B.BankFrame.staleBags) then
		for bagID, bag in next, B.BankFrame.staleBags do
			if bagID == BANK_CONTAINER then
				for slotID in next, bag.staleSlots do
					B:UpdateSlot(B.BankFrame, bagID, slotID)
					bag.staleSlots[slotID] = nil
				end
			else
				B:UpdateBagSlots(B.BankFrame, bagID)
			end

			B.BankFrame.staleBags[bagID] = nil
		end
	end

	if B.db.autoToggle.bank then
		B:OpenBags()
	end
end

function B:PLAYERBANKBAGSLOTS_CHANGED()
	B:Layout(true)
end

function B:GUILDBANKBAGSLOTS_CHANGED()
	B:SetGuildBankSearch('')
end

function B:CloseBank()
	_G.BankFrame:Hide()

	B:CloseBags()
end

function B:updateContainerFrameAnchors()
	local xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
	local screenWidth = E.screenWidth
	local bags = _G.ContainerFrame1.bags
	local containerScale = 1
	local leftLimit = 0

	if _G.BankFrame:IsShown() then
		leftLimit = _G.BankFrame:GetRight() - 25
	end

	while containerScale > CONTAINER_SCALE do
		screenHeight = E.screenHeight / containerScale
		-- Adjust the start anchor for bags depending on the multibars
		xOffset = CONTAINER_OFFSET_X / containerScale
		yOffset = CONTAINER_OFFSET_Y / containerScale
		-- freeScreenHeight determines when to start a new column of bags
		freeScreenHeight = screenHeight - yOffset
		leftMostPoint = screenWidth - xOffset
		column = 1

		for _, name in ipairs(bags) do
			local frame = _G[name]
			local frameHeight = frame:GetHeight()
			if freeScreenHeight < frameHeight then
				column = column + 1 -- Start a new column
				leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
				freeScreenHeight = screenHeight - yOffset
			end

			freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
		end

		if leftMostPoint < leftLimit then
			containerScale = containerScale - 0.01
		else
			break
		end
	end

	if containerScale < CONTAINER_SCALE then
		containerScale = CONTAINER_SCALE
	end

	screenHeight = E.screenHeight / containerScale
	-- Adjust the start anchor for bags depending on the multibars
	yOffset = CONTAINER_OFFSET_Y / containerScale
	-- freeScreenHeight determines when to start a new column of bags
	freeScreenHeight = screenHeight - yOffset
	column = 0

	local bagsPerColumn = 0
	for index, name in ipairs(bags) do
		local frame = _G[name]
		local frameHeight = frame:GetHeight()

		frame:SetScale(1)

		if index == 1 then -- First bag
			frame:Point('BOTTOMRIGHT', _G.ElvUIBagMover, 'BOTTOMRIGHT', E.Spacing, -E.Border)
			bagsPerColumn = bagsPerColumn + 1
		elseif freeScreenHeight < frameHeight then -- Start a new column
			column = column + 1
			freeScreenHeight = screenHeight - yOffset
			frame:Point('BOTTOMRIGHT', bags[(index - bagsPerColumn) - (column > 1 and 1 or 0)], 'BOTTOMLEFT', -CONTAINER_SPACING, 0 )
			bagsPerColumn = 0
		else -- Anchor to the previous bag
			frame:Point('BOTTOMRIGHT', bags[index - 1], 'TOPRIGHT', 0, CONTAINER_SPACING)
			bagsPerColumn = bagsPerColumn + 1
		end

		freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
	end
end

function B:PostBagMove()
	if not E.private.bags.enable then return end

	local x, y = self:GetCenter() -- self refers to the mover (bag or bank)
	if not x or not y then return end

	if y > (E.screenHeight * 0.5) then
		self:SetText(self.textGrowDown)
		self.POINT = x > (E.screenWidth * 0.5) and 'TOPRIGHT' or 'TOPLEFT'
	else
		self:SetText(self.textGrowUp)
		self.POINT = x > (E.screenWidth * 0.5) and 'BOTTOMRIGHT' or 'BOTTOMLEFT'
	end

	local bagFrame = (self.name == 'ElvUIBankMover' and B.BankFrame) or B.BagFrame
	bagFrame:ClearAllPoints()
	bagFrame:Point(self.POINT, self)
end

function B:MERCHANT_CLOSED()
	B.SellFrame:Hide()

	wipe(B.SellFrame.Info.itemList)

	B.SellFrame.Info.delete = false
	B.SellFrame.Info.ProgressTimer = 0
	B.SellFrame.Info.SellInterval = B.db.vendorGrays.interval
	B.SellFrame.Info.ProgressMax = 0
	B.SellFrame.Info.goldGained = 0
	B.SellFrame.Info.itemsSold = 0
end

function B:ProgressQuickVendor()
	local item = B.SellFrame.Info.itemList[1]
	if not item then return nil, true end -- No more to sell

	local bagID, slotID, itemLink, stackCount, stackPrice = unpack(item)
	if B.db.vendorGrays.details and itemLink then
		E:Print(format('%s|cFF00DDDDx%d|r %s', itemLink, stackCount, E:FormatMoney(stackPrice, B.db.moneyFormat, not B.db.moneyCoins)))
	end

	UseContainerItem(bagID, slotID)
	tremove(B.SellFrame.Info.itemList, 1)

	return stackPrice
end

function B:VendorGrays_OnUpdate(elapsed)
	B.SellFrame.Info.ProgressTimer = B.SellFrame.Info.ProgressTimer - elapsed
	if B.SellFrame.Info.ProgressTimer > 0 then return end
	B.SellFrame.Info.ProgressTimer = B.SellFrame.Info.SellInterval

	local goldGained, lastItem = B:ProgressQuickVendor()
	if goldGained then
		B.SellFrame.Info.goldGained = B.SellFrame.Info.goldGained + goldGained
		B.SellFrame.Info.itemsSold = B.SellFrame.Info.itemsSold + 1
		B.SellFrame.statusbar:SetValue(B.SellFrame.Info.itemsSold)
		B.SellFrame.statusbar.ValueText:SetText(B.SellFrame.Info.itemsSold..' / '..B.SellFrame.Info.ProgressMax)
	elseif lastItem then
		B.SellFrame:Hide()

		if B.SellFrame.Info.goldGained > 0 then
			E:Print((L["Vendored gray items for: %s"]):format(E:FormatMoney(B.SellFrame.Info.goldGained, B.db.moneyFormat, not B.db.moneyCoins)))
		end
	end
end

function B:CreateSellFrame()
	B.SellFrame = CreateFrame('Frame', 'ElvUIVendorGraysFrame', E.UIParent)
	B.SellFrame:Size(200, 40)
	B.SellFrame:Point('CENTER', E.UIParent)
	B.SellFrame:CreateBackdrop('Transparent')
	B.SellFrame:SetAlpha(B.db.vendorGrays.progressBar and 1 or 0)

	B.SellFrame.title = B.SellFrame:CreateFontString(nil, 'OVERLAY')
	B.SellFrame.title:FontTemplate(nil, 12, 'OUTLINE')
	B.SellFrame.title:Point('TOP', B.SellFrame, 'TOP', 0, -2)
	B.SellFrame.title:SetText(L["Vendoring Grays"])

	B.SellFrame.statusbar = CreateFrame('StatusBar', 'ElvUIVendorGraysFrameStatusbar', B.SellFrame)
	B.SellFrame.statusbar:Size(180, 16)
	B.SellFrame.statusbar:Point('BOTTOM', B.SellFrame, 'BOTTOM', 0, 4)
	B.SellFrame.statusbar:SetStatusBarTexture(E.media.normTex)
	B.SellFrame.statusbar:SetStatusBarColor(1, 0, 0)
	B.SellFrame.statusbar:CreateBackdrop('Transparent')

	B.SellFrame.statusbar.anim = _G.CreateAnimationGroup(B.SellFrame.statusbar)
	B.SellFrame.statusbar.anim.progress = B.SellFrame.statusbar.anim:CreateAnimation('Progress')
	B.SellFrame.statusbar.anim.progress:SetEasing('Out')
	B.SellFrame.statusbar.anim.progress:SetDuration(.3)

	B.SellFrame.statusbar.ValueText = B.SellFrame.statusbar:CreateFontString(nil, 'OVERLAY')
	B.SellFrame.statusbar.ValueText:FontTemplate(nil, 12, 'OUTLINE')
	B.SellFrame.statusbar.ValueText:Point('CENTER', B.SellFrame.statusbar)
	B.SellFrame.statusbar.ValueText:SetText('0 / 0 ( 0s )')

	B.SellFrame.Info = {
		delete = false,
		ProgressTimer = 0,
		SellInterval = B.db.vendorGrays.interval,
		ProgressMax = 0,
		goldGained = 0,
		itemsSold = 0,
		itemList = {},
	}

	B.SellFrame:SetScript('OnUpdate', B.VendorGrays_OnUpdate)
	B.SellFrame:Hide()
end

function B:UpdateSellFrameSettings()
	if not B.SellFrame or not B.SellFrame.Info then return end

	B.SellFrame.Info.SellInterval = B.db.vendorGrays.interval
	B.SellFrame:SetAlpha(B.db.vendorGrays.progressBar and 1 or 0)
end

B.BagIndice = {
	quiver = 0x1,
	ammoPouch = 0x2,
	soulBag = 0x4,
	leatherworking = 0x8,
	inscription = 0x10,
	herbs = 0x20,
	enchanting = 0x40,
	engineering = 0x80,
	keyring = 0x100,
	gems = 0x200,
	mining = 0x400,
}

B.QuestKeys = {
	questStarter = 'questStarter',
	questItem = 'questItem',
}

B.AutoToggleEvents = {
	guildBank = { GUILDBANKFRAME_OPENED = 'OpenBags', GUILDBANKFRAME_CLOSED = 'CloseBags' },
	auctionHouse = { AUCTION_HOUSE_SHOW = 'OpenBags', AUCTION_HOUSE_CLOSED = 'CloseBags' },
	professions = { TRADE_SKILL_SHOW = 'OpenBags', TRADE_SKILL_CLOSE = 'CloseBags' },
	trade = { TRADE_SHOW = 'OpenBags', TRADE_CLOSED = 'CloseBags' },
}

function B:AutoToggle()
	for option, eventTable in next, B.AutoToggleEvents do
		for event, func in next, eventTable do
			if B.db.autoToggle[option] then
				B:RegisterEvent(event, func)
			else
				B:UnregisterEvent(event)
			end
		end
	end
end

function B:UpdateBagColors(table, indice, r, g, b)
	local colorTable
	if table == 'items' then
		colorTable = B.QuestColors[B.QuestKeys[indice]]
	else
		if table == 'profession' then table = 'ProfessionColors' end
		colorTable = B[table][B.BagIndice[indice]]
	end

	colorTable.r, colorTable.g, colorTable.b = r, g, b
end

function B:GetBindLines()
	local c = GetCVarBool('colorblindmode')
	return c and 8 or 7
end

function B:UpdateBindLines(_, cvar)
	if cvar == 'USE_COLORBLIND_MODE' then
		BIND_START, BIND_END = B:GetBindLines()
	end
end

function B:Initialize()
	B.db = E.db.bags

	BIND_START, BIND_END = B:GetBindLines()

	B.ProfessionColors = {
		[0x1]		= E:GetColorTable(B.db.colors.profession.quiver),
		[0x2]		= E:GetColorTable(B.db.colors.profession.ammoPouch),
		[0x4]		= E:GetColorTable(B.db.colors.profession.soulBag),
		[0x8]		= E:GetColorTable(B.db.colors.profession.leatherworking),
		[0x10]		= E:GetColorTable(B.db.colors.profession.inscription),
		[0x20]		= E:GetColorTable(B.db.colors.profession.herbs),
		[0x40]		= E:GetColorTable(B.db.colors.profession.enchanting),
		[0x80]		= E:GetColorTable(B.db.colors.profession.engineering),
		[0x100]		= E:GetColorTable(B.db.colors.profession.keyring),
		[0x200]		= E:GetColorTable(B.db.colors.profession.gems),
		[0x400]		= E:GetColorTable(B.db.colors.profession.mining),
	}

	B.QuestColors = {
		questStarter = E:GetColorTable(B.db.colors.items.questStarter),
		questItem = E:GetColorTable(B.db.colors.items.questItem),
	}

	B:LoadBagBar()

	--Creating vendor grays frame
	B:CreateSellFrame()
	B:RegisterEvent('MERCHANT_CLOSED')

	--Bag Mover (We want it created even if Bags module is disabled, so we can use it for default bags too)
	local BagFrameHolder = CreateFrame('Frame', nil, E.UIParent)
	BagFrameHolder:Width(200)
	BagFrameHolder:Height(22)
	BagFrameHolder:SetFrameLevel(400)

	if not E.private.bags.enable then
		-- Set a different default anchor
		BagFrameHolder:Point('BOTTOMRIGHT', _G.RightChatPanel, 'BOTTOMRIGHT', -(E.Border*2), 22 + E.Border*4 - E.Spacing*2)
		E:CreateMover(BagFrameHolder, 'ElvUIBagMover', L["Bags"], nil, nil, B.PostBagMove, nil, nil, 'bags,general')
		CONTAINER_SPACING = E.private.skins.blizzard.enable and E.private.skins.blizzard.bags and (E.Border*2) or 0
		B:SecureHook('updateContainerFrameAnchors')
		return
	end

	B.Initialized = true
	B.BagFrames = {}

	--Bag Mover: Set default anchor point and create mover
	BagFrameHolder:Point('BOTTOMRIGHT', _G.RightChatPanel, 'BOTTOMRIGHT', 0, 22 + E.Border*4 - E.Spacing*2)
	E:CreateMover(BagFrameHolder, 'ElvUIBagMover', L["Bags (Grow Up)"], nil, nil, B.PostBagMove, nil, nil, 'bags,general')

	--Bank Mover
	local BankFrameHolder = CreateFrame('Frame', nil, E.UIParent)
	BankFrameHolder:Width(200)
	BankFrameHolder:Height(22)
	BankFrameHolder:Point('BOTTOMLEFT', _G.LeftChatPanel, 'BOTTOMLEFT', 0, 22 + E.Border*4 - E.Spacing*2)
	BankFrameHolder:SetFrameLevel(400)
	E:CreateMover(BankFrameHolder, 'ElvUIBankMover', L["Bank (Grow Up)"], nil, nil, B.PostBagMove, nil, nil, 'bags,general')

	--Set some variables on movers
	_G.ElvUIBagMover.textGrowUp = L["Bags (Grow Up)"]
	_G.ElvUIBagMover.textGrowDown = L["Bags (Grow Down)"]
	_G.ElvUIBagMover.POINT = 'BOTTOM'
	_G.ElvUIBankMover.textGrowUp = L["Bank (Grow Up)"]
	_G.ElvUIBankMover.textGrowDown = L["Bank (Grow Down)"]
	_G.ElvUIBankMover.POINT = 'BOTTOM'

	--Create Containers
	B.BagFrame = B:ConstructContainerFrame('ElvUI_ContainerFrame')
	B.BankFrame = B:ConstructContainerFrame('ElvUI_BankContainerFrame', true)

	B:SecureHook('BackpackTokenFrame_Update', 'UpdateTokens')

	B:SecureHook('OpenAllBags')
	B:SecureHook('CloseAllBags', 'CloseBags')
	B:SecureHook('ToggleBag', 'ToggleBags')
	B:SecureHook('OpenBackpack', 'OpenBags')
	B:SecureHook('CloseBackpack', 'CloseBags')
	B:SecureHook('ToggleBackpack')

	B:DisableBlizzard()
	B:UpdateGoldText()

	B:RegisterEvent('PLAYER_ENTERING_WORLD')
	B:RegisterEvent('PLAYER_MONEY', 'UpdateGoldText')
	B:RegisterEvent('PLAYER_TRADE_MONEY', 'UpdateGoldText')
	B:RegisterEvent('TRADE_MONEY_CHANGED', 'UpdateGoldText')
	B:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateBagButtons')
	B:RegisterEvent('PLAYER_REGEN_DISABLED', 'UpdateBagButtons')
	B:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
	B:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')
	B:RegisterEvent('CVAR_UPDATE', 'UpdateBindLines')
	B:RegisterEvent('PLAYERBANKBAGSLOTS_CHANGED')
	B:RegisterEvent('GUILDBANKBAGSLOTS_CHANGED')

	B:AutoToggle()
end

local function InitializeCallback()
	B:Initialize()
end

E:RegisterModule(B:GetName(), InitializeCallback)