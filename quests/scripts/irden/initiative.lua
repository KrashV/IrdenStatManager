require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/messageutil.lua"

local SERVER_ENTITY = "server"
local CURRENT_TURN_PARAMETER = "currentTurnUuid"

local MESSAGE = {
    CHECK = "irden:fight:check",
    LEAVE = "irden:fight:leave",
    NEXT_TURN = "irden:fight:turn:next",
    UPDATE = "irden:fight:update"
}

local ENTITY_COLOR = {
    PLAYER = "^white;%s^reset;",
    MONSTER = "^red;%s^reset;",
    SPECTATOR = "^cyan;%s^reset;"
}

---@class FightData
---@field authorUuid string
---@field fightName string
---@field queue string[] UUID в порядке инициативы
---@field playersInFight table<string, PlayerInFight>
---@field turn number Номер текущего хода
---@field currentPlayerUuidTurn string
---@field snapshotVersion string Версия снапшота для слабых куомпуктеров

---@class PlayerInFight
---@field name string
---@field uuid string
---@field entityType "PLAYER"|"MONSTER"|"SPECTATOR"
---@field initiative number

local function queueMessage(message)
    if message ~= nil and message ~= "" then
        interface.queueMessage(tostring(message))
    end
end

local function completeQuest(message)
    queueMessage(message)
    quest.complete()
end

local function sendFightMessage(messageName, onSuccess, onError)
    promises:add(
            world.sendEntityMessage(SERVER_ENTITY, messageName, self.fightName),
            onSuccess,
            onError
    )
end

local function colorPlayerName(playerInFight)
    local colorTemplate = ENTITY_COLOR[playerInFight and playerInFight.entityType] or ENTITY_COLOR.PLAYER
    local name = playerInFight and playerInFight.name or "Неизвестно"
    return colorTemplate:format(name)
end

local function findCurrentPlayerIndex(queue, currentPlayerUuid)
    if not currentPlayerUuid then
        return nil
    end

    for index, uuid in ipairs(queue) do
        if uuid == currentPlayerUuid then
            return index
        end
    end

    return nil
end

local function createObjectiveList(data, queue, playersInFight, currentPlayerIndex)
    local currentPlayer = playersInFight[data.currentPlayerUuidTurn]

    local objectiveList = {
        {
            ("^white;Бой:^reset; ^yellow;%s^reset;"):format(self.fightName),
            true
        },
        {
            ("^white;Текущий ход:^reset; ^green;%s^reset;"):format(data.turn or "Неизвестно"),
            true
        },
        {
            ("^white;Ход:^reset; %s"):format(colorPlayerName(currentPlayer)),
            true
        },
        {
            "^white;Очередь:^reset;",
            true
        }
    }

    for index, uuid in ipairs(queue) do
        local fighter = playersInFight[uuid]

        if fighter then
            local marker = index == currentPlayerIndex and "^yellow;>^reset;" or ""
            local completed = currentPlayerIndex ~= nil and index < currentPlayerIndex

            table.insert(objectiveList, {
                ("%s  %s (%s)"):format(
                        marker,
                        colorPlayerName(fighter),
                        fighter.initiative or 0
                ),
                completed
            })
        end
    end

    return objectiveList
end

local function updateProgress(queueSize, currentPlayerIndex)
    if queueSize == 0 or currentPlayerIndex == nil then
        quest.setProgress(0)
        return
    end

    quest.setProgress(1 - currentPlayerIndex / queueSize)
end

local function showWaitingState()
    quest.setIndicators({})
    quest.setObjectiveList({
        {
            ("Бой: ^yellow;%s^reset;\n- Ожидайте обновления боя"):format(self.fightName),
            false
        }
    })
end

local function checkFightExists()
    sendFightMessage(
            MESSAGE.CHECK,
            function(exists)
                if not exists then
                    quest.complete()
                end
            end,
            completeQuest
    )
end

---@param data FightData
local function ensureFight(data)
    if not data or self.snapshotVersion == data.snapshotVersion then
        return
    end

    local queue = data.queue or {}
    local playersInFight = data.playersInFight or {}
    local currentPlayerUuid = data.currentPlayerUuidTurn
    local currentPlayer = currentPlayerUuid and playersInFight[currentPlayerUuid] or nil
    local currentPlayerIndex = findCurrentPlayerIndex(queue, currentPlayerUuid)

    self.snapshotVersion = data.snapshotVersion

    if currentPlayer then
        quest.setParameter(CURRENT_TURN_PARAMETER, {
            type = "entity",
            uniqueId = currentPlayerUuid
        })
        quest.setIndicators({ CURRENT_TURN_PARAMETER })
    else
        quest.setIndicators({})
    end

    quest.setObjectiveList(
            createObjectiveList(data, queue, playersInFight, currentPlayerIndex)
    )
    updateProgress(#queue, currentPlayerIndex)
end

local function handleNextTurn()
    sendFightMessage(
            MESSAGE.NEXT_TURN,
            queueMessage,
            completeQuest
    )
end

local function handleLeaveFight(_, isLocal, message)
    if not isLocal then
        completeQuest(message)
        return
    end

    sendFightMessage(
            MESSAGE.LEAVE,
            completeQuest,
            completeQuest
    )
end

function init()
    local fightParameter = quest.questDescriptor().parameters.fight

    self.fightName = fightParameter.data.fightName
    player.setProperty("irdenfightName", self.fightName)
    self.snapshotVersion = nil

    message.setHandler(MESSAGE.LEAVE, handleLeaveFight)
    message.setHandler(MESSAGE.NEXT_TURN, simpleHandler(handleNextTurn))
    message.setHandler(MESSAGE.UPDATE, simpleHandler(ensureFight))

    showWaitingState()
    checkFightExists()
end

function update()
    promises:update()
end
