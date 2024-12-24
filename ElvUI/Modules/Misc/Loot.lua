local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Misc')
local LBG = E.Libs.ButtonGlow

local _G = _G
local unpack = unpack
local tinsert = tinsert
local next = next
local max = math.max
local find = string.find

local CloseDropDownMenus = CloseDropDownMenus
local CloseLoot = CloseLoot
local CreateFrame = CreateFrame
local CursorOnUpdate = CursorOnUpdate
local CursorUpdate = CursorUpdate
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local GetCVar = GetCVar
local GetItemInfo = GetItemInfo
local GetLootSlotInfo = GetLootSlotInfo
local GetLootSlotLink = GetLootSlotLink
local GetNumLootItems = GetNumLootItems
local GiveMasterLoot = GiveMasterLoot
local IsFishingLoot = IsFishingLoot
local IsModifiedClick = IsModifiedClick
local LootSlot = LootSlot
local LootSlotIsItem = LootSlotIsItem
local ResetCursor = ResetCursor
local ToggleDropDownMenu = ToggleDropDownMenu
local UIParent = UIParent
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitName = UnitName
local UISpecialFrames = UISpecialFrames

local GroupLootDropDown_GiveLoot = GroupLootDropDown_GiveLoot

local StaticPopup_Hide = StaticPopup_Hide

local hooksecurefunc = hooksecurefunc
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local TEXTURE_ITEM_QUEST_BANG = TEXTURE_ITEM_QUEST_BANG
local TEXTURE_ITEM_QUEST_BORDER = TEXTURE_ITEM_QUEST_BORDER
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local LOOT = LOOT

local slotQuality, slotID, slotName
local lootFrame, lootFrameHolder
local iconSize, lootFrame, lootFrameHolder = 30

local questItemCache = {}

local function SlotEnter(slot)
	local id = slot:GetID()
	if LootSlotIsItem(id) then
		GameTooltip:SetOwner(slot, 'ANCHOR_RIGHT')
		GameTooltip:SetLootItem(id)
		CursorUpdate(slot)
	end

	slot.drop:Show()
	slot.drop:SetVertexColor(1, 1, 0)
end

local function SlotLeave(slot)
	if slot.quality and (slot.quality > 1) then
		local color = ITEM_QUALITY_COLORS[slot.quality]
		slot.drop:SetVertexColor(color.r, color.g, color.b)
	else
		slot.drop:Hide()
	end

	GameTooltip:Hide()
	ResetCursor()
end

local function SlotClick(slot)
	local frame = _G.LootFrame
	frame.selectedQuality = slot.quality
	frame.selectedItemName = slot.name:GetText()
	frame.selectedTexture = slot.icon:GetTexture()
	frame.selectedLootButton = slot:GetName()
	frame.selectedSlot = slot:GetID()

	if IsModifiedClick() then
		_G.HandleModifiedItemClick(GetLootSlotLink(frame.selectedSlot))
	else
		slotID = frame.selectedSlot
		slotQuality = frame.selectedQuality
		slotName = frame.selectedItemName
		StaticPopup_Hide('CONFIRM_LOOT_DISTRIBUTION')
		LootSlot(frame.selectedSlot)
	end
end

local function FrameHide()
	StaticPopup_Hide('CONFIRM_LOOT_DISTRIBUTION')
	CloseLoot()
end

local function SlotShow(slot)
	if GameTooltip:IsOwned(slot) then
		GameTooltip:SetOwner(slot, 'ANCHOR_RIGHT')
		GameTooltip:SetLootItem(slot:GetID())
		CursorOnUpdate(slot)
	end
end

local function AnchorSlots(self)
	local shownSlots = 0

	for i = 1, #self.slots do
		local frame = self.slots[i]
		if frame:IsShown() then
			shownSlots = shownSlots + 1

			frame:Point('TOP', lootFrame, 4, (-8 + iconSize) - (shownSlots * iconSize))
		end
	end

	self:Height(max(shownSlots * iconSize + 16, 20))
end

local function CreateSlot(id)
	local size = (iconSize - 2)

	local slot = CreateFrame('Button', 'ElvLootSlot'..id, lootFrame)
	slot:Point('LEFT', 8, 0)
	slot:Point('RIGHT', -8, 0)
	slot:Height(size)
	slot:SetID(id)

	slot:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	slot:SetScript('OnEnter', SlotEnter)
	slot:SetScript('OnLeave', SlotLeave)
	slot:SetScript('OnClick', SlotClick)
	slot:SetScript('OnShow', SlotShow)

	local iconFrame = CreateFrame('Frame', nil, slot)
	iconFrame:Size(iconSize - 2)
	iconFrame:SetPoint('RIGHT', slot)
	iconFrame:SetTemplate()
	slot.iconFrame = iconFrame
	E.frames[iconFrame] = nil

	local icon = iconFrame:CreateTexture(nil, 'ARTWORK')
	icon:SetTexCoord(unpack(E.TexCoords))
	icon:SetInside()
	slot.icon = icon

	local count = iconFrame:CreateFontString(nil, 'OVERLAY')
	count:SetJustifyH('RIGHT')
	count:Point('BOTTOMRIGHT', iconFrame, -2, 2)
	count:FontTemplate(nil, nil, 'OUTLINE')
	count:SetText(1)
	slot.count = count

	local name = slot:CreateFontString(nil, 'OVERLAY')
	name:SetJustifyH('LEFT')
	name:SetPoint('LEFT', slot)
	name:SetPoint('RIGHT', icon, 'LEFT')
	name:SetNonSpaceWrap(true)
	name:FontTemplate(nil, nil, 'OUTLINE')
	slot.name = name

	local drop = slot:CreateTexture(nil, 'ARTWORK')
	drop:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
	drop:SetPoint('LEFT', icon, 'RIGHT', 0, 0)
	drop:SetPoint('RIGHT', slot)
	drop:SetAllPoints(slot)
	drop:SetAlpha(.3)
	slot.drop = drop

	local questTexture = iconFrame:CreateTexture(nil, 'OVERLAY')
	questTexture:SetInside()
	questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
	questTexture:SetTexCoord(unpack(E.TexCoords))
	slot.questTexture = questTexture

	lootFrame.slots[id] = slot
	return slot
end

function M:LOOT_SLOT_CLEARED(_, id)
	if not lootFrame:IsShown() then return end

	local slot = lootFrame.slots[id]
	if slot then
		slot:Hide()
	end

	AnchorSlots(lootFrame)
end

function M:LOOT_CLOSED()
	StaticPopup_Hide('LOOT_BIND')
	lootFrame:Hide()

	for _, slot in next, lootFrame.slots do
		slot:Hide()
	end
end

function M:LOOT_OPENED(_, autoloot)
	lootFrame:Show()

	if not lootFrame:IsShown() then
		CloseLoot(not autoloot)
	end

	if IsFishingLoot() then
		lootFrame.title:SetText(L["Fishy Loot"])
	elseif not UnitIsFriend('player', 'target') and UnitIsDead('target') then
		lootFrame.title:SetText(UnitName('target'))
	else
		lootFrame.title:SetText(LOOT)
	end

	lootFrame:ClearAllPoints()

	-- Blizzard uses strings here
	if GetCVar('lootUnderMouse') == '1' then
		local scale = lootFrame:GetEffectiveScale()
		local x, y = GetCursorPosition()

		lootFrame:Point('TOPLEFT', UIParent, 'BOTTOMLEFT', (x / scale) - 40, (y / scale) + 20)
		lootFrame:GetCenter()
		lootFrame:Raise()
		E:DisableMover('LootFrameMover')
	else
		lootFrame:SetPoint('TOPLEFT', lootFrameHolder, 'TOPLEFT')
		E:EnableMover('LootFrameMover')
	end

	local max_quality, max_width = 0, 0
	local numItems = GetNumLootItems()
	if numItems > 0 then
		for i = 1, numItems do
			local slot = lootFrame.slots[i] or CreateSlot(i)
			local texture, item, count, quality, _, isQuestItem, questID, isActive = E:GetLootSlotInfo(i)
			local color = ITEM_QUALITY_COLORS[quality or 0]

			if texture and find(texture, 'INV_Misc_Coin') then
				item = item:gsub('\n', ', ')
			end

			slot.count:SetShown(count and count > 1)
			slot.count:SetText(count or '')

			slot.drop:SetShown(quality and quality > 1)
			slot.drop:SetVertexColor(color.r, color.g, color.b)

			slot.quality = quality
			slot.name:SetText(item)
			slot.name:SetTextColor(color.r, color.g, color.b)
			slot.icon:SetTexture(texture)

			max_width = max(max_width, slot.name:GetStringWidth())

			if quality then
				max_quality = max(max_quality, quality)
			end

			local questTexture = slot.questTexture
			if questID and not isActive then
				questTexture:Show()
				LBG.ShowOverlayGlow(slot.iconFrame)
			elseif questID or isQuestItem then
				questTexture:Hide()
				LBG.ShowOverlayGlow(slot.iconFrame)
			else
				questTexture:Hide()
				LBG.HideOverlayGlow(slot.iconFrame)
			end

			-- Check for FasterLooting scripts or w/e (if bag is full)
			if texture then
				slot:Enable()
				slot:Show()
			end
		end
	else
		local slot = lootFrame.slots[1] or CreateSlot(1)
		local color = ITEM_QUALITY_COLORS[0]

		slot.name:SetText(L["No Loot"])
		slot.name:SetTextColor(color.r, color.g, color.b)
		slot.icon:SetTexture([[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])

		max_width = max(max_width, slot.name:GetStringWidth())

		slot.count:Hide()
		slot.drop:Hide()
		slot:Disable()
		slot:Show()
	end

	AnchorSlots(lootFrame)

	local color = ITEM_QUALITY_COLORS[max_quality]
	lootFrame:SetBackdropBorderColor(color.r, color.g, color.b, .8)
	lootFrame:Width(max(max_width + 60, lootFrame.title:GetStringWidth()  + 5))
end

function M:OPEN_MASTER_LOOT_LIST()
	ToggleDropDownMenu(1, nil, _G.GroupLootDropDown, lootFrame.slots[slotID], 0, 0)
end

function M:UPDATE_MASTER_LOOT_LIST()
	_G.UIDropDownMenu_Refresh(_G.GroupLootDropDown)
end

function M:LoadLoot()
	if not E.private.general.loot then return end

	lootFrameHolder = CreateFrame('Frame', 'ElvLootFrameHolder', E.UIParent)
	lootFrameHolder:Point('TOPLEFT', E.UIParent, 'TOPLEFT', 418, -186)
	lootFrameHolder:Size(150, 22)

	lootFrame = CreateFrame('Button', 'ElvLootFrame', lootFrameHolder)
	lootFrame:SetClampedToScreen(true)
	lootFrame:SetPoint('TOPLEFT')
	lootFrame:Size(256, 64)
	lootFrame:SetTemplate('Transparent')
	lootFrame:SetFrameStrata(_G.LootFrame:GetFrameStrata())
	lootFrame:SetToplevel(true)
	lootFrame.title = lootFrame:CreateFontString(nil, 'OVERLAY')
	lootFrame.title:FontTemplate(nil, nil, 'OUTLINE')
	lootFrame.title:Point('BOTTOMLEFT', lootFrame, 'TOPLEFT', 0, 1)
	lootFrame.slots = {}
	lootFrame:SetScript('OnHide', FrameHide) -- mimic LootFrame_OnHide, mostly
	E.frames[lootFrame] = nil

	self:RegisterEvent('LOOT_OPENED')
	self:RegisterEvent('LOOT_SLOT_CLEARED')
	self:RegisterEvent('LOOT_CLOSED')
	self:RegisterEvent('OPEN_MASTER_LOOT_LIST')
	self:RegisterEvent('UPDATE_MASTER_LOOT_LIST')

	E:CreateMover(lootFrameHolder, 'LootFrameMover', L["Loot Frame"], nil, nil, nil, nil, nil, 'general,blizzardImprovements')

	_G.LootFrame:UnregisterAllEvents()
	tinsert(UISpecialFrames, 'ElvLootFrame')

	local function GroupLootDropDown_GiveLoot(self)
		if slotQuality >= _G.MASTER_LOOT_THREHOLD then
			local dialog = E:StaticPopup_Show('CONFIRM_LOOT_DISTRIBUTION', ITEM_QUALITY_COLORS[slotQuality].hex .. slotName .. FONT_COLOR_CODE_CLOSE, self:GetText())
			if dialog then
				dialog.data = self.value
			end
		else
			GiveMasterLoot(slotID, self.value)
		end
		CloseDropDownMenus()
	end

	E.PopupDialogs.CONFIRM_LOOT_DISTRIBUTION.OnAccept = function(_, data)
		GiveMasterLoot(slotID, data)
	end
	_G.StaticPopupDialogs.CONFIRM_LOOT_DISTRIBUTION.preferredIndex = 3
end