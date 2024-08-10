local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local getmetatable = getmetatable
local ipairs = ipairs
local select = select
local unpack, next = unpack, next
local hooksecurefunc = hooksecurefunc

local GetCurrencyListInfo = GetCurrencyListInfo
local GetInventoryItemQuality = GetInventoryItemQuality
local GetInventoryItemTexture = GetInventoryItemTexture
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetNumFactions = GetNumFactions
local GetPetHappiness = GetPetHappiness
local HasPetUI = HasPetUI
local UnitFactionGroup = UnitFactionGroup
local IsAddOnLoaded = IsAddOnLoaded

local ResistanceCoords = {
	{ 0.21875, 0.8125, 0.25, 0.32421875 },		--Arcane
	{ 0.21875, 0.8125, 0.0234375, 0.09765625 },	--Fire
	{ 0.21875, 0.8125, 0.13671875, 0.2109375 },	--Nature
	{ 0.21875, 0.8125, 0.36328125, 0.4375},		--Frost
	{ 0.21875, 0.8125, 0.4765625, 0.55078125},	--Shadow
}

local function HandleCompanionsPerPage()
	for i = 1, _G.NUM_COMPANIONS_PER_PAGE do
		local button = _G['CompanionButton'..i]

		if button.creatureID then
			local iconNormal = button:GetNormalTexture()
			iconNormal:SetTexCoord(unpack(E.TexCoords))
			iconNormal:SetInside()
		end
	end
end

local function PaperDollItemSlotButtonUpdate(frame)
	if not frame.SetBackdropBorderColor then return end

	local id = frame:GetID()
	local rarity = id and GetInventoryItemQuality('player', id)
	if rarity and rarity > 1 then
		local r, g, b = GetItemQualityColor(rarity)
		frame:SetBackdropBorderColor(r, g, b)
	else
		frame:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

local function HandleTabs(frameCheck)
	local lastTab
	for index, tab in next, { _G.CharacterFrameTab1, (HasPetUI() and (GetNumCompanions('CRITTER') > 0) or (GetNumCompanions('MOUNT') > 0)) and _G.CharacterFrameTab2 or nil, _G.CharacterFrameTab3, _G.CharacterFrameTab4, _G.CharacterFrameTab5 } do
		tab:ClearAllPoints()

		if index == 1 then
			tab:Point('TOPLEFT', _G.CharacterFrame, 'BOTTOMLEFT', 10, E.private.enhanced.character.enable and not E:IsHDClient() and 80 or 78) -- check if using ElvUI_Enhanced
		else
			tab:Point('TOPLEFT', lastTab, 'TOPRIGHT', -15.5, 0)
		end

		if IsAddOnLoaded('Blizzard_TokenUI') and index == 5 then
			tab:Show()
		end

		lastTab = tab
	end
end

local function HandleHappiness(frame)
	local happiness = GetPetHappiness()
	local _, isHunterPet = HasPetUI()
	if not (happiness and isHunterPet) then return end

	local texture = frame:GetRegions()
	if happiness == 1 then
		texture:SetTexCoord(0.41, 0.53, 0.06, 0.30)
	elseif happiness == 2 then
		texture:SetTexCoord(0.22, 0.345, 0.06, 0.30)
	elseif happiness == 3 then
		texture:SetTexCoord(0.04, 0.15, 0.06, 0.30)
	end
end

local function HandleResistanceFrame(frameName)
	if not _G[frameName..'1'] then return end

	for i = 1, 5 do
		local frame, icon, text = _G[frameName..i], _G[frameName..i]:GetRegions()
		frame:Size(24)
		frame:SetTemplate()

		if i ~= 1 then
			frame:ClearAllPoints()
			if not E:IsHDClient() or frameName == 'PetMagicResFrame' then
				frame:Point('TOP', _G[frameName..i - 1], 'BOTTOM', 0, -1)
			else
				frame:Point('LEFT', _G[frameName..i - 1], 'RIGHT', -1, 0)
			end
		end

		if icon then
			icon:SetInside()
			icon:SetTexCoord(unpack(ResistanceCoords[i]))
			icon:SetDrawLayer('ARTWORK')
		end

		if text then
			text:SetDrawLayer('OVERLAY')
		end
	end
end

local function HandleTokenButton(button)
	if not button.isSkinned then
		button.categoryLeft:Kill()
		button.categoryRight:Kill()
		button.highlight:Kill()

		button.expandIcon:Size(16)
		button.expandIcon:SetTexCoord(0, 1, 0, 1)
		button.expandIcon.SetTexCoord = E.noop

		button.isSkinned = true
	end
end

local tokenSkinned = 0

local function HandleTokenContainerFrame()
	local offset = _G.HybridScrollFrame_GetOffset(_G.TokenFrameContainer)
	local buttons = _G.TokenFrameContainer.buttons
	local numButtons = #buttons
	local index, button
	local _, name, isHeader, isExpanded, extraCurrencyType, icon

	if numButtons > tokenSkinned then
		for i = tokenSkinned + 1, numButtons do
			HandleTokenButton(_G.TokenFrameContainer.buttons[i])
		end

		tokenSkinned = numButtons
	end

	for i = 1, numButtons do
		index = offset + i
		button = buttons[i]

		name, isHeader, isExpanded, _, _, _, extraCurrencyType, icon = GetCurrencyListInfo(index)

		if name then
			if isHeader then
				if isExpanded then
					button.expandIcon:SetTexture(E.Media.Textures.MinusButton)
				else
					button.expandIcon:SetTexture(E.Media.Textures.PlusButton)
				end
			else
				if extraCurrencyType == 1 then
					button.icon:SetTexCoord(unpack(E.TexCoords))
				elseif extraCurrencyType == 2 then
					local factionGroup = UnitFactionGroup('player')

					if factionGroup then
						button.icon:SetTexture([[Interface\TargetingFrame\UI-PVP-]]..factionGroup)
						-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 64, 64, 36, 36, 4, 1
						button.icon:SetTexCoord(0.0625, 0.625, 0.015625, 0.578125)
					else
						button.icon:SetTexCoord(unpack(E.TexCoords))
					end
				else
					button.icon:SetTexture(icon)
					button.icon:SetTexCoord(unpack(E.TexCoords))
				end
			end
		end
	end
end

local function HandleFrameTab(button)
    if not button.backdrop then
		button:Size(33, 35)
		S:HandlePointXY(button, -button:GetWidth() - 5)
        button:CreateBackdrop()

        -- Create Highlight texture if it doesn't exist
        if not button.Highlight then
			button:GetHighlightTexture():Hide()

            button.Highlight = button:CreateTexture(nil, 'HIGHLIGHT')
            button.Highlight:SetTexture(1, 1, 1, 0.3)
            button.Highlight:SetAllPoints()
        end

        -- Check if this is the character button (assumed to be PaperDollSidebarTabCharacter)
        if button == _G.CharManagerToggleButton then
            for _, region in next, { button:GetRegions() } do
                region:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
            end
        end

		if button == _G.PlayerTitleToggleButton then
            for _, region in next, { button:GetRegions() } do
                region:SetTexCoord(0.01562500, 0.53125000, 0.32421875, 0.46093750)
            end
        end

		if button == _G.GearManagerToggleButton then
			for _, region in next, { button:GetRegions() } do
                region:SetTexCoord(0.203125, 0.828125, 0.15625, 0.875)
            end
		end
    end
end

S:AddCallback('Skin_Character', function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.character then return end

	-- CharacterFrame
	local CharacterFrame = _G.CharacterFrame
	S:HandleFrame(CharacterFrame, true, nil, 11, -12, -32, 76)

	S:SetUIPanelWindowInfo(CharacterFrame, 'width')

	S:SetBackdropHitRect(_G.PaperDollFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.PetPaperDollFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.PetPaperDollFrameCompanionFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.PetPaperDollFramePetFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.ReputationFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.SkillFrame, CharacterFrame.backdrop)
	S:SetBackdropHitRect(_G.TokenFrame, CharacterFrame.backdrop)

	S:HandleCloseButton(_G.CharacterFrameCloseButton, CharacterFrame.backdrop)

	_G.PaperDollFrame:StripTextures(true)

	-- PaperDollFrame
	_G.PlayerTitleFrame:StripTextures()
	_G.PlayerTitleFrame:CreateBackdrop('Default')
	_G.PlayerTitleFrame.backdrop:Point('TOPLEFT', 20, 3)
	_G.PlayerTitleFrame.backdrop:Point('BOTTOMRIGHT', -16, 15)
	_G.PlayerTitleFrame.backdrop:SetFrameLevel(PlayerTitleFrame:GetFrameLevel())

	S:HandleNextPrevButton(_G.PlayerTitleFrameButton)
	_G.PlayerTitleFrameButton:Size(16)
	_G.PlayerTitleFrameButton:Point('TOPRIGHT', _G.PlayerTitleFrameRight, 'TOPRIGHT', -18, -16)

	_G.PlayerTitlePickerFrame:StripTextures()
	_G.PlayerTitlePickerFrame:CreateBackdrop('Transparent')
	_G.PlayerTitlePickerFrame.backdrop:Point('TOPLEFT', 6, -10)
	_G.PlayerTitlePickerFrame.backdrop:Point('BOTTOMRIGHT', -13, 6)
	_G.PlayerTitlePickerFrame.backdrop:SetFrameLevel(_G.PlayerTitlePickerFrame:GetFrameLevel())

	S:HandleScrollBar(_G.PlayerTitlePickerScrollFrameScrollBar)

	_G.PlayerTitlePickerScrollFrameScrollBar:Point('TOPLEFT', _G.PlayerTitlePickerScrollFrame, 'TOPRIGHT', 1, -14)
	_G.PlayerTitlePickerScrollFrameScrollBar:Point('BOTTOMLEFT', _G.PlayerTitlePickerScrollFrame, 'BOTTOMRIGHT', 1, 15)

	for _, button in ipairs(_G.PlayerTitlePickerScrollFrame.buttons) do
		button.text:FontTemplate()
		S:HandleButtonHighlight(button)
	end

	S:HandleRotateButton(_G.CharacterModelFrameRotateLeftButton)
	S:HandleRotateButton(_G.CharacterModelFrameRotateRightButton)

	S:HandleDropDownBox(_G.PlayerStatFrameRightDropDown, 145)
	S:HandleDropDownBox(_G.PlayerStatFrameLeftDropDown, 147)
	_G.PlayerStatFrameRightDropDown:Point('TOP', -2, 24)
	_G.PlayerStatFrameLeftDropDown:Point('LEFT', -25, 24)

	_G.CharacterAttributesFrame:StripTextures()

	_G.PaperDollFrameItemFlyoutButtons:EnableMouse(false)
	_G.PaperDollFrameItemFlyoutHighlight:Kill()

	HandleFrameTab(_G.GearManagerToggleButton)

	_G.PlayerTitleFrame:Point('TOP', _G.CharacterLevelText, 'BOTTOM', -7, -7)
	_G.PlayerTitlePickerFrame:Point('TOPLEFT', _G.PlayerTitleFrame, 'BOTTOMLEFT', 14, 26)

	_G.CharacterModelFrame:Size(237, 217)
	_G.CharacterModelFrame:Point('TOPLEFT', 63, -76)

	_G.CharacterModelFrameRotateLeftButton:Point('TOPLEFT', 4, -4)
	_G.CharacterModelFrameRotateRightButton:Point('TOPLEFT', _G.CharacterModelFrameRotateLeftButton, 'TOPRIGHT', 3, 0)

	_G.CharacterResistanceFrame:Point('TOPRIGHT', _G.PaperDollFrame, 'TOPLEFT', 300, -81)

	_G.CharacterHeadSlot:Point('TOPLEFT', 19, -76)
	_G.CharacterHandsSlot:Point('TOPLEFT', 307, -76)
	_G.CharacterMainHandSlot:Point('TOPLEFT', _G.PaperDollFrame, 'BOTTOMLEFT', 110, 131)

	_G.CharacterAttributesFrame:Point('TOPLEFT', 66, -292)

	local popoutButtonOnEnter = function(self) self.icon:SetVertexColor(unpack(E.media.rgbvaluecolor)) end
	local popoutButtonOnLeave = function(self) self.icon:SetVertexColor(1, 1, 1) end

	HandleResistanceFrame('MagicResFrame')
	HandleResistanceFrame('MagicResFrameer') -- WotLK HD Interface

	local slots = {
		_G.CharacterHeadSlot,
		_G.CharacterNeckSlot,
		_G.CharacterShoulderSlot,
		_G.CharacterShirtSlot,
		_G.CharacterChestSlot,
		_G.CharacterWaistSlot,
		_G.CharacterLegsSlot,
		_G.CharacterFeetSlot,
		_G.CharacterWristSlot,
		_G.CharacterHandsSlot,
		_G.CharacterFinger0Slot,
		_G.CharacterFinger1Slot,
		_G.CharacterTrinket0Slot,
		_G.CharacterTrinket1Slot,
		_G.CharacterBackSlot,
		_G.CharacterMainHandSlot,
		_G.CharacterSecondaryHandSlot,
		_G.CharacterRangedSlot,
		_G.CharacterTabardSlot,
		_G.CharacterAmmoSlot
	}

	for i, slot in ipairs(slots) do
		slot = _G[slot:GetName()..'9'] or slot -- WotLK HD Interface

		local icon = _G[slot:GetName()..'IconTexture']
		local cooldown = _G[slot:GetName()..'Cooldown']

		slot:StripTextures()
		slot:SetTemplate(nil, true, true)
		slot:StyleButton()

		S:HandleIcon(icon)
		icon:SetInside()

		slot:SetFrameLevel(_G.PaperDollFrame:GetFrameLevel() + 2)

		if cooldown then
			E:RegisterCooldown(cooldown)
		end
	end

	hooksecurefunc('PaperDollItemSlotButton_Update', PaperDollItemSlotButtonUpdate)

	local nStripped = 0
	hooksecurefunc('PaperDollFrameItemFlyout_Show', function()
		if nStripped < _G.PaperDollFrameItemFlyoutButtons.numBGs then
			nStripped = _G.PaperDollFrameItemFlyoutButtons.numBGs
			_G.PaperDollFrameItemFlyoutButtons:StripTextures()
			_G.PaperDollFrameItemFlyoutButtons:CreateBackdrop('Transparent')
			_G.PaperDollFrameItemFlyoutButtons.backdrop:Point('TOPLEFT', 0, 0)
			_G.PaperDollFrameItemFlyoutButtons.backdrop:Point('BOTTOMRIGHT', 4, 0)
		end
	end)

	hooksecurefunc('PaperDollFrameItemFlyout_DisplayButton', function(button)
		if not button.isSkinned then
			button.icon = _G[button:GetName()..'IconTexture']

			button:GetNormalTexture():SetTexture(nil)
			button:SetTemplate('Default')
			button:StyleButton()

			button.icon:SetInside()
			button.icon:SetTexCoord(unpack(E.TexCoords))

			E:RegisterCooldown(button.cooldown)
		end

		if not button.location or button.location >= _G.PDFITEMFLYOUT_FIRST_SPECIAL_LOCATION then return end

		local id = _G.EquipmentManager_GetItemInfoByLocation(button.location)
		local _, _, quality = GetItemInfo(id)

		button:SetBackdropBorderColor(GetItemQualityColor(quality))
	end)

	-- GearManager Dialog
	_G.GearManagerDialog:StripTextures()
	_G.GearManagerDialog:CreateBackdrop('Transparent')
	_G.GearManagerDialog.backdrop:Point('TOPLEFT', 5, -2)
	_G.GearManagerDialog.backdrop:Point('BOTTOMRIGHT', -3, 4)

	S:SetBackdropHitRect(_G.GearManagerDialog)

	S:HandleCloseButton(_G.GearManagerDialogClose, _G.GearManagerDialog.backdrop)

	for i, button in ipairs(_G.GearManagerDialog.buttons) do
		button:StripTextures()
		button:CreateBackdrop('Default')
		button.backdrop:SetAllPoints()

		button:StyleButton(nil, true)

		button.icon:SetInside()
		button.icon:SetTexCoord(unpack(E.TexCoords))
	end

	S:HandleButton(_G.GearManagerDialogDeleteSet)
	S:HandleButton(_G.GearManagerDialogEquipSet)
	S:HandleButton(_G.GearManagerDialogSaveSet)

	_G.GearSetButton1:Point('TOPLEFT', 15, -29)
	_G.GearSetButton6:Point('TOP', _G.GearSetButton1, 'BOTTOM', 0, -13)

	_G.GearManagerDialogDeleteSet:Point('BOTTOMLEFT', 11, 12)
	_G.GearManagerDialogEquipSet:Point('BOTTOMLEFT', 92, 12)
	_G.GearManagerDialogSaveSet:Point('BOTTOMRIGHT', -10, 12)

	-- GearManager DialogPopup
	_G.GearManagerDialogPopup:EnableMouse(true)
	_G.GearManagerDialogPopup:StripTextures()
	_G.GearManagerDialogPopup:CreateBackdrop('Transparent')
	_G.GearManagerDialogPopup.backdrop:Point('TOPLEFT', 5, -10)
	_G.GearManagerDialogPopup.backdrop:Point('BOTTOMRIGHT', -39, 8)

	S:SetBackdropHitRect(_G.GearManagerDialogPopup)

	_G.GearManagerDialogPopupScrollFrame:StripTextures()
	S:HandleScrollBar(_G.GearManagerDialogPopupScrollFrameScrollBar)

	S:HandleEditBox(_G.GearManagerDialogPopupEditBox)

	for i, button in ipairs(_G.GearManagerDialogPopup.buttons) do
		button:StripTextures()
		button:SetFrameLevel(button:GetFrameLevel() + 2)
		button:CreateBackdrop('Default')
		button.backdrop:SetAllPoints()

		button:StyleButton(true, true)

		button.icon:SetInside()
		button.icon:SetTexCoord(unpack(E.TexCoords))

		if i > 1 then
			local lastPos = (i - 1) / _G.NUM_GEARSET_ICONS_PER_ROW

			if lastPos == math.floor(lastPos) then
				button:SetPoint('TOPLEFT', _G.GearManagerDialogPopup.buttons[i-_G.NUM_GEARSET_ICONS_PER_ROW], 'BOTTOMLEFT', 0, -7)
			else
				button:SetPoint('TOPLEFT', _G.GearManagerDialogPopup.buttons[i-1], 'TOPRIGHT', 7, 0)
			end
		end
	end

	S:HandleButton(_G.GearManagerDialogPopupOkay)
	S:HandleButton(_G.GearManagerDialogPopupCancel)

	local text1, text2 = select(5, _G.GearManagerDialogPopup:GetRegions())
	text1:Point('TOPLEFT', 24, -19)
	text2:Point('TOPLEFT', 24, -63)

	if GetLocale() == 'ruRU' then
		text1:SetText(string.utf8sub(_G.GEARSETS_POPUP_TEXT, 0, -7) .. '):')
	end

	_G.GearManagerDialogPopupEditBox:Point('TOPLEFT', 24, -36)

	_G.GearManagerDialogPopupButton1:Point('TOPLEFT', 17, -83)

	_G.GearManagerDialogPopupScrollFrame:SetTemplate('Transparent')
	_G.GearManagerDialogPopupScrollFrame:Size(216, 130)
	_G.GearManagerDialogPopupScrollFrame:Point('TOPRIGHT', -68, -79)
	_G.GearManagerDialogPopupScrollFrameScrollBar:Point('TOPLEFT', _G.GearManagerDialogPopupScrollFrame, 'TOPRIGHT', 3, -19)
	_G.GearManagerDialogPopupScrollFrameScrollBar:Point('BOTTOMLEFT', _G.GearManagerDialogPopupScrollFrame, 'BOTTOMRIGHT', 3, 19)

	_G.GearManagerDialogPopupOkay:Point('BOTTOMRIGHT', _G.GearManagerDialogPopupCancel, 'BOTTOMLEFT', -3, 0)
	_G.GearManagerDialogPopupCancel:Point('BOTTOMRIGHT', -47, 16)

	-- PetPaperDollFrame
	_G.PetPaperDollFrame:StripTextures(true)

	for i = 1, 3 do
		local tab = _G['PetPaperDollFrameTab'..i]
		tab:StripTextures()
		tab:CreateBackdrop('Default', true)
		tab.backdrop:Point('TOPLEFT', 2, -7)
		tab.backdrop:Point('BOTTOMRIGHT', -1, -1)
		S:SetBackdropHitRect(tab)

		tab:HookScript('OnEnter', S.SetModifiedBackdrop)
		tab:HookScript('OnLeave', S.SetOriginalBackdrop)
	end

	-- PetPaperDollFrame PetFrame
	S:HandleRotateButton(_G.PetModelFrameRotateLeftButton)
	S:HandleRotateButton(_G.PetModelFrameRotateRightButton)

	HandleResistanceFrame('PetMagicResFrame')

	_G.PetAttributesFrame:StripTextures()

	_G.PetPaperDollFrameExpBar:StripTextures()
	_G.PetPaperDollFrameExpBar:CreateBackdrop('Default')
	_G.PetPaperDollFrameExpBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(_G.PetPaperDollFrameExpBar)

	S:HandleButton(_G.PetPaperDollCloseButton)

	_G.PetModelFrame:Width(325)
	_G.PetModelFrame:Point('TOPLEFT', 19, -71)

	_G.PetModelFrameRotateLeftButton:Point('TOPLEFT', _G.PetPaperDollFrame, 'TOPLEFT', 23, -75)
	_G.PetModelFrameRotateRightButton:Point('TOPLEFT', _G.PetModelFrameRotateLeftButton, 'TOPRIGHT', 3, 0)

	_G.PetResistanceFrame:Point('TOPRIGHT', _G.PetPaperDollFrame, 'TOPLEFT', 344, -75)

	_G.PetPaperDollPetInfo:SetFrameLevel(_G.PetModelFrame:GetFrameLevel() + 2)
	_G.PetPaperDollPetInfo:CreateBackdrop('Default')
	_G.PetPaperDollPetInfo:Size(25)
	_G.PetPaperDollPetInfo:Point('TOPLEFT', _G.PetModelFrameRotateLeftButton, 'BOTTOMLEFT', 10, -4)
	-- texWidth, texHeight, cropWidth, cropHeight, offsetX, offsetY = 128, 64, 16, 16, 52, 4
	_G.PetPaperDollPetInfo:GetRegions():SetTexCoord(0.03125, 0.15625, 0.0625, 0.3125)

	_G.PetPaperDollPetInfo:RegisterEvent('UNIT_HAPPINESS')
	_G.PetPaperDollPetInfo:SetScript('OnEvent', HandleHappiness)
	_G.PetPaperDollPetInfo:SetScript('OnShow', HandleHappiness)
	HandleHappiness(_G.PetPaperDollPetInfo)

	_G.PetLevelText:Point('CENTER', 0, -50)
	_G.PetAttributesFrame:Point('TOPLEFT', 67, -310)

	_G.PetPaperDollFrameExpBar:Width(323)
	_G.PetPaperDollFrameExpBar:Point('BOTTOMLEFT', 20, 112)

	_G.PetPaperDollCloseButton:Point('CENTER', _G.PetPaperDollFramePetFrame, 'TOPLEFT', 304, -417)

	-- PetPaperDollFrame CompanionFrame
	_G.PetPaperDollFrameCompanionFrame:StripTextures()

	S:HandleRotateButton(_G.CompanionModelFrameRotateLeftButton)
	S:HandleRotateButton(_G.CompanionModelFrameRotateRightButton)

	S:HandleButton(_G.CompanionSummonButton)

	S:HandleNextPrevButton(_G.CompanionPrevPageButton)
	S:HandleNextPrevButton(_G.CompanionNextPageButton)

	hooksecurefunc('PetPaperDollFrame_UpdateCompanions', HandleCompanionsPerPage)

	for i = 1, _G.NUM_COMPANIONS_PER_PAGE do
		local button = _G['CompanionButton'..i]
		local iconDisabled = button:GetDisabledTexture()
		local activeTexture = _G['CompanionButton'..i..'ActiveTexture']

		button:StyleButton(nil, true)
		button:SetTemplate('Default', true)

		iconDisabled:SetAlpha(0)

		activeTexture:SetInside(button)
		activeTexture:SetTexture(1, 1, 1, .15)

		if i == 7 then
			button:Point('TOP', _G.CompanionButton1, 'BOTTOM', 0, -5)
		elseif i ~= 1 then
			button:Point('LEFT', _G['CompanionButton'..i-1], 'RIGHT', 5, 0)
		end
	end

	_G.CompanionModelFrame:Size(325, 174)
	_G.CompanionModelFrame:Point('TOPLEFT', 19, -71)

	_G.CompanionModelFrameRotateLeftButton:Point('TOPLEFT', _G.PetPaperDollFrame, 'TOPLEFT', 23, -75)
	_G.CompanionModelFrameRotateRightButton:Point('TOPLEFT', _G.CompanionModelFrameRotateLeftButton, 'TOPRIGHT', 3, 0)

	_G.CompanionButton1:Point('TOPLEFT', 58, -308)

	_G.CompanionSummonButton:Width(149)
	_G.CompanionSummonButton:Point('CENTER', -11, -24)

	_G.CompanionPrevPageButton:Point('BOTTOMLEFT', 122, 92)
	_G.CompanionNextPageButton:Point('LEFT', _G.CompanionPrevPageButton, 'RIGHT', 83, 0)

	_G.CompanionPageNumber:Point('CENTER', -10, -155)

	-- Reputation Frame
	_G.ReputationFrame:StripTextures(true)

	for i = 1, _G.NUM_FACTIONS_DISPLAYED do
		local factionBar = _G['ReputationBar'..i]
		local factionStatusBar = _G['ReputationBar'..i..'ReputationBar']
		local factionBarButton = _G['ReputationBar'..i..'ExpandOrCollapseButton']
		local factionName = _G['ReputationBar'..i..'FactionName']

		factionBar:StripTextures()
		factionStatusBar:StripTextures()
		factionStatusBar:CreateBackdrop()
		factionStatusBar:SetStatusBarTexture(E.media.normTex)
		factionStatusBar:Size(108, 13)

		S:HandleCollapseTexture(factionBarButton, nil, true)
		E:RegisterStatusBar(factionStatusBar)

		factionName:Width(140)
		factionName:Point('LEFT', factionBar, 'LEFT', -150, 0)
		factionName.SetWidth = E.noop
	end

	_G.ReputationListScrollFrame:StripTextures()
	S:HandleScrollBar(_G.ReputationListScrollFrameScrollBar)

	_G.ReputationFrameFactionLabel:Point('TOPLEFT', 70, -60)
	_G.ReputationFrameStandingLabel:Point('TOPLEFT', 235, -60)

	_G.ReputationBar1:Point('TOPRIGHT', -51, -81)

	_G.ReputationListScrollFrame:Width(304)
	_G.ReputationListScrollFrame:Point('TOPRIGHT', -61, -74)
	_G.ReputationListScrollFrameScrollBar:Point('TOPLEFT', _G.ReputationListScrollFrame, 'TOPRIGHT', 3, -19)
	_G.ReputationListScrollFrameScrollBar:Point('BOTTOMLEFT', _G.ReputationListScrollFrame, 'BOTTOMRIGHT', 3, 19)

	_G.ReputationListScrollFrame:SetScript('OnShow', function()
		_G.ReputationBar1:Point('TOPRIGHT', -75, -81)
	end)
	_G.ReputationListScrollFrame:SetScript('OnHide', function()
		_G.ReputationBar1:Point('TOPRIGHT', -51, -81)
	end)

	-- Reputation DetailFrame
	_G.ReputationDetailFrame:StripTextures()
	_G.ReputationDetailFrame:SetTemplate('Transparent')
	_G.ReputationDetailFrame:Point('TOPLEFT', _G.ReputationFrame, 'TOPRIGHT', -33, -12)

	S:HandleCloseButton(_G.ReputationDetailCloseButton, _G.ReputationDetailFrame)

	S:HandleCheckBox(_G.ReputationDetailAtWarCheckBox)
	S:HandleCheckBox(_G.ReputationDetailInactiveCheckBox)
	S:HandleCheckBox(_G.ReputationDetailMainScreenCheckBox)

	-- Skill Frame
	_G.SkillFrame:StripTextures(true)

	_G.SkillFrameExpandButtonFrame:StripTextures()

	S:HandleCollapseTexture(_G.SkillFrameCollapseAllButton, nil, true)

	for i = 1, _G.SKILLS_TO_DISPLAY do
		local statusBar = _G['SkillRankFrame'..i]
		local statusBarBorder = _G['SkillRankFrame'..i..'Border']
		local statusBarBackground = _G['SkillRankFrame'..i..'Background']
		local skillTypeLabel = _G['SkillTypeLabel'..i]

		statusBar:Width(276)
		statusBar:CreateBackdrop('Default')
		statusBar:SetStatusBarTexture(E.media.normTex)

		S:HandleCollapseTexture(skillTypeLabel, nil, true)
		E:RegisterStatusBar(statusBar)

		statusBarBorder:StripTextures()
		statusBarBackground:SetTexture(nil)
	end

	_G.SkillDetailStatusBar:StripTextures()
	_G.SkillDetailStatusBar:SetParent(_G.SkillDetailScrollFrame)
	_G.SkillDetailStatusBar:CreateBackdrop('Default')
	_G.SkillDetailStatusBar:SetStatusBarTexture(E.media.normTex)
	E:RegisterStatusBar(_G.SkillDetailStatusBar)

	S:HandleCloseButton(_G.SkillDetailStatusBarUnlearnButton)
	_G.SkillDetailStatusBarUnlearnButton:SetPoint('LEFT', _G.SkillDetailStatusBarBorder, 'RIGHT')
	_G.SkillDetailStatusBarUnlearnButton.Texture:Size(16)
	_G.SkillDetailStatusBarUnlearnButton.Texture:SetVertexColor(1, 0, 0)
	_G.SkillDetailStatusBarUnlearnButton:HookScript('OnEnter', function(btn) btn.Texture:SetVertexColor(1, 1, 1) end)
	_G.SkillDetailStatusBarUnlearnButton:HookScript('OnLeave', function(btn) btn.Texture:SetVertexColor(1, 0, 0) end)

	_G.SkillListScrollFrame:StripTextures()
	S:HandleScrollBar(_G.SkillListScrollFrameScrollBar)

	_G.SkillDetailScrollFrame:StripTextures()
	S:HandleScrollBar(_G.SkillDetailScrollFrameScrollBar)

	S:HandleButton(_G.SkillFrameCancelButton)

	_G.SkillFrameExpandButtonFrame:Point('TOPLEFT', 30, -50)

	_G.SkillTypeLabel1:Point('LEFT', _G.SkillFrame, 'TOPLEFT', 22, -85)
	_G.SkillRankFrame1:Point('TOPLEFT', 38, -78)

	_G.SkillListScrollFrame:Width(304)
	_G.SkillListScrollFrame:Point('TOPRIGHT', -61, -74)

	_G.SkillListScrollFrameScrollBar:Point('TOPLEFT', _G.SkillListScrollFrame, 'TOPRIGHT', 3, -19)
	_G.SkillListScrollFrameScrollBar:Point('BOTTOMLEFT', _G.SkillListScrollFrame, 'BOTTOMRIGHT', 3, 19)

	_G.SkillDetailScrollFrame:Size(304, 98)
	_G.SkillDetailScrollFrame:Point('TOPLEFT', _G.SkillListScrollFrame, 'BOTTOMLEFT', 0, -7)

	_G.SkillDetailScrollFrameScrollBar:Point('TOPLEFT', _G.SkillDetailScrollFrame, 'TOPRIGHT', 3, -19)
	_G.SkillDetailScrollFrameScrollBar:Point('BOTTOMLEFT', _G.SkillDetailScrollFrame, 'BOTTOMRIGHT', 3, 19)

	_G.SkillFrameCancelButton:Point('CENTER', _G.SkillFrame, 'TOPLEFT', 304, -417)

	-- Token Frame
	_G.TokenFrame:StripTextures(true)

	select(4, _G.TokenFrame:GetChildren()):Hide()

	S:HandleScrollBar(_G.TokenFrameContainerScrollBar)

	S:HandleButton(_G.TokenFrameCancelButton)

	_G.TokenFrameContainer:Size(304, 360)
	_G.TokenFrameContainer:Point('TOPLEFT', 19, -39)

	_G.TokenFrameContainerScrollBar:Point('TOPLEFT', _G.TokenFrameContainer, 'TOPRIGHT', 3, -19)
	_G.TokenFrameContainerScrollBar:Point('BOTTOMLEFT', _G.TokenFrameContainer, 'BOTTOMRIGHT', 3, 19)

	_G.TokenFrameMoneyFrame:Point('BOTTOMRIGHT', -115, 88)

	_G.TokenFrameCancelButton:Point('CENTER', _G.TokenFrame, 'TOPLEFT', 304, -417)

	_G.TokenFrameContainerScrollBar.Show = function(self)
		_G.TokenFrameContainer:SetWidth(304)
		for _, button in ipairs(_G.TokenFrameContainer.buttons) do
			button:SetWidth(300)
		end
		getmetatable(self).__index.Show(self)
	end

	_G.TokenFrameContainerScrollBar.Hide = function(self)
		_G.TokenFrameContainer:SetWidth(325)
		for _, button in ipairs(_G.TokenFrameContainer.buttons) do
			button:SetWidth(325)
		end
		getmetatable(self).__index.Hide(self)
	end

	hooksecurefunc('TokenFrame_Update', HandleTokenContainerFrame)
	hooksecurefunc(_G.TokenFrameContainer, 'update', HandleTokenContainerFrame)

	-- Token Frame Popup
	_G.TokenFramePopup:StripTextures()
	_G.TokenFramePopup:SetTemplate('Transparent')

	S:HandleCloseButton(_G.TokenFramePopupCloseButton, TokenFramePopup)

	S:HandleCheckBox(_G.TokenFramePopupInactiveCheckBox)
	S:HandleCheckBox(_G.TokenFramePopupBackpackCheckBox)

	_G.TokenFramePopup:Point('TOPLEFT', _G.TokenFrame, 'TOPRIGHT', -33, -12)

	-- Tabs
	for i = 1, #CHARACTERFRAME_SUBFRAMES do
		S:HandleTab(_G['CharacterFrameTab'..i])
	end

	-- Reposition Tabs
	HandleTabs()

	-- Handle other HD interface frames
	if E:IsHDClient() then
		S:HandleButton(_G.MostrarStatPaperDollLeftDropDown)
		S:HandleButton(_G.MostrarStatPaperDollRightDropDown)

		_G.PetAttributesFrame:SetTemplate('Transparent')
		_G.PetAttributesFrame:Size(_G.PetPaperDollFrameExpBar:GetWidth() + 1, 96)
		S:HandlePointXY(_G.PetStatFrame1, 12, -5)
		S:HandlePointXY(_G.PetAttributesFrame, 19, -286)
		S:HandlePointXY(_G.PetAttackPowerFrame, 170, -5)
		S:HandlePointXY(_G.PetLevelText, 0, -18)

		for i, frame in ipairs({ PetAttributesFrame:GetChildren() }) do
			if frame:IsObjectType('Frame') then
				frame:Width(frame:GetWidth() + 40)
			end
		end

		HandleFrameTab(_G.CharManagerToggleButton)
		HandleFrameTab(_G.PlayerTitleToggleButton)

		if _G.PersonalGearScore then
			_G.PersonalGearScore:Hide()
		end

		if _G.GearScore2 then
			_G.GearScore2:Hide()
		end
	end
end)