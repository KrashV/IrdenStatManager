require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")
require "/scripts/messageutil.lua"

function init()
  self.fightName = player.getProperty("irdenfightName")

  message.setHandler("leaveFight", function(_, isLocal)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "nextTurn", player.id(), true, player.isAdmin())
    quest.complete()
  end)

  message.setHandler("nextTurn", function(_, isLocal, pUUID)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "nextTurn", player.id(), false, player.isAdmin())
  end)

  message.setHandler("clearFight", function(_, isLocal)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName or "", "destroy")

    world.setProperty("currentFight", nil)
    world.setProperty("currentFights_v2", nil)
    quest.complete()
  end)

  setPortraits()
end

function questStart()
  promises:add(world.findUniqueEntity("irdenfighthandler_" .. self.fightName), function(pos)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "addPlayerToFight", player.id(), player.getProperty("irdeninitiative", math.random(20)))
  end, function(error)
    local stagehandId = world.spawnStagehand(world.entityPosition(player.id()), "irdenhandler", 
      {name = self.fightName, author = player.id(), initiative = player.getProperty("irdeninitiative", math.random(20)) })
  end)
end

function questComplete()

end

function update(dt)
  promises:update()
  populateList()
end

function uninit()

end


function populateList()
    promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), function(currentFight)
      local currentPlayerName = "Неизвестно"
      if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] then currentPlayerName = currentFight.players[currentFight.currentPlayer].name end

      local objectiveList = not next(currentFight.players) and {{"Перезайдите в бой!", false}} or {
        {"^yellow;" .. currentFight.round .. "^reset;: Ход игрока ^orange;".. currentPlayerName .. "^reset;", false}
      }

      for _, fighter in ipairs(sortedKeys(currentFight.players)) do 
        quest.setParameter(fighter.uniqueId, fighter)
        table.insert(objectiveList, {string.format("%2s: %s", fighter.initiative, fighter.name), fighter.done})
      end
      quest.setObjectiveList(objectiveList)

      if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] and player.getProperty("toShowCurrentPlayerIndicator", true) then
        quest.setIndicators({currentFight.currentPlayer})
      else
        quest.setIndicators({})
      end
    end)
end


function sortedKeys(query)
  local keys = {}
  for k,v in pairs(query) do
    table.insert(keys, v)
  end

  table.sort(keys, function(a, b) 
    if a.initiative ~= b.initiative then return a.initiative > b.initiative 
      else return a.uniqueId  > b.uniqueId 
    end
  end)
  return keys
end