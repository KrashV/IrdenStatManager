require "/scripts/messageutil.lua"

function init()
  local fightName = config.getParameter("name")
  local fights = world.getProperty("currentFights_v2") or {}

  self.fight = fights[fightName] or {
    name = fightName,
    players = {},
    started = false,
    currentPlayer = nil,
    done = false,
    round = 1
  }

  local author = config.getParameter("author")
  if author and world.entityExists(author) then
    addPlayerToFight(author, config.getParameter("initiative") or 0)
  end

  stagehand.setUniqueId("irdenfighthandler_" .. fightName)

  message.setHandler("addPlayerToFight", simpleHandler(addPlayerToFight))

  message.setHandler("nextTurn", simpleHandler(nextPlayer))

  message.setHandler("getFight", function() return self.fight end)

  message.setHandler("destroy", function() stagehand.die() end)
end



function addPlayerToFight(playerId, initiative, asEnemy)

  local playerUUID = world.entityUniqueId(playerId)

  if not self.fight.players[playerUUID] then
    self.fight.players[playerUUID] = {
      type = "entity",
      uniqueId = playerUUID,
      name = world.entityName(playerId),
      initiative = initiative,
      asEnemy = asEnemy,
      done = false
    }

    local sortedPlayers = sortedKeys(self.fight.players)

    if sortedPlayers[1].uniqueId == playerUUID and not self.fight.started then
      self.fight.currentPlayer = playerUUID
    end
  end
end



function nextPlayer(playerId, toLeave, isAdmin)
  local playerUUID = world.entityUniqueId(playerId)
  if self.fight.currentPlayer == playerUUID or isAdmin then

    -- in case we actually moved our turn, the battle starts
    if not toLeave then self.fight.started = true end


    self.fight.players[self.fight.currentPlayer].done = true
    local sortedCurrentFight = sortedKeys(self.fight.players)

    for ind, fighter in ipairs(sortedCurrentFight) do
      if fighter.uniqueId == self.fight.currentPlayer then
        local newInd = ind % #sortedCurrentFight + 1
        self.fight.currentPlayer = sortedCurrentFight[newInd].uniqueId

        -- drop done flags for players
        if newInd == 1 then
          for _, fighter in ipairs(sortedCurrentFight) do
            fighter.done = false
          end
          self.fight.round = self.fight.round + 1
        end
        break
      end
    end
  end

  if toLeave then
    self.fight.players[playerUUID] = nil
  else
    world.sendEntityMessage(self.fight.currentPlayer, "ism_your_turn")
  end

end


function update()
  if next(self.fight.players) == nil then
    clearFight()
    stagehand.die()
  end
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

function uninit()
  clearFight()
end

function clearFight()
  local fights = world.getProperty("currentFights_v2") or {}
  fights[self.fight.name] = nil
  world.setProperty("currentFights_v2", fights)
end