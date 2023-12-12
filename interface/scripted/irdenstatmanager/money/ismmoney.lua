function printMoney()
  populateMoneyTargets()
  sendMessageToServer("statmanager", {
    type = "showMoney"
  })
end

function populateMoneyTargets()
  widget.removeAllChildren("lytMoney.saPlayers")

  local players = world.playerQuery(world.entityPosition(player.id()), 100, {
    withoutEntityId = player.id(),
    order = "nearest",
    boundMode = "position"
  })

  for k, p_id in ipairs(players) do
    players[k] = {
      id = p_id,
      name = world.entityName(p_id)
    }
  end
  
  local btnPos = {0, 0}
  local lblPos = {21, -12}
  local cnvPos = {3, 27}
  local dstPos = {39, 32}


  local radioGroupTemplate = {
    type = "radioGroup",
    position = {0, -16},
    zlevel = 10,
    buttons = {},
    callback = "null"
  }

  local buttonTemplate = {
    type = "button",
    zlevel = 16,
    checkable = true,
    baseImage = "/interface/scripted/irdenstatmanager/players/background.png",
    hoverImage = "/interface/scripted/irdenstatmanager/players/background.png?saturation=-20",
    baseImageChecked = "/interface/scripted/irdenstatmanager/players/background_selected_money.png",
    hoverImageChecked = "/interface/scripted/irdenstatmanager/players/background_selected_money.png?saturation=-20",
    position = btnPos,
    data = null
  }

  local nameTemplate = {
    type = "label",
    value = "Никто",
    position = vec2.add(buttonTemplate.position, lblPos), 
    hAnchor = "mid",
    zlevel = 17,
    mouseTransparent = true
  }

  local canvasTemplate = {
    type = "canvas",
    zlevel = 15,
    position = cnvPos,
    rect = {0, 0, 43, 43},
    captureMouseEvents = false,
    captureKeyboardEvents = false,
    mouseTransparent = true
  }

  local buttons = {}
  -- Apparently, we can't render widgets underneath the existing ones. Stupid!
  local names = {}

  for i, p in ipairs(players) do
    -- Player image
    canvasTemplate.rect = {2 + btnPos[1], 0 + btnPos[2], 37 + btnPos[1], 41 + btnPos[2]}
    widget.addChild("lytMoney.saPlayers", canvasTemplate, "canvas_" .. i)
    drawIcon("lytMoney.saPlayers." .. "canvas_" .. i, p.id, 2)

    -- Button image
    buttonTemplate.position = btnPos
    buttonTemplate.data = {
      id = p.id,
      name = p.name
    }
    table.insert(buttons, copy(buttonTemplate))

    -- Player name
    nameTemplate.value = p.name
    nameTemplate.position = vec2.add(buttonTemplate.position, lblPos)
    table.insert(names, copy(nameTemplate))

    btnPos = vec2.add(btnPos, {45, 0})
    if i % 5 == 0 then
      btnPos[1] = 0
      btnPos[2] = btnPos[2] - 60
    end
  end

  if #buttons > 0 then
    radioGroupTemplate.buttons = buttons
    widget.addChild("lytMoney.saPlayers", radioGroupTemplate, "rgRecipient")

    for _, name in ipairs(names) do 
      widget.addChild("lytMoney.saPlayers", name)
    end
  end
end

function sendMoney()
  if widget.getText("lytMoney.tbxAmount") == "" then
    pane.setTitle(self.defaultTitle, string.format("^red;Введите сумму!^reset;"))
    timers:add(2, function()
      pane.setTitle(self.defaultTitle, self.defaultSubtitle)
    end)
    return 
  end

  local pid = widget.getSelectedData("lytMoney.saPlayers.rgRecipient")
  if not pid then
    pane.setTitle(self.defaultTitle, string.format("^red;Выберите игрока!^reset;"))
    timers:add(2, function()
      pane.setTitle(self.defaultTitle, self.defaultSubtitle)
    end)
    return
  end

  if not world.entityExists(pid.id) then
    pane.setTitle(self.defaultTitle, string.format("^red;Игрок не на сервере!^reset;"))
    timers:add(2, function()
      pane.setTitle(self.defaultTitle, self.defaultSubtitle)
    end)
    return
  end

  sendMessageToServer("statmanager", {
    type = "transferMoney", 
    target = world.entityName(pid.id),
    amount = tonumber(widget.getText("lytMoney.tbxAmount"))
  })

  widget.setText("lytMoney.tbxAmount", "")
  printMoney()
end