local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")
local LibStub = LibStub

local _G = _G
local tinsert, xpcall, next, ipairs, pairs = tinsert, xpcall, next, ipairs, pairs
local unpack, assert, type, strfind = unpack, assert, type, strfind

local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded
local UIPanelWindows = UIPanelWindows
local UpdateUIPanelPositions = UpdateUIPanelPositions

S.allowBypass = {}
S.addonsToLoad = {}
S.nonAddonsToLoad = {}

S.Blizzard = {}
S.Blizzard.Regions = {
	'Left',
	'Middle',
	'Right',
	'Mid',
	'LeftDisabled',
	'MiddleDisabled',
	'RightDisabled',
	'BorderBottom',
	'BorderBottomLeft',
	'BorderBottomRight',
	'BorderLeft',
	'BorderRight',
	'TopLeft',
	'TopRight',
	'BottomLeft',
	'BottomRight',
	'TopMiddle',
	'MiddleLeft',
	'MiddleRight',
	'BottomMiddle',
	'MiddleMiddle',
	'TabSpacer',
	'TabSpacer1',
	'TabSpacer2',
	'_RightSeparator',
	'_LeftSeparator',
	'Cover',
	'Border',
	'Background',
	'TopTex',
	'TopLeftTex',
	'TopRightTex',
	'LeftTex',
	'BottomTex',
	'BottomLeftTex',
	'BottomRightTex',
	'RightTex',
	'MiddleTex',
	'Center'
}

-- Depends on the arrow texture to be up by default.
S.ArrowRotation = {
	up = 0,
	down = 3.14,
	left = 1.57,
	right = -1.57,
}

do
	local function HighlightOnEnter(button)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		button.HighlightTexture:SetVertexColor(r, g, b, 0.50)
		button.HighlightTexture:Show()
	end

	local function HighlightOnLeave(button)
		button.HighlightTexture:SetVertexColor(0, 0, 0, 0)
		button.HighlightTexture:Hide()
	end

	function S:HandleCategoriesButtons(button, strip)
		if button.isSkinned then return end

		if button.SetNormalTexture then button:SetNormalTexture(E.ClearTexture) end
		if button.SetHighlightTexture then button:SetHighlightTexture(E.ClearTexture) end
		if button.SetPushedTexture then button:SetPushedTexture(E.ClearTexture) end
		if button.SetDisabledTexture then button:SetDisabledTexture(E.ClearTexture) end

		if strip then button:StripTextures() end
		S:HandleBlizzardRegions(button)

		button.HighlightTexture = button:CreateTexture(nil, "BACKGROUND")
		button.HighlightTexture:SetBlendMode("BLEND")
		button.HighlightTexture:SetSize(button:GetSize())
		button.HighlightTexture:Point("CENTER", button, 0, 2)
		button.HighlightTexture:SetTexture(E.Media.Textures.Highlight)
		button.HighlightTexture:SetVertexColor(0, 0, 0, 0)
		button.HighlightTexture:Hide()

		button:HookScript("OnEnter", HighlightOnEnter)
		button:HookScript("OnLeave", HighlightOnLeave)

		button.isSkinned = true
	end
end

function S:HandleButtonHighlight(frame, r, g, b)
	if frame.SetHighlightTexture then
		frame:SetHighlightTexture(E.ClearTexture)
	end

	if not frame.highlightGradient then
		local width, h = frame:GetSize()
		local height = h * 0.95

		local gradient = frame:CreateTexture(nil, "HIGHLIGHT")
		gradient:SetTexture(E.Media.Textures.Highlight)
		gradient:Point("LEFT", frame)
		gradient:Size(width, height)

		frame.highlightGradient = gradient
	end

	if not r then r = 0.9 end
	if not g then g = 0.9 end
	if not b then b = 0.9 end

	frame.highlightGradient:SetVertexColor(r, g, b, 0.3)
end

function S:HandlePointXY(frame, x, y)
	local a, b, c, d, e = frame:GetPoint()
	frame:SetPoint(a, b, c, x or d, y or e)
end

function S:HandleFrame(frame, setBackdrop, template, x1, y1, x2, y2)
	assert(frame, "doesn't exist!")

	local name = frame and frame.GetName and frame:GetName()
	local insetFrame = name and _G[name.."Inset"] or frame.Inset
	local portraitFrame = name and _G[name.."Portrait"] or frame.Portrait or frame.portrait
	local portraitFrameOverlay = name and _G[name.."PortraitOverlay"] or frame.PortraitOverlay
	local artFrameOverlay = name and _G[name.."ArtOverlayFrame"] or frame.ArtOverlayFrame

	frame:StripTextures()

	if portraitFrame then portraitFrame:SetAlpha(0) end
	if portraitFrameOverlay then portraitFrameOverlay:SetAlpha(0) end
	if artFrameOverlay then artFrameOverlay:SetAlpha(0) end

	if insetFrame then
		S:HandleInsetFrame(insetFrame)
	end

	if frame.CloseButton then
		S:HandleCloseButton(frame.CloseButton)
	end

	if setBackdrop then
		frame:CreateBackdrop(template or "Transparent")
	else
		frame:SetTemplate(template or "Transparent")
	end

	if frame.backdrop then
		frame.backdrop:Point("TOPLEFT", x1 or 0, y1 or 0)
		frame.backdrop:Point("BOTTOMRIGHT", x2 or 0, y2 or 0)
	end
end

function S:HandleInsetFrame(frame)
	assert(frame, "doesn't exist!")

	if frame.InsetBorderTop then frame.InsetBorderTop:Hide() end
	if frame.InsetBorderTopLeft then frame.InsetBorderTopLeft:Hide() end
	if frame.InsetBorderTopRight then frame.InsetBorderTopRight:Hide() end

	if frame.InsetBorderBottom then frame.InsetBorderBottom:Hide() end
	if frame.InsetBorderBottomLeft then frame.InsetBorderBottomLeft:Hide() end
	if frame.InsetBorderBottomRight then frame.InsetBorderBottomRight:Hide() end

	if frame.InsetBorderLeft then frame.InsetBorderLeft:Hide() end
	if frame.InsetBorderRight then frame.InsetBorderRight:Hide() end

	if frame.Bg then frame.Bg:Hide() end
end

-- All frames that have a Portrait
function S:HandlePortraitFrame(frame, createBackdrop, noStrip)
	assert(frame, "doesn't exist!")

	local name = frame and frame.GetName and frame:GetName()

	local insetFrame = name and _G[name.."Inset"] or frame.Inset
	local portraitFrame = name and _G[name.."Portrait"] or frame.Portrait or frame.portrait
	local portraitFrameOverlay = name and _G[name.."PortraitOverlay"] or frame.PortraitOverlay
	local artFrameOverlay = name and _G[name.."ArtOverlayFrame"] or frame.ArtOverlayFrame

	if not noStrip then
		frame:StripTextures()

		if portraitFrame then portraitFrame:SetAlpha(0) end
		if portraitFrameOverlay then portraitFrameOverlay:SetAlpha(0) end
		if artFrameOverlay then artFrameOverlay:SetAlpha(0) end

		if insetFrame then
			S:HandleInsetFrame(insetFrame)
		end
	end

	if frame.CloseButton then
		S:HandleCloseButton(frame.CloseButton)
	end

	if createBackdrop then
		frame:CreateBackdrop("Transparent", nil, nil, nil, nil, nil, nil, true)
	else
		frame:SetTemplate("Transparent")
	end
end

function S:SetBackdropBorderColor(frame, script)
	if frame.backdrop then frame = frame.backdrop end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(unpack(script == "OnEnter" and E.media.rgbvaluecolor or E.media.bordercolor))
	end
end

function S:SetModifiedBackdrop()
	if self:IsEnabled() then
		S:SetBackdropBorderColor(self, "OnEnter")
	end
end

function S:SetOriginalBackdrop()
	if self:IsEnabled() then
		S:SetBackdropBorderColor(self, "OnLeave")
	end
end

function S:SetDisabledBackdrop()
	if self:IsMouseOver() then
		S:SetBackdropBorderColor(self, "OnDisable")
	end
end

function S:StatusBarColorGradient(bar, value, max, backdrop)
	if not (bar and value) then return end

	local current = (not max and value) or (value and max and max ~= 0 and value/max)
	if not current then return end

	local r, g, b = E:ColorGradient(current, 0.8,0,0, 0.8,0.8,0, 0,0.8,0)
	bar:SetStatusBarColor(r, g, b)

	if not backdrop then
		backdrop = bar.backdrop
	end

	if backdrop then
		backdrop:SetBackdropColor(r * 0.25, g * 0.25, b * 0.25)
	end
end

-- DropDownMenu library support
function S:SkinLibDropDownMenu(prefix)
	if S[prefix.."_UIDropDownMenuSkinned"] then return end

	local key = (prefix == "L4" or prefix == "L3") and "L" or prefix

	local bd = _G[key.."_DropDownList1Backdrop"]
	local mbd = _G[key.."_DropDownList1MenuBackdrop"]
	if bd and not bd.template then bd:SetTemplate("Transparent") end
	if mbd and not mbd.template then mbd:SetTemplate("Transparent") end

	S[prefix.."_UIDropDownMenuSkinned"] = true

	local lib = prefix == "L4" and LibStub.libs["LibUIDropDownMenu-4.0"]
	if (lib and lib.UIDropDownMenu_CreateFrames) or _G[key.."_UIDropDownMenu_CreateFrames"] then
		hooksecurefunc(lib or _G, (lib and "" or key.."_") .. "UIDropDownMenu_CreateFrames", function()
			local lvls = _G[(key == "Lib" and "LIB" or key).."_UIDROPDOWNMENU_MAXLEVELS"]
			local ddbd = lvls and _G[key.."_DropDownList"..lvls.."Backdrop"]
			local ddmbd = lvls and _G[key.."_DropDownList"..lvls.."MenuBackdrop"]
			if ddbd and not ddbd.template then ddbd:SetTemplate("Transparent") end
			if ddmbd and not ddmbd.template then ddmbd:SetTemplate("Transparent") end
		end)
	end
end

function S:SkinTalentListButtons(frame)
	local name = frame and frame:GetName()
	if name then
		local bcl = _G[name.."BtnCornerLeft"]
		local bcr = _G[name.."BtnCornerRight"]
		local bbb = _G[name.."ButtonBottomBorder"]
		if bcl then bcl:SetTexture() end
		if bcr then bcr:SetTexture() end
		if bbb then bbb:SetTexture() end
	end

	if frame.Inset then
		S:HandleInsetFrame(frame.Inset)

		frame.Inset:Point("TOPLEFT", 4, -60)
		frame.Inset:Point("BOTTOMRIGHT", -6, 26)
	end
end

function S:HandleButton(button, strip, isDecline, noStyle, createBackdrop, template, noGlossTex, overrideTex, frameLevel, regionsKill, regionsZero)
	assert(button, "doesn't exist!")

	if button.isSkinned then return end

	if button.SetNormalTexture and not overrideTex then button:SetNormalTexture(E.ClearTexture) end
	if button.SetHighlightTexture then button:SetHighlightTexture(E.ClearTexture) end
	if button.SetPushedTexture then button:SetPushedTexture(E.ClearTexture) end
	if button.SetDisabledTexture then button:SetDisabledTexture(E.ClearTexture) end

	if strip then button:StripTextures() end

	S:HandleBlizzardRegions(button, nil, regionsKill, regionsZero)

	if button.Icon then
		local Texture = button.Icon:GetTexture()
		if Texture and (type(Texture) == "string" and strfind(Texture, [[Interface\ChatFrame\ChatFrameExpandArrow]])) then
			button.Icon:SetTexture(E.Media.Textures.ArrowUp)
			button.Icon:SetRotation(S.ArrowRotation.right)
			button.Icon:SetVertexColor(1, 1, 1)
		end
	end

	if isDecline and button.Icon then
		button.Icon:SetTexture(E.Media.Textures.Close)
	end

	if not noStyle then
		if createBackdrop then
			button:CreateBackdrop(template, not noGlossTex, nil, nil, nil, nil, nil, true, frameLevel)
		else
			button:SetTemplate(template, not noGlossTex)
		end

		button:HookScript("OnEnter", S.SetModifiedBackdrop)
		button:HookScript("OnLeave", S.SetOriginalBackdrop)
		button:HookScript("OnDisable", S.SetDisabledBackdrop)
	end

	button.isSkinned = true
end

do
	local function GetElement(frame, element, useParent)
		if useParent then frame = frame:GetParent() end

		local child = frame[element]
		if child then return child end

		local name = frame:GetName()
		if name then return _G[name..element] end
	end

	local function GetButton(frame, buttons)
		for _, data in ipairs(buttons) do
			if type(data) == "string" then
				local found = GetElement(frame, data)
				if found then return found end
			else -- has useParent
				local found = GetElement(frame, data[1], data[2])
				if found then return found end
			end
		end
	end

	local function ThumbStatus(frame)
		if not frame.Thumb then
			return
		elseif not frame:IsEnabled() then
			frame.Thumb.backdrop:SetBackdropColor(0.3, 0.3, 0.3)
			return
		end

		local _, max = frame:GetMinMaxValues()
		if max == 0 then
			frame.Thumb.backdrop:SetBackdropColor(0.3, 0.3, 0.3)
		else
			frame.Thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
		end
	end

	local function ThumbWatcher(frame)
		hooksecurefunc(frame, "Enable", ThumbStatus)
		hooksecurefunc(frame, "Disable", ThumbStatus)
		hooksecurefunc(frame, "SetEnabled", ThumbStatus)
		hooksecurefunc(frame, "SetMinMaxValues", ThumbStatus)
		ThumbStatus(frame)
	end

	local upButtons = {"ScrollUpButton", "UpButton", "ScrollUp", {"scrollUp", true}, "Back"}
	local downButtons = {"ScrollDownButton", "DownButton", "ScrollDown", {"scrollDown", true}, "Forward"}
	local thumbButtons = {"ThumbTexture", "thumbTexture", "Thumb"}

	function S:HandleScrollBar(frame, thumbY, thumbX, template)
		assert(frame, "doesn't exist!")

		if frame.backdrop then return end

		local upButton, downButton = GetButton(frame, upButtons), GetButton(frame, downButtons)
		local thumb = GetButton(frame, thumbButtons) or (frame.GetThumbTexture and frame:GetThumbTexture())

		frame:StripTextures()
		frame:CreateBackdrop(template or "Transparent", nil, nil, nil, nil, nil, nil, nil, true)
		frame.backdrop:Point("TOPLEFT", upButton or frame, upButton and "BOTTOMLEFT" or "TOPLEFT", 0, 1)
		frame.backdrop:Point("BOTTOMRIGHT", downButton or frame, upButton and "TOPRIGHT" or "BOTTOMRIGHT", 0, -1)

		if frame.Background then frame.Background:Hide() end
		if frame.ScrollUpBorder then frame.ScrollUpBorder:Hide() end
		if frame.ScrollDownBorder then frame.ScrollDownBorder:Hide() end

		local frameLevel = frame:GetFrameLevel()
		if upButton then
			S:HandleNextPrevButton(upButton, "up")
			upButton:SetFrameLevel(frameLevel + 2)
		end
		if downButton then
			S:HandleNextPrevButton(downButton, "down")
			downButton:SetFrameLevel(frameLevel + 2)
		end
		if thumb and not thumb.backdrop then
			thumb:SetTexture()
			thumb:CreateBackdrop(nil, true, true, nil, nil, nil, nil, nil, frameLevel + 1)

			if not frame.Thumb then
				frame.Thumb = thumb
			end

			if thumb.backdrop then
				if not thumbX then thumbX = 0 end
				if not thumbY then thumbY = 0 end

				thumb.backdrop:Point("TOPLEFT", thumb, thumbX, -thumbY)
				thumb.backdrop:Point("BOTTOMRIGHT", thumb, -thumbX, thumbY)

				if frame.SetEnabled then
					ThumbWatcher(frame)
				else
					thumb.backdrop:SetBackdropColor(unpack(E.media.rgbvaluecolor))
				end
			end
		end
	end

	-- WoWTrimScrollBar
	local function ReskinScrollBarArrow(frame, direction)
		S:HandleNextPrevButton(frame, direction)

		if frame.Texture then
			frame.Texture:SetAlpha(0)

			if frame.Overlay then
				frame.Overlay:SetAlpha(0)
			end
		else
			frame:StripTextures()
		end
	end

	local function ThumbOnEnter(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .75)
		end
	end

	local function ThumbOnLeave(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame

		if thumb.backdrop and not thumb.__isActive then
			thumb.backdrop:SetBackdropColor(r, g, b, .25)
		end
	end

	local function ThumbOnMouseDown(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		thumb.__isActive = true

		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .75)
		end
	end

	local function ThumbOnMouseUp(frame)
		local r, g, b = unpack(E.media.rgbvaluecolor)
		local thumb = frame.thumb or frame
		thumb.__isActive = nil

		if thumb.backdrop then
			thumb.backdrop:SetBackdropColor(r, g, b, .25)
		end
	end

	function S:HandleTrimScrollBar(frame, small)
		assert(frame, "does not exist.")

		frame:StripTextures()

		ReskinScrollBarArrow(frame.Back, 'up')
		ReskinScrollBarArrow(frame.Forward, 'down')

		if frame.Background then
			frame.Background:Hide()
		end

		local track = frame.Track
		if track then
			track:DisableDrawLayer('ARTWORK')
		end

		local thumb = frame:GetThumb()
		if thumb then
			thumb:DisableDrawLayer('ARTWORK')
			thumb:DisableDrawLayer('BACKGROUND')
			thumb:CreateBackdrop('Transparent')
			thumb.backdrop:SetFrameLevel(thumb:GetFrameLevel()+1)

			local r, g, b = unpack(E.media.rgbvaluecolor)
			thumb.backdrop:SetBackdropColor(r, g, b, .25)

			thumb:HookScript('OnEnter', ThumbOnEnter)
			thumb:HookScript('OnLeave', ThumbOnLeave)
			thumb:HookScript('OnMouseUp', ThumbOnMouseUp)
			thumb:HookScript('OnMouseDown', ThumbOnMouseDown)
		end
	end
end

do --Tab Regions
	local tabs = {
		"LeftDisabled",
		"MiddleDisabled",
		"RightDisabled",
		"Left",
		"Middle",
		"Right"
	}

	function S:HandleTab(tab, noBackdrop, template)
		if not tab or (tab.backdrop and not noBackdrop) then return end

		for _, object in pairs(tabs) do
			local textureName = tab:GetName() and _G[tab:GetName()..object]
			if textureName then
				textureName:SetTexture()
			elseif tab[object] then
				tab[object]:SetTexture()
			end
		end

		local highlightTex = tab.GetHighlightTexture and tab:GetHighlightTexture()
		if highlightTex then
			highlightTex:SetTexture()
		else
			tab:StripTextures()
		end

		if not noBackdrop then
			tab:CreateBackdrop(template)

			local spacing = 8
			tab.backdrop:Point("TOPLEFT", spacing, E.PixelMode and -1 or -3)
			tab.backdrop:Point("BOTTOMRIGHT", -spacing, 3)
		end
	end
end

function S:HandleRotateButton(btn)
	if btn.isSkinned then return end

	btn:SetTemplate()
	btn:Size(btn:GetWidth() - 14, btn:GetHeight() - 14)

	local normTex = btn:GetNormalTexture()
	local pushTex = btn:GetPushedTexture()
	local highlightTex = btn:GetHighlightTexture()

	normTex:SetInside()
	normTex:SetTexCoord(0.3, 0.29, 0.3, 0.65, 0.69, 0.29, 0.69, 0.65)

	pushTex:SetAllPoints(normTex)
	pushTex:SetTexCoord(0.3, 0.29, 0.3, 0.65, 0.69, 0.29, 0.69, 0.65)

	highlightTex:SetAllPoints(normTex)
	highlightTex:SetTexture(1, 1, 1, 0.3)

	btn.isSkinned = true
end

function S:HandleBlizzardRegions(frame, name, kill, zero)
	if not name then name = frame.GetName and frame:GetName() end
	for _, area in pairs(S.Blizzard.Regions) do
		local object = (name and _G[name..area]) or frame[area]
		if object then
			if kill then
				object:Kill()
			elseif zero then
				object:SetAlpha(0)
			else
				object:Hide()
			end
		end
	end
end

function S:HandleEditBox(frame, template)
	assert(frame, "doesn't exist!")

	if frame.backdrop then return end

	frame:CreateBackdrop(template, nil, nil, nil, nil, nil, nil, nil, true)
	frame.backdrop:SetPoint("TOPLEFT", -2, 0)
	frame.backdrop:SetPoint("BOTTOMRIGHT")
	S:HandleBlizzardRegions(frame)

	local EditBoxName = frame:GetName()
	if EditBoxName and (strfind(EditBoxName, "Silver") or strfind(EditBoxName, "Copper")) then
		frame.backdrop:Point("BOTTOMRIGHT", -12, -2)
	end
end

function S:HandleDropDownBox(frame, width, pos, template)
	assert(frame, "doesn't exist!")

	local frameName = frame.GetName and frame:GetName()
	local button = frame.Button or frameName and (_G[frameName.."Button"] or _G[frameName.."_Button"])
	local text = frameName and _G[frameName.."Text"] or frame.Text
	local icon = frame.Icon

	if not width then
		width = 155
	end

	frame:Width(width)
	frame:StripTextures()
	frame:CreateBackdrop(template)
	frame:SetFrameLevel(frame:GetFrameLevel() + 2)
	frame.backdrop:Point("TOPLEFT", 20, -2)
	frame.backdrop:Point("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)

	button:ClearAllPoints()

	if pos then
		button:Point("TOPRIGHT", frame.Right, -20, -21)
	else
		button:Point("RIGHT", frame, "RIGHT", -10, 3)
	end

	button.SetPoint = E.noop
	S:HandleNextPrevButton(button, "down")

	if text then
		text:ClearAllPoints()
		text:Point("RIGHT", button, "LEFT", -2, 0)
	end

	if icon then
		icon:Point("LEFT", 23, 0)
	end
end

function S:HandleStatusBar(frame, color, template)
	frame:SetFrameLevel(frame:GetFrameLevel() + 1)
	frame:StripTextures()
	frame:CreateBackdrop(template or "Transparent")
	frame:SetStatusBarTexture(E.media.normTex)
	frame:SetStatusBarColor(unpack(color or {.01, .39, .1}))
	E:RegisterStatusBar(frame)
end

do
	local check = [[Interface\Buttons\UI-CheckBox-Check]]
	local disabled = [[Interface\Buttons\UI-CheckBox-Check-Disabled]]

	local function checkNormalTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetNormalTexture(E.ClearTexture) end end
	local function checkPushedTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetPushedTexture(E.ClearTexture) end end
	local function checkHighlightTexture(checkbox, texture) if texture ~= E.ClearTexture then checkbox:SetHighlightTexture(E.ClearTexture) end end
	local function checkCheckedTexture(checkbox, texture)
		if texture == E.Media.Textures.Melli or texture == check then return end
		checkbox:SetCheckedTexture(E.private.skins.checkBoxSkin and E.Media.Textures.Melli or check)
	end
	local function checkOnDisable(checkbox)
		if not checkbox.SetDisabledTexture then return end
		checkbox:SetDisabledTexture(checkbox:GetChecked() and (E.private.skins.checkBoxSkin and E.Media.Textures.Melli or disabled) or '')
	end

	function S:HandleCheckBox(frame, noBackdrop, noReplaceTextures, frameLevel, template)
		assert(frame, "doesn't exist.")

		if frame.isSkinned then return end

		frame:StripTextures()

		if noBackdrop then
			frame:Size(16)
		else
			frame:CreateBackdrop(template, nil, nil, nil, nil, nil, nil, nil, frameLevel)
			frame.backdrop:SetInside(nil, 4, 4)
		end

		if not noReplaceTextures then
			if frame.SetCheckedTexture then
				if E.private.skins.checkBoxSkin then
					frame:SetCheckedTexture(E.Media.Textures.Melli)

					local checkedTexture = frame:GetCheckedTexture()
					checkedTexture:SetVertexColor(1, .82, 0, 0.8)
					checkedTexture:SetInside(frame.backdrop)
				else
					frame:SetCheckedTexture(check)

					if noBackdrop then
						frame:GetCheckedTexture():SetInside(nil, -4, -4)
					end
				end
			end

			if frame.SetDisabledTexture then
				if E.private.skins.checkBoxSkin then
					frame:SetDisabledTexture(E.Media.Textures.Melli)

					local disabledTexture = frame:GetDisabledTexture()
					disabledTexture:SetVertexColor(.6, .6, .6, .8)
					disabledTexture:SetInside(frame.backdrop)
				else
					frame:SetDisabledTexture(disabled)

					if noBackdrop then
						frame:GetDisabledTexture():SetInside(nil, -4, -4)
					end
				end
			end

			frame:HookScript("OnDisable", checkOnDisable)

			hooksecurefunc(frame, "SetNormalTexture", checkNormalTexture)
			hooksecurefunc(frame, "SetPushedTexture", checkPushedTexture)
			hooksecurefunc(frame, "SetCheckedTexture", checkCheckedTexture)
			hooksecurefunc(frame, "SetHighlightTexture", checkHighlightTexture)
		end

		frame.isSkinned = true
	end
end

function S:HandleColorSwatch(frame, size)
	if frame.isSkinned then return end

	frame:StripTextures()
	frame:CreateBackdrop("Default")
	frame.backdrop:SetFrameLevel(frame:GetFrameLevel())

	if size then
		frame:Size(size)
	end

	local normalTexture = frame:GetNormalTexture()
	normalTexture:SetTexture(E.media.blankTex)
	normalTexture:SetInside(frame.backdrop)

	frame.isSkinned = true
end

function S:HandleIcon(icon, parent)
	parent = parent or icon:GetParent()

	icon:SetTexCoord(unpack(E.TexCoords))
	parent:CreateBackdrop("Default")
	icon:SetParent(parent.backdrop)
	parent.backdrop:SetOutside(icon)
end

function S:HandleItemButton(b, shrinkIcon)
	if b.isSkinned then return end

	local icon = b.icon or b.IconTexture or b.iconTexture
	local texture
	if b:GetName() and _G[b:GetName().."IconTexture"] then
		icon = _G[b:GetName().."IconTexture"]
	elseif b:GetName() and _G[b:GetName().."Icon"] then
		icon = _G[b:GetName().."Icon"]
	end

	if icon and icon:GetTexture() then
		texture = icon:GetTexture()
	end

	b:StripTextures()
	b:CreateBackdrop("Default", true)
	b:StyleButton()

	if icon then
		icon:SetTexCoord(unpack(E.TexCoords))

		if shrinkIcon then
			b.backdrop:SetAllPoints()
			icon:SetInside(b)
		else
			b.backdrop:SetOutside(icon)
		end
		icon:SetParent(b.backdrop)

		if texture then
			icon:SetTexture(texture)
		end
	end

	b.isSkinned = true
end

do
	local closeOnEnter = function(btn) if btn.Texture then btn.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor)) end end
	local closeOnLeave = function(btn) if btn.Texture then btn.Texture:SetVertexColor(1, 1, 1) end end

	function S:HandleCloseButton(f, point, x, y)
		assert(f, "doenst exist!")

		f:StripTextures()

		if not f.Texture then
			f.Texture = f:CreateTexture(nil, "OVERLAY")
			f.Texture:Point("CENTER")
			f.Texture:SetTexture(E.Media.Textures.Close)
			f.Texture:Size(12)
			f:HookScript("OnEnter", closeOnEnter)
			f:HookScript("OnLeave", closeOnLeave)
			f:SetHitRectInsets(6, 6, 7, 7)
		end

		if point then
			f:Point("TOPRIGHT", point, "TOPRIGHT", x or 2, y or 2)
		end
	end

	function S:HandleNextPrevButton(btn, arrowDir, color, noBackdrop, stripTexts, frameLevel)
		if btn.isSkinned then return end

		if not arrowDir then
			arrowDir = "down"

			local name = btn:GetName()
			local ButtonName = name and name:lower()
			if ButtonName then
				if strfind(ButtonName, "left") or strfind(ButtonName, "prev") or strfind(ButtonName, "decrement") or strfind(ButtonName, "backward") or strfind(ButtonName, "back") then
					arrowDir = "left"
				elseif strfind(ButtonName, "right") or strfind(ButtonName, "next") or strfind(ButtonName, "increment") or strfind(ButtonName, "forward") then
					arrowDir = "right"
				elseif strfind(ButtonName, "scrollup") or strfind(ButtonName, "upbutton") or strfind(ButtonName, "top") or strfind(ButtonName, "asc") or strfind(ButtonName, "home") or strfind(ButtonName, "maximize") then
					arrowDir = "up"
				end
			end
		end

		btn:StripTextures()

		if btn.Texture then
			btn.Texture:SetAlpha(0)
		end

		if not noBackdrop then
			S:HandleButton(btn, nil, nil, true, nil, nil, nil, nil, frameLevel)
		end

		if stripTexts then
			btn:StripTexts()
		end

		btn:SetNormalTexture(E.Media.Textures.ArrowUp)
		btn:SetPushedTexture(E.Media.Textures.ArrowUp)
		btn:SetDisabledTexture(E.Media.Textures.ArrowUp)

		local Normal, Disabled, Pushed = btn:GetNormalTexture(), btn:GetDisabledTexture(), btn:GetPushedTexture()

		if noBackdrop then
			btn:Size(20)
			Disabled:SetVertexColor(.5, .5, .5)
			btn.Texture = Normal

			if not color then
				btn:HookScript("OnEnter", closeOnEnter)
				btn:HookScript("OnLeave", closeOnLeave)
			end
		else
			btn:Size(18)
			Disabled:SetVertexColor(.3, .3, .3)
		end

		Normal:SetInside()
		Pushed:SetInside()
		Disabled:SetInside()

		Normal:SetTexCoord(0, 1, 0, 1)
		Pushed:SetTexCoord(0, 1, 0, 1)
		Disabled:SetTexCoord(0, 1, 0, 1)

		local rotation = S.ArrowRotation[arrowDir]
		if rotation then
			Normal:SetRotation(rotation)
			Pushed:SetRotation(rotation)
			Disabled:SetRotation(rotation)
		end

		if color then
			Normal:SetVertexColor(color.r, color.g, color.b)
		else
			Normal:SetVertexColor(1, 1, 1)
		end

		btn.isSkinned = true
	end
end

function S:HandleSliderFrame(frame, template, frameLevel)
	assert(frame, "doesn't exist!")

	local orientation = frame:GetOrientation()
	local SIZE = 12

	if frame.SetBackdrop then
		frame:SetBackdrop(nil)
	end

	frame:StripTextures()
	frame:SetThumbTexture(E.Media.Textures.Melli)

	if not frame.backdrop then
		frame:SetTemplate(template)
	end

	local thumb = frame:GetThumbTexture()
	thumb:SetVertexColor(1, 0.82, 0, 0.8)
	thumb:Size(SIZE-2)

	if orientation == "VERTICAL" then
		frame:Width(SIZE)
	else
		frame:Height(SIZE)

		for _, region in next, { frame:GetRegions() } do
			if region:IsObjectType('FontString') then
				local point, anchor, anchorPoint, x, y = region:GetPoint()
				if strfind(anchorPoint, 'BOTTOM') then
					region:Point(point, anchor, anchorPoint, x, y - 4)
				end
			end
		end
	end
end

function S:HandleIconSelectionFrame(frame, numIcons, buttonNameTemplate, frameNameOverride)
	local frameName = frameNameOverride or frame:GetName() --We need override in case Blizzard fucks up the naming (guild bank)
	local scrollFrame = _G[frameName.."ScrollFrame"]
	local editBox = _G[frameName.."EditBox"]
	local okayButton = _G[frameName.."OkayButton"] or _G[frameName.."Okay"]
	local cancelButton = _G[frameName.."CancelButton"] or _G[frameName.."Cancel"]

	frame:StripTextures()
	scrollFrame:StripTextures()
	editBox:DisableDrawLayer("BACKGROUND") --Removes textures around it

	frame:CreateBackdrop("Transparent")
	frame.backdrop:Point("TOPLEFT", frame, "TOPLEFT", 10, -12)
	frame.backdrop:Point("BOTTOMRIGHT", cancelButton, "BOTTOMRIGHT", 8, -8)

	S:HandleButton(okayButton)
	S:HandleButton(cancelButton)
	S:HandleEditBox(editBox)

	for i = 1, numIcons do
		local button = _G[buttonNameTemplate..i]
		local icon = _G[button:GetName().."Icon"]
		button:StripTextures()
		button:SetTemplate("Default")
		button:StyleButton(nil, true)
		icon:SetInside()
		icon:SetTexCoord(unpack(E.TexCoords))
	end
end

function S:SetNextPrevButtonDirection(frame, arrowDir)
	local direction = self.ArrowRotation[(arrowDir or "down")]

	frame:GetNormalTexture():SetRotation(direction)
	frame:GetDisabledTexture():SetRotation(direction)
	frame:GetPushedTexture():SetRotation(direction)
end

local function collapseSetNormalTexture_Text(self, texture)
	if texture then
		if strfind(texture, "MinusButton", 1, true) or strfind(texture, "ZoomOutButton", 1, true) then
			self.collapseText:SetText("-")
			return
		elseif strfind(texture, "PlusButton", 1, true) or strfind(texture, "ZoomInButton", 1, true) then
			self.collapseText:SetText("+")
			return
		end
	end
	self.collapseText:SetText("")
end
local function collapseSetNormalTexture_Texture(self, texture)
	if texture then
		if strfind(texture, "MinusButton", 1, true) or strfind(texture, "ZoomOutButton", 1, true) then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Minus)
			self:GetPushedTexture():SetTexture(E.Media.Textures.Minus)
			self:GetDisabledTexture():SetTexture(E.Media.Textures.Minus)
			return
		elseif strfind(texture, "PlusButton", 1, true) or strfind(texture, "ZoomInButton", 1, true) then
			self:GetNormalTexture():SetTexture(E.Media.Textures.Plus)
			self:GetPushedTexture():SetTexture(E.Media.Textures.Plus)
			self:GetDisabledTexture():SetTexture(E.Media.Textures.Plus)
			return
		end
	end
	self:GetNormalTexture():SetTexture(0, 0, 0, 0)
	self:GetPushedTexture():SetTexture(0, 0, 0, 0)
	self:GetDisabledTexture():SetTexture(0, 0, 0, 0)
end
function S:HandleCollapseExpandButton(button, defaultState, useFontString, xOffset, yOffset)
	if button.isSkinned then return end

	if defaultState == "auto" then
		local texture = button:GetNormalTexture():GetTexture()
		if strfind(texture, "MinusButton", 1, true) or strfind(texture, "ZoomOutButton", 1, true) then
			defaultState = "-"
		elseif strfind(texture, "PlusButton", 1, true) or strfind(texture, "ZoomInButton", 1, true) then
			defaultState = "+"
		end
	end

	button:SetNormalTexture("")
	button:SetPushedTexture("")
	button:SetHighlightTexture("")
	button:SetDisabledTexture("")

	button.SetPushedTexture = E.noop
	button.SetHighlightTexture = E.noop
	button.SetDisabledTexture = E.noop

	if useFontString then
		button.collapseText = button:CreateFontString(nil, "OVERLAY")
		button.collapseText:FontTemplate(nil, 22)
		button.collapseText:Point("LEFT", xOffset or 5, yOffset or 0)
		button.collapseText:SetText("")

		if defaultState == "+" then
			button.collapseText:SetText("+")
		elseif defaultState == "-" then
			button.collapseText:SetText("-")
		end

		button.SetNormalTexture = collapseSetNormalTexture_Text
	else
		local normalTexture = button:GetNormalTexture()
		normalTexture:Size(16)
		normalTexture:ClearAllPoints()
		normalTexture:Point("LEFT", xOffset or 3, yOffset or 0)
		normalTexture.SetPoint = E.noop

		local pushedTexture = button:GetPushedTexture()
		pushedTexture:Size(16)
		pushedTexture:ClearAllPoints()
		pushedTexture:Point("LEFT", xOffset or 3, yOffset or 0)
		pushedTexture.SetPoint = E.noop

		local disabledTexture = button:GetDisabledTexture()
		disabledTexture:Size(16)
		disabledTexture:ClearAllPoints()
		disabledTexture:Point("LEFT", xOffset or 3, yOffset or 0)
		disabledTexture.SetPoint = E.noop
		disabledTexture:SetVertexColor(0.6, 0.6, 0.6)

		if defaultState == "+" then
			normalTexture:SetTexture(E.Media.Textures.Plus)
			pushedTexture:SetTexture(E.Media.Textures.Plus)
			disabledTexture:SetTexture(E.Media.Textures.Plus)
		elseif defaultState == "-" then
			normalTexture:SetTexture(E.Media.Textures.Minus)
			pushedTexture:SetTexture(E.Media.Textures.Minus)
			disabledTexture:SetTexture(E.Media.Textures.Minus)
		end

		button.SetNormalTexture = collapseSetNormalTexture_Texture
	end

	button.isSkinned = true
end

do -- Handle collapse
	local function UpdateCollapseTexture(button, texture, skip)
		if skip then return end

		if type(texture) == "number" then -- 130821 minus, 130838 plus
			button:SetNormalTexture(texture == 130838 and E.Media.Textures.PlusButton or E.Media.Textures.MinusButton, true)
		elseif strfind(texture, "Plus") or strfind(texture, "Closed") then
			button:SetNormalTexture(E.Media.Textures.PlusButton, true)
		elseif strfind(texture, "Minus") or strfind(texture, "Open") then
			button:SetNormalTexture(E.Media.Textures.MinusButton, true)
		end
	end

	local function syncPushTexture(button, _, skip)
		if skip then return end

		local normal = button:GetNormalTexture():GetTexture()
		button:SetPushedTexture(normal, true)
	end

	function S:HandleCollapseTexture(button, syncPushed)
		if syncPushed then -- not needed always
			hooksecurefunc(button, "SetPushedTexture", syncPushTexture)
			syncPushTexture(button)
		else
			button:SetPushedTexture(E.ClearTexture)
		end

		hooksecurefunc(button, "SetNormalTexture", UpdateCollapseTexture)
		UpdateCollapseTexture(button, button:GetNormalTexture():GetTexture())
	end
end


local function SetPanelWindowInfo(frame, name, value, igroneUpdate)
	frame:SetAttribute(name, value)

	if not igroneUpdate and frame:IsShown() then
		UpdateUIPanelPositions(frame)
	end
end

local UI_PANEL_OFFSET = 7

function S:SetUIPanelWindowInfo(frame, name, value, offset, igroneUpdate, anyPanel)
	local frameName = frame and frame.GetName and frame:GetName()
	if not (frameName and (anyPanel or UIPanelWindows[frameName])) then return end

	name = "UIPanelLayout-"..name

	if name == "UIPanelLayout-width" then
		value = E:Scale(value or (frame.backdrop and frame.backdrop:GetWidth() or frame:GetWidth())) + (offset or 0) + UI_PANEL_OFFSET
	end

	local valueChanged = frame:GetAttribute(name) ~= value

	if not frame:CanChangeAttribute() then
		local frameInfo = format("%s-%s", frameName, name)

		if S.uiPanelQueue[frameInfo] then
			if not valueChanged then
				S.uiPanelQueue[frameInfo][3] = nil
			else
				S.uiPanelQueue[frameInfo][3] = value
				S.uiPanelQueue[frameInfo][4] = igroneUpdate
			end
		elseif valueChanged then
			S.uiPanelQueue[frameInfo] = {frame, name, value, igroneUpdate}

			if not S.inCombat then
				S.inCombat = true
				S:RegisterEvent("PLAYER_REGEN_ENABLED")
			end
		end
	elseif valueChanged then
		SetPanelWindowInfo(frame, name, value, igroneUpdate)
	end
end

function S:SetBackdropHitRect(frame, backdrop, clampRect, attempt)
	if not frame then return end

	backdrop = backdrop or frame.backdrop
	if not backdrop then return end

	local left = frame:GetLeft()
	local bleft = backdrop:GetLeft()

	if not left or not bleft then
		if attempt ~= 10 then
			E:Delay(0.1, S.SetBackdropHitRect, S, frame, backdrop, clampRect, attempt and attempt + 1 or 1)
		end

		return
	end

	left = floor(left + 0.5)
	local right = floor(frame:GetRight() + 0.5)
	local top = floor(frame:GetTop() + 0.5)
	local bottom = floor(frame:GetBottom() + 0.5)

	bleft = floor(bleft + 0.5)
	local bright = floor(backdrop:GetRight() + 0.5)
	local btop = floor(backdrop:GetTop() + 0.5)
	local bbottom = floor(backdrop:GetBottom() + 0.5)

	left = bleft - left
	right = right - bright
	top = top - btop
	bottom = bbottom - bottom

	if not frame:CanChangeAttribute() then
		S.hitRectQueue[frame] = {left, right, top, bottom, clampRect}

		if not S.inCombat then
			S.inCombat = true
			S:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
	else
		frame:SetHitRectInsets(left, right, top, bottom)

		if clampRect then
			frame:SetClampRectInsets(left, -right, -top, bottom)
		end
	end
end

function S:PLAYER_REGEN_ENABLED()
	S.inCombat = nil
	S:UnregisterEvent("PLAYER_REGEN_ENABLED")

	for frameInfo, info in pairs(S.uiPanelQueue) do
		if info[3] then
			SetPanelWindowInfo(info[1], info[2], info[3], info[4])
		end
		S.uiPanelQueue[frameInfo] = nil
	end

	for frame, info in pairs(S.hitRectQueue) do
		frame:SetHitRectInsets(info[1], info[2], info[3], info[4])

		if info[5] then
			frame:SetClampRectInsets(info[1], info[2], info[3], info[4])
		end

		S.hitRectQueue[frame] = nil
	end
end

function S:ADDON_LOADED(_, addonName)
	if not S.allowBypass[addonName] and not E.initialized then
		return
	end

	local object = S.addonsToLoad[addonName]
	if object then
		S:CallLoadedAddon(addonName, object)
	end
end

-- EXAMPLE:
--- S:AddCallbackForAddon('Details', 'MyAddon_Details', MyAddon.SkinDetails)
---- arg1: Addon name (same as the toc): MyAddon.toc (without extension)
---- arg2: Given name (try to use something that won't be used by someone else)
---- arg3: load function (preferably not-local)
-- this is used for loading skins that should be executed when the addon loads (including blizzard addons that load later).
-- please add a given name, non-given-name is specific for elvui core addon.
function S:AddCallbackForAddon(addonName, name, func, forceLoad, bypass, position) -- arg2: name is 'given name'; see example above.
	local load = (type(name) == 'function' and name) or (not func and (S[name] or S[addonName]))
	S:RegisterSkin(addonName, load or func, forceLoad, bypass, position)
end

-- nonAddonsToLoad:
--- this is used for loading skins when our skin init function executes.
--- please add a given name, non-given-name is specific for elvui core addon.
function S:AddCallback(name, func, position) -- arg1: name is 'given name'
	local load = (type(name) == 'function' and name) or (not func and S[name])
	S:RegisterSkin('ElvUI', load or func, nil, nil, position)
end

local function errorhandler(err)
	return _G.geterrorhandler()(err)
end

function S:RegisterSkin(addonName, func, forceLoad, bypass, position)
	if bypass then
		S.allowBypass[addonName] = true
	end

	if forceLoad then
		xpcall(func, errorhandler)
		S.addonsToLoad[addonName] = nil
	elseif addonName == 'ElvUI' then
		if position then
			tinsert(S.nonAddonsToLoad, position, func)
		else
			tinsert(S.nonAddonsToLoad, func)
		end
	else
		local addon = S.addonsToLoad[addonName]
		if not addon then
			S.addonsToLoad[addonName] = {}
			addon = S.addonsToLoad[addonName]
		end

		if position then
			tinsert(addon, position, func)
		else
			tinsert(addon, func)
		end
	end
end

function S:CallLoadedAddon(addonName, object)
	for _, func in next, object do
		xpcall(func, errorhandler)
	end

	S.addonsToLoad[addonName] = nil
end

function S:Initialize()
	S.Initialized = true
	S.db = E.private.skins

	S.uiPanelQueue = {}
	S.hitRectQueue = {}

	for index, func in next, S.nonAddonsToLoad do
		xpcall(func, errorhandler)
		S.nonAddonsToLoad[index] = nil
	end

	for addonName, object in pairs(S.addonsToLoad) do
		local isLoaded, isFinished = IsAddOnLoaded(addonName)
		if isLoaded and isFinished then
			S:CallLoadedAddon(addonName, object)
		end
	end

	-- Early Skin Handling (populated before ElvUI is loaded from the Ace3 file)
	if E.private.skins.ace3Enable and S.EarlyAceWidgets then
		for _, n in next, S.EarlyAceWidgets do
			if n.SetLayout then
				S:Ace3_RegisterAsContainer(n)
			else
				S:Ace3_RegisterAsWidget(n)
			end
		end
		for _, n in next, S.EarlyAceTooltips do
			S:Ace3_SkinTooltip(LibStub(n, true))
		end
	end

	if E.private.skins.libDropdown and S.EarlyDropdowns then
		for _, n in next, S.EarlyDropdowns do
			S:SkinLibDropDownMenu(n)
		end
	end
end

-- Keep this outside, it's used for skinning addons before ElvUI load
S:RegisterEvent("ADDON_LOADED")

local function InitializeCallback()
	S:Initialize()
end

E:RegisterModule(S:GetName(), InitializeCallback)