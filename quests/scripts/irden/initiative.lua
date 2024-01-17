require("/quests/scripts/portraits.lua")
require("/quests/scripts/questutil.lua")
require "/scripts/messageutil.lua"

function init()
  self.questParams = quest.questDescriptor()["parameters"]["fight"]["data"]
  self.fightName = self.questParams["fightName"]

  message.setHandler("leaveFight", function(_, isLocal)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "nextTurn", player.id(), true)
    quest.complete()
  end)
  
  message.setHandler("ism_kicked_from_fight", function(_, isLocal, fightName)
    if self.fightName == fightName then
      player.setProperty("irdenfightName", nil)
      quest.complete()
    end
  end)

  message.setHandler("nextTurn", function(_, isLocal, pUUID)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "nextTurn", player.id(), false)
  end)

  --setPortraits()
  startUpdatingFights()
end

function questStart()
  promises:add(world.findUniqueEntity("irdenfighthandler_" .. self.fightName), function(pos)
    world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "addPlayerToFight", player.id(), self.questParams["initiative"], self.questParams["asEnemy"])
  end, function(error)
    local stagehandId = world.spawnStagehand(world.entityPosition(player.id()), "irdenhandler", 
      {name = self.fightName, author = player.id(), initiative = self.questParams["initiative"] })
  end)
end

function questComplete()

end

function update(dt)
  promises:update()
end

function uninit()

end

function addPromise()
  promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), updateFightSituation, addPromise)
end

function startUpdatingFights()
  function updateFightSituation(currentFight)
    local currentPlayerName = "Неизвестно"
    if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] then currentPlayerName = currentFight.players[currentFight.currentPlayer].name end

    local objectiveList = not next(currentFight.players) and {{"Перезайдите в бой!", false}} or {
      {currentFight.name .. "(^yellow;" .. currentFight.round .. "^reset;): Ход ^orange;".. currentPlayerName .. "^reset;", false}
    }

    for _, fighter in ipairs(sortedKeys(currentFight.players)) do 
      quest.setParameter(fighter.uniqueId, fighter)
      table.insert(objectiveList, {string.format("%2s: %s%s^reset;", fighter.initiative, fighter.name == world.entityName(player.id()) and "^yellow;" or (fighter.asEnemy and "^red;" or ""), fighter.name), fighter.done})
    end
    quest.setObjectiveList(objectiveList)

    if currentFight.currentPlayer and currentFight.players[currentFight.currentPlayer] and player.getProperty("toShowCurrentPlayerIndicator", true) then
      quest.setIndicators({currentFight.currentPlayer})
    else
      quest.setIndicators({})
    end
    promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), updateFightSituation, addPromise)
  end


  promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.fightName, "getFight"), updateFightSituation, addPromise)
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