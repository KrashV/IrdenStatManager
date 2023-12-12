function changeFightName()
  self.irden.fightName = widget.getText("lytCharacter.tbxFightName")
end

function enterFight()
  local function rollInitiative()
    local initiative = math.random(20)
    local bonuses = getBonuses({"INITIATIVE"})

    sendMessageToServer("statmanager", {
      type = "initiative", 
      dice = 20,
      rgseed = util.seedTime(),
      initiative = initiative,
      source = world.entityName(player.id()),
      fightName = self.irden.fightName,
      bonuses = bonuses
    })

    return irdenUtils.calculateBonuses(initiative, bonuses)
  end


  if self.irden.fightName and self.irden.fightName ~= "" then
    -- We entered a fight: if we were in the fight already, send the message that we leave
    local previousFight = player.getProperty("irdenfightName")
    if previousFight then
      world.sendEntityMessage("irdenfighthandler_" .. previousFight, "nextTurn", player.id(), true, player.isAdmin())
    end


    player.setProperty("irdenfightName", self.irden.fightName)

    promises:add(world.findUniqueEntity("irdenfighthandler_" .. self.irden.fightName), function(pos)
      -- we are already in a fight
      promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.irden.fightName, "getFight"), function(currentFight)
        local init = 20
        if not currentFight.players[player.uniqueId()] then
          init = rollInitiative()
        else
          init = currentFight.players[player.uniqueId()].initiative
          sendMessageToServer("statmanager", {
            type = "return_to_fight",
            fightName = self.irden.fightName,
            initiative = init
          })
        end
        
        player.startQuest({
          templateId = "irdeninitiative",
          questId = "irdeninitiative",
          parameters = {
            fight = {
              type = "json",
              data = {
                fightName = self.irden.fightName,
                initiative = init,
                asEnemy = widget.getChecked("lytCharacter.btnEnterFightAsEnemy")
              }
            }
          }
        })
      end)
    end, function(error)
      player.startQuest({
        templateId = "irdeninitiative",
        questId = "irdeninitiative",
        parameters = {
          fight = {
            type = "json",
            data = {
              fightName = self.irden.fightName,
              initiative = rollInitiative(),
              asEnemy = widget.getChecked("lytCharacter.btnEnterFightAsEnemy")
            }
          }
        }
      })
    end)
  else
    pane.setTitle(self.defaultTitle, string.format("^red;Введите имя боя!^reset;"))
    timers:add(2, function()
      pane.setTitle(self.defaultTitle, self.defaultSubtitle)
    end)
  end
end

function leaveFight()
  widget.setText("lytCharacter.tbxFightName", "")
  self.irden.fightName = nil
  world.sendEntityMessage(player.id(), "leaveFight")
end

function clearFight()
  world.sendEntityMessage(player.id(), "clearFight")
end

function nextTurn()
  world.sendEntityMessage(player.id(), "nextTurn", player.uniqueId())
end