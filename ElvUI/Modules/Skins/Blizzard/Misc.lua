local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")

--Lua functions
local _G = _G
local type = type
local unpack = unpack
--WoW API / Variables

S:AddCallback("Skin_Misc", function()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.misc then return end

	-- reskin all esc/menu buttons
	for _, Button in pairs({_G.GameMenuFrame:GetChildren()}) do
		if Button.IsObjectType and Button:IsObjectType("Button") then
			S:HandleButton(Button)
		end
	end

	GameMenuFrame:StripTextures()
	GameMenuFrame:SetTemplate("Transparent")
	GameMenuFrameHeader:SetTexture()
	GameMenuFrameHeader:ClearAllPoints()
	GameMenuFrameHeader:Point("TOP", GameMenuFrame, 0, 7)

	-- Static Popups
	for i = 1, 4 do
		local staticPopup = _G["StaticPopup"..i]
		local itemFrame = _G["StaticPopup"..i.."ItemFrame"]
		local itemFrameBox = _G["StaticPopup"..i.."EditBox"]
		local itemFrameTexture = _G["StaticPopup"..i.."ItemFrameIconTexture"]
		local itemFrameNormal = _G["StaticPopup"..i.."ItemFrameNormalTexture"]
		local itemFrameName = _G["StaticPopup"..i.."ItemFrameNameFrame"]
		local closeButton = _G["StaticPopup"..i.."CloseButton"]
		local wideBox = _G["StaticPopup"..i.."WideEditBox"]

		staticPopup:SetTemplate("Transparent")

		S:HandleEditBox(itemFrameBox)
		itemFrameBox.backdrop:Point("TOPLEFT", -2, -4)
		itemFrameBox.backdrop:Point("BOTTOMRIGHT", 2, 4)

		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameGold"])
		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameSilver"])
		S:HandleEditBox(_G["StaticPopup"..i.."MoneyInputFrameCopper"])

		for j = 1, itemFrameBox:GetNumRegions() do
			local region = select(j, itemFrameBox:GetRegions())
			if region and region:IsObjectType("Texture") then
				if region:GetTexture() == [[Interface\ChatFrame\UI-ChatInputBorder-Left]] or region:GetTexture() == [[Interface\ChatFrame\UI-ChatInputBorder-Right]] then
					region:Kill()
				end
			end
		end

		closeButton:StripTextures()
		S:HandleCloseButton(closeButton, staticPopup)

		itemFrame:GetNormalTexture():Kill()
		itemFrame:SetTemplate()
		itemFrame:StyleButton()

		hooksecurefunc("StaticPopup_Show", function(which, _, _, data)
			local info = StaticPopupDialogs[which]
			if not info then return nil end

			if info.hasItemFrame then
				if data and type(data) == "table" then
					if data.color then
						itemFrame:SetBackdropBorderColor(unpack(data.color))
					else
						itemFrame:SetBackdropBorderColor(1, 1, 1, 1)
					end
				end
			end
		end)

		itemFrameTexture:SetTexCoord(unpack(E.TexCoords))
		itemFrameTexture:SetInside()

		itemFrameNormal:SetAlpha(0)
		itemFrameName:Kill()

		select(8, wideBox:GetRegions()):Hide()
		S:HandleEditBox(wideBox)
		wideBox:Height(22)

		for j = 1, 3 do
			S:HandleButton(_G["StaticPopup"..i.."Button"..j])
		end
	end

	-- Other Frames
	TicketStatusFrameButton:SetTemplate("Transparent")
	AutoCompleteBox:SetTemplate("Transparent")
	ConsolidatedBuffsTooltip:SetTemplate("Transparent")

	-- Basic Script Errors
	BasicScriptErrors:SetScale(E.global.general.UIScale)
	BasicScriptErrors:SetTemplate("Transparent")
	S:HandleButton(BasicScriptErrorsButton)

	-- BNToast Frame
	BNToastFrame:SetTemplate("Transparent")

	BNToastFrameCloseButton:Size(32)
	S:HandleCloseButton(BNToastFrameCloseButton, BNToastFrame)

	-- Ready Check Frame
	ReadyCheckFrame:EnableMouse(true)
	ReadyCheckFrame:SetTemplate("Transparent")

	S:HandleButton(ReadyCheckFrameYesButton)
	ReadyCheckFrameYesButton:SetParent(ReadyCheckFrame)
	ReadyCheckFrameYesButton:ClearAllPoints()
	ReadyCheckFrameYesButton:Point("TOPRIGHT", ReadyCheckFrame, "CENTER", -3, -5)

	S:HandleButton(ReadyCheckFrameNoButton)
	ReadyCheckFrameNoButton:SetParent(ReadyCheckFrame)
	ReadyCheckFrameNoButton:ClearAllPoints()
	ReadyCheckFrameNoButton:Point("TOPLEFT", ReadyCheckFrame, "CENTER", 4, -5)

	ReadyCheckFrameText:SetParent(ReadyCheckFrame)
	ReadyCheckFrameText:Point("TOP", 0, -15)
	ReadyCheckFrameText:SetTextColor(1, 1, 1)

	ReadyCheckListenerFrame:SetAlpha(0)

	-- Coin PickUp Frame
	CoinPickupFrame:StripTextures()
	CoinPickupFrame:SetTemplate("Transparent")

	S:HandleButton(CoinPickupOkayButton)
	S:HandleButton(CoinPickupCancelButton)

	-- Zone Text Frame
	ZoneTextFrame:ClearAllPoints()
	ZoneTextFrame:Point("TOP", 0, -128)

	-- Stack Split Frame
	StackSplitFrame:SetTemplate("Transparent")
	StackSplitFrame:GetRegions():Hide()
	StackSplitFrame:SetFrameStrata("DIALOG")

	StackSplitFrame.bg1 = CreateFrame("Frame", nil, StackSplitFrame)
	StackSplitFrame.bg1:SetFrameLevel(StackSplitFrame.bg1:GetFrameLevel() - 1)
	StackSplitFrame.bg1:SetTemplate("Transparent")
	StackSplitFrame.bg1:Point("TOPLEFT", 10, -15)
	StackSplitFrame.bg1:Point("BOTTOMRIGHT", -10, 55)

	S:HandleButton(StackSplitOkayButton)
	S:HandleButton(StackSplitCancelButton)

	-- Opacity Frame
	OpacityFrame:StripTextures()
	OpacityFrame:SetTemplate("Transparent")

	S:HandleSliderFrame(OpacityFrameSlider)

	-- Channel Pullout Frame
	ChannelPullout:SetTemplate("Transparent")

	ChannelPulloutBackground:Kill()

	S:HandleTab(ChannelPulloutTab)
	ChannelPulloutTab:Size(107, 26)
	ChannelPulloutTabText:Point("LEFT", ChannelPulloutTabLeft, "RIGHT", 0, 4)

	S:HandleCloseButton(ChannelPulloutCloseButton, ChannelPullout)
	ChannelPulloutCloseButton:Size(32)

	-- Dropdown Menu
	hooksecurefunc("UIDropDownMenu_CreateFrames", function(level, index)
		local listFrame = _G["DropDownList"..level]
		local listFrameName = listFrame:GetName()
		local expandArrow = _G[listFrameName.."Button"..index.."ExpandArrow"]
		if expandArrow then
			local normTex = expandArrow:GetNormalTexture()
			expandArrow:SetNormalTexture(E.Media.Textures.ArrowUp)
			normTex:SetVertexColor(unpack(E.media.rgbvaluecolor))
			normTex:SetRotation(S.ArrowRotation.right)
			expandArrow:Size(16)
		end

		local Backdrop = _G[listFrameName.."Backdrop"]
		if Backdrop and not Backdrop.template then
			Backdrop:StripTextures()
			Backdrop:SetTemplate("Transparent")
		end

		local menuBackdrop = _G[listFrameName.."MenuBackdrop"]
		if menuBackdrop and not menuBackdrop.template then
			menuBackdrop:SetTemplate("Transparent")
		end
	end)

	hooksecurefunc("ToggleDropDownMenu", function(level)
		if not level then
			level = 1
		end

		local r, g, b = unpack(E.media.rgbvaluecolor)

		for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
			local button = _G["DropDownList"..level.."Button"..i]
			local check = _G["DropDownList"..level.."Button"..i.."Check"]
			local highlight = _G["DropDownList"..level.."Button"..i.."Highlight"]
			local text = _G["DropDownList"..level.."Button"..i.."NormalText"]

			highlight:SetTexture(E.Media.Textures.Highlight)
			highlight:SetBlendMode("BLEND")
			highlight:SetDrawLayer("BACKGROUND")
			highlight:SetVertexColor(r, g, b)

			if not button.backdrop then
				button:CreateBackdrop()
			end

			if not button.notCheckable then
				if E.private.skins.checkBoxSkin then
					check:SetTexture(E.media.normTex)
					check:SetVertexColor(r, g, b, 1)
					check:Size(10)
					check:SetDesaturated(false)
					button.backdrop:SetOutside(check)

					S:HandlePointXY(text, 18)
				else
					check:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
					check:SetVertexColor(r, g, b, 1)
					check:Size(20)
					check:SetDesaturated(true)
					button.backdrop:SetInside(check, 4, 4)

					S:HandlePointXY(text, 22)
				end

				button.backdrop:Show()
				check:SetTexCoord(0, 1, 0, 1)
			else
				button.backdrop:Hide()
				check:Size(16)
			end
		end
	end)

	-- Chat Menu
	do
		local menuBackdrop = function(s)
			s:SetTemplate('Transparent')
		end

		local chatMenuBackdrop = function(s)
			s:SetTemplate('Transparent')

			s:ClearAllPoints()
			s:Point('BOTTOMLEFT', _G.ChatFrame1, 'TOPLEFT', 0, 30)
		end

		for index, menu in next, { _G.ChatMenu, _G.EmoteMenu, _G.LanguageMenu, _G.VoiceMacroMenu } do
			menu:StripTextures()

			if index == 1 then -- ChatMenu
				menu:HookScript('OnShow', chatMenuBackdrop)
			else
				menu:HookScript('OnShow', menuBackdrop)
			end
		end
	end

	-- Localization specific frames
	local locale = GetLocale()
	if locale == "koKR" then
		S:HandleButton(GameMenuButtonRatings)

		-- RatingMenuFrame
		RatingMenuFrame:SetTemplate("Transparent")
		RatingMenuFrameHeader:SetTexture()
		S:HandleButton(RatingMenuButtonOkay)

		RatingMenuButtonOkay:Point("BOTTOMRIGHT", -8, 8)
	elseif locale == "ruRU" then
		-- Declension Frame
		DeclensionFrame:SetTemplate("Transparent")

		S:HandleNextPrevButton(DeclensionFrameSetPrev, "left")
		S:HandleNextPrevButton(DeclensionFrameSetNext, "right")
		S:HandleButton(DeclensionFrameOkayButton)
		S:HandleButton(DeclensionFrameCancelButton)

		DeclensionFrameSet:Point("BOTTOM", 0, 40)
		DeclensionFrameOkayButton:Point("RIGHT", DeclensionFrame, "BOTTOM", -3, 19)
		DeclensionFrameCancelButton:Point("LEFT", DeclensionFrame, "BOTTOM", 3, 19)

		hooksecurefunc("DeclensionFrame_Update", function()
			for i = 1, RUSSIAN_DECLENSION_PATTERNS do
				_G["DeclensionFrameDeclension"..i.."Edit"]:SetTemplate("Default")
			end
		end)
	end
end)