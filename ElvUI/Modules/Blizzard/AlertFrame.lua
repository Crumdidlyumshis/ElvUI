local E, L = unpack(ElvUI)
local B = E:GetModule("Blizzard")
local Misc = E:GetModule("Misc")

--Lua functions
local _G = _G
local pairs = pairs
--WoW API / Variables
local NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES

local POSITION, ANCHOR_POINT, Y_OFFSET, BASE_YOFFSET = 'TOP', 'BOTTOM', -5, 0 -- should match in PostAlertMove

function E:PostAlertMove()
	local AlertFrame = _G.AlertFrame
	local AlertFrameMover = _G.AlertFrameMover

	local _, y = AlertFrameMover:GetCenter()
	local growUp = y < (E.UIParent:GetTop() * 0.5)

	if growUp then
		POSITION, ANCHOR_POINT, Y_OFFSET, BASE_YOFFSET = 'BOTTOM', 'TOP', 5, 0
	else -- should match above in the cache
		POSITION, ANCHOR_POINT, Y_OFFSET, BASE_YOFFSET = 'TOP', 'BOTTOM', -5, 0
	end

	AlertFrameMover:SetFormattedText('%s %s', AlertFrameMover.textString, growUp and '(Grow Up)' or '(Grow Down)')

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints((E.private.general.lootRoll and Misc:UpdateLootRollAnchors(POSITION)) or _G.AlertFrameHolder)
end

function B:AchievementAlertFrame_FixAnchors()
	local alertAnchor
	for i = 1, MAX_ACHIEVEMENT_ALERTS do
		local frame = _G["AchievementAlertFrame"..i]
		if frame then
			frame:ClearAllPoints()
			if alertAnchor and alertAnchor:IsShown() then
				frame:Point(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
			else
				frame:Point(POSITION, AlertFrame, ANCHOR_POINT)
			end

			alertAnchor = frame
		end
	end
end

function B:DungeonCompletionAlertFrame_FixAnchors()
	for i = MAX_ACHIEVEMENT_ALERTS, 1, -1 do
		local frame = _G["AchievementAlertFrame"..i]
		if frame and frame:IsShown() then
			DungeonCompletionAlertFrame1:ClearAllPoints()
			DungeonCompletionAlertFrame1:Point(POSITION, frame, ANCHOR_POINT, 0, YOFFSET)
			return
		end

		DungeonCompletionAlertFrame1:ClearAllPoints()
		DungeonCompletionAlertFrame1:Point(POSITION, AlertFrame, ANCHOR_POINT)
	end
end

function B:AlertMovers()
	local AlertFrameHolder = CreateFrame("Frame", "AlertFrameHolder", E.UIParent)
	AlertFrameHolder:Size(250, 20)
	AlertFrameHolder:Point("TOP", E.UIParent, "TOP", 0, -18)

	self:SecureHook("AlertFrame_FixAnchors", E.PostAlertMove)
	self:SecureHook("AchievementAlertFrame_FixAnchors")
	self:SecureHook("DungeonCompletionAlertFrame_FixAnchors")

	E:CreateMover(AlertFrameHolder, "AlertFrameMover", L["Loot / Alert Frames"], nil, nil, E.PostAlertMove, nil, nil, "general,blizzardImprovements")
end