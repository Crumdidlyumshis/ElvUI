local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin
local UnitStat = UnitStat

local ITEM_MOD_INTELLECT_SHORT = ITEM_MOD_INTELLECT_SHORT

local displayString, db = ''

local function OnEvent(self)
	local intellect = UnitStat('player', 4)
	if db.NoLabel then
		self.text:SetFormattedText(displayString, intellect)
	else
		self.text:SetFormattedText(displayString, db.Label ~= '' and db.Label or ITEM_MOD_INTELLECT_SHORT..': ', intellect)
	end
end

local function ApplySettings(self, hex)
	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	displayString = strjoin('', db.NoLabel and '' or '%s', hex, '%.f|r')
end

DT:RegisterDatatext('Intellect', L["Attributes"], { 'UNIT_STATS', 'UNIT_AURA' }, OnEvent, nil, nil, nil, nil, ITEM_MOD_INTELLECT_SHORT, nil, ApplySettings)
