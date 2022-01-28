require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")

function init()
  self.emptyFight = {
    players = {},
    started = false,
    currentPlayer = nil,
    done = false
  }

  self.fightName = player.getProperty("irdenfightName")

  message.setHandler("leaveFight", function(_, isLocal)
    nextTurn(player.uniqueId(), true)
    quest.complete()
  end)

  message.setHandler("nextTurn", function(_, isLocal, pUUID)
    nextTurn(pUUID)
  end)

  message.setHandler("clearFight", function(_, isLocal)

    world.setProperty("currentFight", nil)
    quest.complete()
  end)

  setPortraits()
end

function questStart()
  local fights = world.getProperty("currentFight") or {}
  local currentFight = fights[self.fightName] or self.emptyFight
  
  if currentFight and not currentFight.players[player.uniqueId()] then
    currentFight.players[player.uniqueId()] = {
      type = "entity",
      uniqueId = player.uniqueId(),
      name = world.entityName(player.id()),
      initiative = player.getProperty("irdeninitiative", math.random(20)),
      done = false
    }

    local sortedPlayers = sortedKeys(currentFight.players)

    if sortedPlayers[1].uniqueId == player.uniqueId() and not currentFight.started then
      currentFight.currentPlayer = player.uniqueId()
    end

    fights[self.fightName] = currentFight
    world.setProperty("currentFight", fights)
  end
end

function questComplete()

end

function update(dt)
  populateList()
end

function uninit()

end

function nextTurn(pUUID, toLeave)
  local fights = world.getProperty("currentFight") or {}
  local currentFight = fights[self.fightName] or self.emptyFight

  if currentFight.currentPlayer == pUUID then

    -- in case we actually moved our turn, the battle starts
    if not toLeave then currentFight.started = true end


    currentFight.players[pUUID].done = true
    local sortedCurrentFight = sortedKeys(currentFight.players)

    for ind, fighter in ipairs(sortedCurrentFight) do
      if fighter.uniqueId == pUUID then
        local newInd = ind % #sortedCurrentFight + 1
        currentFight.currentPlayer = sortedCurrentFight[newInd].uniqueId

        -- drop done flags for players
        if newInd == 1 then
          for _, fighter in ipairs(sortedCurrentFight) do
            fighter.done = false
          end
        end
        break
      end
    end
  end

  if toLeave then
    currentFight.players[pUUID] = nil
  end

  fights[self.fightName] = currentFight
  world.setProperty("currentFight", fights)
end

function populateList()
    local fights = world.getProperty("currentFight") or {}
    local currentFight = fights[self.fightName] or self.emptyFight

    local currentPlayerName = "Неизвестно"
    if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] then currentPlayerName = currentFight.players[currentFight.currentPlayer].name end

    local objectiveList = not next(currentFight.players) and {{"Тут никого!", false}} or {
      {"Ход игрока ".. currentPlayerName, false}
    }

    for _, fighter in ipairs(sortedKeys(currentFight.players)) do 
      quest.setParameter(fighter.uniqueId, fighter)
      table.insert(objectiveList, {string.format("%2s: %s", fighter.initiative, fighter.name), fighter.done})
    end
    quest.setObjectiveList(objectiveList)

    if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] then
      quest.setIndicators({currentFight.currentPlayer})
    end
end


function sortedKeys(query)
  local keys = {}
  for k,v in pairs(query) do
    table.insert(keys, v)
  end

  table.sort(keys, function(a, b) return a.initiative > b.initiative end)
  return keys
end