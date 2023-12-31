function loadResources()
  local events = root.assetJson("/irden_events.config")
  local position = {8, 161}
  local lblOffset = {45, 11}
  local iconOffset = {3, 3}
  local slOffset = {5, -10}
  local sliderAttemptsOffset = {-2, -6}
  local leftAttemptsOffset = {70, -6}
  local totalAttemptsOffset = {64, 17}
  widget.removeAllChildren("lytResources.lytButtons")

  for _, event in ipairs(events) do
    event.stat = self.irden.overrides.events[event.event] and self.irden.overrides.events[event.event].stat or event.stat
    self.eventStats[event.event] = event.stat
    table.insert(event.tags, event.stat)
    event.activeBonuses = {
      name = event.name,
      tags = {"ALL", table.unpack(event.tags)}
    }

    local icon = event.icon
    event.icon = nil

    -- Big button
    widget.addChild("lytResources.lytButtons", {
      type = "button",
      position = position,
      base = "/interface/scripted/irdenstatmanager/resources/resourcebutton.png",
      hover = "/interface/scripted/irdenstatmanager/resources/resourcebuttonhover.png",
      callback = "resources",
      data = event
    }, "btn" .. event.event)

    -- Icon
    widget.addChild("lytResources.lytButtons", {
      type = "image",
      position = vec2.add(position, iconOffset),
      file = icon,
      mouseTransparent = true
    }, "btn" .. event.event)

    -- Name
    widget.addChild("lytResources.lytButtons", {
      type = "label",
      hAnchor = "mid",
      vAnchor = "mid",
      wrapWidth = 45,
      position = vec2.add(position, lblOffset),
      value = event.name,
      mouseTransparent = true
    })

    

    -- Slider
    widget.addChild("lytResources.lytButtons", {
      type = "slider",
      gridImage = "/interface/optionsmenu/smallselection.png",
      position = vec2.add(position, slOffset),
      callback = "updateResourceSlider",
      data = event.event
    }, "slResource" .. event.event)

    -- Slider attempts
    widget.addChild("lytResources.lytButtons", {
      type = "label",
      hAnchor = "left",
      vAnchor = "mid",
      wrapWidth = 45,
      value = "???",
      position = vec2.add(position, sliderAttemptsOffset),
      mouseTransparent = true
    }, "lblCurrent" .. event.event)    


    -- Left attempts
    widget.addChild("lytResources.lytButtons", {
      type = "label",
      hAnchor = "left",
      vAnchor = "mid",
      wrapWidth = 45,
      value = "???",
      position = vec2.add(position, leftAttemptsOffset),
      mouseTransparent = true
    }, "lblLeft" .. event.event)

    -- Total attempts
    widget.addChild("lytResources.lytButtons", {
      type = "label",
      hAnchor = "left",
      vAnchor = "mid",
      color = "indigo",
      wrapWidth = 45,
      position = vec2.add(position, totalAttemptsOffset),
      mouseTransparent = true
    }, "lblTotal" .. event.event)

    position[1] = position[1] + 86
    if position[1] > 260 then
      position[1] = 8
      position[2] = position[2] - 43
    end
  end
end

function updateResourceSlider(_, type)
  widget.setText("lytResources.lytButtons.lblCurrent" .. type, widget.getSliderValue("lytResources.lytButtons.slResource" .. type))
end

function perfectAttempts(stat)
  return  1 + (irdenUtils.addBonusToStat(self.irden["stats"][self.characterStats[stat]], stat) + 1) // 2
end

function getMaxResourceAttempts(type)
  local attempts = {
    prey = 2 + irdenUtils.getBonusByTag("RESOURSE_HUNTING").value,
    fishing = 2 + irdenUtils.getBonusByTag("RESOURSE_FISHING").value,
    herbalism = irdenUtils.addBonusToStat(self.irden["stats"][self.characterStats[self.eventStats["herbalism"]]], self.eventStats["herbalism"]) // 5 + irdenUtils.getBonusByTag("RESOURSE_HERBALISM").value,
    mining = perfectAttempts("END") // 2 + irdenUtils.getBonusByTag("RESOURSE_MINING").value,
    quarry = perfectAttempts("END") + irdenUtils.getBonusByTag("RESOURSE_QUARRY").value,
    chopping = perfectAttempts("END") // 2 + irdenUtils.getBonusByTag("RESOURSE_CHOPPING").value,
    riches = irdenUtils.addBonusToStat(self.irden["stats"][self.characterStats[self.eventStats["riches"]]], self.eventStats["riches"]) // 5 + irdenUtils.getBonusByTag("RESOURSE_RICHES").value,
    wooddoing = perfectAttempts("END") + irdenUtils.getBonusByTag("RESOURSE_WOODDOING").value
  }

  return attempts[type] or "?"
end

function getLeftResourceAttempts(type)
  return (self.irden.eventAttempts and self.irden.eventAttempts[type] and self.irden.eventAttempts[type]) or getMaxResourceAttempts(type)
end

function setResourseAttempts()
  for _, event in ipairs(root.assetJson("/irden_events.config")) do
    widget.setSliderRange("lytResources.lytButtons.slResource" .. event.event, 0, getLeftResourceAttempts(event.event), 1)
    widget.setSliderValue("lytResources.lytButtons.slResource" .. event.event, getLeftResourceAttempts(event.event))

    
    widget.setText("lytResources.lytButtons.lblTotal" .. event.event, getMaxResourceAttempts(event.event))
    widget.setText("lytResources.lytButtons.lblLeft" .. event.event, getLeftResourceAttempts(event.event))
    widget.setText("lytResources.lytButtons.lblCurrent" .. event.event, widget.getSliderValue("lytResources.lytButtons.slResource" .. event.event))
  end
end

function resetResourceAttempts()
  self.irden.eventAttempts = {}
  setResourseAttempts()
end

function resources(_, data)
  local type = data.type

  local function decreaseLeftAttempts(type, n_attempts)
    self.irden.eventAttempts = self.irden.eventAttempts or {}
    self.irden.eventAttempts[type] = self.irden.eventAttempts[type] or getMaxResourceAttempts(type)
    self.irden.eventAttempts[type] = math.max(self.irden.eventAttempts[type] - n_attempts, 0)
  end

  if not self.editMode then
    local n_attempts = widget.getSliderValue("lytResources.lytButtons.slResource" .. data.event)
    n_attempts = n_attempts > 0 and n_attempts or 1

    sendMessageToServer("statmanager", {
      type = "resourceEvent", 
      action = data.action,
      source = world.entityName(player.id()),
      minCrit = self.irden.overrides.events[data.event] and self.irden.overrides.events[data.event].minCrit,
      bonuses = getBonuses({"ALL", table.unpack(data.tags)}, self.irden.stats[self.characterStats[data.stat]], data.stat),
      data = data,
      attempts = n_attempts
    })
    decreaseLeftAttempts(data.event, n_attempts)
  elseif not widget.active("lytEditResource") then
    for i, stat in ipairs({"STR", "END", "PER", "REF", "MAG", "WIL", "INT", "DET"}) do 
      if stat == data.stat then
        widget.setSelectedOption("lytEditResource.rgStat", i - 2)
        break
      end
    end
    widget.setData("lytEditResource", {
      event = data.event
    })
    widget.setText("lytEditResource.minCrit", self.irden.overrides.events[data.event] and self.irden.overrides.events[data.event].minCrit or 20)
    widget.setText("lytEditResource.lblTitle", data.activeBonuses.name)
    widget.setVisible("lytEditResource", true)
  end
  setResourseAttempts()
end

function editMode()
  self.editMode = widget.getChecked("lytResources.editMode")
end

function editSave()
  local event = widget.getData("lytEditResource").event
  local minCrit = widget.getText("lytEditResource.minCrit")
  self.irden.overrides.events[event] = self.irden.overrides.events[event] or {}
  self.irden.overrides.events[event].stat = widget.getSelectedData("lytEditResource.rgStat")
  self.irden.overrides.events[event].minCrit = minCrit ~= "" and tonumber(minCrit) or 20
  self.eventStats[event] = event.stat
  loadResources()
  setResourseAttempts()
  widget.setVisible("lytEditResource", false)
end

function editClose()
  widget.setVisible("lytEditResource", false)
end