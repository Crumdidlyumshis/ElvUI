local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local LC = E.Libs.Compat

local _G = _G
local date = date
local FormatShortDate = LC.FormatShortDate

local displayString

local function OnClick()
    if not E:AlertCombat() then
        _G.GameTimeFrame:Click()
    end
end

local function OnEvent(self)
	local dateTable = date('*t')

	self.text:SetText(FormatShortDate(dateTable.day, dateTable.month, dateTable.year):gsub('([/.])', displayString))
end

local function ApplySettings(_, hex)
	displayString = hex..'%1|r'
end

DT:RegisterDatatext('Date', nil, { 'UPDATE_INSTANCE_INFO' }, OnEvent, nil, OnClick, nil, nil, nil, nil, ApplySettings)
