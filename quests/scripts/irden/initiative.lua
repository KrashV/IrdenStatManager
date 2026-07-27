require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")
require "/scripts/messageutil.lua"

local ENTITY_COLOR = {
    ["PLAYER"] = "^white;%s^reset;",
    ["MONSTER"] = "^red;%s^reset;",
    ["SPECTATOR"] = "^cyan;%s^reset;"
}

function init()
    self.questParams = quest.questDescriptor()["parameters"]["fight"]["data"]
    self.fightName = self.questParams["fightName"]
    self.snapshotVersion = nil

    message.setHandler("irden:fight:leave", handleLeaveFight)

    message.setHandler("irden:fight:turn:next", simpleHandler(function()
        handleNextTurn()
    end))

    message.setHandler("irden:fight:update", simpleHandler(ensureFight))

    fightBlank()
end


---@class FightData
---@field authorUuid string
---@field fightName string
---@field queue table<string> - uuids in list (keys already sorted by initiative)
---@field playersInFight table<string, FightData.PlayersInFight>
---@field turn number - current turn number
---@field currentPlayerUuidTurn string
---@field snapshotVersion string -- для слабых компуктеров чтоб не пересчитывать всё по новой

---@class FightData.PlayersInFight
---@field name string - player name
---@field uuid string - player uuid
---@field entityType string - one of PLAYER, MONSTER, SPECTATOR
---@field initiative number - initiative, sorting by this

function fightBlank()
    quest.setIndicators({})
    quest.setObjectiveList(
            {
                {
                    ("Бой: ^yellow;%s^reset;"):format(self.fightName), false
                },
                {
                    "Ожидайте обновления боя", false
                }
            }
    )

end

---@param data FightData
function ensureFight(data)
    local playersInFight = data.playersInFight
    if self.snapshotVersion == data.snapshotVersion then
        return
    else
        self.snapshotVersion = data.snapshotVersion
    end
    quest.setParameter("currentTurnUuid", { type = "entity", uniqueId = data.currentPlayerUuidTurn })
    quest.setIndicators({ "currentTurnUuid" })

    local objectiveList = {
        {
            ("^white;Бой:^reset; ^yellow;%s^reset;"):format(self.fightName), true
        },
        {
            ("^white;Текущий ход:^reset; ^green;%s^reset;"):format(data.turn), true
        },
        {
            ("^white;Ход:^reset; %s"):format(
                    colorPlayerNameByEntityType(playersInFight[data.currentPlayerUuidTurn].name,
                            playersInFight[data.currentPlayerUuidTurn].entityType)
            ), true
        },
        {
            "^white;Очередь:^reset;", true
        }
    }
    local queueState = true
    local currentPlayerTurnNumber = 0
    for i, uuid in ipairs(data.queue) do
        local p = playersInFight[uuid]
        queueState = uuid ~= data.currentPlayerUuidTurn
        if currentPlayerTurnNumber == 0 then
            -- Нашли текущего, помечаем как false
            currentPlayerTurnNumber = queueState and 0 or i
        else
            queueState = false
        end

        table.insert(objectiveList,
                {
                    ("%s  %s (%s)"):format(currentPlayerTurnNumber == i and "^yellow;>^reset;" or "", p.name, p.initiative), queueState
                })
    end
    quest.setObjectiveList(objectiveList)

    local progressMod = 1 / #data.queue
    local currentProgress = 1 - (currentPlayerTurnNumber * progressMod)
    quest.setProgress(currentProgress)
end

function colorPlayerNameByEntityType(name, entityType)
    local code = ENTITY_COLOR[entityType]
    return code:format(name)
end

function update(dt)
    promises:update()
end

function handleNextTurn()
    promises:add(world.sendEntityMessage("server", "irden:fight:turn:next", self.fightName),
            function(message)
                interface.queueMessage(message)
            end, function(error)
                interface.queueMessage(error)
                quest.complete()
            end
    )
end
function handleLeaveFight(_, isLocal)
    if (isLocal) then
        promises:add(world.sendEntityMessage("server", "irden:fight:leave", self.fightName),
                function(result)
                    interface.queueMessage(result)
                    quest.complete()
                end,
                function(error)
                    interface.queueMessage(error)
                    quest.complete()
                end
        )
    end
end


--function addPromise()
--    promises:add(world.sendEntityMessage("server", "irden:fight:get", self.fightName), updateFightSituation, addPromise)
--end
--
--function startUpdatingFights()
--    function updateFightSituation(currentFight)
--        local currentPlayerName = "Неизвестно"
--        if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] then
--            currentPlayerName = currentFight.players[currentFight.currentPlayer].name
--        end
--
--        local objectiveList = not next(currentFight.players) and { { "Перезайдите в бой!", false } } or {
--            { currentFight.name .. "(^yellow;" .. currentFight.round .. "^reset;): Ход ^orange;" .. currentPlayerName .. "^reset;", false }
--        }
--
--        for _, fighter in ipairs(sortedKeys(currentFight.players)) do
--            quest.setParameter(fighter.uniqueId, fighter)
--            table.insert(objectiveList, { string.format("%2s: %s%s^reset;", fighter.initiative, fighter.name == world.entityName(player.id()) and "^yellow;" or (fighter.asEnemy and "^red;" or ""), fighter.name), fighter.done })
--        end
--        quest.setObjectiveList(objectiveList)
--
--        if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] and player.getProperty("toShowCurrentPlayerIndicator", true) then
--            quest.setIndicators({ currentFight.currentPlayer })
--        else
--            quest.setIndicators({})
--        end
--        promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), updateFightSituation, addPromise)
--    end
--
--    promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), updateFightSituation, addPromise)
--end
--
--function sortedKeys(query)
--    local keys = {}
--    for k, v in pairs(query) do
--        table.insert(keys, v)
--    end
--
--    table.sort(keys, function(a, b)
--        if a.initiative ~= b.initiative then
--            return a.initiative > b.initiative
--        else
--            return a.uniqueId > b.uniqueId
--        end
--    end)
--    return keys
--end