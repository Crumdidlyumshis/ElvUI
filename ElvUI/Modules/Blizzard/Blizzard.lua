local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule("Blizzard")

--Lua functions
--WoW API / Variables
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local GetTradeSkillListLink = GetTradeSkillListLink
local Minimap_SetPing = Minimap_SetPing
local UnitIsUnit = UnitIsUnit
local MINIMAPPING_FADE_TIMER = MINIMAPPING_FADE_TIMER

function BL:ADDON_LOADED(_, addon)
	if addon == "Blizzard_TradeSkillUI" then
		TradeSkillLinkButton:SetScript("OnClick", function()
			local ChatFrameEditBox = ChatEdit_ChooseBoxForSend()
			if not ChatFrameEditBox:IsShown() then
				ChatEdit_ActivateChat(ChatFrameEditBox)
			end

			ChatFrameEditBox:Insert(GetTradeSkillListLink())
		end)

		BL:UnregisterEvent("ADDON_LOADED")
	end

	if addon == 'Blizzard_GuildBankUI' then
		BL:ImproveGuildBank()
	elseif BL.TryDisableTutorials then
		BL:ShutdownTutorials()
	end
end

function BL:ObjectiveTracker_AutoHide()
	local tracker = _G.WatchFrame
	if not tracker then return end

	if not tracker.AutoHider then
		tracker.AutoHider = CreateFrame('Frame', nil, tracker, 'SecureHandlerStateTemplate')
		tracker.AutoHider:SetAttribute('_onstate-objectiveHider', 'if newstate == 1 then self:Hide() else self:Show() end')
		tracker.AutoHider:SetScript('OnHide', BL.ObjectiveTracker_AutoHideOnHide)
		tracker.AutoHider:SetScript('OnShow', BL.ObjectiveTracker_AutoHideOnShow)
	end

	if E.db.general.objectiveFrameAutoHide then
		RegisterStateDriver(tracker.AutoHider, 'objectiveHider', '[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists][@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists][@boss5,exists] 1;0')
	else
		UnregisterStateDriver(tracker.AutoHider, 'objectiveHider')
	end
end

function BL:Initialize()
	BL.Initialized = true

	BL:AlertMovers()
	BL:EnhanceColorPicker()
	BL:KillBlizzard()
	BL:PositionCaptureBar()
	BL:PositionDurabilityFrame()
	BL:PositionGMFrames()
	BL:PositionVehicleFrame()
	BL:ObjectiveTracker_Setup()

	BL:RegisterEvent("ADDON_LOADED")
	BL:RegisterEvent("ZONE_CHANGED_NEW_AREA", SetMapToCurrentZone)

	KBArticle_BeginLoading = E.noop
	KBSetup_BeginLoading = E.noop
	KnowledgeBaseFrame_OnEvent(nil, "KNOWLEDGE_BASE_SETUP_LOAD_FAILURE")

	if GetLocale() == "deDE" then
		DAY_ONELETTER_ABBR = "%d d"
		MINUTE_ONELETTER_ABBR = "%d m"
	end

	CreateFrame("Frame"):SetScript("OnUpdate", function()
		if LFRBrowseFrame.timeToClear then
			LFRBrowseFrame.timeToClear = nil
		end
	end)

	MinimapPing:HookScript("OnUpdate", function(self)
		if self.fadeOut or self.timer > MINIMAPPING_FADE_TIMER then
			Minimap_SetPing(Minimap:GetPingPosition())
		end
	end)

	QuestLogFrame:HookScript("OnShow", function()
		local questFrame = QuestLogFrame:GetFrameLevel()
		local controlPanel = QuestLogControlPanel:GetFrameLevel()
		local scrollFrame = QuestLogDetailScrollFrame:GetFrameLevel()

		if questFrame >= controlPanel then
			QuestLogControlPanel:SetFrameLevel(questFrame + 1)
		end
		if questFrame >= scrollFrame then
			QuestLogDetailScrollFrame:SetFrameLevel(questFrame + 1)
		end
	end)

	ReadyCheckFrame:HookScript("OnShow", function(self)
		if UnitIsUnit("player", self.initiator) then
			self:Hide()
		end
	end)

--	WORLDMAP_POI_FRAMELEVEL = 300
--	WorldMapFrame:SetToplevel(true)

	do
		local originalFunc = LFDQueueFrameRandomCooldownFrame_OnEvent
		local originalScript = LFDQueueFrameCooldownFrame:GetScript("OnEvent")

		LFDQueueFrameRandomCooldownFrame_OnEvent = function(self, event, unit, ...)
			if event == "UNIT_AURA" and not unit then return end
			originalFunc(self, event, unit, ...)
		end

		if originalFunc == originalScript then
			LFDQueueFrameCooldownFrame:SetScript("OnEvent", LFDQueueFrameRandomCooldownFrame_OnEvent)
		else
			LFDQueueFrameCooldownFrame:SetScript("OnEvent", function(self, event, unit, ...)
				if event == "UNIT_AURA" and not unit then return end
				originalScript(self, event, unit, ...)
			end)
		end
	end
end

local function InitializeCallback()
	BL:Initialize()
end

E:RegisterModule(BL:GetName(), InitializeCallback)