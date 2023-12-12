function createAttackQueue()
  -- Local promise to retrieve incoming attacks
  self.attackQueue = {}
  self.currentAttack = false

  local function addAttacksToQueue(queue)
    if queue then
      for _, att in ipairs(queue) do 
        table.insert(self.attackQueue, att)
      end
      if not self.currentAttack then
        self.currentAttack = true
        replyToAttack(self.attackQueue[1])
      end
    end
    promises:add(world.sendEntityMessage(player.id(), "irden_get_action_queue"), addAttacksToQueue)
  end

  promises:add(world.sendEntityMessage(player.id(), "irden_get_action_queue"), addAttacksToQueue)
end

function moveAttackQueue()
  local function dropToDefault()
    self.currentAttack = false
    self.defensePlayerId = nil
    self.defensePlayerUuid = nil
    self.defenseAttackDescription = nil
    widget.setVisible("lytOtherAttack", false)
    self.receivingEffects = {}
  end

  if #self.attackQueue > 0 then
    table.remove(self.attackQueue, 1)
    if #self.attackQueue > 0 then
      replyToAttack(self.attackQueue[1])
    else
      dropToDefault()
    end
  else
    dropToDefault()
  end
end


function replyToAttack(attack)
  widget.removeAllChildren("lytOtherAttack.lytStatuses")
  widget.setPosition("lytOtherAttack", {240, -180})
  widget.setVisible("lytOtherAttack", true)
  local otherAttackLayout = AnimatedWidget:bind("lytOtherAttack")
  animatedWidgets:add(otherAttackLayout:move({240, 20}, 0.2), function() 

    self.receivingEffects = {}
    self.receivingEffects.bonuses = {}
  
    local attackType = attack.attackType
  
    self.defensePlayerId = attack.defensePlayerId
    self.defensePlayerUuid = attack.defensePlayerUuid
    self.defenseAttackDescription = attack.attackDesc
  
    drawIcon("lytOtherAttack.attackerAvatar", attack.defensePlayerId)
    widget.setText("lytOtherAttack.playerName", world.entityName(attack.defensePlayerId))
    widget.setText("lytOtherAttack.attackName", attack.attackDesc)
    widget.setSelectedOption("lytOtherAttack.rgAttackType", (attackType == "melee" or attackType == "ranged") and -1 or (attackType == "magic" and 0) or 1)
    widget.setText("lytOtherAttack.tbxDamage", attack.damageBonuses and irdenUtils.calculateBonuses(0, attack.damageBonuses) or 0)
    widget.setVisible("lytOtherAttack", true)
  
    local statusImagePosition = {0, 0}
    self.tooltipFields = {}
    for _, bonus in ipairs(attack.attackBonuses or {}) do 
      if bonus.status then
        local statusConfig = root.assetJson("/stats/effects/irden/" .. bonus.status .. ".statuseffect")
        widget.addFlowImage("lytOtherAttack.lytStatuses", statusConfig.label, statusConfig.icon)
        self.tooltipFields["lytOtherAttack.lytStatuses." .. statusConfig.label] = statusConfig.label
        table.insert(self.receivingEffects.bonuses, {
          group = "Эффекты",
          name = statusConfig.label
        })
      end
      statusImagePosition[1] = statusImagePosition[1] + 20
    end
    self.tooltipFields["lytOtherAttack.rgAttackType.-1"] = "Физическая"
    self.tooltipFields["lytOtherAttack.rgAttackType.0"] = "Магическая"
    self.tooltipFields["lytOtherAttack.rgAttackType.1"] = "Чистый урон"
  
    if attack.richDescription then
      self.tooltipFields["lytOtherAttack.attackName"] = attack.richDescription
    end
    widget.setVisible("lytOtherAttack", true)
  
  end)
end

function populateAttackEffects()
  widget.clearListItems("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses")
  self.possibleAttackEffects = {}

  for name, group in pairs(self.irden.bonusGroups) do 
    if name == "Эффекты" then
      for _, bonus in ipairs(group.bonuses) do 
        local li = widget.addListItem("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses")
        widget.setText("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
        widget.setData("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li, bonus)
        table.insert(self.possibleAttackEffects, li)
      end
    -- elseif group.isCustom == true then
    --   for _, bonus in ipairs(group.bonuses) do 
    --     local li = widget.addListItem("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses")
    --     widget.setText("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li .. ".bonusName", "^cyan;" .. bonus.name)
    --     widget.setData("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li, bonus)
    --     table.insert(self.possibleAttackEffects, li)
    --   end
    end
  end
end

function addEffectsToAttack()
  widget.setVisible("lytAttacks.lytAddNewAttack.lytAttackEffects", true)
end

function closeEffectsToAttack()
  widget.setVisible("lytAttacks.lytAddNewAttack.lytAttackEffects", false)
end

function accept_damage()
  local damage = tonumber(widget.getText("lytOtherAttack.tbxDamage")) or 0
  local damageType = widget.getSelectedData("lytOtherAttack.rgAttackType").type

  if self.receivingEffects and self.receivingEffects.bonuses then 
    selfBonus(_, self.receivingEffects)
  end

  if damage > 0 then
    subtractHP(damage, damageType)
  end
  moveAttackQueue()
end

function decline_damage()
  moveAttackQueue()
end