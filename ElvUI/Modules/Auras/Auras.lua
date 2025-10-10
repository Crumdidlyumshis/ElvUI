local E, L, V, P, G = unpack(ElvUI)
local A = E:GetModule("Auras")
local LSM = E.Libs.LSM
local LBF = E.Libs.LBF

--Lua functions
local _G = _G
local unpack, pairs, ipairs, next, type = unpack, pairs, ipairs, next, type
local floor, min, max, huge = math.floor, math.min, math.max, math.huge
local wipe, tinsert, tsort, tremove = table.wipe, table.insert, table.sort, table.remove
--WoW API / Variables
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitAura = UnitAura
local CancelItemTempEnchantment = CancelItemTempEnchantment
local CancelUnitBuff = CancelUnitBuff
local GetInventoryItemQuality = GetInventoryItemQuality
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local DebuffTypeColor = DebuffTypeColor

local DIRECTION_TO_POINT = {
	DOWN_RIGHT = "TOPLEFT",
	DOWN_LEFT = "TOPRIGHT",
	UP_RIGHT = "BOTTOMLEFT",
	UP_LEFT = "BOTTOMRIGHT",
	RIGHT_DOWN = "TOPLEFT",
	RIGHT_UP = "BOTTOMLEFT",
	LEFT_DOWN = "TOPRIGHT",
	LEFT_UP = "BOTTOMRIGHT"
}

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = 1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = -1,
	RIGHT_DOWN = 1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = -1
}

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	DOWN_RIGHT = -1,
	DOWN_LEFT = -1,
	UP_RIGHT = 1,
	UP_LEFT = 1,
	RIGHT_DOWN = -1,
	RIGHT_UP = 1,
	LEFT_DOWN = -1,
	LEFT_UP = 1
}

local IS_HORIZONTAL_GROWTH = {
	RIGHT_DOWN = true,
	RIGHT_UP = true,
	LEFT_DOWN = true,
	LEFT_UP = true
}

local enchantableSlots = {
	[1] = 16,
	[2] = 17
}

local weaponEnchantTime = {}
A.EnchanData = weaponEnchantTime

function A:UpdateTime(elapsed)
	self.timeLeft = self.timeLeft - elapsed

	self.statusBar:SetValue(self.timeLeft)

	if self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	local db = A.db[self.auraType]
	if self.statusBar:IsShown() and db.barColorGradient then
		self.statusBar:SetStatusBarColor(E.oUF:ColorGradient(self.timeLeft, self.duration or 0, .8, 0, 0, .8, .8, 0, 0, .8, 0))
	end

	local value, id, nextUpdate, remainder = E:GetTimeInfo(self.timeLeft, self.threshold, self.hhmmThreshold, self.mmssThreshold)
	self.nextUpdate = nextUpdate

	local style = E.TimeFormats[id]
	if style then
		local which = (self.textColors and 2 or 1) + (self.showSeconds and 0 or 2)
		if self.textColors then
			self.text:SetFormattedText(style[which], value, self.textColors[id], remainder)
		else
			self.text:SetFormattedText(style[which], value, remainder)
		end
	end

	local color = self.timeColors[id]
	if color then
		self.text:SetTextColor(color.r, color.g, color.b)
	end
end

local UpdateTooltip = function(self)
	if self.IsWeapon then
		GameTooltip:SetInventoryItem("player", enchantableSlots[self:GetID()])
	else
		GameTooltip:SetUnitAura("player", self:GetID(), self:GetParent().filter)
	end
end

local OnEnter = function(self)
	if not self:IsVisible() then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", -5, -5)
	self:UpdateTooltip()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnClick = function(self)
	if self.IsWeapon then
		CancelItemTempEnchantment(self:GetID())
	else
		CancelUnitBuff("player", self:GetID(), self:GetParent().filter)
	end
end

function A:CreateIcon(button)
	button.header = button:GetParent()
	button.filter = button.header.filter
	button.auraType = button.header.filter == 'HELPFUL' and 'buffs' or 'debuffs' -- used to update cooldown text

	button.name = button:GetName()

	button.texture = button:CreateTexture(nil, 'ARTWORK')
	button.texture:SetInside()
	button.texture:SetTexCoord(unpack(E.TexCoords))

	button.count = button:CreateFontString(nil, 'OVERLAY')
	button.count:FontTemplate()

	button.text = button:CreateFontString(nil, 'OVERLAY')
	button.text:FontTemplate()

	button.highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	button.highlight:SetTexture(1, 1, 1, .45)
	button.highlight:SetInside()

	button.statusBar = CreateFrame('StatusBar', nil, button)
	button.statusBar:OffsetFrameLevel(nil, button)
	button.statusBar:SetFrameStrata(button:GetFrameStrata())
	button.statusBar:SetMinMaxValues(0, 1)
	button.statusBar:SetValue(0)
	button.statusBar:CreateBackdrop()

	button:RegisterForClicks('RightButtonUp')

	button.UpdateTooltip = UpdateTooltip
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)
	button:SetScript("OnClick", OnClick)

	-- support cooldown override
	if not button.isRegisteredCooldown then
		button.CooldownOverride = 'auras'
		button.isRegisteredCooldown = true
		button.forceEnabled = true
		button.showSeconds = true

		if not E.RegisteredCooldowns.auras then E.RegisteredCooldowns.auras = {} end
		tinsert(E.RegisteredCooldowns.auras, button)
	end

	A:Update_CooldownOptions(button)
	A:UpdateIcon(button)

	E:SetSmoothing(button.statusBar)

	if button.filter == 'HELPFUL' and MasqueGroupBuffs and E.private.auras.masque.buffs then
		MasqueGroupBuffs:AddButton(button, A:MasqueData(button.texture, button.highlight))
		if button.__MSQ_BaseFrame then button.__MSQ_BaseFrame:SetFrameLevel(2) end --Lower the framelevel to fix issue with buttons created during combat
		MasqueGroupBuffs:ReSkin()
	elseif button.filter == 'HARMFUL' and MasqueGroupDebuffs and E.private.auras.masque.debuffs then
		MasqueGroupDebuffs:AddButton(button, A:MasqueData(button.texture, button.highlight))
		if button.__MSQ_BaseFrame then button.__MSQ_BaseFrame:SetFrameLevel(2) end --Lower the framelevel to fix issue with buttons created during combat
		MasqueGroupDebuffs:ReSkin()
	else
		button:SetTemplate()
	end
end

function A:UpdateIcon(button, update)
	local db = A.db[button.auraType]

	if update then
		button:Size(db.size)
	end

	button.count:ClearAllPoints()
	button.count:Point('BOTTOMRIGHT', db.countXOffset, db.countYOffset)
	button.count:FontTemplate(LSM:Fetch('font', db.countFont), db.countFontSize, db.countFontOutline)

	button.text:ClearAllPoints()
	button.text:Point('TOP', button, 'BOTTOM', db.timeXOffset, db.timeYOffset)
	button.text:FontTemplate(LSM:Fetch('font', db.timeFont), db.timeFontSize, db.timeFontOutline)

	local pos, iconSize = db.barPosition, db.size - (E.Border * 2)
	local onTop, onBottom, onLeft = pos == 'TOP', pos == 'BOTTOM', pos == 'LEFT'
	local barSpacing = db.barSpacing + (E.PixelMode and 1 or 3)
	local barSize = db.barSize + (E.PixelMode and 0 or 2)
	local isHorizontal = onTop or onBottom

	button.statusBar:ClearAllPoints()
	button.statusBar:Size(isHorizontal and iconSize or barSize, isHorizontal and barSize or iconSize)
	button.statusBar:Point(E.InversePoints[pos], button, pos, isHorizontal and 0 or (onLeft and -barSpacing or barSpacing), not isHorizontal and 0 or (onTop and barSpacing or -barSpacing))
	button.statusBar:SetStatusBarTexture(LSM:Fetch('statusbar', db.barTexture))
	button.statusBar:SetOrientation(isHorizontal and 'HORIZONTAL' or 'VERTICAL')
	button.statusBar:SetRotatesTexture(not isHorizontal)
end

function A:SetAuraTime(button, expiration, duration)
	button.duration = duration
	button.statusBar:SetMinMaxValues(0, duration)

	button.nextUpdate = 0

	if not button.timeLeft then
		button.timeLeft = expiration
		button:SetScript("OnUpdate", A.UpdateTime)
	else
		button.timeLeft = expiration
	end
end

function A:ClearAuraTime(button, expired)
	if not expired then
		button.statusBar:SetValue(1)
		button.statusBar:SetMinMaxValues(0, 1)
	end

	button.timeLeft = nil
	button.text:SetText("")
	button:SetScript("OnUpdate", nil)
end

function A:HasEnchant(index, weapon, expiration)
	if not weapon then
		if weaponEnchantTime[index] then
			weaponEnchantTime[index] = nil
			return true
		end
		return
	end

	if not weaponEnchantTime[index] or weaponEnchantTime[index] < expiration then
		weaponEnchantTime[index] = expiration
		return true
	end

	weaponEnchantTime[index] = expiration
end

function A:Update_CooldownOptions(button)
	E:Cooldown_Options(button, A.db.cooldown, button)
end

local buttons = {}
function A:ConfigureAuras(header, auraTable, weaponPosition)
	local headerName = header:GetName()
	local db = A.db.debuffs
	if header.filter == "HELPFUL" then
		db = A.db.buffs
	end

	local xOffset, yOffset, wrapXOffset, wrapYOffset, minWidth, minHeight
	local size = db.size
	local point = DIRECTION_TO_POINT[db.growthDirection]
	local wrapAfter = db.wrapAfter
	local maxWraps = db.maxWraps

	if IS_HORIZONTAL_GROWTH[db.growthDirection] then
		minWidth = ((wrapAfter == 1 and 0 or db.horizontalSpacing) + size) * wrapAfter
		minHeight = (db.verticalSpacing + size) * maxWraps
		xOffset = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[db.growthDirection] * (db.horizontalSpacing + size)
		yOffset = 0
		wrapXOffset = 0
		wrapYOffset = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[db.growthDirection] * (db.verticalSpacing + size)
	else
		minWidth = (db.horizontalSpacing + size) * maxWraps
		minHeight = ((wrapAfter == 1 and 0 or db.verticalSpacing) + size) * wrapAfter
		xOffset = 0
		yOffset = DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[db.growthDirection] * (db.verticalSpacing + size)
		wrapXOffset = DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[db.growthDirection] * (db.horizontalSpacing + size)
		wrapYOffset = 0
	end

	wipe(buttons)
	local button
	for i = 1, #auraTable do
		button = _G[headerName.."AuraButton"..i]
		if button then
			if button:IsShown() then button:Hide() end
		else
			button = CreateFrame("Button", "$parentAuraButton"..i, header)
			A:CreateIcon(button)
		end
		local buffInfo = auraTable[i]
		button:SetID(buffInfo.index)

		if buffInfo.duration > 0 and buffInfo.expires then
			A:SetAuraTime(button, buffInfo.expires - GetTime(), buffInfo.duration)
		else
			A:ClearAuraTime(button)
		end

		if buffInfo.count > 1 then
			button.count:SetText(buffInfo.count)
		else
			button.count:SetText("")
		end

		if (db.barShow and buffInfo.duration > 0) or (db.barShow and db.barNoDuration and buffInfo.duration == 0) then
			button.statusBar:Show()

			if not button.timeLeft or not db.barColorGradient then
				button.statusBar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b)
			end
		else
			button.statusBar:Hide()
		end

		button.text:SetShown(db.showDuration)

		if buffInfo.filter == "HARMFUL" then
			local color = DebuffTypeColor[buffInfo.dispelType or ""]
			button:SetBackdropBorderColor(color.r, color.g, color.b)
			button.statusBar.backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			local cr, cg, cb = unpack(E.media.bordercolor)
			button:SetBackdropBorderColor(cr, cg, cb)
			button.statusBar.backdrop:SetBackdropBorderColor(cr, cg, cb)
		end

		button.texture:SetTexture(buffInfo.icon)

		buttons[i] = button
	end

	if weaponPosition then
		for weapon = 2, 1, -1 do
			button = _G["ElvUIPlayerBuffsTempEnchant"..weapon]
			if weaponEnchantTime[weapon] then
				if not button then
					button = CreateFrame("Button", "$parentTempEnchant"..weapon, header)
					button.IsWeapon = true
					A:CreateIcon(button)
				end
				if button then
					if button:IsShown() then button:Hide() end

					button:SetID(weapon)
					local index = enchantableSlots[weapon]
					button.texture:SetTexture(GetInventoryItemTexture("player", index))

					button:SetBackdropBorderColor(E:GetItemQualityColor(GetInventoryItemQuality("player", index) or 1))

					local duration = 600
					local expirationTime = weaponEnchantTime[weapon]
					if expirationTime then
						expirationTime = expirationTime / 1000
						if expirationTime <= 3600 and expirationTime > 1800 then
							duration = 3600
						elseif expirationTime <= 1800 and expirationTime > 600 then
							duration = 1800
						end

						A:SetAuraTime(button, expirationTime, duration)
					else
						A:ClearAuraTime(button)
					end

					if (db.barShow and duration > 0) or (db.barShow and db.barNoDuration and duration == 0) then
						button.statusBar:Show()

						if not button.timeLeft or not db.barColorGradient then
							button.statusBar:SetStatusBarColor(db.barColor.r, db.barColor.g, db.barColor.b)
						end
					else
						button.statusBar:Hide()
					end

					if db.showDuration then
						button.text:Show()
					else
						button.text:Hide()
					end

					if weaponPosition == 0 then
						tinsert(buttons, button)
					else
						tinsert(buttons, weaponPosition, button)
					end
				end
			else
				if button and type(button.Hide) == "function" then
					button:Hide()
				end
			end
		end
	end

	local display = #buttons
	if wrapAfter and maxWraps then
		display = min(display, wrapAfter * maxWraps)
	end

	local pos, spacing, iconSize = db.barPosition, db.barSpacing, db.size - (E.Border * 2)
	local isOnTop = pos == "TOP" and true or false
	local isOnBottom = pos == "BOTTOM" and true or false
	local isOnLeft = pos == "LEFT" and true or false
	local isOnRight = pos == "RIGHT" and true or false

	local left, right, top, bottom = huge, -huge, -huge, huge
	for index = 1, display do
		button = buttons[index]
		local tick, cycle = floor((index - 1) % wrapAfter), floor((index - 1) / wrapAfter)
		button:ClearAllPoints()
		button:SetPoint(point, header, cycle * wrapXOffset + tick * xOffset, cycle * wrapYOffset + tick * yOffset)

		button:SetSize(size, size)

		if button.text then
			local buttonDb = A.db[button.auraType]

			button.text:ClearAllPoints()
			button.text:Point("TOP", button, "BOTTOM", 1 + buttonDb.timeXOffset, 0 + buttonDb.timeYOffset)
			button.text:FontTemplate(LSM:Fetch('font', buttonDb.timeFont), buttonDb.timeFontSize, buttonDb.timeFontOutline)

			button.count:ClearAllPoints()
			button.count:Point("BOTTOMRIGHT", -1 + buttonDb.countXOffset, 0 + buttonDb.countYOffset)
			button.count:FontTemplate(LSM:Fetch('font', buttonDb.countFont), buttonDb.countFontSize, buttonDb.countFontOutline)
		end

		local barSize = db.barSize + (E.PixelMode and 0 or 2)
		button.statusBar:Width((isOnTop or isOnBottom) and iconSize or barSize)
		button.statusBar:Height((isOnLeft or isOnRight) and iconSize or barSize)
		button.statusBar:ClearAllPoints()
		button.statusBar:Point(E.InversePoints[pos], button, pos, (isOnTop or isOnBottom) and 0 or ((isOnLeft and -((E.PixelMode and 1 or 3) + spacing)) or ((E.PixelMode and 1 or 3) + spacing)), (isOnLeft or isOnRight) and 0 or ((isOnTop and ((E.PixelMode and 1 or 3) + spacing) or -((E.PixelMode and 1 or 3) + spacing))))
		button.statusBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.barTexture))
		if isOnLeft or isOnRight then
			button.statusBar:SetOrientation("VERTICAL")
		else
			button.statusBar:SetOrientation("HORIZONTAL")
		end

		button:Show()
		left = min(left, button:GetLeft() or huge)
		right = max(right, button:GetRight() or -huge)
		top = max(top, button:GetTop() or -huge)
		bottom = min(bottom, button:GetBottom() or huge)
	end
	local deadIndex = #(auraTable) + 1
	button = _G[headerName.."AuraButton"..deadIndex]
	while button do
		if button:IsShown() then button:Hide() end
		deadIndex = deadIndex + 1
		button = _G[headerName.."AuraButton"..deadIndex]
	end

	if display >= 1 then
		header:SetWidth(max(right - left, minWidth))
		header:SetHeight(max(top - bottom, minHeight))
	else
		header:SetWidth(minWidth)
		header:SetHeight(minHeight)
	end
end

local freshTable
local releaseTable
do
	local tableReserve = {}
	freshTable = function ()
		local t = next(tableReserve) or {}
		tableReserve[t] = nil
		return t
	end
	releaseTable = function (t)
		tableReserve[t] = wipe(t)
	end
end

local function sortFactory(key, separateOwn, reverse)
	if separateOwn ~= 0 then
		if reverse then
			return function(a, b)
				if a.filter == b.filter then
					local ownA, ownB = a.caster == "player", b.caster == "player"
					if ownA ~= ownB then
						return ownA == (separateOwn > 0)
					end
					return a[key] > b[key]
				else
					return a.filter < b.filter
				end
			end;
		else
			return function(a, b)
				if a.filter == b.filter then
					local ownA, ownB = a.caster == "player", b.caster == "player"
					if ownA ~= ownB then
						return ownA == (separateOwn > 0)
					end
					return a[key] < b[key]
				else
					return a.filter < b.filter
				end
			end;
		end
	else
		if reverse then
			return function(a, b)
				if a.filter == b.filter then
					return a[key] > b[key]
				else
					return a.filter < b.filter
				end
			end;
		else
			return function(a, b)
				if a.filter == b.filter then
					return a[key] < b[key]
				else
					return a.filter < b.filter
				end
			end;
		end
	end
end

local sorters = {}
for _, key in ipairs{"index", "name", "expires"} do
	local label = string.upper(key)
	sorters[label] = {}
	for bool in pairs{[true] = true, [false] = false} do
		sorters[label][bool] = {}
		for sep = -1, 1 do
			sorters[label][bool][sep] = sortFactory(key, sep, bool)
		end
	end
end
sorters.TIME = sorters.EXPIRES

local sortingTable = {}
function A:UpdateHeader(header)
	local filter = header.filter
	local db = A.db.debuffs

	wipe(sortingTable)

	local weaponPosition
	if filter == "HELPFUL" then
		db = A.db.buffs
		weaponPosition = 1
	end

	local i = 1
	repeat
		local aura, _ = freshTable()
		aura.name, _, aura.icon, aura.count, aura.dispelType, aura.duration, aura.expires, aura.caster = UnitAura("player", i, filter)
		if aura.name then
			aura.filter = filter
			aura.index = i

			tinsert(sortingTable, aura)
		else
			releaseTable(aura)
		end
		i = i + 1
	until not aura.name

	local sortMethod = (sorters[db.sortMethod] or sorters.INDEX)[db.sortDir == "-"][db.seperateOwn]
	tsort(sortingTable, sortMethod)

	A:ConfigureAuras(header, sortingTable, weaponPosition)
	while sortingTable[1] do
		releaseTable(tremove(sortingTable))
	end

	if A.LBFGroup then
		A.LBFGroup:Skin(E.private.auras.lbf.skin)
	elseif A.MSQGroup then
		A.MSQGroup:ReSkin()
	end
end

function A:CreateAuraHeader(filter)
	local name, auraType = filter == "HELPFUL" and "ElvUIPlayerBuffs" or "ElvUIPlayerDebuffs", filter == "HELPFUL" and "buffs" or "debuffs"


	local header = CreateFrame("Frame", name, UIParent)
	header:SetClampedToScreen(true)
	header:SetAttribute("unit", "player")
	header:SetAttribute("filter", filter)
	header.filter = filter
	header.auraType = auraType

	header:RegisterEvent("UNIT_AURA")
	header:SetScript("OnEvent", function(self, _, unit)
		if unit ~= "player" then return end

		A:UpdateHeader(self)
	end)

	A:UpdateHeader(header)

	return header
end

function A:Initialize()
	if E.private.auras.disableBlizzard then
		BuffFrame:Kill()
		TemporaryEnchantFrame:Kill()
		ConsolidatedBuffs:Kill()
	end

	if not E.private.auras.enable then return end

	A.Initialized = true
	A.db = E.db.auras

	if LBF then
		A.LBFGroup = LBF and LBF:Group("ElvUI", "Auras")
	elseif E.Masque then
		A.MSQGroup = E.Masque:Group("ElvUI", "Auras")
	end

	local xoffset = -(6 + E.Border)
	if E.private.auras.buffsHeader then
		A.BuffFrame = A:CreateAuraHeader("HELPFUL")
		A.BuffFrame:ClearAllPoints()
		A.BuffFrame:Point("TOPRIGHT", _G.ElvUI_MinimapHolder or _G.Minimap, "TOPLEFT", xoffset, E.Spacing)
		E:CreateMover(A.BuffFrame, "BuffsMover", L["Player Buffs"], nil, nil, nil, nil, nil, "auras,buffs")

		A.BuffFrame.nextUpdate = -1
		A.BuffFrame:SetScript("OnUpdate", function(bf, elapsed)
			if bf.nextUpdate > 0 then
				bf.nextUpdate = bf.nextUpdate - elapsed
				return
			end

			bf.nextUpdate = 1

			local hasMainHandEnchant, mainHandExpiration, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
			if A:HasEnchant(1, hasMainHandEnchant, mainHandExpiration) or A:HasEnchant(2, hasOffHandEnchant, offHandExpiration) then
				A:UpdateHeader(bf)
			end
		end)
	end

	if E.private.auras.debuffsHeader then
		A.DebuffFrame = A:CreateAuraHeader("HARMFUL")
		A.DebuffFrame:ClearAllPoints()
		A.DebuffFrame:Point("BOTTOMRIGHT", _G.ElvUI_MinimapHolder or _G.Minimap, "BOTTOMLEFT", xoffset, E.Spacing)
		E:CreateMover(A.DebuffFrame, "DebuffsMover", L["Player Debuffs"], nil, nil, nil, nil, nil, "auras,debuffs")
	end
end

local function InitializeCallback()
	A:Initialize()
end

E:RegisterModule(A:GetName(), InitializeCallback)