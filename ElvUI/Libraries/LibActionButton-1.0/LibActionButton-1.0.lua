-- License: LICENSE.txt

local MAJOR_VERSION = "LibActionButton-1.0-ElvUI"
local MINOR_VERSION = 47 -- the real minor version is 108

local LibStub = LibStub
if not LibStub then error(MAJOR_VERSION .. " requires LibStub.") end
local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

-- Lua functions
local type, error, tostring, tonumber, assert, select = type, error, tostring, tonumber, assert, select
local setmetatable, wipe, unpack, pairs, ipairs, next, pcall = setmetatable, wipe, unpack, pairs, ipairs, next, pcall
local str_match, format, tinsert, tremove, strsub = string.match, format, tinsert, tremove, strsub

local KeyBound = LibStub("LibKeyBound-1.0", true)
local CBH = LibStub("CallbackHandler-1.0")

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()

lib.buttonRegistry = lib.buttonRegistry or {}
lib.activeButtons = lib.activeButtons or {}
lib.actionButtons = lib.actionButtons or {}
lib.nonActionButtons = lib.nonActionButtons or {}

-- usable state for retail using slot
lib.slotByButton = lib.slotByButton or {}
lib.buttonsBySlot = lib.buttonsBySlot or {}

local AuraButtons = lib.AuraButtons or { auras = {}, buttons = {} }
lib.AuraButtons = AuraButtons

lib.callbacks = lib.callbacks or CBH:New(lib)

local Generic = CreateFrame("CheckButton")
local Generic_MT = {__index = Generic}

local Action = setmetatable({}, {__index = Generic})
local Action_MT = {__index = Action}

local PetAction = setmetatable({}, {__index = Generic})
local PetAction_MT = {__index = PetAction}

local Spell = setmetatable({}, {__index = Generic})
local Spell_MT = {__index = Spell}

local Item = setmetatable({}, {__index = Generic})
local Item_MT = {__index = Item}

local Macro = setmetatable({}, {__index = Generic})
local Macro_MT = {__index = Macro}

local Custom = setmetatable({}, {__index = Generic})
local Custom_MT = {__index = Custom}

local type_meta_map = {
	empty  = Generic_MT,
	action = Action_MT,
	pet    = PetAction_MT,
	spell  = Spell_MT,
	item   = Item_MT,
	macro  = Macro_MT,
	custom = Custom_MT
}

local ButtonRegistry, ActiveButtons, ActionButtons, NonActionButtons = lib.buttonRegistry, lib.activeButtons, lib.actionButtons, lib.nonActionButtons

local Update, UpdateButtonState, UpdateUsable, UpdateCount, UpdateCooldown, UpdateTooltip
local StartFlash, StopFlash, UpdateFlash, UpdateHotkeys, UpdateRangeTimer
local ShowGrid, HideGrid, UpdateGrid, SetupSecureSnippets, WrapOnClick
local UpdateRange -- Sezz: new method

local UpdateAuraCooldowns -- Simpy
local AURA_COOLDOWNS_ENABLED = true
local AURA_COOLDOWNS_DURATION = 0

local InitializeEventHandler, OnEvent, ForAllButtons, OnUpdate

local RangeFont
do -- properly support range symbol when it's shown ~Simpy
	local locale = GetLocale()
	local stockFont, stockFontSize, stockFontOutline
	if locale == 'koKR' then
		stockFont, stockFontSize, stockFontOutline = [[Fonts\2002.TTF]], 11, 'MONOCHROME, THICKOUTLINE'
	elseif locale == 'zhTW' then
		stockFont, stockFontSize, stockFontOutline = [[Fonts\arheiuhk_bd.TTF]], 11, 'MONOCHROME, THICKOUTLINE'
	elseif locale == 'zhCN' then
		stockFont, stockFontSize, stockFontOutline = [[Fonts\FRIZQT__.TTF]], 11, 'MONOCHROME, OUTLINE'
	else
		stockFont, stockFontSize, stockFontOutline = [[Fonts\ARIALN.TTF]], 12, 'MONOCHROME, THICKOUTLINE'
	end

	RangeFont = {
		font = {
			font = stockFont,
			size = stockFontSize,
			flags = stockFontOutline,
		},
		color = { 0.9, 0.9, 0.9 }
	}
end

local DefaultConfig = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	enabled = true,
	showGrid = false,
	useColoring = true,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		mana = { 0.5, 0.5, 1.0 },
		usable = { 1.0, 1.0, 1.0 },
		notUsable = { 0.4, 0.4, 0.4 },
	},
	hideElements = {
		count = false,
		macro = false,
		hotkey = false,
		equipped = false,
		border = false,
		borderIfEmpty = false,
	},
	keyBoundTarget = false,
	keyBoundClickButton = "LeftButton",
	clickOnDown = false,
	flyoutDirection = "UP",
	disableCountDownNumbers = false,
	useDrawBling = true,
	handleOverlay = true,
	text = {
		hotkey = {
			font = {
				font = false, -- "Fonts\\ARIALN.TTF",
				size = 14,
				flags = "OUTLINE",
			},
			color = { 0.75, 0.75, 0.75 },
			position = {
				anchor = "TOPRIGHT",
				relAnchor = "TOPRIGHT",
				offsetX = -2,
				offsetY = -4,
			},
			justifyH = "RIGHT",
		},
		count = {
			font = {
				font = false, -- "Fonts\\ARIALN.TTF",
				size = 16,
				flags = "OUTLINE",
			},
			color = { 1, 1, 1 },
			position = {
				anchor = "BOTTOMRIGHT",
				relAnchor = "BOTTOMRIGHT",
				offsetX = -2,
				offsetY = 4,
			},
			justifyH = "RIGHT",
		},
		macro = {
			font = {
				font = false, -- "Fonts\\FRIZQT__.TTF",
				size = 12,
				flags = "OUTLINE",
			},
			color = { 1, 1, 1 },
			position = {
				anchor = "BOTTOM",
				relAnchor = "BOTTOM",
				offsetX = 0,
				offsetY = 2,
			},
			justifyH = "CENTER",
		},
	},
}

--- Create a new action button.
-- @param id Internal id of the button (not used by LibActionButton-1.0, only for tracking inside the calling addon)
-- @param name Name of the button frame to be created (not used by LibActionButton-1.0 aside from naming the frame)
-- @param header Header that drives these action buttons (if any)
function lib:CreateButton(id, name, header, config)
	if type(name) ~= "string" then
		error("Usage: CreateButton(id, name. header): Buttons must have a valid name!", 2)
	end
	if not header then
		error("Usage: CreateButton(id, name, header): Buttons without a secure header are not yet supported!", 2)
	end

	if not KeyBound then
		KeyBound = LibStub("LibKeyBound-1.0", true)
	end

	local button = setmetatable(CreateFrame("CheckButton", name, header, "SecureActionButtonTemplate, ActionButtonTemplate"), Generic_MT)
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")

	-- Store all sub frames on the button object for easier access
	button.icon               = _G[name .. "Icon"]
	button.Flash              = _G[name .. "Flash"]
	button.HotKey             = _G[name .. "HotKey"]
	button.Count              = _G[name .. "Count"]
	button.Name         	  = _G[name .. "Name"]
	button.Border             = _G[name .. "Border"]
	button.cooldown           = _G[name .. "Cooldown"]
	button.NormalTexture      = _G[name .. "NormalTexture"]

	button.cooldown:SetFrameStrata(button:GetFrameStrata())
	button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)

	local AuraCooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.AuraCooldown = AuraCooldown

	-- Frame Scripts
	button:SetScript("OnEnter", Generic.OnEnter)
	button:SetScript("OnLeave", Generic.OnLeave)
	button:SetScript("PreClick", Generic.PreClick)
	button:SetScript("PostClick", Generic.PostClick)
	button:SetScript("OnEvent", Generic.OnButtonEvent)

	button.id = id
	button.header = header
	-- Mapping of state -> action
	button.state_types = {}
	button.state_actions = {}

	-- Store the LAB Version that created this button for debugging
	button.__LAB_Version = MINOR_VERSION

	-- just in case we're not run by a header, default to state 0
	button:SetAttribute("state", 0)

	SetupSecureSnippets(button)
	WrapOnClick(button)

	-- if there is no button yet, initialize events later
	local InitializeEvents = not next(ButtonRegistry)

	-- Store the button in the registry, needed for event and OnUpdate handling
	ButtonRegistry[button] = true

	-- setup button configuration
	button:UpdateConfig(config)

	-- run an initial update
	button:UpdateAction()
	UpdateHotkeys(button)

	-- initialize events
	if InitializeEvents then
		InitializeEventHandler()
	end

	-- somewhat of a hack for the Flyout buttons to not error.
	button.action = 0

	lib.callbacks:Fire("OnButtonCreated", button)

	return button
end

function SetupSecureSnippets(button)
	button:SetAttribute("_custom", Custom.RunCustom)
	-- secure UpdateState(self, state)
	-- update the type and action of the button based on the state
	button:SetAttribute("UpdateState", [[
		local state = ...
		self:SetAttribute("state", state)
		local type, action = (self:GetAttribute(format("labtype-%s", state)) or "empty"), self:GetAttribute(format("labaction-%s", state))

		self:SetAttribute("type", type)
		if type ~= "empty" and type ~= "custom" then
			local action_field = (type == "pet") and "action" or type
			self:SetAttribute(action_field, action)
			self:SetAttribute("action_field", action_field)
		end
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self:Run(onStateChanged, state, type, action)
		end
	]])

	-- this function is invoked by the header when the state changes
	button:SetAttribute("_childupdate-state", [[
		control:RunFor(self, self:GetAttribute("UpdateState"), message)
	]])

	-- secure PickupButton(self, kind, value, ...)
	-- utility function to place a object on the cursor
	button:SetAttribute("PickupButton", [[
		local kind, value = ...
		if kind == "empty" then
			return "clear"
		elseif kind == "action" or kind == "pet" then
			local actionType = (kind == "pet") and "petaction" or kind
			return actionType, value
		elseif kind == "spell" or kind == "item" or kind == "macro" then
			return "clear", kind, value
		else
			print("LibActionButton-1.0: Unknown type: " .. tostring(kind))
			return false
		end
	]]);

	button:SetAttribute("OnDragStart", [[
		if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION")) or self:GetAttribute("LABdisableDragNDrop") then return false end
		local state = self:GetAttribute("state")
		local type = self:GetAttribute("type")
		-- if the button is empty, we can't drag anything off it
		if type == "empty" or type == "custom" then
			return false
		end
		-- Get the value for the action attribute
		local action_field = self:GetAttribute("action_field")
		local action = self:GetAttribute(action_field)

		-- non-action fields need to change their type to empty
		if type ~= "action" and type ~= "pet" then
			self:SetAttribute(format("labtype-%s", state), "empty")
			self:SetAttribute(format("labaction-%s", state), nil)
			-- update internal state
			control:RunFor(self, self:GetAttribute("UpdateState"), state)
			-- send a notification to the insecure code
			--self:CallMethod("ButtonContentsChanged", state, "empty", nil)
		end
		-- return the button contents for pickup
		return control:RunFor(self, self:GetAttribute("PickupButton"), type, action)
	]])

	button:SetAttribute("OnReceiveDrag", [[
		if self:GetAttribute("LABdisableDragNDrop") then return false end
		local kind, value, subtype, extra = ...
		if not kind or not value then return false end
		local state = self:GetAttribute("state")
		local buttonType, buttonAction = self:GetAttribute("type"), nil
		if buttonType == "custom" then return false end
		-- action buttons can do their magic themself
		-- for all other buttons, we'll need to update the content now
		if buttonType ~= "action" and buttonType ~= "pet" then
			-- with "spell" types, the 4th value contains the actual spell id
			if kind == "spell" then
				if extra then
					value = extra
				else
					print("no spell id?", ...)
				end
			elseif kind == "item" and value then
				value = format("item:%d", value)
			end

			-- Get the action that was on the button before
			if buttonType ~= "empty" then
				buttonAction = self:GetAttribute(self:GetAttribute("action_field"))
			end

			-- TODO: validate what kind of action is being fed in here
			-- We can only use a handful of the possible things on the cursor
			-- return false for all those we can't put on buttons

			self:SetAttribute(format("labtype-%s", state), kind)
			self:SetAttribute(format("labaction-%s", state), value)
			-- update internal state
			control:RunFor(self, self:GetAttribute("UpdateState"), state)
			-- send a notification to the insecure code
			--self:CallMethod("ButtonContentsChanged", state, kind, value)
		else
			-- get the action for (pet-)action buttons
			buttonAction = self:GetAttribute("action")
		end
		return control:RunFor(self, self:GetAttribute("PickupButton"), buttonType, buttonAction)
	]])

	button:SetScript("OnDragStart", nil)
	-- Wrapped OnDragStart(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnDragStart", [[
		return control:RunFor(self, self:GetAttribute("OnDragStart"))
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnDragStart", [[
		return "message", "update";
	]], [[
		return control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
	]])

	button:SetScript("OnReceiveDrag", nil)
	-- Wrapped OnReceiveDrag(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return control:RunFor(self, self:GetAttribute("OnReceiveDrag"), kind, value, ...)
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return "message", "update"
	]], [[
		control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
	]])

	button:SetScript("OnAttributeChanged", function(self, ...)
		button:ButtonContentsChanged(...)
	end)
end

function WrapOnClick(button)
	-- Wrap OnClick, to catch changes to actions that are applied with a click on the button.
	button.header:WrapScript(button, "OnClick", [[
		if self:GetAttribute("type") == "action" then
			local type, action = GetActionInfo(self:GetAttribute("action"))
			return nil, format("%s|%s", tostring(type), tostring(action))
		end
	]], [[
		local type, action = GetActionInfo(self:GetAttribute("action"))
		if message ~= format("%s|%s", tostring(type), tostring(action)) then
			return control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
		end
	]])
end

do
	local reset
	function Generic:ToggleOnDownForPickup(pre)
		if not WoWRetail then return end

		-- this is bugged: some talent spells will always cast on down
		-- even when this code does not execute and keydown is disabled.
		if pre and GetCVarBool("ActionButtonUseKeyDown") then
			SetCVar("ActionButtonUseKeyDown", "0")
			reset = true
		elseif reset then
			SetCVar("ActionButtonUseKeyDown", "1")
			reset = nil
		end
	end
end

-- update click handling ~Simpy
local function UpdateRegisterClicks(self, down)
	self:RegisterForClicks(self.config.clickOnDown and not down and 'AnyDown' or 'AnyUp')
end

-- prevent pickup calling spells ~Simpy
function Generic:OnButtonEvent(event, key, down, spellID)
	if self.config.clickOnDown and GetCVarBool('lockActionBars') then -- non-retail only, retail uses ToggleOnDownForPickup method
		if event == 'MODIFIER_STATE_CHANGED' then
			if GetModifiedClick('PICKUPACTION') == strsub(key, 2) then
				UpdateRegisterClicks(self, down == 1)
			end
		elseif event == 'OnEnter' then
			local action = GetModifiedClick('PICKUPACTION')
			UpdateRegisterClicks(self, action == 'SHIFT' and IsShiftKeyDown() or action == 'ALT' and IsAltKeyDown() or action == 'CTRL' and IsControlKeyDown())
		elseif event == 'OnLeave' then
			UpdateRegisterClicks(self)
		end
	end
end

-----------------------------------------------------------
--- retail range event api ~Simpy

local function WatchRange(button, slot)
	if not lib.buttonsBySlot[slot] then
		lib.buttonsBySlot[slot] = {}
	end

	lib.buttonsBySlot[slot][button] = true
	lib.slotByButton[button] = slot
end

local function ClearRange(button, slot)
	local buttons = lib.buttonsBySlot[slot]
	if buttons then
		buttons[button] = nil

		if not next(buttons) then -- deactivate event for slot (unused)
			lib.buttonsBySlot[slot] = nil
		end
	end
end

local function SetupRange(button, hasTexture)
	if hasTexture and button._state_type == 'action' then
		local action = button._state_action
		if action then
			local slot = lib.slotByButton[button]
			if not slot then -- new action
				WatchRange(button, action)
			elseif slot ~= action then -- changed action
				WatchRange(button, action) -- add new action
				ClearRange(button, slot) -- clear previous action
			end
		end
	else -- remove old action
		local slot = lib.slotByButton[button]
		if slot then
			lib.slotByButton[button] = nil

			ClearRange(button, slot)
		end
	end
end

-----------------------------------------------------------
--- utility

function lib:GetAllButtons()
	local buttons = {}
	for button in next, ButtonRegistry do
		buttons[button] = true
	end
	return buttons
end

function Generic:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

function Generic:NewHeader(header)
	self.header = header
	self:SetParent(header)
	SetupSecureSnippets(self)
	WrapOnClick(self)
end

-----------------------------------------------------------
--- state management

function Generic:ClearStates()
	for state in pairs(self.state_types) do
		self:SetAttribute(format("labtype-%s", state), nil)
		self:SetAttribute(format("labaction-%s", state), nil)
	end
	wipe(self.state_types)
	wipe(self.state_actions)
end

function Generic:SetStateFromHandlerInsecure(state, kind, action)
	state = tostring(state)
	-- we allow a nil kind for setting a empty state
	if not kind then kind = "empty" end
	if not type_meta_map[kind] then
		error("SetStateAction: unknown action type: " .. tostring(kind), 2)
	end
	if kind ~= "empty" and action == nil then
		error("SetStateAction: an action is required for non-empty states", 2)
	end
	if kind ~= "custom" and action ~= nil and type(action) ~= "number" and type(action) ~= "string" or (kind == "custom" and type(action) ~= "table") then
		error("SetStateAction: invalid action data type, only strings and numbers allowed", 2)
	end

	if kind == "item" then
		if tonumber(action) then
			action = format("item:%s", action)
		else
			local itemString = str_match(action, "^|c%x+|H(item[%d:]+)|h%[")
			if itemString then
				action = itemString
			end
		end
	end

	self.state_types[state] = kind
	self.state_actions[state] = action
end

function Generic:SetState(state, kind, action)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)

	self:SetStateFromHandlerInsecure(state, kind, action)
	self:UpdateState(state)
end

function Generic:UpdateState(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	self:SetAttribute(format("labtype-%s", state), self.state_types[state])
	self:SetAttribute(format("labaction-%s", state), self.state_actions[state])
	if state ~= tostring(self:GetAttribute("state")) then return end
	if self.header then
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("UpdateState"), frame:GetAttribute("state"))
		]])
	else
	-- TODO
	end
	self:UpdateAction()
end

function Generic:GetAction(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	return self.state_types[state] or "empty", self.state_actions[state]
end

function Generic:UpdateAllStates()
	for state in pairs(self.state_types) do
		self:UpdateState(state)
	end
end

function Generic:ButtonContentsChanged(state, kind, value)
	state = tostring(state)
	self.state_types[state] = kind or "empty"
	self.state_actions[state] = value
	lib.callbacks:Fire("OnButtonContentsChanged", self, state, self.state_types[state], self.state_actions[state])
	self:UpdateAction(self)
end

function Generic:DisableDragNDrop(flag)
	if InCombatLockdown() then
		error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
	end
	if flag then
		self:SetAttribute("LABdisableDragNDrop", true)
	else
		self:SetAttribute("LABdisableDragNDrop", nil)
	end
end

function Generic:AddToButtonFacade(group)
	if type(group) ~= "table" or type(group.AddButton) ~= "function" then
		error("LibActionButton-1.0:AddToButtonFacade: You need to supply a proper group to use!", 2)
	end
	group:AddButton(self)
	self.LBFSkinned = true
end

function Generic:AddToMasque(group)
	if type(group) ~= "table" or type(group.AddButton) ~= "function" then
		error("LibActionButton-1.0:AddToMasque: You need to supply a proper group to use!", 2)
	end
	group:AddButton(self, nil, "Action")
	self.MasqueSkinned = true
end

function Generic:UpdateAlpha()
	UpdateCooldown(self)
end

-----------------------------------------------------------
--- frame scripts

-- copied (and adjusted) from SecureHandlers.lua
local function PickupAny(kind, target, detail, ...)
	if kind == "clear" then
		ClearCursor()
		kind, target, detail = target, detail, ...
	end

	if kind == 'action' then
		PickupAction(target)
	elseif kind == 'item' then
		PickupItem(target)
	elseif kind == 'macro' then
		PickupMacro(target)
	elseif kind == 'petaction' then
		PickupPetAction(target)
	elseif kind == 'spell' then
		PickupSpell(target)
	elseif kind == 'companion' then
		PickupCompanion(target, detail)
	elseif kind == 'equipmentset' then
		PickupEquipmentSet(target)
	end
end

function Generic:OnEnter()
	if self.config.tooltip ~= "disabled" and (self.config.tooltip ~= "nocombat" or not InCombatLockdown()) then
		UpdateTooltip(self)
	end
	if KeyBound then
		KeyBound:Set(self)
	end

	Generic.OnButtonEvent(self, 'OnEnter')
	self:RegisterEvent('MODIFIER_STATE_CHANGED')
end

function Generic:OnLeave()
	GameTooltip:Hide()

	Generic.OnButtonEvent(self, 'OnLeave')
	self:UnregisterEvent('MODIFIER_STATE_CHANGED')
end

-- Insecure drag handler to allow clicking on the button with an action on the cursor
-- to place it on the button. Like action buttons work.
function Generic:PreClick()
	if self._state_type == "action" or self._state_type == "pet"
	   or InCombatLockdown() or self:GetAttribute("LABdisableDragNDrop")
	then
		return
	end
	-- check if there is actually something on the cursor
	local kind, value, _subtype = GetCursorInfo()
	if not (kind and value) then return end
	self._old_type = self._state_type
	if self._state_type and self._state_type ~= "empty" then
		self._old_type = self._state_type
		self:SetAttribute("type", "empty")
		--self:SetState(nil, "empty", nil)
	end
	self._receiving_drag = true
end

local function formatHelper(input)
	if type(input) == "string" then
		return format("%q", input)
	else
		return tostring(input)
	end
end

function Generic:PostClick()
	UpdateButtonState(self)

	if self._receiving_drag and not InCombatLockdown() then
		if self._old_type then
			self:SetAttribute("type", self._old_type)
			self._old_type = nil
		end
		local oldType, oldAction = self._state_type, self._state_action
		local kind, data, subtype = GetCursorInfo()
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute(format([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("OnReceiveDrag"), %s, %s, %s)
			control:RunFor(frame, frame:GetAttribute("UpdateState"), %s)
		]], formatHelper(kind), formatHelper(data), formatHelper(subtype), formatHelper(self:GetAttribute("state"))))
		PickupAny("clear", oldType, oldAction)
	end
	self._receiving_drag = nil
end

-----------------------------------------------------------
--- configuration

local function merge(target, source, default)
	for k,v in pairs(default) do
		if type(v) ~= "table" then
			if source and source[k] ~= nil then
				target[k] = source[k]
			else
				target[k] = v
			end
		else
			if type(target[k]) ~= "table" then target[k] = {} else wipe(target[k]) end
			merge(target[k], type(source) == "table" and source[k], v)
		end
	end
	return target
end

local function UpdateTextElement(button, element, config, defaultFont, fromRange)
	local rangeIndicator = fromRange and element:GetText() == RANGE_INDICATOR
	if rangeIndicator then
		element:SetShown(button.outOfRange)
		element:SetFont(RangeFont.font.font, RangeFont.font.size, RangeFont.font.flags)
	else
		element:SetFont(config.font.font or defaultFont, config.font.size or 11, config.font.flags or "")
	end

	if fromRange and button.outOfRange then
		element:SetVertexColor(unpack(button.config.colors.range))
	elseif rangeIndicator then
		element:SetVertexColor(unpack(RangeFont.color))
	else
		element:SetVertexColor(unpack(config.color))
	end

	element:ClearAllPoints()
	element:SetPoint(config.position.anchor, element:GetParent(), config.position.relAnchor or config.position.anchor, config.position.offsetX or 0, config.position.offsetY or 0)
	element:SetJustifyH(config.justifyH)
end

local function UpdateTextElements(button)
	UpdateTextElement(button, button.HotKey, button.config.text.hotkey, (NumberFontNormalSmallGray:GetFont()))
	UpdateTextElement(button, button.Count, button.config.text.count, (NumberFontNormal:GetFont()))
	UpdateTextElement(button, button.Name, button.config.text.macro, (GameFontHighlightSmallOutline:GetFont()))
end

function Generic:UpdateConfig(config)
	if config and type(config) ~= "table" then
		error("LibActionButton-1.0: UpdateConfig requires a valid configuration!", 2)
	end

	local oldconfig = self.config
	self.config = {}
	-- merge the two configs
	merge(self.config, config, DefaultConfig)

	if self.config.outOfRangeColoring == "button" or (oldconfig and oldconfig.outOfRangeColoring == "button") then
		UpdateUsable(self)
	end
	if self.config.outOfRangeColoring == "hotkey" then
		self.outOfRange = nil
	end

	if self.config.hideElements.macro then
		self.Name:Hide()
	else
		self.Name:Show()
	end

	self:SetAttribute("flyoutDirection", self.config.flyoutDirection)

	UpdateTextElements(self)
	UpdateHotkeys(self)
	UpdateGrid(self)
	Update(self, 'UpdateConfig')
end

-----------------------------------------------------------
--- event handler

function ForAllButtons(method, onlyWithAction, event)
	assert(type(method) == "function")
	for button in next, (onlyWithAction and ActiveButtons or ButtonRegistry) do
		method(button, event)
	end
end

function InitializeEventHandler()
	lib.eventFrame:SetScript("OnEvent", OnEvent)
	lib.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
	lib.eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_BINDINGS")
	lib.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")
	lib.eventFrame:RegisterEvent("TRADE_CLOSED")
	lib.eventFrame:RegisterEvent("UNIT_AURA")
	lib.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	lib.eventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
	lib.eventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
	lib.eventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	lib.eventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	lib.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	lib.eventFrame:RegisterEvent("COMPANION_UPDATE")
	lib.eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
	lib.eventFrame:RegisterEvent("PET_STABLE_UPDATE")
	lib.eventFrame:RegisterEvent("PET_STABLE_SHOW")

	-- With those two, do we still need the ACTIONBAR equivalents of them?
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function OnEvent(frame, event, arg1, ...)
	if event == "SPELLS_CHANGED" then
		for button in next, ActiveButtons do
			local texture = button:GetTexture()
			if texture then
				button.icon:SetTexture(texture)
			end
		end

		if AURA_COOLDOWNS_ENABLED then
			UpdateAuraCooldowns(event)
		end
	elseif event == "UNIT_MODEL_CHANGED" then
		for button in next, ActiveButtons do
			local texture = button:GetTexture()
			if texture then
				button.icon:SetTexture(texture)
			end
		end

		if AURA_COOLDOWNS_ENABLED then
			UpdateAuraCooldowns(event)
		end
	elseif (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "LEARNED_SPELL_IN_TAB" then
		local tooltipOwner = GameTooltip:GetOwner()
		if ButtonRegistry[tooltipOwner] then
			tooltipOwner:SetTooltip()
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		for button in next, ButtonRegistry do
			if button._state_type == "action" and (arg1 == 0 or arg1 == tonumber(button._state_action)) then
				Update(button, event)
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" then
		ForAllButtons(Update, nil, event)
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		for button in next, ButtonRegistry do
			if button._state_type == "action" and (arg1 == 0 or arg1 == tonumber(button._state_action)) then
				Update(button, event)
			end
		end

		if AURA_COOLDOWNS_ENABLED then
			UpdateAuraCooldowns()
		end
	elseif event == "ACTIONBAR_SHOWGRID" then
		ShowGrid()
	elseif event == "ACTIONBAR_HIDEGRID" then
		HideGrid()
	elseif event == "UPDATE_BINDINGS" then
		ForAllButtons(UpdateHotkeys, nil, event)
	elseif event == "PLAYER_TARGET_CHANGED" then
		if AURA_COOLDOWNS_ENABLED then
			UpdateAuraCooldowns(event)
		end

		for button in next, ActiveButtons do
			UpdateRangeTimer(button)
		end
	elseif event == "UNIT_AURA" then
		if AURA_COOLDOWNS_ENABLED then
			UpdateAuraCooldowns()
		end
	elseif (event == "ACTIONBAR_UPDATE_STATE") or ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player"))
		or ((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) or (event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" or event == "TRADE_CLOSED") then
		ForAllButtons(UpdateButtonState, true, event)
	elseif event == "ACTIONBAR_UPDATE_USABLE" then
		for button in next, ActionButtons do
			UpdateUsable(button)
		end
	elseif event == "SPELL_UPDATE_USABLE" then
		for button in next, NonActionButtons do
			UpdateUsable(button)
		end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		for button in next, ActionButtons do
			UpdateCooldown(button)
			if GameTooltip:GetOwner() == button then
				UpdateTooltip(button)
			end
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		for button in next, NonActionButtons do
			UpdateCooldown(button)
			if GameTooltip:GetOwner() == button then
				UpdateTooltip(button)
			end
		end
	elseif event == "PLAYER_ENTER_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StartFlash(button)
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button:IsAutoRepeat() then
				StartFlash(button)
			end
		end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button.flashing and not button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
		ForAllButtons(Update, nil, event)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		for button in next, ActiveButtons do
			if button._state_type == "item" then
				Update(button, event)
			end
		end
	end
end

function Generic:OnUpdate(elapsed)
	if self.flashing then
		self.flashTime = (self.flashTime or 0) - elapsed

		if self.flashTime <= 0 then
			self.Flash:SetShown(not self.Flash:IsShown())

			self.flashTime = self.flashTime + ATTACK_BUTTON_FLASH_TIME
		end
	end

	self.rangeTimer = (self.rangeTimer or 0) - elapsed

	if self.rangeTimer <= 0 then
		UpdateRange(self) -- Sezz

		self.rangeTimer = TOOLTIP_UPDATE_TIME
	end
end

local gridCounter = 0
function ShowGrid()
	gridCounter = gridCounter + 1
	if gridCounter >= 1 then
		for button in next, ButtonRegistry do
			if button:IsShown() then
				button:SetAlpha(1.0)
			end
		end
	end
end

function HideGrid()
	if gridCounter > 0 then
		gridCounter = gridCounter - 1
	end
	if gridCounter == 0 then
		for button in next, ButtonRegistry do
			if button:IsShown() and not button:HasAction() and not button.config.showGrid then
				button:SetAlpha(0.0)
			end
		end
	end
end

function UpdateGrid(self)
	if self.config.showGrid then
		self:SetAlpha(1.0)
	elseif gridCounter == 0 and self:IsShown() and not self:HasAction() then
		self:SetAlpha(0.0)
	end
end

function UpdateRange(button, force, inRange, checksRange) -- Sezz: moved from OnUpdate
	local oldRange = button.outOfRange
	button.outOfRange = ((inRange == nil or checksRange == nil) and button:IsInRange() == false) or (checksRange and not inRange)

	if force or (oldRange ~= button.outOfRange) then
		if button.config.outOfRangeColoring == "button" then
			UpdateUsable(button)
		elseif button.config.outOfRangeColoring == "hotkey" and not button.config.hideElements.hotkey then
			UpdateTextElement(button, button.HotKey, button.config.text.hotkey, NumberFontNormalSmallGray:GetFont(), true)
		end

		lib.callbacks:Fire("OnUpdateRange", button)
	end
end

-----------------------------------------------------------
--- Active Aura Cooldowns for Target ~ By Simpy

local currentAuras = {}
function UpdateAuraCooldowns(event, disable)
	local filter = disable and "" or UnitIsFriend("player", "target") and "PLAYER|HELPFUL" or "PLAYER|HARMFUL"

	local previousAuras = CopyTable(currentAuras, true)
	wipe(currentAuras)

	local index = 1
	local name, _, _, _, _, duration, expiration = UnitAura("target", index, filter)
	while name do
		local buttons = AuraButtons.auras[name]
		if buttons then
			local start = (duration and duration > 0 and duration <= AURA_COOLDOWNS_DURATION) and (expiration - duration)
			for _, button in next, buttons do
				if start then
					button.AuraCooldown:SetCooldown(start, duration, 1)

					currentAuras[button] = true
					previousAuras[button] = nil
				end
			end
		end

		index = index + 1
		name, _, _, _, _, duration, expiration = UnitAura("target", index, filter)
	end

	for button in next, previousAuras do
		button.AuraCooldown:Clear()
	end
end

function lib:SetAuraCooldownDuration(value)
	AURA_COOLDOWNS_DURATION = value

	UpdateAuraCooldowns('SetAuraCooldownDuration')
end

function lib:SetAuraCooldowns(enabled)
	AURA_COOLDOWNS_ENABLED = enabled

	UpdateAuraCooldowns('SetAuraCooldowns', not enabled)
end

-----------------------------------------------------------
--- KeyBound integration

function Generic:GetBindingAction()
	return self.config.keyBoundTarget or "CLICK "..self:GetName()..":LeftButton"
end

function Generic:GetHotkey()
	local name = ("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton)
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if not key and self.config.keyBoundTarget then
		key = GetBindingKey(name)
	end
	if key then
		return KeyBound and KeyBound:ToShortKey(key) or key
	end
end

local function getKeys(binding, keys)
	keys = keys or ""
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey)
	end
	return keys
end

function Generic:GetBindings()
	local keys

	if self.config.keyBoundTarget then
		keys = getKeys(self.config.keyBoundTarget)
	end

	keys = getKeys(("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton), keys)

	return keys
end

function Generic:SetKey(key)
	if self.config.keyBoundTarget then
		SetBinding(key, self.config.keyBoundTarget)
	else
		SetBindingClick(key, self:GetName(), self.config.keyBoundClickButton)
	end
	lib.callbacks:Fire("OnKeybindingChanged", self, key)
end

local function clearBindings(binding)
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

function Generic:ClearBindings()
	if self.config.keyBoundTarget then
		clearBindings(self.config.keyBoundTarget)
	end
	clearBindings(("CLICK %s:%s"):format(self:GetName(), self.config.keyBoundClickButton))
	lib.callbacks:Fire("OnKeybindingChanged", self, nil)
end

-----------------------------------------------------------
--- button management

function Generic:UpdateAction(force)
	local actionType, action = self:GetAction()
	if force or actionType ~= self._state_type or action ~= self._state_action then
		-- type changed, update the metatable
		if force or self._state_type ~= actionType then
			local meta = type_meta_map[actionType] or type_meta_map.empty
			setmetatable(self, meta)
			self._state_type = actionType
		end

		self._state_action = action

		Update(self, 'UpdateAction')
	end
end

function Update(self, which)
	if self:HasAction() then
		ActiveButtons[self] = true
		if self._state_type == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
		end

		self:SetAlpha(1.0)

		UpdateButtonState(self)
		UpdateUsable(self)
		UpdateCooldown(self)
		UpdateFlash(self)
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil

		if gridCounter == 0 and not self.config.showGrid then
			self:SetAlpha(0.0)
		end

		self.cooldown:Hide()
		self:SetChecked(0)
	end

	-- Add a green border if button is an equipped item
	if self:IsEquipped() and not self.config.hideElements.equipped then
		self.Border:SetVertexColor(0, 1.0, 0, 0.35)
		self.Border:Show()
	else
		self.Border:Hide()
	end

	-- Update Action Text
	if not self:IsConsumableOrStackable() then
		self.Name:SetText(self:GetActionText())
	else
		self.Name:SetText("")
	end

	-- Target Aura ~Simpy
	local previousAbility = AuraButtons.buttons[self]
	if previousAbility then
		AuraButtons.buttons[self] = nil

		local auras = AuraButtons.auras[previousAbility]
		for i, button in next, auras do
			if button == self then
				tremove(auras, i)
				break
			end
		end

		if not next(auras) then
			AuraButtons.auras[previousAbility] = nil
		end
	end

	-- Update icon and hotkey
	local texture = self:GetTexture()
	if texture then
		self:SetScript("OnUpdate", Generic.OnUpdate)
		self.icon:SetTexture(texture)
		self.icon:Show()
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
		if not self.LBFSkinned and not self.MasqueSkinned then
			self.NormalTexture:SetTexCoord(0, 0, 0, 0)
		end
	else
		self:SetScript("OnUpdate", nil)
		self.icon:Hide()
		self.cooldown:Hide()
		self:SetNormalTexture("Interface\\Buttons\\UI-Quickslot")

		if not self.LBFSkinned and not self.MasqueSkinned then
			self.NormalTexture:SetTexCoord(-0.15, 1.15, -0.15, 1.17)
		end
	end

	local isTypeAction = self._state_type == 'action'
	if isTypeAction then
		local actionType, actionID, subType = GetActionInfo(self._state_action)
		local actionSpell, actionMacro, actionFlyout = actionType == 'spell', actionType == 'macro', actionType == 'flyout'
		local macroSpell = actionMacro and ((subType == 'spell' and actionID) or (subType ~= 'spell' and GetMacroSpell(actionID))) or nil
		local spellID = (actionSpell and actionID) or macroSpell
		local spellName = spellID and GetSpellInfo(spellID) or nil

		self.isFlyoutButton = actionFlyout
		self.abilityName = spellName
		self.abilityID = spellID

		AuraButtons.buttons[self] = spellName

		if spellName then
			if not AuraButtons.auras[spellName] then
				AuraButtons.auras[spellName] = {}
			end

			tinsert(AuraButtons.auras[spellName], self)
		end
	else
		self.isFlyoutButton = nil
		self.abilityName = nil
		self.abilityID = nil
	end

	self:UpdateLocal()

	SetupRange(self, texture) -- we can call this on retail or not, only activates events on retail ~Simpy

	UpdateRange(self, which == 'UpdateConfig') -- Sezz: update range check on state change

	UpdateCount(self)

	UpdateButtonState(self)

	UpdateRegisterClicks(self)

	if GameTooltip:GetOwner() == self then
		UpdateTooltip(self)
	end

	-- this could've been a spec change, need to call OnStateChanged for action buttons, if present
	if isTypeAction and not InCombatLockdown() then
		local updateReleaseCasting = which == "PLAYER_ENTERING_WORLD" and self:GetAttribute("UpdateReleaseCasting")
		if updateReleaseCasting then -- zone in dragon mount on Evokers can bug
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("UpdateReleaseCasting"), %s, %s)
			]]):format(formatHelper(self._state_type), formatHelper(self._state_action)))
		end

		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("OnStateChanged"), %s, %s, %s)
			]]):format(formatHelper(self:GetAttribute("state")), formatHelper(self._state_type), formatHelper(self._state_action)))
		end
	end

	lib.callbacks:Fire("OnButtonUpdate", self, which)
end

function Generic:UpdateLocal()
-- dummy function the other button types can override for special updating
end

function UpdateButtonState(self)
	if (self:IsCurrentlyActive() or self:IsAutoRepeat()) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end

	lib.callbacks:Fire("OnButtonState", self)
end

function UpdateUsable(self, isUsable, notEnoughMana)
	-- TODO: make the colors configurable
	-- TODO: allow disabling of the whole recoloring
	if self.config.outOfRangeColoring == "button" and self.outOfRange then
		self.icon:SetVertexColor(unpack(self.config.colors.range))
	else
		if isUsable == nil or notEnoughMana == nil then
			isUsable, notEnoughMana = self:IsUsable()
		end

		if isUsable then
			self.icon:SetVertexColor(unpack(self.config.colors.usable))
		elseif notEnoughMana then
			self.icon:SetVertexColor(unpack(self.config.colors.mana))
		else
			self.icon:SetVertexColor(unpack(self.config.colors.notUsable))
		end
	end

	lib.callbacks:Fire("OnButtonUsable", self)
end

function UpdateCount(self)
	if not self:HasAction() then
		self.Count:SetText("")
		return
	end

	if self:IsConsumableOrStackable() then
		local count = self:GetCount()
		if count > (self.maxDisplayCount or 9999) then
			self.Count:SetText("*")
		else
			self.Count:SetText(count)
		end
	else
		self.Count:SetText("")
	end
end

function UpdateCooldown(self)
	local start, duration, enable = self:GetCooldown()
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)

	lib.callbacks:Fire("OnCooldownUpdate", self, start, duration, enable)
end

function UpdateRangeTimer(self)
	self.rangeTimer = -1
end

function StartFlash(self)
	local prevFlash = self.flashing

	self.flashing = true

	if prevFlash ~= self.flashing then
		UpdateButtonState(self)
	end
end

function StopFlash(self)
	local prevFlash = self.flashing

	self.flashing = false
	self.flashTime = nil

	if self.Flash:IsShown() then
		self.Flash:Hide()
	end

	if prevFlash ~= self.flashing then
		UpdateButtonState(self)
	end
end

function UpdateFlash(self)
	if (self:IsAttack() and self:IsCurrentlyActive()) or self:IsAutoRepeat() then
		StartFlash(self)
	else
		StopFlash(self)
	end
end

function UpdateTooltip(self)
	if (GetCVar("UberTooltips") == "1") then
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	if self:SetTooltip() then
		self.UpdateTooltip = UpdateTooltip
	else
		self.UpdateTooltip = nil
	end
end

function UpdateHotkeys(self)
	local key = self:GetHotkey()
	if not key or key == "" or self.config.hideElements.hotkey then
		self.HotKey:SetText(RANGE_INDICATOR)
		self.HotKey:SetPoint("TOPRIGHT", 0, -3);
		self.HotKey:Hide()
	else
		self.HotKey:SetText(key)
		self.HotKey:SetPoint("TOPRIGHT", 0, -3);
		self.HotKey:Show()
	end

	if self.postKeybind then
		self.postKeybind(nil, self)
	end
end

-----------------------------------------------------------
--- WoW API mapping
--- Generic Button
Generic.HasAction               = function(self) return nil end
Generic.GetActionText           = function(self) return "" end
Generic.GetTexture              = function(self) return nil end
Generic.GetCount                = function(self) return 0 end
Generic.GetCooldown             = function(self) return 0, 0, 0 end
Generic.IsAttack                = function(self) return nil end
Generic.IsEquipped              = function(self) return nil end
Generic.IsCurrentlyActive       = function(self) return nil end
Generic.IsAutoRepeat            = function(self) return nil end
Generic.IsUsable                = function(self) return nil end
Generic.IsConsumableOrStackable = function(self) return nil end
Generic.IsUnitInRange           = function(self, unit) return nil end
Generic.IsInRange               = function(self)
	local unit = self:GetAttribute("unit")
	if unit == "player" then
		unit = nil
	end

	local val = self:IsUnitInRange(unit)
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	return val
end
Generic.SetTooltip              = function(self) return nil end
Generic.GetSpellId              = function(self) return nil end
-----------------------------------------------------------
--- Action Button
Action.HasAction               = function(self) return HasAction(self._state_action) end
Action.GetActionText           = function(self) return GetActionText(self._state_action) end
Action.GetTexture              = function(self) return GetActionTexture(self._state_action) end
Action.GetCount                = function(self) return GetActionCount(self._state_action) end
Action.GetCooldown             = function(self) return GetActionCooldown(self._state_action) end
Action.IsAttack                = function(self) return IsAttackAction(self._state_action) end
Action.IsEquipped              = function(self) return IsEquippedAction(self._state_action) end
Action.IsCurrentlyActive       = function(self) return IsCurrentAction(self._state_action) end
Action.IsAutoRepeat            = function(self) return IsAutoRepeatAction(self._state_action) end
Action.IsUsable                = function(self) return IsUsableAction(self._state_action) end
Action.IsConsumableOrStackable = function(self) return IsConsumableAction(self._state_action) or IsStackableAction(self._state_action) end
Action.IsUnitInRange           = function(self, unit) return IsActionInRange(self._state_action, unit) end
Action.SetTooltip              = function(self) return GameTooltip:SetAction(self._state_action) end
Action.GetSpellId              = function(self)
	if self._state_type == "action" then
		local actionType, id, subType = GetActionInfo(self._state_action)
		if actionType == "spell" then
			return id
		elseif actionType == "macro" then
			if subType == "spell" then
				return id
			else
				return (GetMacroSpell(id))
			end
		end
	end
end

-----------------------------------------------------------
--- Spell Button
Spell.HasAction               = function(self) return true end
Spell.GetActionText           = function(self) return "" end
Spell.GetTexture              = function(self) return GetSpellTexture(self._state_action) end
Spell.GetCount                = function(self) return GetSpellCount(self._state_action) end
Spell.GetCooldown             = function(self) return GetSpellCooldown(self._state_action) end
Spell.IsAttack                = function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsEquipped              = function(self) return nil end
Spell.IsCurrentlyActive       = function(self) return IsCurrentSpell(self._state_action) end
Spell.IsAutoRepeat            = function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsUsable                = function(self) return IsUsableSpell(self._state_action) end
Spell.IsConsumableOrStackable = function(self) return IsConsumableSpell(self._state_action) end
Spell.IsUnitInRange           = function(self, unit) return IsSpellInRange(FindSpellBookSlotBySpellID(self._state_action), "spell", unit) end -- needs spell book id as of 4.0.1.13066
Spell.SetTooltip              = function(self) return GameTooltip:SetSpellByID(self._state_action) end
Spell.GetSpellId              = function(self) return self._state_action end

-----------------------------------------------------------
--- Item Button
local function getItemId(input)
	return input:match("^item:(%d+)")
end

Item.HasAction               = function(self) return true end
Item.GetActionText           = function(self) return "" end
Item.GetTexture              = function(self) return GetItemIcon(self._state_action) end
Item.GetCount                = function(self) return GetItemCount(self._state_action, nil, true) end
Item.GetCooldown             = function(self) return GetItemCooldown(getItemId(self._state_action)) end
Item.IsAttack                = function(self) return nil end
Item.IsEquipped              = function(self) return IsEquippedItem(self._state_action) end
Item.IsCurrentlyActive       = function(self) return IsCurrentItem(self._state_action) end
Item.IsAutoRepeat            = function(self) return nil end
Item.IsUsable                = function(self) return IsUsableItem(self._state_action) end
Item.IsConsumableOrStackable = function(self) return IsConsumableItem(self._state_action) end
Item.IsUnitInRange           = function(self, unit) return IsItemInRange(self._state_action, unit) end
Item.SetTooltip              = function(self) return GameTooltip:SetHyperlink(self._state_action) end
Item.GetSpellId              = function(self) return nil end

-----------------------------------------------------------
--- Macro Button
-- TODO: map results of GetMacroSpell/GetMacroItem to proper results
Macro.HasAction               = function(self) return true end
Macro.GetActionText           = function(self) return (GetMacroInfo(self._state_action)) end
Macro.GetTexture              = function(self) return (select(2, GetMacroInfo(self._state_action))) end
Macro.GetCount                = function(self) return 0 end
Macro.GetCooldown             = function(self) return 0, 0, 0 end
Macro.IsAttack                = function(self) return nil end
Macro.IsEquipped              = function(self) return nil end
Macro.IsCurrentlyActive       = function(self) return nil end
Macro.IsAutoRepeat            = function(self) return nil end
Macro.IsUsable                = function(self) return nil end
Macro.IsConsumableOrStackable = function(self) return nil end
Macro.IsUnitInRange           = function(self, unit) return nil end
Macro.SetTooltip              = function(self) return nil end
Macro.GetSpellId              = function(self) return nil end

-----------------------------------------------------------
--- Custom Button
Custom.HasAction               = function(self) return true end
Custom.GetActionText           = function(self) return "" end
Custom.GetTexture              = function(self) return self._state_action.texture end
Custom.GetCount                = function(self) return 0 end
Custom.GetCooldown             = function(self) return 0, 0, 0 end
Custom.IsAttack                = function(self) return nil end
Custom.IsEquipped              = function(self) return nil end
Custom.IsCurrentlyActive       = function(self) return nil end
Custom.IsAutoRepeat            = function(self) return nil end
Custom.IsUsable                = function(self) return true end
Custom.IsConsumableOrStackable = function(self) return nil end
Custom.IsUnitInRange           = function(self, unit) return nil end
Custom.SetTooltip              = function(self) return GameTooltip:SetText(self._state_action.tooltip) end
Custom.GetSpellId              = function(self) return nil end
Custom.RunCustom               = function(self, unit, button) return self._state_action.func(self, unit, button) end

-----------------------------------------------------------
--- Update old Buttons
if oldversion and next(lib.buttonRegistry) then
	InitializeEventHandler()
	for button in next, lib.buttonRegistry do
		-- this refreshes the metatable on the button
		Generic.UpdateAction(button, true)
		SetupSecureSnippets(button)
		if oldversion < 12 then
			WrapOnClick(button)
		end
	end
end
