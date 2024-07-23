local E, L, V, P, G = unpack(ElvUI)
local DB = E:GetModule('DataBars')

local _G = _G
local format = string.format
local huge = math.huge

local GameTooltip = GameTooltip
local ToggleCharacter = ToggleCharacter

local REPUTATION = REPUTATION
local STANDING = STANDING
local UNKNOWN = UNKNOWN

local function GetValues(currentStanding, currentReactionThreshold, nextReactionThreshold)
	local maximum = nextReactionThreshold - currentReactionThreshold
	local current, diff = currentStanding - currentReactionThreshold, maximum

	if diff == 0 then diff = 1 end -- prevent a division by zero

	if current == maximum then
		return 1, 1, 100, true
	else
		return current, maximum, current / diff * 100
	end
end

function DB:ReputationBar_Update()
	local bar = DB.StatusBars.Reputation
	DB:SetVisibility(bar)

	if not bar.db.enable or bar:ShouldHide() then return end

	local data = E:GetWatchedFactionInfo()
	local name, reaction, currentReactionThreshold, nextReactionThreshold, currentStanding = data.name, data.reaction, data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
	local displayString, textFormat = '', DB.db.reputation.textFormat

	if reaction == 0 then
		reaction = 1
	end

	local label = _G['FACTION_STANDING_LABEL'..reaction] or UNKNOWN

	local customColors = DB.db.colors.useCustomFactionColors
	local color = customColors and DB.db.colors.factionColors[reaction] or _G.FACTION_BAR_COLORS[reaction]
	local alpha = (customColors and color.a) or DB.db.colors.reputationAlpha
	local total = nextReactionThreshold == huge and 1 or nextReactionThreshold -- we need to correct the min/max of friendship factions to display the bar at 100%

	bar:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, alpha or 1)
	bar:SetMinMaxValues(currentReactionThreshold, total)
	bar:SetValue(currentStanding)

	local current, maximum, percent, capped = GetValues(currentStanding, currentReactionThreshold, total)
	if capped and textFormat ~= 'NONE' then -- show only name and standing on exalted
		displayString = format('%s: [%s]', name, label)
	elseif textFormat == 'PERCENT' then
		displayString = format('%s: %d%% [%s]', name, percent, label)
	elseif textFormat == 'CURMAX' then
		displayString = format('%s: %s - %s [%s]', name, E:ShortValue(current), E:ShortValue(maximum), label)
	elseif textFormat == 'CURPERC' then
		displayString = format('%s: %s - %d%% [%s]', name, E:ShortValue(current), percent, label)
	elseif textFormat == 'CUR' then
		displayString = format('%s: %s [%s]', name, E:ShortValue(current), label)
	elseif textFormat == 'REM' then
		displayString = format('%s: %s [%s]', name, E:ShortValue(maximum - current), label)
	elseif textFormat == 'CURREM' then
		displayString = format('%s: %s - %s [%s]', name, E:ShortValue(current), E:ShortValue(maximum - current), label)
	elseif textFormat == 'CURPERCREM' then
		displayString = format('%s: %s - %d%% (%s) [%s]', name, E:ShortValue(current), percent, E:ShortValue(maximum - current), label)
	end

	bar.text:SetText(displayString)
end

function DB:ReputationBar_OnEnter()
	if self.db.mouseover then
		E:UIFrameFadeIn(self, 0.4, self:GetAlpha(), 1)
	end

	local data = E:GetWatchedFactionInfo()
	local name, reaction, currentReactionThreshold, nextReactionThreshold, currentStanding = data.name, data.reaction, data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
	local standing = _G['FACTION_STANDING_LABEL'..reaction] or UNKNOWN

	if name then
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, 'ANCHOR_CURSOR', 0, -4)
		GameTooltip:AddLine(name)
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine(STANDING..':', standing, 1, 1, 1)
		GameTooltip:AddDoubleLine(REPUTATION..':', format('%d / %d (%d%%)', GetValues(currentStanding, currentReactionThreshold, nextReactionThreshold)), 1, 1, 1)
		GameTooltip:Show()
	end
end

function DB:ReputationBar_OnClick()
	if E:AlertCombat() then return end

	ToggleCharacter('ReputationFrame')
end

function DB:ReputationBar_Toggle()
	local bar = DB.StatusBars.Reputation
	bar.db = DB.db.reputation

	if bar.db.enable then
		E:EnableMover(bar.holder.mover.name)

		DB:RegisterEvent('UPDATE_FACTION', 'ReputationBar_Update')
		DB:RegisterEvent('COMBAT_TEXT_UPDATE', 'ReputationBar_Update')
		DB:RegisterEvent('QUEST_FINISHED', 'ReputationBar_Update')

		DB:ReputationBar_Update()
	else
		E:DisableMover(bar.holder.mover.name)

		DB:UnregisterEvent('UPDATE_FACTION')
		DB:UnregisterEvent('COMBAT_TEXT_UPDATE')
		DB:UnregisterEvent('QUEST_FINISHED')
	end
end

function DB:ReputationBar()
	local Reputation = DB:CreateBar('ElvUI_ReputationBar', 'Reputation', DB.ReputationBar_Update, DB.ReputationBar_OnEnter, DB.ReputationBar_OnClick, {'TOPRIGHT', E.UIParent, 'TOPRIGHT', -3, -264})
	DB:CreateBarBubbles(Reputation)

	Reputation.ShouldHide = function()
		return (DB.db.reputation.hideBelowMaxLevel and not E:XPIsLevelMax()) or not E:GetWatchedFactionInfo()
	end

	E:CreateMover(Reputation.holder, 'ReputationBarMover', L['Reputation Bar'], nil, nil, nil, nil, nil, 'databars,reputation')

	DB:ReputationBar_Toggle()
end