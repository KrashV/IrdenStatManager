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

  message.setHandler("kickPlayer", simpleHandler(kickPlayer))

  message.setHandler("endFight", simpleHandler(endFight))

  message.setHandler("setInitiative", simpleHandler(setInitiative))

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

function setInitiative(playerUUID, newInit)
  if self.fight.players[playerUUID] then
    self.fight.players[playerUUID].initiative = tonumber(newInit) or self.fight.players[playerUUID].initiative
  end
end

function kickPlayer(playerId, uuidToKick, isAdmin)
  if isAdmin then
    world.sendEntityMessage(uuidToKick, "ism_kicked_from_fight", self.fight.name)
    if self.fight.currentPlayer == uuidToKick then
      nextPlayerInt()
    end
    self.fight.players[uuidToKick] = nil
  end
end

function nextPlayerInt()
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
      world.sendEntityMessage(self.fight.currentPlayer, "ism_your_turn", self.fight.name)
      return
    end
  end
end

function nextPlayer(playerId, toLeave, isAdmin, UUID)
  local playerUUID = UUID or world.entityUniqueId(playerId)
  if self.fight.currentPlayer == playerUUID or isAdmin then

    -- in case we actually moved our turn, the battle starts
    if not toLeave then self.fight.started = true end

    if not self.fight.players[self.fight.currentPlayer] then
      -- Something happened, we don't know what exactly
      if next(self.fight.players) == nil then
        stagehand.die()
      else
        local k, v = next(self.fight.players)
        self.fight.currentPlayer = k
      end
    end

    self.fight.players[self.fight.currentPlayer].done = true
    nextPlayerInt()
    
  end

  if toLeave then
    self.fight.players[playerUUID] = nil
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
  -- We actually should store the fight, yup.
  clearFight()
end

function noPlayersLeft(players)
  local someoneHere = false
  for uuid, player in pairs(players) do 
    someoneHere = someoneHere or (world.loadUniqueEntity(uuid) ~= 0)
  end
  return not someoneHere
end

function endFight()
  self.fight = nil
  clearFight(true)
  stagehand.die()
end

function clearFight(forceDelete)
  local fights = world.getProperty("currentFights_v2") or {}
  if not self.fight or next(self.fight.players) == nil or noPlayersLeft(self.fight.players) or forceDelete then
    fights[config.getParameter("name")] = nil
  else
    fights[config.getParameter("name")] = self.fight
  end
  world.setProperty("currentFights_v2", fights)
end