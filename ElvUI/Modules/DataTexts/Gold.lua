local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')
local B = E:GetModule('Bags')
local LC = E.Libs.Compat
-- GLOBALS: ElvDB

local type, wipe, pairs, ipairs, sort = type, wipe, pairs, ipairs, sort
local format, gsub, match, strjoin, tinsert = format, string.gsub, string.match, strjoin, tinsert

local _G = _G
local EasyMenu = EasyMenu
local GetMoney = GetMoney
local IsLoggedIn = IsLoggedIn
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown

local BreakUpLargeNumbers = LC.BreakUpLargeNumbers

local Profit, Spent = 0, 0
local resetCountersFormatter = strjoin('', '|cffaaaaaa', L["Reset Session Data: Hold Ctrl + Right Click"], '|r')
local resetInfoFormatter = strjoin('', '|cffaaaaaa', L["Reset Character Data: Hold Shift + Right Click"], '|r')

local PRIEST_COLOR = RAID_CLASS_COLORS.PRIEST
local CURRENCY = CURRENCY

local menuList, myGold = {}, {}
local totalGold, totalHorde, totalAlliance = 0, 0, 0
local iconString = '|T%s:20:20:0:0:64:64:4:60:4:60|t'
local db

local function sortFunction(a, b)
	return a.amount > b.amount
end

local function deleteCharacter(_, realm, name)
	ElvDB.gold[realm][name] = nil
	ElvDB.class[realm][name] = nil
	ElvDB.faction[realm][name] = nil

	DT:ForceUpdate_DataText('Gold')
end

local function updateTotal(faction, change)
	if faction == 'Alliance' then
		totalAlliance = totalAlliance + change
	elseif faction == 'Horde' then
		totalHorde = totalHorde + change
	end

	totalGold = totalGold + change
end

local function updateGold(self, updateAll, goldChange)
	local textOnly = not db.goldCoins and true or false
	local style = db.goldFormat or 'BLIZZARD'

	if updateAll then
		wipe(myGold)
		wipe(menuList)

		totalGold, totalHorde, totalAlliance = 0, 0, 0

		tinsert(menuList, { text = '', isTitle = true, notCheckable = true })
		tinsert(menuList, { text = 'Delete Character', isTitle = true, notCheckable = true })

		for name in pairs(ElvDB.gold[E.myrealm]) do
			local faction = ElvDB.faction[E.myrealm][name]
			local gold = ElvDB.gold[E.myrealm][name]

			if gold then
				local color = E:ClassColor(ElvDB.class[E.myrealm][name]) or PRIEST_COLOR

				tinsert(myGold, {
						name = name,
						realm = E.myrealm,
						amount = gold,
						amountText = E:FormatMoney(gold, style, textOnly),
						faction = faction or '',
						r = color.r, g = color.g, b = color.b,
				})

				tinsert(menuList, {
					text = format('%s - %s', name, E.myrealm),
					notCheckable = true,
					func = function() deleteCharacter(self, E.myrealm, name) end
				})

				updateTotal(faction, gold)
			end
		end

		for _, info in ipairs(myGold) do
			if info.name == E.myname and info.realm == E.myrealm then
				info.amount = ElvDB.gold[E.myrealm][E.myname]
				info.amountText = E:FormatMoney(ElvDB.gold[E.myrealm][E.myname], style, textOnly)

				break
			end
		end

		if goldChange then
			updateTotal(E.myfaction, goldChange)
		end
	end
end

local function OnEvent(self, event)
	if not IsLoggedIn() then return end

	if not db then
		db = E.global.datatexts.settings[self.name]
	end

	--prevent an error possibly from really old profiles
	local oldMoney = ElvDB.gold[E.myrealm][E.myname]
	if oldMoney and type(oldMoney) ~= 'number' then
		ElvDB.gold[E.myrealm][E.myname] = nil
		oldMoney = nil
	end

	local NewMoney = GetMoney()
	ElvDB.gold[E.myrealm][E.myname] = NewMoney

	local OldMoney = oldMoney or NewMoney
	local Change = NewMoney-OldMoney -- Positive if we gain money
	if OldMoney>NewMoney then		-- Lost Money
		Spent = Spent - Change
	else							-- Gained Moeny
		Profit = Profit + Change
	end

	updateGold(self, event == 'ELVUI_FORCE_UPDATE', Change)

	self.text:SetText(E:FormatMoney(NewMoney, db.goldFormat or 'BLIZZARD', not db.goldCoins))
end

local function Click(self, btn)
	if btn == 'RightButton' then
		if IsShiftKeyDown() then
			E:SetEasyMenuAnchor(E.EasyMenu, self)
			EasyMenu(menuList, E.EasyMenu, nil, nil, nil, 'MENU')
		elseif IsControlKeyDown() then
			Profit = 0
			Spent = 0
		end
	else
		B:ToggleAllBags()
	end
end

local function OnEnter()
	DT.tooltip:ClearLines()

	local textOnly = not db.goldCoins and true or false
	local style = db.goldFormat or 'BLIZZARD'

	DT.tooltip:AddLine(L["Session:"])
	DT.tooltip:AddDoubleLine(L["Earned:"], E:FormatMoney(Profit, style, textOnly), 1, 1, 1, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Spent:"], E:FormatMoney(Spent, style, textOnly), 1, 1, 1, 1, 1, 1)

	if Spent ~= 0 then
		local gained = Profit > Spent
		DT.tooltip:AddDoubleLine(gained and L["Profit:"] or L["Deficit:"], E:FormatMoney(Profit-Spent, style, textOnly), gained and 0 or 1, gained and 1 or 0, 0, 1, 1, 1)
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(L["Character: "])

	sort(myGold, sortFunction)

	for _, g in ipairs(myGold) do
		local nameLine = ''
		if g.faction ~= '' and g.faction ~= 'Neutral' then
			nameLine = format([[|TInterface\FriendsFrame\PlusManz-%s:24|t ]], g.faction)
		end

		local toonName = format('%s%s%s', nameLine, g.name, (g.realm and g.realm ~= E.myrealm and ' - '..g.realm) or '')
		DT.tooltip:AddDoubleLine((g.name == E.myname and toonName..[[ |TInterface\COMMON\Indicator-Green:24|t]]) or toonName, g.amountText, g.r, g.g, g.b, 1, 1, 1)
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(L["Server: "])
	if totalAlliance > 0 and totalHorde > 0 then
		if totalAlliance ~= 0 then DT.tooltip:AddDoubleLine(L["Alliance: "], E:FormatMoney(totalAlliance, style, textOnly), 0, .376, 1, 1, 1, 1) end
		if totalHorde ~= 0 then DT.tooltip:AddDoubleLine(L["Horde: "], E:FormatMoney(totalHorde, style, textOnly), 1, .2, .2, 1, 1, 1) end
		DT.tooltip:AddLine(' ')
	end
	DT.tooltip:AddDoubleLine(L["Total: "], E:FormatMoney(totalGold, style, textOnly), 1, 1, 1, 1, 1, 1)

	local index = 1
	local info, name = DT:BackpackCurrencyInfo(index)

	while name do
		if index == 1 then
			DT.tooltip:AddLine(' ')
			DT.tooltip:AddLine(CURRENCY)
		end

		if info.quantity then
			iconString = match(info and info.iconFileID or '', E.myfaction) ~= nil and gsub(iconString, '4:60:4:60', '4:38:2:36') or iconString
			DT.tooltip:AddDoubleLine(format('%s %s', format(iconString, info.iconFileID), name), BreakUpLargeNumbers(info.quantity), 1, 1, 1, 1, 1, 1)
		end

		index = index + 1
		info, name = DT:BackpackCurrencyInfo(index)
	end

	local grayValue = B:GetGraysValue()
	if grayValue > 0 then
		DT.tooltip:AddLine(' ')
		DT.tooltip:AddDoubleLine(L["Grays"], E:FormatMoney(grayValue, style, textOnly), nil, nil, nil, 1, 1, 1)
	end

	DT.tooltip:AddLine(' ')
	DT.tooltip:AddLine(resetCountersFormatter)
	DT.tooltip:AddLine(resetInfoFormatter)
	DT.tooltip:Show()
end

DT:RegisterDatatext('Gold', nil, { 'PLAYER_MONEY', 'SEND_MAIL_MONEY_CHANGED', 'SEND_MAIL_COD_CHANGED', 'PLAYER_TRADE_MONEY', 'TRADE_MONEY_CHANGED', 'CURRENCY_DISPLAY_UPDATE' }, OnEvent, nil, Click, OnEnter, nil, L["Gold"])
