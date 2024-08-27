local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local date = date

local SHORTDATE = '%2$d/%1$02d/%3$02d'
local SHORTDATENOYEAR = '%2$d/%1$02d'
local SHORTDATENOYEAR_EU = '%1$d/%2$d'
local SHORTDATE_EU = '%1$d/%2$d/%3$02d'
local locale = E:GetLocale()

local displayString

local function FormatShortDate(day, month, year)
    if year then
        if locale == 'enGB' then
            return SHORTDATE_EU:format(day, month, year);
        else
            return SHORTDATE:format(day, month, year);
        end
    else
        if locale == 'enGB' then
            return SHORTDATENOYEAR_EU:format(day, month);
        else
            return SHORTDATENOYEAR:format(day, month);
        end
    end
end

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
