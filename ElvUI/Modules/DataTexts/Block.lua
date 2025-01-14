local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local strjoin = strjoin

local GetBlockChance = GetBlockChance

local BLOCK = BLOCK
local DEFENSE = DEFENSE

local displayString = ''

local function OnEvent(self)
	self.text:SetFormattedText(displayString, BLOCK, GetBlockChance())
end

local function ApplySettings(_, hex)
	displayString = strjoin('', '%s: ', hex, '%.f|r')
end

DT:RegisterDatatext('Block', DEFENSE, { 'UNIT_STATS', 'UNIT_AURA', 'SKILL_LINES_CHANGED' }, OnEvent, nil, nil, nil, nil, BLOCK, nil, ApplySettings)

