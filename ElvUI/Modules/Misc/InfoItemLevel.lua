local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Misc')
local LSM = E.Libs.LSM
local LC = E.Libs.Compat

local _G = _G
local wipe = wipe
local next = next
local pairs = pairs
local unpack = unpack
local UnitGUID = UnitGUID
local CreateFrame = CreateFrame
local GetItemLevelColor = LC.GetItemLevelColor

local InspectItems = {
    'HeadSlot',
    'NeckSlot',
    'ShoulderSlot',
	'',
    'ChestSlot',
    'WaistSlot',
    'LegsSlot',
    'FeetSlot',
    'WristSlot',
    'HandsSlot',
    'Finger0Slot',
    'Finger1Slot',
    'Trinket0Slot',
    'Trinket1Slot',
    'BackSlot',
    'MainHandSlot',
    'SecondaryHandSlot',
}

local whileOpenEvents = {
	UPDATE_INVENTORY_DURABILITY = true,
}

function M:CreateInspectTexture(slot, x, y)
	local texture = slot:CreateTexture()
	texture:Point('BOTTOM', x, y)
	texture:SetTexCoord(unpack(E.TexCoords))
	texture:Size(14)

	local backdrop = CreateFrame('Frame', nil, slot)
	backdrop:SetTemplate(nil, nil, true)
	backdrop:SetBackdropColor(0,0,0,0)
	backdrop:SetOutside(texture)
	backdrop:Hide()

	return texture, backdrop
end

function M:GetInspectPoints(id)
	if not id then return end

	if id <= 5 or (id == 9 or id == 15) then
		return 40, 3, 18, 'BOTTOMLEFT' -- Left side
	elseif (id >= 6 and id <= 8) or (id >= 10 and id <= 14) then
		return -40, 3, 18, 'BOTTOMRIGHT' -- Right side
	else
		return 0, 45, 60, 'BOTTOM'
	end
end

function M:UpdateInspectInfo(_, arg1)
	M:UpdatePageInfo(_G.InspectFrame, 'Inspect', arg1)
end

function M:UpdateCharacterInfo(event)
	if (not E.db.general.itemLevel.displayCharacterInfo)
	or (whileOpenEvents[event] and not _G.CharacterFrame:IsShown()) then return end

	M:UpdatePageInfo(_G.CharacterFrame, 'Character', nil, event)
end

function M:UpdateCharacterItemLevel()
	M:UpdateAverageString(_G.CharacterFrame, 'Character')
end

function M:ClearPageInfo(frame, which)
	if not (frame and frame.ItemLevelText) then return end
	frame.ItemLevelText:SetText('')

	for i = 1, 17 do
		if i ~= 4 then
			local inspectItem = _G[which..InspectItems[i]]
			inspectItem.socketText:SetText('')
			inspectItem.iLvlText:SetText('')

			for y = 1, 10 do
				inspectItem['textureSlot'..y]:SetTexture()
				inspectItem['textureSlotBackdrop'..y]:Hide()
			end
		end
	end
end

function M:ToggleItemLevelInfo(setupCharacterPage)
	if not IsAddOnLoaded("ElvUI_Enhanced") then return end
	if not E.private.enhanced.character.enable then return end

	if setupCharacterPage then
		M:CreateSlotStrings(_G.CharacterFrame, 'Character')
	end

	if E.db.general.itemLevel.displayCharacterInfo then
		M:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateCharacterInfo')
		M:RegisterEvent('UPDATE_INVENTORY_DURABILITY', 'UpdateCharacterInfo')
		M:RegisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateCharacterItemLevel')

		CharacterAttributesFrame:Hide()
		CharacterResistanceFrame:Hide()

		if not _G.CharacterFrame.CharacterInfoHooked then
			_G.CharacterFrame:HookScript('OnShow', M.UpdateCharacterInfo)
			_G.CharacterFrame.CharacterInfoHooked = true
		end

		if not setupCharacterPage then
			M:UpdateCharacterInfo()
		end
	else
		M:UnregisterEvent('PLAYER_EQUIPMENT_CHANGED')
		M:UnregisterEvent('UPDATE_INVENTORY_DURABILITY')
		M:UnregisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE')

		CharacterAttributesFrame:Show()
		CharacterResistanceFrame:Show()


		M:ClearPageInfo(_G.CharacterFrame, 'Character')
	end

	if E.db.general.itemLevel.displayInspectInfo then
		M:RegisterEvent('INSPECT_TALENT_READY', 'UpdateInspectInfo')
	else
		M:UnregisterEvent('INSPECT_TALENT_READY')
		M:ClearPageInfo(_G.InspectFrame, 'Inspect')
	end
end

function M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which) -- `which` is used by plugins
	iLevelDB[i] = slotInfo.iLvl

	inspectItem.socketText:SetText(slotInfo.socketTextShort)
	if slotInfo.socketColors and next(slotInfo.socketColors) then
		inspectItem.socketText:SetTextColor(unpack(slotInfo.socketColors))
	end

	inspectItem.iLvlText:SetText(slotInfo.iLvl)
	if slotInfo.itemLevelColors and next(slotInfo.itemLevelColors) then
		inspectItem.iLvlText:SetTextColor(unpack(slotInfo.itemLevelColors))
	end

	local gemStep = 1
	for x = 1, 10 do
		local texture = inspectItem['textureSlot'..x]
		local backdrop = inspectItem['textureSlotBackdrop'..x]
		local gem = slotInfo.gems and slotInfo.gems[gemStep]
		if gem then
			texture:SetTexture(gem)
			backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			backdrop:Show()

			gemStep = gemStep + 1
		else
			texture:SetTexture()
			backdrop:Hide()
		end
	end
end

function M:UpdateAverageString(frame, which, iLevelDB)
	local charPage, avgItemLevel, avgTotal = which == 'Character'
	if charPage then
		avgTotal, avgItemLevel = E:GetPlayerItemLevel() -- rounded average, rounded equipped
	elseif frame.unit then
		avgItemLevel = E:CalculateAverageItemLevel(iLevelDB, frame.unit)
	end

	if avgItemLevel then
		if charPage then
			frame.ItemLevelText:SetFormattedText(L["Avg: %.2f"], avgItemLevel)
			frame.ItemLevelText:SetTextColor(GetItemLevelColor(frame.unit))
		else
			frame.ItemLevelText:SetFormattedText(L["Item level: %.2f"], avgItemLevel)
		end

		-- we have to wait to do this on inspect so handle it in here
		if not E.db.general.itemLevel.itemLevelRarity then
			for i = 1, 17 do
				if i ~= 4 then
					local ilvl = iLevelDB[i]
					if ilvl then
						local inspectItem = _G[which..InspectItems[i]]
						local r, g, b = E:ColorizeItemLevel(ilvl - (avgTotal or avgItemLevel))
						inspectItem.iLvlText:SetTextColor(r, g, b)
					end
				end
			end
		end
	else
		frame.ItemLevelText:SetText('')
	end
end

function M:TryGearAgain(frame, which, i, deepScan, iLevelDB, inspectItem)
	E:Delay(0.05, function()
		if which == 'Inspect' and (not frame or not frame.unit) then return end

		local unit = (which == 'Character' and 'player') or frame.unit
		local slotInfo = E:GetGearSlotInfo(unit, i, deepScan)
		if slotInfo == 'tooSoon' then return end

		M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
	end)
end

do
	local iLevelDB = {}
	function M:UpdatePageInfo(frame, which, guid, event)
		if not (which and frame and frame.ItemLevelText) then return end
		if which == 'Inspect' and (not frame or not frame.unit or (guid and frame:IsShown() and UnitGUID(frame.unit) ~= guid)) then return end

		wipe(iLevelDB)

		local waitForItems
		for i = 1, 17 do
			if i ~= 4 then
				local inspectItem = _G[which..InspectItems[i]]
				inspectItem.socketText:SetText('')
				inspectItem.iLvlText:SetText('')

				local unit = (which == 'Character' and 'player') or frame.unit
				local slotInfo = E:GetGearSlotInfo(unit, i, true)
				if slotInfo == 'tooSoon' then
					if not waitForItems then waitForItems = true end
					M:TryGearAgain(frame, which, i, true, iLevelDB, inspectItem)
				else
					M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
				end
			end
		end

		if event and event == 'PLAYER_EQUIPMENT_CHANGED' then
			return
		end

		if waitForItems then
			E:Delay(0.10, M.UpdateAverageString, M, frame, which, iLevelDB)
		else
			M:UpdateAverageString(frame, which, iLevelDB)
		end
	end
end

function M:CreateSlotStrings(frame, which)
	if not (frame and which) then return end

	local itemLevelFont = E.db.general.itemLevel.itemLevelFont
	local itemLevelFontSize = E.db.general.itemLevel.itemLevelFontSize or 12
	local itemLevelFontOutline = E.db.general.itemLevel.itemLevelFontOutline or 'OUTLINE'

	if which == 'Inspect' then
		frame.ItemLevelText = InspectPaperDollFrame:CreateFontString(nil, 'OVERLAY')
		frame.ItemLevelText:Point('BOTTOMLEFT', 16, 82)
	else
		frame.ItemLevelText = PaperDollFrame:CreateFontString(nil, 'OVERLAY')
		frame.ItemLevelText:Point('TOP', CharacterModelFrame, 'TOP', 0, 20)
	end
	frame.ItemLevelText:FontTemplate(nil, which == 'Inspect' and 12 or 20)

	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			local slot = _G[which..s]
			local x, y, z, justify = M:GetInspectPoints(i)
			slot.iLvlText = slot:CreateFontString(nil, 'OVERLAY')
			slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
			slot.iLvlText:Point('BOTTOM', slot, x, y)

			slot.socketText = slot:CreateFontString(nil, 'OVERLAY')
			slot.socketText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)

			if i == 16 or i == 17 then
				slot.socketText:Point(i==16 and 'BOTTOMRIGHT' or 'BOTTOMLEFT', slot, i == 16 and -40 or 40, 3)
			else
				slot.socketText:Point(justify, slot, x + (justify == 'BOTTOMLEFT' and 5 or -5), z)
			end

			for u = 1, 10 do
				local offset = 8+(u*16)
				local newX = ((justify == 'BOTTOMLEFT' or i == 17) and x+offset) or x-offset
				slot['textureSlot'..u], slot['textureSlotBackdrop'..u] = M:CreateInspectTexture(slot, newX, --[[newY or]] y)
			end
		end
	end
end

function M:SetupInspectPageInfo()
	local frame = _G.InspectFrame
	if frame and not frame.ItemLevelText then
		M:CreateSlotStrings(frame, 'Inspect')
	end
end

function M:UpdateInspectPageFonts(which)
	local itemLevelFont = E.db.general.itemLevel.itemLevelFont
	local itemLevelFontSize = E.db.general.itemLevel.itemLevelFontSize or 12
	local itemLevelFontOutline = E.db.general.itemLevel.itemLevelFontOutline or 'OUTLINE'

	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			local slot = _G[which..s]
			if slot then
				slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
				slot.socketText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
			end
		end
	end
end
