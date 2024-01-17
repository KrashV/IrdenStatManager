irdenUtils = {}

function irdenUtils.getMaxStamina(type)
  if type == "END" then
    return (irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END") + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_END")
  elseif type == "WIL" then
    return (irdenUtils.addBonusToStat(self.irden["stats"]["willpower"], "WIL") + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_WIL")
  elseif type == "INT" then
    return (irdenUtils.addBonusToStat(self.irden["stats"]["intellect"], "INT") + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_INT")
  end
end

function irdenUtils.addBonusToStat(base, stat)
  for groupName, bonusGroup in pairs(self.irden.bonusGroups) do
    for _, bonus in ipairs(bonusGroup.bonuses) do
      if bonus.tag == stat and bonus.ready then
        base = base + bonus.value
      end
    end
  end

  return base
end

function irdenUtils.getBonusByTag(tag) 
  for groupName, group in pairs(self.irden.bonusGroups) do
    for i, bonus in ipairs(group.bonuses) do
      if bonus.tag == tag then return bonus end
    end
  end

  return {
    name = "",
    value = 0,
    tag = ""
  }
end

function irdenUtils.getActiveBonusesByTags(tags)
  local activeBonuses = {}
  for groupName, group in pairs(self.irden.bonusGroups) do
    local groupType = self.irden.bonusGroups[groupName].type
    for _, bonus in ipairs(group.bonuses) do
      for _, tag in ipairs(tags) do 
        if bonus.tag == tag and (bonus.ready or groupType == "actions" or groupType == "stuff") and bonus.value ~= 0 then
          table.insert(activeBonuses, bonus)
        end
      end
    end
  end

  return activeBonuses
end


function irdenUtils.calculateBonuses(value, bonuses)
  local sum = value
  for i = 1, #bonuses, 2 do
    sum = sum + bonuses[i]
  end
  return sum
end

function irdenUtils.alert(text, time)
  pane.setTitle(self.defaultTitle, text)
  timers:add(time or 2, function()
    pane.setTitle(self.defaultTitle, self.defaultSubtitle)
  end)
end


function findIndexAtValue(t, attr, value)
  for i, v in ipairs(t) do
    if v[attr] == value then
      return i
    end
  end
end

function table.index(t, value)
  for i, v in ipairs(t) do
    if v == value then
      return i
    end
  end
end

function has_value (tab, val)
  for index, value in ipairs(tab) do
      if value == val then
          return true
      end
  end

  return false
end

function sortedKeys(query)
  local keys = {}
  for k,v in pairs(query) do
    table.insert(keys, k)
  end
  
  table.sort(keys)
  return keys
end

function table.filter(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
    if filterIter(v, k, t) then out[k] = v end
  end

  return out
end

function createTooltip(screenPosition)
  if self.tooltipFields then
    for widgetName, tooltip in pairs(self.tooltipFields) do
      if widget.inMember(widgetName, screenPosition) then
        return tooltip
      end
    end
  end
  
  if widget.getChildAt(screenPosition) then
    local w = widget.getChildAt(screenPosition)
    local wData = widget.getData(w:sub(2))
    if wData and type(wData) == "table" and wData.defaultTooltip then
      return wData.defaultTooltip
    end
  end
end