local E, L, V, P, G = unpack(ElvUI)
local TT = E:GetModule('Tooltip')
local LC = E.Libs.Compat
local LCS = E.Libs.LCS

local _G = _G
local type, ipairs, pairs, unpack = type, ipairs, pairs, unpack
local wipe, max, next, tinsert, date, time = wipe, max, next, tinsert, date, time
local strfind, strlen, tonumber, tostring = strfind, strlen, tonumber, tostring

local CreateFrame = CreateFrame
local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local GetExpansionLevel = GetExpansionLevel
local GetInstanceInfo = GetInstanceInfo
local GetNumPartyMembers = GetNumPartyMembers
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local GetActiveTalentGroup = GetActiveTalentGroup
local GetCVarBool = GetCVarBool
local GetFunctionCPUUsage = GetFunctionCPUUsage
local GetTalentTabInfo = GetTalentTabInfo
local IsAddOnLoaded = IsAddOnLoaded
local IsInRaid = LC.IsInRaid
local IsXPUserDisabled = IsXPUserDisabled
local RequestBattlefieldScoreData = RequestBattlefieldScoreData
local SetCVar = SetCVar
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit
local GetGameTime = GetGameTime

local GetSpecialization = LCS.GetSpecialization
local GetSpecializationInfo = LCS.GetSpecializationInfo
local GetSpecializationInfoForClassID = LCS.GetSpecializationInfoForClassID

local GetClassInfo = LC.GetClassInfo

local MAX_TALENT_TABS = MAX_TALENT_TABS
local NONE = NONE

local ERR_NOT_IN_COMBAT = ERR_NOT_IN_COMBAT
local FACTION_HORDE = FACTION_HORDE
local FACTION_ALLIANCE = FACTION_ALLIANCE
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP

local GameMenuButtonLogout = GameMenuButtonLogout
local GameMenuFrame = GameMenuFrame
local UIErrorsFrame = UIErrorsFrame
-- GLOBALS: ElvDB, ElvUI

local DebuffTypeColor = DebuffTypeColor

E.SpecInfoBySpecClass = {} -- ['Protection Warrior'] = specInfo (table)
E.SpecInfoBySpecID = {} -- [250] = specInfo (table)

E.SpecByClass = {
	DEATHKNIGHT	= { 250, 251, 252 },
	DRUID		= { 102, 103, 104, 105 },
	HUNTER		= { 253, 254, 255 },
	MAGE		= { 62, 63, 64 },
	PALADIN		= { 65, 66, 70 },
	PRIEST		= { 256, 257, 258 },
	ROGUE		= { 259, 260, 261 },
	SHAMAN		= { 262, 263, 264 },
	WARLOCK		= { 265, 266, 267 },
	WARRIOR		= { 71, 72, 73 },
}

E.ClassName = { -- english locale
	DEATHKNIGHT	= 'Death Knight',
	DRUID		= 'Druid',
	HUNTER		= 'Hunter',
	MAGE		= 'Mage',
	PALADIN		= 'Paladin',
	PRIEST		= 'Priest',
	ROGUE		= 'Rogue',
	SHAMAN		= 'Shaman',
	WARLOCK		= 'Warlock',
	WARRIOR		= 'Warrior',
}

E.SpecName = { -- english locale
	-- Death Knight
	[250]	= 'Blood',
	[251]	= 'Frost',
	[252]	= 'Unholy',
	-- Druids
	[102]	= 'Balance',
	[103]	= 'Feral',
	[104]	= 'Guardian',
	[105]	= 'Restoration',
	-- Hunter
	[253]	= 'Beast Mastery',
	[254]	= 'Marksmanship',
	[255]	= 'Survival',
	-- Mage
	[62]	= 'Arcane',
	[63]	= 'Fire',
	[64]	= 'Frost',
	-- Paladin
	[65]	= 'Holy',
	[66]	= 'Protection',
	[70]	= 'Retribution',
	-- Priest
	[256]	= 'Discipline',
	[257]	= 'Holy',
	[258]	= 'Shadow',
	-- Rogue
	[259]	= 'Assasination',
	[260]	= 'Combat',
	[261]	= 'Sublety',
	-- Shaman
	[262]	= 'Elemental',
	[263]	= 'Enhancement',
	[264]	= 'Restoration',
	-- Walock
	[265]	= 'Affliction',
	[266]	= 'Demonology',
	[267]	= 'Destruction',
	-- Warrior
	[71]	= 'Arms',
	[72]	= 'Fury',
	[73]	= 'Protection',
}

function E:GetDateTime(localTime, unix)
	if not localTime then -- try to properly handle realm time
		local dateTable = date('*t', time())

		local hours, minutes = GetGameTime() -- realm time since it doesnt match ServerTimeLocal
		dateTable.hour = hours
		dateTable.min = minutes

		if unix then
			return time(dateTable)
		else
			return dateTable
		end
	elseif unix then
		return time()
	else
		return date('*t', time())
	end
end

function E:ClassColor(class, usePriestColor)
	if not class then return end

	local color = (_G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[class]) or _G.RAID_CLASS_COLORS[class]
	if type(color) ~= 'table' then return end

	if not color.colorStr then
		color.colorStr = E:RGBToHex(color.r, color.g, color.b, 'ff')
	elseif strlen(color.colorStr) == 6 then
		color.colorStr = 'ff'..color.colorStr
	end

	if usePriestColor and class == 'PRIEST' and tonumber(color.colorStr, 16) > tonumber(E.PriestColors.colorStr, 16) then
		return E.PriestColors
	else
		return color
	end
end

function E:InverseClassColor(class, usePriestColor, forceCap)
	local color = E:CopyTable({}, E:ClassColor(class, usePriestColor))
	local capColor = class == 'PRIEST' or forceCap

	color.r = capColor and max(1-color.r,0.35) or (1-color.r)
	color.g = capColor and max(1-color.g,0.35) or (1-color.g)
	color.b = capColor and max(1-color.b,0.35) or (1-color.b)
	color.colorStr = E:RGBToHex(color.r, color.g, color.b, 'ff')

	return color
end

do -- other non-english locales require this
	E.UnlocalizedClasses = {}
	for k, v in pairs(_G.LOCALIZED_CLASS_NAMES_MALE) do E.UnlocalizedClasses[v] = k end
	for k, v in pairs(_G.LOCALIZED_CLASS_NAMES_FEMALE) do E.UnlocalizedClasses[v] = k end

	function E:UnlocalizedClassName(className)
		return E.UnlocalizedClasses[className]
	end
end

do
	function E:ScanTooltipTextures()
		local tt = E.ScanTooltip

		if not tt.gems then
			tt.gems = {}
		else
			wipe(tt.gems)
		end

		for i = 1, 10 do
			local tex = _G['ElvUI_ScanTooltipTexture'..i]
			local texture = tex and tex:IsShown() and tex:GetTexture()
			if texture then
				tt.gems[i] = texture
			end
		end

		return tt.gems
	end
end

do
	local function FindAura(key, value, unit, index, filter, ...)
		local name, _, _, _, _, _, _, _, _, spellID = ...

		if not name then
			return
		elseif key == 'name' and value == name then
			return ...
		elseif key == 'spellID' and value == spellID then
			return ...
		else
			index = index + 1
			return FindAura(key, value, unit, index, filter, UnitAura(unit, index, filter))
		end
	end

	function E:GetAuraByID(unit, spellID, filter)
		return FindAura('spellID', spellID, unit, 1, filter, UnitAura(unit, 1, filter))
	end

	function E:GetAuraByName(unit, name, filter)
		return FindAura('name', name, unit, 1, filter, UnitAura(unit, 1, filter))
	end
end

function E:GetTalentSpecInfo(isInspect)
	local talantGroup = GetActiveTalentGroup(isInspect)
	local maxPoints, specIdx, specName, specIcon = 0, 0

	for i = 1, MAX_TALENT_TABS do
		local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect, nil, talantGroup)
		if maxPoints < pointsSpent then
			maxPoints = pointsSpent
			specIdx = i
			specName = name
			specIcon = icon
		end
	end

	if not specName then
		specName = NONE
	end

	if not specIcon then
		specIcon = [[Interface\Icons\INV_Misc_QuestionMark]]
	end

	return specIdx, specName, specIcon
end

function E:GetThreatStatusColor(status, nothreat)
	local color = ElvUF.colors.threat[status]
	if color then
		return color.r, color.g, color.b, color.a or 1
	elseif nothreat then
		if status == -1 then -- how or why?
			return 1, 1, 1, 1
		else
			return .7, .7, .7, 1
		end
	end
end

function E:GetPlayerRole()
	local tank, healer, damage = UnitGroupRolesAssigned('player')
	local role = (tank and 'TANK') or (healer and 'HEALER') or (damage and 'DAMAGER') or NONE

	return (role ~= NONE and role) or E.myspecRole or NONE
end

function E:CheckRole()
	E.myspec = GetSpecialization()

	if E.myspec then
		E.myspecID, E.myspecName, E.myspecDesc, E.myspecIcon, E.myspecBackground, E.myspecRole = GetSpecializationInfo(E.myspec)
	end

	E.myrole = E:GetPlayerRole()
end

function E:IsDispellableByMe(debuffType)
	if not E.DispelClasses[E.myclass] then return end

	if E.DispelClasses[E.myclass][debuffType] then return true end
end

function E:UpdateDispelColors()
	local colors = E.db.general.debuffColors
	for debuffType, db in next, colors do
		local color = DebuffTypeColor[debuffType]
		if color then
			E:UpdateClassColor(db)
			color.r, color.g, color.b = db.r, db.g, db.b
		end
	end
end

function E:UpdateDispelColor(debuffType, r, g, b)
	local color = DebuffTypeColor[debuffType]
	if color then
		color.r, color.g, color.b = r, g, b
	end

	local db = E.db.general.debuffColors[debuffType]
	if db then
		db.r, db.g, db.b = r, g, b
	end
end

do
	local Masque = E.Libs.Masque
	local MasqueGroupState = {}
	local MasqueGroupToTableElement = {
		['ActionBars'] = {'actionbar', 'actionbars'},
		['Pet Bar'] = {'actionbar', 'petBar'},
		['Stance Bar'] = {'actionbar', 'stanceBar'},
		['Buffs'] = {'auras', 'buffs'},
		['Debuffs'] = {'auras', 'debuffs'},
	}

	function E:MasqueCallback(Group, _, _, _, _, Disabled)
		if not E.private then return end
		local element = MasqueGroupToTableElement[Group]
		if element then
			if Disabled then
				if E.private[element[1]].masque[element[2]] and MasqueGroupState[Group] == 'enabled' then
					E.private[element[1]].masque[element[2]] = false
					E:StaticPopup_Show('CONFIG_RL')
				end
				MasqueGroupState[Group] = 'disabled'
			else
				MasqueGroupState[Group] = 'enabled'
			end
		end
	end

	if Masque then
		Masque:Register('ElvUI', E.MasqueCallback)
	end
end

do
	local CPU_USAGE = {}
	local function CompareCPUDiff(showall, minCalls)
		local greatestUsage, greatestCalls, greatestName, newName, newFunc
		local greatestDiff, lastModule, mod, usage, calls, diff = 0

		for name, oldUsage in pairs(CPU_USAGE) do
			newName, newFunc = strmatch(name, '^([^:]+):(.+)$')
			if not newFunc then
				E:Print('CPU_USAGE:', name, newFunc)
			else
				if newName ~= lastModule then
					mod = E:GetModule(newName, true) or E
					lastModule = newName
				end
				usage, calls = GetFunctionCPUUsage(mod[newFunc], true)
				diff = usage - oldUsage
				if showall and (calls > minCalls) then
					E:Print('Name('..name..') Calls('..calls..') Diff('..(diff > 0 and format('%.3f', diff) or 0)..')')
				end
				if (diff > greatestDiff) and calls > minCalls then
					greatestName, greatestUsage, greatestCalls, greatestDiff = name, usage, calls, diff
				end
			end
		end

		if greatestName then
			E:Print(greatestName..' had the CPU usage of: '..(greatestUsage > 0 and format('%.3f', greatestUsage) or 0)..'ms. And has been called '..greatestCalls..' times.')
		else
			E:Print('CPU Usage: No CPU Usage differences found.')
		end

		wipe(CPU_USAGE)
	end

	function E:GetTopCPUFunc(msg)
		if not GetCVarBool('scriptProfile') then
			E:Print('For `/cpuusage` to work, you need to enable script profiling via: `/console scriptProfile 1` then reload. Disable after testing by setting it back to 0.')
			return
		end

		local module, showall, delay, minCalls = strmatch(msg, '^(%S+)%s*(%S*)%s*(%S*)%s*(.*)$')
		local checkCore, mod = (not module or module == '') and 'E'

		showall = (showall == 'true' and true) or false
		delay = (delay == 'nil' and nil) or tonumber(delay) or 5
		minCalls = (minCalls == 'nil' and nil) or tonumber(minCalls) or 15

		wipe(CPU_USAGE)
		if module == 'all' then
			for moduName, modu in pairs(self.modules) do
				for funcName, func in pairs(modu) do
					if (funcName ~= 'GetModule') and (type(func) == 'function') then
						CPU_USAGE[moduName..':'..funcName] = GetFunctionCPUUsage(func, true)
					end
				end
			end
		else
			if not checkCore then
				mod = self:GetModule(module, true)
				if not mod then
					self:Print(module..' not found, falling back to checking core.')
					mod, checkCore = self, 'E'
				end
			else
				mod = self
			end
			for name, func in pairs(mod) do
				if (name ~= 'GetModule') and type(func) == 'function' then
					CPU_USAGE[(checkCore or module)..':'..name] = GetFunctionCPUUsage(func, true)
				end
			end
		end

		self:Delay(delay, CompareCPUDiff, showall, minCalls)
		self:Print('Calculating CPU Usage differences (module: '..(checkCore or module)..', showall: '..tostring(showall)..', minCalls: '..tostring(minCalls)..', delay: '..tostring(delay)..')')
	end
end

function E:RegisterObjectForVehicleLock(object, originalParent)
	if not object or not originalParent then
		E:Print('Error. Usage: RegisterObjectForVehicleLock(object, originalParent)')
		return
	end

	object = _G[object] or object
	--Entering/Exiting vehicles will often happen in combat.
	--For this reason we cannot allow protected objects.
	if object.IsProtected and object:IsProtected() then
		E:Print('Error. Object is protected and cannot be changed in combat.')
		return
	end

	--Check if we are already in a vehicles
	if UnitHasVehicleUI('player') then
		object:SetParent(E.HiddenFrame)
	end

	--Add object to table
	E.VehicleLocks[object] = originalParent
end

function E:UnregisterObjectForVehicleLock(object)
	if not object then
		E:Print('Error. Usage: UnregisterObjectForVehicleLock(object)')
		return
	end

	object = _G[object] or object
	--Check if object was registered to begin with
	if not E.VehicleLocks[object] then return end

	--Change parent of object back to original parent
	local originalParent = E.VehicleLocks[object]
	if originalParent then
		object:SetParent(originalParent)
	end

	--Remove object from table
	E.VehicleLocks[object] = nil
end

function E:EnterVehicleHideFrames(_, unit)
	if unit ~= 'player' then return end

	for object in pairs(E.VehicleLocks) do
		object:SetParent(E.HiddenFrame)
	end
end

function E:ExitVehicleShowFrames(_, unit)
	if unit ~= 'player' then return end

	for object, originalParent in pairs(E.VehicleLocks) do
		object:SetParent(originalParent)
	end
end

function E:RequestBGInfo()
	RequestBattlefieldScoreData()
end

function E:PLAYER_ENTERING_WORLD()
	E:CheckRole()

	if not ElvDB.DisabledAddOns then
		ElvDB.DisabledAddOns = {}
	end

	E:CheckIncompatible()

	if not E.MediaUpdated then
		E:UpdateMedia()
		E.MediaUpdated = true
	end

	-- Blizzard will set this value to int(60/CVar cameraDistanceMax)+1 at logout if it is manually set higher than that
	if E.db.general.lockCameraDistanceMax then
		SetCVar('cameraDistanceMax', E.db.general.cameraDistanceMax)
	end

	local _, instanceType = GetInstanceInfo()
	if instanceType == 'pvp' then
		E.BGTimer = E:ScheduleRepeatingTimer('RequestBGInfo', 5)
		E:RequestBGInfo()
	elseif E.BGTimer then
		E:CancelTimer(E.BGTimer)
		E.BGTimer = nil
	end
end

function E:PLAYER_REGEN_ENABLED()
	if E.ShowOptions then
		E:ToggleOptionsUI()

		E.ShowOptions = nil
	end
end

do
	local function NoCombat()
		UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1.0, 0.2, 0.2, 1.0)
	end

	function E:PLAYER_REGEN_DISABLED()
		local wasShown

		if IsAddOnLoaded('ElvUI_OptionsUI') then
			local ACD = E.Libs.AceConfigDialog
			if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI then
				ACD:Close('ElvUI')
				wasShown = true
			end
		end

		if E.CreatedMovers then
			for name in pairs(E.CreatedMovers) do
				local mover = _G[name]
				if mover and mover:IsShown() then
					mover:Hide()
					wasShown = true
				end
			end
		end

		if wasShown then
			NoCombat()
		end
	end

	function E:AlertCombat()
		local combat = InCombatLockdown()
		if combat then NoCombat() end
		return combat
	end
end

function E:XPIsUserDisabled()
	return IsXPUserDisabled()
end

function E:XPIsLevelMax()
	return E.mylevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] or E:XPIsUserDisabled()
end

function E:GetGroupUnit(unit)
	if UnitIsUnit(unit, 'player') then return end
	if strfind(unit, 'party') or strfind(unit, 'raid') then
		return unit
	end

	-- returns the unit as raid# or party# when grouped
	if UnitInParty(unit) or UnitInRaid(unit) then
		local isInRaid = IsInRaid()
		for i = 1, GetNumPartyMembers() do
			local groupUnit = (isInRaid and 'raid' or 'party')..i
			if UnitIsUnit(unit, groupUnit) then
				return groupUnit
			end
		end
	end
end

function E:GetUnitBattlefieldFaction(unit)
	local englishFaction, localizedFaction = UnitFactionGroup(unit)

	-- this might be a rated BG or wargame and if so the player's faction might be altered
	if unit == 'player' then
		englishFaction = PLAYER_FACTION_GROUP[GetBattlefieldArenaFaction()]
		localizedFaction = (englishFaction == 'Alliance' and FACTION_ALLIANCE) or FACTION_HORDE
	end

	return englishFaction, localizedFaction
end

function E:PositionGameMenuButton()
	GameMenuFrame:Height(GameMenuFrame:GetHeight() + GameMenuButtonLogout:GetHeight() - 4)

	local button = GameMenuFrame.ElvUI
	button:SetFormattedText('%s%s|r', E.media.hexvaluecolor, 'ElvUI')

	local _, relTo, _, _, offY = GameMenuButtonLogout:GetPoint()
	if relTo ~= button then
		button:ClearAllPoints()
		button:Point('TOPLEFT', relTo, 'BOTTOMLEFT', 0, -1)
		GameMenuButtonLogout:ClearAllPoints()
		GameMenuButtonLogout:Point('TOPLEFT', button, 'BOTTOMLEFT', 0, offY)
	end
end

function E:PLAYER_LEVEL_UP(_, level)
	E.mylevel = level
end

function E:ClickGameMenu()
	E:ToggleOptionsUI() -- we already prevent it from opening in combat

	if not InCombatLockdown() then
		HideUIPanel(GameMenuFrame)
	end
end

function E:SetupGameMenu()
	local button = CreateFrame('Button', nil, GameMenuFrame, 'GameMenuButtonTemplate')
	button:SetScript('OnClick', E.ClickGameMenu)
	GameMenuFrame.ElvUI = button

	E.PositionGameMenuButton()
end

function E:CompatibleTooltip(tt) -- knock off compatibility
	if tt.GetTooltipData then return end -- real support exists

	local info = { name = tt:GetName(), lines = {} }
	info.leftTextName = info.name .. 'TextLeft'
	info.rightTextName = info.name .. 'TextRight'

	tt.GetTooltipData = function()
		wipe(info.lines)

		for i = 1, tt:NumLines() do
			local left = _G[info.leftTextName..i]
			local leftText = left and left:GetText() or nil

			local right = _G[info.rightTextName..i]
			local rightText = right and right:GetText() or nil

			tinsert(info.lines, i, { lineIndex = i, leftText = leftText, rightText = rightText })
		end

		return info
	end
end

function E:GetUnitSpecInfo(unit)
	if not UnitIsPlayer(unit) then return end

	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetUnit(unit)
	E.ScanTooltip:Show()

	local _, specLine = TT:GetLevelLine(E.ScanTooltip, 1, true)
	local specText = specLine and specLine.leftText
	if specText then
		return E.SpecInfoBySpecClass[specText]
	end
end

function E:GetClassCoords(classFile, crop, get)
	local t = _G.CLASS_ICON_TCOORDS[classFile]
	if not t then return 0, 1, 0, 1 end

	if get then
		return t
	elseif type(crop) == 'number' then
		return t[1] + crop, t[2] - crop, t[3] + crop, t[4] - crop
	elseif crop then
		return t[1] + 0.022, t[2] - 0.025, t[3] + 0.022, t[4] - 0.025
	else
		return t[1], t[2], t[3], t[4]
	end
end

function E:CropRatio(frame, coords, mult)
	local left, right, top, bottom = unpack(coords or E.TexCoords)
	if not mult then mult = 0.5 end

	local width, height = frame:GetSize()
	local ratio = width / height
	if ratio > 1 then
		local trimAmount = (1 - (1 / ratio)) * mult
		top = top + trimAmount
		bottom = bottom - trimAmount
	else
		local trimAmount = (1 - ratio) * mult
		left = left + trimAmount
		right = right - trimAmount
	end

	return left, right, top, bottom
end

function E:ScanTooltip_UnitInfo(unit)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetUnit(unit)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:ScanTooltip_InventoryInfo(unit, slot)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetInventoryItem(unit, slot)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:ScanTooltip_HyperlinkInfo(link)
	E.ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	E.ScanTooltip:SetHyperlink(link)
	E.ScanTooltip:Show()

	return E.ScanTooltip:GetTooltipData()
end

function E:GetClassCoords(classFile, crop, get)
	local t = _G.CLASS_ICON_TCOORDS[classFile]
	if not t then return 0, 1, 0, 1 end

	if get then
		return t
	elseif type(crop) == 'number' then
		return t[1] + crop, t[2] - crop, t[3] + crop, t[4] - crop
	elseif crop then
		return t[1] + 0.022, t[2] - 0.025, t[3] + 0.022, t[4] - 0.025
	else
		return t[1], t[2], t[3], t[4]
	end
end

function E:LoadAPI()
	E:RegisterEvent('PLAYER_LEVEL_UP')
	E:RegisterEvent('PLAYER_ENTERING_WORLD')
	E:RegisterEvent('PLAYER_REGEN_ENABLED')
	E:RegisterEvent('PLAYER_REGEN_DISABLED')
	E:RegisterEvent('UI_SCALE_CHANGED', 'PixelScaleChanged')

	E:SetupGameMenu()

	do -- fill the spec info tables
		local MALE = _G.LOCALIZED_CLASS_NAMES_MALE
		local FEMALE = _G.LOCALIZED_CLASS_NAMES_FEMALE

		local i = 1
		local className, classFile, classID = GetClassInfo(i)
		local male, female = MALE[classFile], FEMALE[classFile]
		while classID do
			for index, id in next, E.SpecByClass[classFile] do
				local info = {
					id = id,
					index = index,
					classFile = classFile,
					className = className,
					englishName = E.SpecName[id]
				}

				E.SpecInfoBySpecID[id] = info

				for x = 3, 1, -1 do
					local _, name, desc, icon, role = GetSpecializationInfoForClassID(id, x)
					name = name or ''

					if x == 1 then -- SpecInfoBySpecID
						info.name = name
						info.desc = desc
						info.icon = icon
						info.role = role

						E.SpecInfoBySpecClass[name..' '..className] = info
					else
						local copy = E:CopyTable({}, info)
						copy.name = name
						copy.desc = desc
						copy.icon = icon
						copy.role = role

						local localized = (x == 3 and female) or male
						copy.className = localized

						if localized then
							E.SpecInfoBySpecClass[name..' '..localized] = copy
						end
					end
				end
			end

			i = i + 1
			className, classFile, classID = GetClassInfo(i)
			male, female = MALE[classFile], FEMALE[classFile]
		end
	end

	E:CompatibleTooltip(E.ScanTooltip)
	E:CompatibleTooltip(E.ConfigTooltip)
	E:CompatibleTooltip(E.SpellBookTooltip)
	E:CompatibleTooltip(_G.GameTooltip)

	E.ScanTooltip.GetUnitInfo = E.ScanTooltip_UnitInfo
	E.ScanTooltip.GetHyperlinkInfo = E.ScanTooltip_HyperlinkInfo
	E.ScanTooltip.GetInventoryInfo = E.ScanTooltip_InventoryInfo

	E:RegisterEvent('SPELL_UPDATE_USABLE', 'CheckRole')
	E:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', 'CheckRole')
	E:RegisterEvent('PLAYER_TALENT_UPDATE', 'CheckRole')
	E:RegisterEvent('CHARACTER_POINTS_CHANGED', 'CheckRole')
	E:RegisterEvent('UNIT_INVENTORY_CHANGED', 'CheckRole')
	E:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'CheckRole')

	E:RegisterEvent('UNIT_ENTERED_VEHICLE', 'EnterVehicleHideFrames')
	E:RegisterEvent('UNIT_EXITED_VEHICLE', 'ExitVehicleShowFrames')

	do -- setup cropIcon texCoords
		local opt = E.db.general.cropIcon
		local modifier = 0.04 * opt
		for i, v in ipairs(E.TexCoords) do
			if i % 2 == 0 then
				E.TexCoords[i] = v - modifier
			else
				E.TexCoords[i] = v + modifier
			end
		end
	end
end