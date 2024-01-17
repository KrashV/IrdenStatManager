function findFightToManage(widgetName)
  local fight = widget.getText("lytFightManager.tbxFightname")

  
  widget.registerMemberCallback("lytFightManager.lytCurrentFight.saFighters.listFighters", "kickFromFight", kickFromFight)
  widget.registerMemberCallback("lytFightManager.lytCurrentFight.saFighters.listFighters", "prepareChangeInitiative", prepareChangeInitiative)

  local function getFight(fightName)
    
    promises:add(world.sendEntityMessage("irdenfighthandler_" .. fightName, "getFight"), function(currentFight)
      if currentFight then
        self.currentManagingFight = currentFight
        drawFight(currentFight)
        timers:add(1, function() 
          getFight(fightName)
        end)
      else
        irdenUtils.alert("^red;Произошла ошибка в проверке боя") 
        widget.setVisible("lytFightManager.lytCurrentFight", false)
        widget.clearListItems("lytFightManager.lytCurrentFight.saFighters.listFighters")
      end
    end, function() 
      irdenUtils.alert("^red;Произошла ошибка в проверке боя") 
      widget.setVisible("lytFightManager.lytCurrentFight", false)
      widget.clearListItems("lytFightManager.lytCurrentFight.saFighters.listFighters")
    end)
  end

  promises:add(world.findUniqueEntity("irdenfighthandler_" .. fight), function()
    widget.setVisible("lytFightManager.lytCurrentFight", true)
    getFight(fight)
  end, function() 
    irdenUtils.alert("^red;Такой бой не найден")
    widget.setVisible("lytFightManager.lytCurrentFight", false)
    widget.clearListItems("lytFightManager.lytCurrentFight.saFighters.listFighters")
  end)
end

function getNameOfCurrentPlayer(currentFight)
  return currentFight.players[currentFight.currentPlayer] and currentFight.players[currentFight.currentPlayer].name or "Неизвестно"
end

function drawFight(currentFight)
  widget.clearListItems("lytFightManager.lytCurrentFight.saFighters.listFighters")
  if currentFight then
    local sortedPlayers = sortFight(currentFight.players)

    widget.setText("lytFightManager.lytCurrentFight.lblCurrentPlayer", string.format("Ходит: %s", currentFight.players and getNameOfCurrentPlayer(currentFight)))

    widget.setText("lytFightManager.lytCurrentFight.lblCurrentRound", string.format("Раунд: %s", currentFight.round or "Неизвестно"))

    for ind, pl in ipairs(sortedPlayers) do 
      local li = widget.addListItem("lytFightManager.lytCurrentFight.saFighters.listFighters")
      widget.setText("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li .. ".lblName", (pl.uniqueId == currentFight.currentPlayer and "-> " or "") .. pl.name)
      widget.setFontColor("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li .. ".lblName", pl.uniqueId == player.uniqueId() and "yellow" or pl.done and "gray" or "white")
      widget.setText("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li .. ".lblInitiative", pl.initiative)
      widget.setData("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li, pl)

      local data = pl
      data.defaultTooltip = "Кикнуть из боя"
      widget.setData("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li .. ".btnKick", pl)
      data.defaultTooltip = "Изменить инициативу"
      widget.setData("lytFightManager.lytCurrentFight.saFighters.listFighters."  .. li .. ".btnKChangeInit", pl)
    end
  end
end

function forceNextTurn()
  if self.currentManagingFight then
    promises:add(
      player.confirm({
        title = self.currentManagingFight.name,
        --subtitle = "Передать ход",
        sourceEntityId = player.id(),
        okCaption = "Да",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Скипнуть ход " .. getNameOfCurrentPlayer(self.currentManagingFight) .. "?"
      }), function (result)
        if result then
          world.sendEntityMessage("irdenfighthandler_" .. self.currentManagingFight.name, "nextTurn", player.id(), false, player.isAdmin())
        end
    end)
  end
end

function prepareChangeInitiative(_, data)

  widget.setText("lytFightManager.lytCurrentFight.lytChangeInit.lblName", "Инициатива " .. data.name .. ":")
  widget.setText("lytFightManager.lytCurrentFight.lytChangeInit.tbxInit", data.initiative)
  widget.setData("lytFightManager.lytCurrentFight.lytChangeInit", data.uniqueId)
  widget.setData("lytFightManager.lytCurrentFight.lytChangeInit.btnAccept", data)
  widget.setVisible("lytFightManager.lytCurrentFight.lytChangeInit", true)
  widget.focus("lytFightManager.lytCurrentFight.lytChangeInit.tbxInit")
end

function changeInitiative(_, data)
  local newInit = tonumber(widget.getText("lytFightManager.lytCurrentFight.lytChangeInit.tbxInit")) or 0

  if newInit and self.currentManagingFight then
    promises:add(
      player.confirm({
        title = self.currentManagingFight.name,
        --subtitle = "Передать ход",
        sourceEntityId = player.id(),
        okCaption = "Да",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Поставить " .. data.name .. " на " .. newInit .."?"
      }), function (result)
        if result then
          world.sendEntityMessage("irdenfighthandler_" .. self.currentManagingFight.name, "setInitiative", data.uniqueId, newInit)
          widget.setVisible("lytFightManager.lytCurrentFight.lytChangeInit", false)
        end
    end)
  end
end


function kickFromFight(_, data)
  if self.currentManagingFight then
    promises:add(
      player.confirm({
        title = self.currentManagingFight.name,
        --subtitle = "Передать ход",
        sourceEntityId = player.id(),
        okCaption = "Да",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Кикнуть " .. data.name .. " из боя?"
      }), function (result)
        if result then
          world.sendEntityMessage("irdenfighthandler_" .. self.currentManagingFight.name, "kickPlayer", player.id(), data.uniqueId, player.isAdmin())
        end
    end)
  end
end

function finishFight()
  if self.currentManagingFight then
    promises:add(
      player.confirm({
        title = self.currentManagingFight.name,
        --subtitle = "Передать ход",
        sourceEntityId = player.id(),
        okCaption = "Да",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Завершить бой " .. self.currentManagingFight.name .. "?"
      }), function (result)
        if result then
          world.sendEntityMessage("irdenfighthandler_" .. self.currentManagingFight.name, "endFight")
          widget.setVisible("lytFightManager.lytCurrentFight", false)
          widget.clearListItems("lytFightManager.lytCurrentFight.saFighters.listFighters")
          widget.setText("lytFightManager.tbxFightname", "")
        end
    end)
  end
end

function sortFight(query)
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