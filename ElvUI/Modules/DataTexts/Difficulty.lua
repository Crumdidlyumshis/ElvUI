local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local _G = _G
local format = format

local GetDungeonDifficulty = GetDungeonDifficulty
local GetRaidDifficulty = GetRaidDifficulty
local SetDungeonDifficulty = SetDungeonDifficulty
local SetRaidDifficulty = SetRaidDifficulty
local GetInstanceInfo = GetInstanceInfo
local ResetInstances = ResetInstances
local EasyMenu = EasyMenu

local heroicTex = [[|Tinterface\lfgframe\ui-lfg-icon-heroic:20:20:0:0:64:64:0:36:0:36|t]]
local dungTex = [[|Tinterface\icons\spell_arcane_teleportstormwind:20:20:0:0:64:64:4:60:4:60|t]]
local raidTex = [[|Tinterface\icons\spell_arcane_teleportshattrath:20:20:0:0:64:64:4:60:4:60|t]]

local RightClickMenu = {
    { text = _G.DUNGEON_DIFFICULTY, isTitle = true, notCheckable = true },
    { text = _G.DUNGEON_DIFFICULTY1, checked = function() return GetDungeonDifficulty() == 1 end, func = function() SetDungeonDifficulty(1);  end },
    { text = _G.DUNGEON_DIFFICULTY2, checked = function() return GetDungeonDifficulty() == 2 end, func = function() SetDungeonDifficulty(2);  end },
    { text = '', isTitle = true, notCheckable = true },
    { text = _G.RAID_DIFFICULTY, isTitle = true, notCheckable = true},
    { text = _G.RAID_DIFFICULTY1, checked = function() return GetRaidDifficulty() == 1 end, func = function() SetRaidDifficulty(1);  end },
    { text = _G.RAID_DIFFICULTY2, checked = function() return GetRaidDifficulty() == 2 end, func = function() SetRaidDifficulty(2);  end },
    { text = _G.RAID_DIFFICULTY3, checked = function() return GetRaidDifficulty() == 3 end, func = function() SetRaidDifficulty(3);  end },
    { text = _G.RAID_DIFFICULTY4, checked = function() return GetRaidDifficulty() == 4 end, func = function() SetRaidDifficulty(4);  end },
    { text = '', isTitle = true, notCheckable = true },
    { text = _G.RESET_INSTANCES, notCheckable = true, func = function() ResetInstances();  end},
}

local DiffDungLabel, DiffRaidLabel = {
    [1] = _G.DUNGEON_DIFFICULTY1,
    [2] = _G.DUNGEON_DIFFICULTY2,
}, {
    [1] = _G.RAID_DIFFICULTY1,
    [2] = _G.RAID_DIFFICULTY2,
	[3] = _G.RAID_DIFFICULTY3,
	[4] = _G.RAID_DIFFICULTY4,
}

local function GetDiffDungInfo(difficultyID)
    local heroicD = (GetDungeonDifficulty() > 1) and heroicTex or ''
    local label = format('%s %s', DiffDungLabel[difficultyID]:gsub('%s*%([^%)]*%)', ''), heroicD)

    return label
end

local function GetDiffRaidInfo(difficultyID)
    local heroicR = (GetRaidDifficulty() > 2) and heroicTex or ''
    local label = format('%s %s', DiffRaidLabel[difficultyID]:gsub('%s*%([^%)]*%)', ''), heroicR)

    return label
end

local function OnEvent(self)
    local name, instanceType = GetInstanceInfo()

    if instanceType == 'none' then
        self.text:SetFormattedText('%s %s %s %s', dungTex, GetDiffDungInfo(GetDungeonDifficulty()), raidTex, GetDiffRaidInfo(GetRaidDifficulty()))
    else
        self.text:SetFormattedText('%s: %s', name, (instanceType == 'raid') and GetDiffRaidInfo(GetRaidDifficulty()) or GetDiffDungInfo(GetDungeonDifficulty()))
    end
end

local function OnClick(self)
    E:SetEasyMenuAnchor(E.EasyMenu, self)
	EasyMenu(RightClickMenu, E.EasyMenu, nil, nil, nil, 'MENU')
end

local function OnEnter()
    DT.tooltip:ClearLines()

    DT.tooltip:AddLine(L['Current Difficulty'])
    DT.tooltip:AddLine(' ')
    DT.tooltip:AddDoubleLine(_G.DUNGEON_DIFFICULTY, GetDiffDungInfo(GetDungeonDifficulty()), 1, 1, 1)
    DT.tooltip:AddDoubleLine(_G.RAID_DIFFICULTY, GetDiffRaidInfo(GetRaidDifficulty()), 1, 1, 1)

    DT.tooltip:Show()
end

DT:RegisterDatatext('Difficulty', nil, {'CHAT_MSG_SYSTEM'}, OnEvent, nil, OnClick, OnEnter, nil, 'Difficulty')