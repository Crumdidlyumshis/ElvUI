local MAJOR_VERSION = "LibButtonGlow-1.0"
local MINOR_VERSION = 8

if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

lib.unusedOverlays = lib.unusedOverlays or {}
lib.numOverlays = lib.numOverlays or 0

lib.mediaPath = lib.mediaPath or "Interface\\AddOns\\ElvUI\\Media\\Textures\\"

local tinsert, tremove, tostring = table.insert, table.remove, tostring
local ceil, floor, fmod = math.ceil, math.floor, math.fmod
local pairs, ipairs, next = pairs, ipairs, next

-- WoW APIs
local CreateFrame = CreateFrame
local UnitBuff = UnitBuff
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()

-- Animation Functions
local function InitAlphaAnimation(self)
    self.target = self.target or self:GetRegionParent()
    self.change = self.change or 0
    self.frameAlpha = self.target:GetAlpha()
    self.alphaFactor = self.frameAlpha + self.change - self.frameAlpha
end

local function TidyAlphaAnimation(self)
    self.alphaFactor = nil
    self.frameAlpha = nil
end

local function AlphaAnimation_OnUpdate(self, elapsed)
    local progress = self:GetSmoothProgress()
    if progress ~= 0 then
        if not self.played then
            InitAlphaAnimation(self)
            self.played = 1
        end

        if self.frameAlpha then
            self.target:SetAlpha(self.frameAlpha + self.alphaFactor * progress)
            if progress == 1 then
                TidyAlphaAnimation(self)
            end
        end
    end
end

local function AlphaAnimation_OnStop(self)
    if self.frameAlpha then
        TidyAlphaAnimation(self)
    end
    self.played = nil
end

local function InitScaleAnimation(self)
	self.target = self.target or self:GetRegionParent()
	self.scaleX = self.scaleX or 0
	self.scaleY = self.scaleY or 0

	local _, _, width, height = self.target:GetRect()
	if not width then return end

	self.frameWidth = width
	self.frameHeight = height

	self.widthFactor = width * self.scaleX - width
	self.heightFactor = height * self.scaleY - height

	local setCenter
	local parent = self.target:GetParent()
	local numPoints = self.target:GetNumPoints()

	if numPoints > 0 then
		local point, relativeTo, relativePoint, xOffset, yOffset = self.target:GetPoint(1)

		if numPoints == 1 and point == "CENTER" then
			setCenter = false
		else
			local i = 1
			while true do
				if relativeTo ~= parent and yOffset then
					local j = #self + 1
					self[j], self[j + 1], self[j + 2], self[j + 3], self[j + 4] = point, relativeTo, relativePoint, xOffset, yOffset
				end

				i = i + 1
				if numPoints >= i then
					point, relativeTo, relativePoint, xOffset, yOffset = self.target:GetPoint(i)
				else
					break
				end
			end

			setCenter = true
		end
	else
		setCenter = true
	end

	if setCenter then
		local x, y = self.target:GetCenter()
		local parentX, parentY = parent:GetCenter()

		self.target:ClearAllPoints()
		self.target:SetPoint("CENTER", x - parentX, y - parentY)
	end

	return 1
end

local function TidyScaleAnimation(self)
	local target = self.target

	if #self ~= 0 then
		target:ClearAllPoints()

		for i = 1, #self, 5 do
			target:SetPoint(self[i], self[i + 1], self[i + 2], self[i + 3], self[i + 4])
			self[i] = nil
			self[i + 1] = nil
			self[i + 2] = nil
			self[i + 3] = nil
			self[i + 4] = nil
		end
	end

	self.widthFactor = nil
	self.heightFactor = nil

	self.frameWidth = nil
	self.frameHeight = nil
end

local function ScaleAnimation_OnUpdate(self, elapsed)
	local progress = self:GetSmoothProgress()
	if progress ~= 0 then
		if not self.played then
			if InitScaleAnimation(self) then
				self.played = 1
			end
		end

		if self.frameWidth then
			self.target:SetSize(self.frameWidth + self.widthFactor * progress, self.frameHeight + self.heightFactor * progress)

			if progress == 1 then
				TidyScaleAnimation(self)
			end
		end
	end
end

local function ScaleAnimation_OnStop(self)
	if self.frameWidth then
		TidyScaleAnimation(self)
	end

	self.played = nil
end

local function CreateAlphaAnim(group, target, order, duration, change, delay, onPlay, onFinished)
    local alpha = group:CreateAnimation()
    if type(target) == "string" then
        alpha.target = _G[alpha:GetRegionParent():GetName() .. target]
    else
        alpha.target = target
    end
    if order then
        alpha:SetOrder(order)
    end
    alpha:SetDuration(duration)
    alpha.change = change
    if delay then
        alpha:SetStartDelay(delay)
    end
    if onPlay then
        alpha:SetScript("OnPlay", onPlay)
    end
    alpha:SetScript("OnUpdate", AlphaAnimation_OnUpdate)
    alpha:SetScript("OnStop", AlphaAnimation_OnStop)
    alpha:SetScript("OnFinished", onFinished or AlphaAnimation_OnStop)
end

local function CreateScaleAnim(group, target, order, duration, x, y, delay, smoothing, onPlay)
    local scale = group:CreateAnimation()
    if type(target) == "string" then
        scale.target = _G[scale:GetRegionParent():GetName() .. target]
    else
        scale.target = target
    end
    scale:SetOrder(order)
    scale:SetDuration(duration)
    scale.scaleX, scale.scaleY = x, y
    if delay then
        scale:SetStartDelay(delay)
    end
    if smoothing then
        scale:SetSmoothing(smoothing)
    end
    if onPlay then
        scale:SetScript("OnPlay", onPlay)
    end
    scale:SetScript("OnUpdate", ScaleAnimation_OnUpdate)
    scale:SetScript("OnStop", ScaleAnimation_OnStop)
    scale:SetScript("OnFinished", ScaleAnimation_OnStop)
end


local function AnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)
    if not texture.frame then
        texture.frame = 1
        texture.throttle = throttle
        texture.numColumns = floor(textureWidth / frameWidth)
        texture.numRows = floor(textureHeight / frameHeight)
        texture.columnWidth = frameWidth / textureWidth
        texture.rowHeight = frameHeight / textureHeight
    end
    if not texture.throttle or texture.throttle > throttle then
        local frame = texture.frame
        local framesToAdvance = floor(texture.throttle / throttle)
        while frame + framesToAdvance > numFrames do
            frame = frame - numFrames
        end
        frame = frame + framesToAdvance
        texture.throttle = 0
        local left = fmod(frame - 1, texture.numColumns) * texture.columnWidth
        local right = left + texture.columnWidth
        local bottom = ceil(frame / texture.numColumns) * texture.rowHeight
        local top = bottom - texture.rowHeight
        texture:SetTexCoord(left, right, top, bottom)
        texture.frame = frame
    else
        texture.throttle = texture.throttle + elapsed
    end
end

-- Overlay Glow Functions
local function OverlayGlowAnimOutFinished(animGroup)
    local overlay = animGroup:GetParent()
    local frame = overlay:GetParent()
    overlay:Hide()
    tinsert(lib.unusedOverlays, overlay)
    frame.__LBGoverlay = nil
end

local function OverlayGlow_OnHide(self)
    if self.animOut:IsPlaying() then
        self.animOut:Stop()
        OverlayGlowAnimOutFinished(self.animOut)
    end
end

local function OverlayGlow_OnUpdate(self, elapsed)
    AnimateTexCoords(self.ants, 256, 256, 48, 48, 22, elapsed, 0.01)
    local cooldown = self:GetParent().cooldown
    -- we need some threshold to avoid dimming the glow during the gdc
    -- (using 1500 exactly seems risky, what if casting speed is slowed or something?)
    if cooldown and cooldown:IsShown() and cooldown:GetCooldownDuration() > 3000 then
        self:SetAlpha(0.5)
    else
        self:SetAlpha(1.0)
    end
end

local function AnimIn_OnPlay(group)
    local frame = group:GetParent()
    local frameWidth, frameHeight = frame:GetSize()
    frame.spark:SetSize(frameWidth, frameHeight)
    frame.spark:SetAlpha(0.3)
    frame.innerGlow:SetSize(frameWidth / 2, frameHeight / 2)
    frame.innerGlow:SetAlpha(1.0)
    frame.innerGlowOver:SetAlpha(1.0)
    frame.outerGlow:SetSize(frameWidth * 2, frameHeight * 2)
    frame.outerGlow:SetAlpha(1.0)
    frame.outerGlowOver:SetAlpha(1.0)
    frame.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
    frame.ants:SetAlpha(0)
    frame:Show()
end

local function AnimIn_OnFinished(group)
    local frame = group:GetParent()
    local frameWidth, frameHeight = frame:GetSize()
    frame.spark:SetAlpha(0)
    frame.innerGlow:SetAlpha(0)
    frame.innerGlow:SetSize(frameWidth, frameHeight)
    frame.innerGlowOver:SetAlpha(0.0)
    frame.outerGlow:SetSize(frameWidth, frameHeight)
    frame.outerGlowOver:SetAlpha(0.0)
    frame.outerGlowOver:SetSize(frameWidth, frameHeight)
    frame.ants:SetAlpha(1.0)
end

local function CreateOverlayGlow()
    lib.numOverlays = lib.numOverlays + 1

    local name = "ButtonGlowOverlay" .. tostring(lib.numOverlays)
    local overlay = CreateFrame("Frame", name, UIParent)

    -- spark
    overlay.spark = overlay:CreateTexture(name .. "Spark", "BACKGROUND")
    overlay.spark:SetPoint("CENTER")
    overlay.spark:SetAlpha(0)
    overlay.spark:SetTexture(lib.mediaPath .. "IconAlert")
    overlay.spark:SetTexCoord(0.00781250, 0.61718750, 0.00390625, 0.26953125)

    -- inner glow
    overlay.innerGlow = overlay:CreateTexture(name .. "InnerGlow", "ARTWORK")
    overlay.innerGlow:SetPoint("CENTER")
    overlay.innerGlow:SetAlpha(0)
    overlay.innerGlow:SetTexture(lib.mediaPath .. "IconAlert")
    overlay.innerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

    -- inner glow over
    overlay.innerGlowOver = overlay:CreateTexture(name .. "InnerGlowOver", "ARTWORK")
    overlay.innerGlowOver:SetPoint("TOPLEFT", overlay.innerGlow, "TOPLEFT")
    overlay.innerGlowOver:SetPoint("BOTTOMRIGHT", overlay.innerGlow, "BOTTOMRIGHT")
    overlay.innerGlowOver:SetAlpha(0)
    overlay.innerGlowOver:SetTexture(lib.mediaPath .. "IconAlert")
    overlay.innerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

    -- outer glow
    overlay.outerGlow = overlay:CreateTexture(name .. "OuterGlow", "ARTWORK")
    overlay.outerGlow:SetPoint("CENTER")
    overlay.outerGlow:SetAlpha(0)
    overlay.outerGlow:SetTexture(lib.mediaPath .. "IconAlert")
    overlay.outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

    -- outer glow over
    overlay.outerGlowOver = overlay:CreateTexture(name .. "OuterGlowOver", "ARTWORK")
    overlay.outerGlowOver:SetPoint("TOPLEFT", overlay.outerGlow, "TOPLEFT")
    overlay.outerGlowOver:SetPoint("BOTTOMRIGHT", overlay.outerGlow, "BOTTOMRIGHT")
    overlay.outerGlowOver:SetAlpha(0)
    overlay.outerGlowOver:SetTexture(lib.mediaPath .. "IconAlert")
    overlay.outerGlowOver:SetTexCoord(0.00781250, 0.50781250, 0.53515625, 0.78515625)

    -- ants
    overlay.ants = overlay:CreateTexture(name .. "Ants", "OVERLAY")
    overlay.ants:SetPoint("CENTER")
    overlay.ants:SetAlpha(0)
    overlay.ants:SetTexture(lib.mediaPath .. "IconAlertAnts")

    -- setup animations
    overlay.animIn = overlay:CreateAnimationGroup()
    CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 1.5, 1.5)
    CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, 1)
    CreateScaleAnim(overlay.animIn, overlay.innerGlow,      1, 0.3, 2, 2)
    CreateScaleAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, 2, 2)
    CreateAlphaAnim(overlay.animIn, overlay.innerGlowOver,  1, 0.3, -1)
    CreateScaleAnim(overlay.animIn, overlay.outerGlow,      1, 0.3, 0.5, 0.5)
    CreateScaleAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, 0.5, 0.5)
    CreateAlphaAnim(overlay.animIn, overlay.outerGlowOver,  1, 0.3, -1)
    CreateScaleAnim(overlay.animIn, overlay.spark,          1, 0.2, 2/3, 2/3, 0.2)
    CreateAlphaAnim(overlay.animIn, overlay.spark,          1, 0.2, -1, 0.2)
    CreateAlphaAnim(overlay.animIn, overlay.innerGlow,      1, 0.2, -1, 0.3)
    CreateAlphaAnim(overlay.animIn, overlay.ants,           1, 0.2, 1, 0.3)
    overlay.animIn:SetScript("OnPlay", AnimIn_OnPlay)
    overlay.animIn:SetScript("OnFinished", AnimIn_OnFinished)

    overlay.animOut = overlay:CreateAnimationGroup()
    CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 1, 0.2, 1)
    CreateAlphaAnim(overlay.animOut, overlay.ants,          1, 0.2, -1)
    CreateAlphaAnim(overlay.animOut, overlay.outerGlowOver, 2, 0.2, -1)
    CreateAlphaAnim(overlay.animOut, overlay.outerGlow,     2, 0.2, -1)
    overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)

    -- scripts
    overlay:SetScript("OnUpdate", OverlayGlow_OnUpdate)
    overlay:SetScript("OnHide", OverlayGlow_OnHide)

    return overlay
end

local function GetOverlayGlow()
    local overlay = tremove(lib.unusedOverlays)
    if not overlay then
        overlay = CreateOverlayGlow()
    end
    return overlay
end

function lib.ShowOverlayGlow(frame)
    if frame.__LBGoverlay then
        if frame.__LBGoverlay.animOut:IsPlaying() then
            frame.__LBGoverlay.animOut:Stop()
            frame.__LBGoverlay.animIn:Play()
        end
    else
        local overlay = GetOverlayGlow()
        local frameWidth, frameHeight = frame:GetSize()
        overlay:SetParent(frame)
        overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
        overlay:ClearAllPoints()
        --Make the height/width available before the next frame:
        overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4)
        overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		overlay.animIn:Play()
		frame.__LBGoverlay = overlay

		if Masque and Masque.UpdateSpellAlert and (not frame.overlay or not issecurevariable(frame, "overlay")) then
			local old_overlay = frame.overlay
			frame.overlay = overlay
			Masque:UpdateSpellAlert(frame)

			frame.overlay = old_overlay
		end
	end
end

function lib.HideOverlayGlow(frame)
	if frame.__LBGoverlay then
		if frame.__LBGoverlay.animIn:IsPlaying() then
			frame.__LBGoverlay.animIn:Stop()
		end
		if frame:IsVisible() then
			frame.__LBGoverlay.animOut:Play()
		else
			OverlayGlowAnimOutFinished(frame.__LBGoverlay.animOut)
		end
	end
end