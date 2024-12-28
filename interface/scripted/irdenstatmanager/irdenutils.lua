irdenUtils = {}

function irdenUtils.loadIrden()
  local irden = player.getProperty("irden") or {
    stats = {
      rollany = 0,
      strength = 0,
      endurance = 0,
      perception = 0,
      reflexes = 0,
     
      magic = 0,
      willpower = 0,
      intellect = 0,
      determination = 0
    },
    gear = {
      weapon = {
        melee = -1,
        ranged = -1,
        magic = -1
      },
      armour = {
        shield = -1,
        armour = -1,
        amulet = -1
      }
    },
    bonusGroups = root.assetJson("/irden_bonuses.config") or {},
    currentHp = 20,
    rollMode = 1,
    weatherEffects = true,
    presets = {},
    overrides = {
      events = {}
    },
    crafts = {
      END = 1,
      WIL = 1,
      INT = 1
    },
    eventAttempts = {},
    inventory = {}
  }
  irden = variousFixes(irden)
  irden.bonusGroups = irdenUtils.loadCustomBonuses(irden)
  return irden
end






function variousFixes(irden)

  --Create overrides table
  irden.overrides = irden.overrides or {
    events = {}
  }

  -- Create crafts table
  irden.crafts = irden.crafts or {
    END = irdenUtils.getMaxStamina("END", irden),
    WIL = irdenUtils.getMaxStamina("WIL", irden),
    INT = irdenUtils.getMaxStamina("INT", irden)
  }

  --Rename Особые атаки to Кастомные атаки
  if irden.bonusGroups["Особые атаки"] then 
    irden.bonusGroups["Кастомные атаки"] = irden.bonusGroups["Особые атаки"]
    irden.bonusGroups["Особые атаки"] = nil
  end
  -- Rename Магические
  if irden.bonusGroups["Магические атаки"] then 
    irden.bonusGroups["Атаки магией"] = irden.bonusGroups["Магические атаки"]
    irden.bonusGroups["Магические атаки"] = nil
  end

  irden.bonusGroups["Атаки магие"] = nil
  -- Rename Магические
  if irden.bonusGroups["Действия противника"] then
    irden.bonusGroups["Действия противника"] = nil
  end
  return irden
end

function irdenUtils.getMaxStamina(type, irden)
  local ird = irden or self.irden
  if type == "END" then
    return (irdenUtils.addBonusToStat(ird["stats"]["endurance"], "END", ird) + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_END", ird)
  elseif type == "WIL" then
    return (irdenUtils.addBonusToStat(ird["stats"]["willpower"], "WIL", ird) + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_WIL", ird)
  elseif type == "INT" then
    return (irdenUtils.addBonusToStat(ird["stats"]["intellect"], "INT", ird) + 1) // 2 + 1 + irdenUtils.addBonusToStat(0, "CRAFTING_INT", ird)
  end
end

function irdenUtils.addBonusToStat(base, stat, irden)
  local ird = irden or self.irden
  for groupName, bonusGroup in pairs(ird.bonusGroups) do
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

function irdenUtils.loadCustomBonuses(irden)
  local baseBonuses = root.assetJson("/irden_bonuses.config")
  irden.bonusGroups = irden.bonusGroups or {}
  -- For each group in custom bonuses do
  for groupName, group in pairs(irden.bonusGroups) do 
    -- If group does not exist at the base, add it whole
    if not baseBonuses[groupName] then
      baseBonuses[groupName] = group
    else
      baseBonuses[groupName].hidden = group.hidden
      -- Loop through each bonus in the group
      for _, bonus in ipairs(group.bonuses) do
        -- If bonus does not exist in the base group (somehow), add it
        local ind = findIndexAtValue(baseBonuses[groupName].bonuses, "name", bonus.name)
        if not ind then
          table.insert(baseBonuses[groupName].bonuses, bonus)
        else
          -- Else overwrite the base bonus with the new one
          baseBonuses[groupName].bonuses[ind] = bonus
        end
      end
    end
  end
  return baseBonuses
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