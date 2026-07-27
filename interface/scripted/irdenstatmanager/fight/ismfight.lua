function changeFightName()
  self.irden.fightName = widget.getText("lytCharacter.tbxFightName")
end

function enterFight()
  local function rollInitiative()
    local bonuses = getBonuses({"INITIATIVE"})

    sendMessageToServer("statmanager", {
      type = "initiative", 
      dice = 20,
      source = world.entityName(player.id()),
      fightName = self.irden.fightName,
      fightEntityType = widget.getChecked("lytCharacter.btnEnterFightAsEnemy") and "MONSTER" or "PLAYER",
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

    rollInitiative()
  else
    irdenUtils.alert("^red;Введите имя боя!^reset;")
  end
end

function leaveFight()
  widget.setText("lytCharacter.tbxFightName", "")
  self.irden.fightName = nil
  world.sendEntityMessage(player.id(), "irden:fight:leave")

  -- Drop the roll mode to default

  if self.irden.rollMode == 2 then
    self.irden.rollMode = 1
    widget.setSelectedOption("lytCharacter.lytRollModes.rgRollModes", self.irden.rollMode)
  end
end

function clearFight()
  world.sendEntityMessage(player.id(), "clearFight")
end

function nextTurn()
  world.sendEntityMessage(player.id(), "irden:fight:turn:next")
end