local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local LCS = E.Libs.LCS

local _G = _G
local strjoin = strjoin

local UnitStat = UnitStat
local GetSpecialization = LCS.GetSpecialization

local PRIMARY_STAT = gsub('Primary Stat: %s', '[:：%s]-%%s$', '')
local NOT_APPLICABLE = NOT_APPLICABLE

local displayString = ''

local function OnEvent(self)
	local spec = GetSpecialization()
	local statID = spec and DT.SPECIALIZATION_CACHE[spec] and DT.SPECIALIZATION_CACHE[spec].statID

	local name = statID and _G['SPELL_STAT'..statID..'_NAME']
	if name then
		self.text:SetFormattedText(displayString, name..': ', UnitStat('player', statID))
	else
		self.text:SetText(NOT_APPLICABLE)
	end
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s', hex, '%.f|r')
end

DT:RegisterDatatext('Primary Stat', L["Attributes"], { 'UNIT_STATS', 'UNIT_AURA' }, OnEvent, nil, nil, nil, nil, PRIMARY_STAT, nil, ApplySettings)
