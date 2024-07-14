local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')
local TT = E:GetModule('Tooltip')

local _G = _G
local next = next

function S:StyleTooltips()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	for _, tt in next, {
		_G.GameTooltip,
		_G.ItemRefTooltip,
		_G.ItemRefShoppingTooltip1,
		_G.ItemRefShoppingTooltip2,
		_G.ItemRefShoppingTooltip3,
		_G.AutoCompleteBox,
		_G.FriendsTooltip,
		_G.ConsolidatedBuffsTooltip,
		_G.ShoppingTooltip1,
		_G.ShoppingTooltip2,
		_G.ShoppingTooltip3,
		_G.WorldMapTooltip,
		_G.WorldMapCompareTooltip1,
		_G.WorldMapCompareTooltip2,
		_G.WorldMapCompareTooltip3,
		_G.DataTextTooltip,
		-- ours
		E.ConfigTooltip,
		E.SpellBookTooltip,
	} do
		TT:SecureHookScript(tt, 'OnShow', 'SetStyle')
	end

	local LQT = LibStub("LibQTip-1.0", true)
	if LQT then
		S:SecureHook(LQT, 'Acquire', function()
			for _, tooltip in LQT:IterateTooltips() do
				if not tooltip.isSkinned then
					tooltip:StripTextures(true)
					tooltip:CreateBackdrop("Transparent")
					-- tooltip.isSkinned = true
				end
			end
		end)
	end

	local LQTRS = LibStub("LibQTip-1.0RS", true)
	if LQTRS then
		S:SecureHook(LQTRS, 'Acquire', function()
			for _, tooltip in LQTRS:IterateTooltips() do
				if not tooltip.isSkinned then
					tooltip:StripTextures(true)
					tooltip:CreateBackdrop("Transparent")
					-- tooltip.isSkinned = true
				end
			end
		end)
	end
end

function S:TooltipFrames()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.tooltip) then return end

	S:StyleTooltips()
	S:HandleCloseButton(_G.ItemRefCloseButton)

	-- Skin GameTooltip Status Bar
	_G.GameTooltipStatusBar:SetStatusBarTexture(E.media.normTex)
	_G.GameTooltipStatusBar:CreateBackdrop('Transparent')
	_G.GameTooltipStatusBar:ClearAllPoints()
	_G.GameTooltipStatusBar:Point('TOPLEFT', _G.GameTooltip, 'BOTTOMLEFT', E.Border, -(E.Spacing * 3))
	_G.GameTooltipStatusBar:Point('TOPRIGHT', _G.GameTooltip, 'BOTTOMRIGHT', -E.Border, -(E.Spacing * 3))
	E:RegisterStatusBar(_G.GameTooltipStatusBar)

	-- Tooltip Styling
	TT:SecureHook('GameTooltip_ShowStatusBar')

	TT:SecureHookScript(_G.GameTooltip, 'OnSizeChanged', 'CheckBackdropColor')
	TT:SecureHookScript(_G.GameTooltip, 'OnUpdate', 'CheckBackdropColor')
end

S:AddCallback('TooltipFrames')