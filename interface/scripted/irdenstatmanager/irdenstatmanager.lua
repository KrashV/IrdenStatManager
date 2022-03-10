require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/interface/scripted/animatedWidgets.lua"

function init()
  math.randomseed(util.seedTime())
  
  widget.setButtonEnabled("lytCharacter.btnClearFight", player.isAdmin())

  widget.registerMemberCallback("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "deleteBonus", deleteBonus)

  self.irden = player.getProperty("irden")

  self.characterStatsTextboxes = config.getParameter("characterStatsTextboxes")
  self.characterStats = config.getParameter("characterStats")
  self.tabs = config.getParameter("tabs")
  self.attackTypes = {"Melee", "Ranged", "Magic", "AddNew"}
  self.selectedLine = nil

  self.movementType = 1

  if config.getParameter("defensePlayer") then 
    self.defensePlayer = config.getParameter("defensePlayer")
    widget.setSelectedOption("lytAttacks.rgAttackTypes", config.getParameter("attackType"))
    pane.setTitle("Irden Stat Manager", string.format("Вас атакует ^magenta;%s, ^reset;используя ^orange;%s", world.entityName(self.defensePlayer), config.getParameter("attackDesc")))
    widget.setSelectedOption("rgTabs", 0)
  end

  -- FIX THE GROUPS
  if self.irden and not self.irden.bonusGroups and self.irden.bonuses then
    self.irden.bonuses = nil
    self.irden.bonusGroups = root.assetJson("/irden_bonuses.config")
  end


  if not self.irden then
    self.irden = {}
    self.irden["stats"] = {
      rollany = 0,
      strength = 0,
      endurance = 0,
      perception = 0,
      reflexes = 0,
     
      magic = 0,
      willpower = 0,
      intellect = 0,
      determination = 0
    }

    self.irden["gear"] = {
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
    }
    self.irden.bonusGroups = root.assetJson("/irden_bonuses.config")
    self.irden.currentHp = 20
  else
    local cHp = self.irden.currentHp
	  loadStats(self.irden["stats"])
    self.irden.currentHp = cHp
  end

  loadPreview()
  loadBonuses()
  loadAttacks()
  loadWeapons(self.irden["gear"])

  setHealthAndArmor()


  self.tooltipCanvas = widget.bindCanvas("tooltipCanvas")
end

function loadPreview()
	widget.setText("lytCharacter.lblName", world.entityName(player.id()))
  widget.setText("lytCharacter.tbxFightName", self.irden.fightName or "")
  widget.setChecked("lytCharacter.btnShowCurrentPlayer", player.getProperty("toShowCurrentPlayerIndicator", true))

	local portrait = world.entityPortrait(player.id(), "full")
	for _, part in ipairs(portrait) do
		local li = widget.addListItem("lytCharacter.lstPreview")
		widget.setImage("lytCharacter.lstPreview." .. li .. ".image", part.image)
	end
end

function setResourseAttempts()
  local perfectAttempts = 1 + (addBonusToStat(self.irden["stats"]["endurance"], "END") + 1) // 2
  widget.setText("lytCharacter.lblHunting", 2 + getBonusByTag("RESOURSE_HUNTING").value)
  widget.setText("lytCharacter.lblMining", perfectAttempts // 2 + getBonusByTag("RESOURSE_MINING").value)
  widget.setText("lytCharacter.lblQuarry", perfectAttempts + getBonusByTag("RESOURSE_QUARRY").value)
  widget.setText("lytCharacter.lblChopping", perfectAttempts // 2 + getBonusByTag("RESOURSE_CHOPPING").value)
  widget.setText("lytCharacter.lblRiches", addBonusToStat(self.irden["stats"]["perception"], "PER") // 5 + getBonusByTag("RESOURSE_RICHES").value)
  widget.setText("lytCharacter.lblWooddoing", perfectAttempts + getBonusByTag("RESOURSE_WOODDOING").value)
end

function loadStats(stats)
  for widgetName, statName in pairs(self.characterStatsTextboxes) do
	  widget.setText("lytCharacter." .. widgetName, stats[statName] or "0")
  end
end

function loadWeapons(gear)
  widget.setSelectedOption("lytArmory.rgmeleeWeapons", gear["weapon"]["melee"])
  widget.setSelectedOption("lytArmory.rgrangedWeapons", gear["weapon"]["ranged"])
  widget.setSelectedOption("lytArmory.rgmagicWeapons", gear["weapon"]["magic"])

  widget.setSelectedOption("lytArmory.rgArmour", gear["armour"]["armour"])
  widget.setSelectedOption("lytArmory.rgShields", gear["armour"]["shield"])
  widget.setSelectedOption("lytArmory.rgAmulets", gear["armour"]["amulet"])
  widget.setChecked("lytArmory.cbxIsAutomatic", not not self.irden["gear"].isAutomatic)

  local movementBonus = widget.getSelectedData("lytArmory.rgArmour").movementBonus
  if (movementBonus) then
    world.sendEntityMessage(player.id(), "irdenGetArmourMovement", getBonusByTag(movementBonus).value)
  end
end


function loadAttacks()
  for _, layout in ipairs(self.attackTypes) do
    widget.removeAllChildren("lytAttacks.lyt" .. layout .. "Attack.lytCustomAttack")
  end

  if self.irden.attacks then
    local attackTypeMap = {
      melee = {
        layout = "Melee",
        position = {30, 100}
      },
      ranged = {
        layout = "Ranged",
        position = {30, 100}
      },
      magic = {
        layout = "Magic",
        position = {30, 160}
      }
    }

    for _, attack in ipairs(self.irden.attacks) do
      attackTypeMap[attack.type].position[2] = attackTypeMap[attack.type].position[2] - 20

      -- add metainfo to attack
      attack.activeBonuses = {
        tags = {"ALL", attack.stat, attack.dmgStat, attack.damageBonus, attack.attackBonus}
      }



      local childName = attack.desc .. math.random(1031)

      widget.addChild("lytAttacks.lyt" .. attackTypeMap[attack.type].layout .. "Attack.lytCustomAttack", {
        type = "button",
        position = attackTypeMap[attack.type].position,
        caption = attack.desc,
        base = "/interface/buttonactive.png",
        hover = "/interface/buttonactivehover.png",
        callback = "attack",
        data = attack
      }, childName)

      attack.buttonName = childName
      widget.addChild("lytAttacks.lyt" .. attackTypeMap[attack.type].layout .. "Attack.lytCustomAttack", {
        type = "button",
        position = vec2.add(attackTypeMap[attack.type].position, {-15, 0}),
        caption = "-",
        base = "/interface/scripted/irdenstatmanager/buttondelete.png",
        hover = "/interface/scripted/irdenstatmanager/buttondeletehover.png",
        callback = "deleteAttack",
        data = attack
      }, childName .. "btn")
      
      if attackTypeMap[attack.type].position[2] <= 60 then
        attackTypeMap[attack.type].position = {attackTypeMap[attack.type].position[1] + 80, 180}
      end
    end
  end
end

function deleteAttack(_, data)
  local attackTypeMap = {
    melee = {
      layout = "Melee"
    },
    ranged = {
      layout = "Ranged"
    },
    magic = {
      layout = "Magic"
    }
  }

  local attackIndex = findIndexAtValue(self.irden.bonusGroups["Особые атаки"].bonuses, "tag", data.attackBonus)
  if attackIndex then
    table.remove(self.irden.bonusGroups["Особые атаки"].bonuses, attackIndex)
  end

  local damageIndex = findIndexAtValue(self.irden.bonusGroups["Особые атаки"].bonuses, "tag", data.damageBonus)
  if damageIndex then
    table.remove(self.irden.bonusGroups["Особые атаки"].bonuses, damageIndex)
  end

  local aIndx = findIndexAtValue(self.irden.attacks, "desc", data.desc)
  if aIndx then
    table.remove(self.irden.attacks, aIndx)
  end

  if #self.irden.attacks == 0 then
    self.irden.bonusGroups["Особые атаки"] = nil
  end


  loadBonuses()

  widget.removeChild("lytAttacks.lyt" .. attackTypeMap[data.type].layout .. "Attack.lytCustomAttack", data.buttonName)
  widget.removeChild("lytAttacks.lyt" .. attackTypeMap[data.type].layout .. "Attack.lytCustomAttack", data.buttonName .. "btn")
end


function loadBonuses()
  widget.clearListItems("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytStuffBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytActionsBonuses.saBonuses.listBonuses")

  local sourtedGroups = sortedKeys(self.irden.bonusGroups)

  for _, groupName in ipairs(sourtedGroups) do
    local group = self.irden.bonusGroups[groupName]

    local bonusType = group.isCustom and "lytCustomBonuses" or (group.type == "stuff" and "lytStuffBonuses" or group.type == "actions" and "lytActionsBonuses" or "lytBaseBonuses")
    local data = {
      type = "group",
      name = groupName
    }

    local groupListItem = widget.addListItem("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses", groupName)
    widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusName", groupName)
    widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusIsActive", data)
    widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".btnDeleteBonus", data)
    widget.setImage("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".background", "/interface/scripted/irdenstatmanager/groupnamebackground.png")
    widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusName", "green")
    widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusValue", "")

    if group.isCustom then
      widget.addChild("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem, {
        type = "button",
        position = {180, 5},
        base = "/interface/scripted/irdenstatmanager/buttonadd.png",
        hover = "/interface/scripted/irdenstatmanager/buttonaddhover.png",
        callback = "changeBonusLayout",
        data = data
      })
    else
      widget.removeChild("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem, "bonusIsActive")
    end

    -- Add hide button
    widget.addChild("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem, {
      type = "button",
      checkable = true,
      checked = not not group.hidden,
      position = {160, 5},
      base = "/interface/scripted/irdenstatmanager/buttonhide.png",
      hover = "/interface/scripted/irdenstatmanager/buttonhidehover.png",
      baseImageChecked = "/interface/scripted/irdenstatmanager/buttonshow.png",
      hoverImageChecked = "/interface/scripted/irdenstatmanager/buttonshowhover.png",
      callback = "hideBonusesInGroup",
      data = data
    })

    if not group.hidden then
      for j, bonus in ipairs(group.bonuses) do
        local li = widget.addListItem("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses")
        widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
        widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
        widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusValue", string.format('%s%d', bonus.value > 0 and "+" or "", bonus.value))
        widget.setPosition("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", {35, 5})
        widget.setPosition("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusIsActive", {13, 5})
        widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusIsActive", {
          type = "bonus",
          group = groupName,
          name = bonus.name
        })
        widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".btnDeleteBonus", {
          type = "bonus",
          group = groupName,
          name = bonus.name
        })
        widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusIsActive", bonus.ready)
        self.irden.bonusGroups[groupName].bonuses[j].listId = li

        if bonus.ready then
          widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", "yellow")
        end

        if group.isCustom or group.type == "stuff" or group.type == "actions" then
          local widgetName = math.random(99999) .. groupName .. bonus.name

          widget.addChild("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li, {
            type = "spinner",
            position = {150, 5},
            upOffset = 16,
            callback = "changeBonus",
            data = {
              group = groupName,
              bonus = bonus.name
            }
          }, widgetName)
          widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. "." .. widgetName .. ".up", {
            group = groupName,
            bonus = bonus.name
          })
          widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. "." .. widgetName .. ".down", {
            group = groupName,
            bonus = bonus.name
          })
        end
      end
    end
    widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusIsActive", checkIfGroupIsFullyReady(groupName))
  end
end


function checkIfGroupIsFullyReady(groupName)
  for j, bonus in ipairs(self.irden.bonusGroups[groupName].bonuses) do
    if not bonus.ready then return false end
  end
  return true
end

function setBonus(_, data)
  if self.selectedLine then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    local isChecked = widget.getChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusIsActive")

    if data.type == "group" then
      for i, bonus in ipairs(self.irden.bonusGroups[data.name].bonuses) do
        self.irden.bonusGroups[data.name].bonuses[i].ready = isChecked
        widget.setChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", isChecked)
        widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusName", isChecked and "yellow" or "white")
      end
    elseif data.type == "bonus" then
      local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "listId", self.selectedLine)
      if index then
        self.irden.bonusGroups[data.group].bonuses[index].ready = isChecked
        widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusName", isChecked and "yellow" or "white")
      end
    end
  end

 setHealthAndArmor()
end

function deleteBonus(_, data)
  if self.selectedLine then
    if data.type == "group" then
      self.irden.bonusGroups[data.name] = nil
    elseif data.type == "bonus" then
      local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "listId", self.selectedLine)
      if index then
        table.remove(self.irden.bonusGroups[data.group].bonuses, index)
      end
    end
    loadBonuses()
  end

 setHealthAndArmor()
end

changeBonus = {}
function changeBonus.up(_, data)
  if self.selectedLine and data then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "name", data.bonus)
    if index then
      local value = self.irden.bonusGroups[data.group].bonuses[index].value + 1
      self.irden.bonusGroups[data.group].bonuses[index].value = value
      widget.setText("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusValue", string.format('%s%d', value > 0 and "+" or "", value))
      setHealthAndArmor()
    end
  end
end

function changeBonus.down(_, data)
  if self.selectedLine and data then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "name", data.bonus)
    if index then
      local value = self.irden.bonusGroups[data.group].bonuses[index].value - 1
      self.irden.bonusGroups[data.group].bonuses[index].value = value
      widget.setText("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusValue", string.format('%s%d', value > 0 and "+" or "", value))
      setHealthAndArmor()
    end
  end
end


function addBonusGroup()
  local groupName = widget.getText("lytMisc.lytBonuses.lytCustomBonuses.tbxGroupName")

  if groupName ~= "" then
    self.irden.bonusGroups[groupName] = {
      name = groupName,
      isCustom = true,
      bonuses = {}
    }

    loadBonuses()
    widget.setText("lytMisc.lytBonuses.lytCustomBonuses.tbxGroupName", "")
  end

end

function addBonus()
  if widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillName"):len() > 0 and widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillValue"):len() > 0 then
    local bonus = {}

    bonus.name = widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillName")
    bonus.value = tonumber(widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillValue"))
    bonus.oneTimed = not widget.getChecked("lytMisc.lytAddNewSkill.cbxIsPermanent")
    bonus.ready = true
    bonus.tag = widget.getSelectedData("lytMisc.lytAddNewSkill.rgBonusTags").tag

    table.insert(self.irden.bonusGroups[self.currentGroup].bonuses, bonus)
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillName", "")
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillValue", "")

    widget.setVisible("lytMisc.lytBonuses", true)
    widget.setVisible("lytMisc.lytAddNewSkill", false)
    loadBonuses()
    setHealthAndArmor()
  end
end

function hideBonusesInGroup(name, data)
  if self.selectedLine then
    if data.type == "group" then
      local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
      local isChecked = widget.getChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. "." .. name)
      self.irden.bonusGroups[data.name].hidden = isChecked
    end
    loadBonuses()
  end
end

function changeBonusLayout(name, data)
  local isDisplayingBonuses = widget.active("lytMisc.lytBonuses")
  widget.setVisible("lytMisc.lytBonuses", not isDisplayingBonuses)
  widget.setVisible("lytMisc.lytAddNewSkill", isDisplayingBonuses)

  if data then
    self.currentGroup = data.name
  end
end




function changeHp()
  local maxHp = 20 + addBonusToStat(self.irden["stats"]["endurance"], "END")
  local oldHP = (self.irden.currentHp or 0) / maxHp

  self.irden.currentHp = tonumber(widget.getText("lytCharacter.tbxCurrentHp")) or 0
  local newValue = self.irden.currentHp / maxHp

  if (newValue ~= oldHP or not self.firstDraw) then
    local aPrgCurrentHp = AnimatedWidget:bind("lytCharacter.prgCurrentHp")
    animatedWidgets:add(aPrgCurrentHp:process(oldHP, newValue, 1))
    self.firstDraw = true
  end
  
  local third = maxHp / 3
  local partImage = self.irden.currentHp >= maxHp and "" or (self.irden.currentHp == 0 and "0" or (self.irden.currentHp < third and "3" or (self.irden.currentHp > 2 * third and "1" or "2")))

  widget.setImage("lytCharacter.imgStatHp", string.format("/interface/scripted/irdenstatmanager/staticons/end%s.png", partImage))
end

function roll20(_, dice)
  sendMessageToServer("statmanager", {
    type = "diceroll", 
    dice = tonumber(widget.getText("lytCharacter.tbxStatRollany")) or 0,
    rgseed = util.seedTime(),
    source = world.entityName(player.id())
  })
end

function rollStat(_, data)
  local description = widget.getText("lytCharacter.tbxSkillName")
  sendMessageToServer("statmanager", {
    type = "statroll", 
    dice = 20,
    rgseed = util.seedTime(),
    action = description ~= "" and description or data.name,
    source = world.entityName(player.id()),
    bonuses = getBonuses({"ALL", data.tag}, self.irden.stats[data.stat], data.tag)
  })
end

function statChange(widgetName, statName)
  self.irden["stats"][statName] = tonumber(widget.getText("lytCharacter." .. widgetName)) or 0
  setHealthAndArmor()
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", 20 + addBonusToStat(self.irden["stats"]["endurance"], "END")))
  self.irden.currentHp = 20 + self.irden["stats"]["endurance"]
end

function gearChange(id, data)
  self.irden["gear"][data.kind][data.type] = id
  if (data.movementBonus) then
    world.sendEntityMessage(player.id(), "irdenGetArmourMovement", getBonusByTag(data.movementBonus).value)
  end
  setHealthAndArmor()
end

function changeTab(id, data)
	for _, tab in ipairs(self.tabs) do
		widget.setVisible(tab, false)
	end
	widget.setVisible(data, true)
end

function showAddAttackLayout(_, data)
  changeAttackType(_, {layout = "lytAddNewAttack"})
  widget.setSelectedOption("lytAttacks.lytAddNewAttack.rgAttackType", data)
end

function changeAttackType(id, data)
  for _, attackType in ipairs(self.attackTypes) do
		widget.setVisible("lytAttacks.lyt" .. attackType .. "Attack", false)
	end
	widget.setVisible("lytAttacks." .. data.layout, true)
end

function changeBonusType(id, data)
  for _, gearType in ipairs({"lytBaseBonuses", "lytCustomBonuses", "lytStuffBonuses", "lytActionsBonuses"}) do
		widget.setVisible("lytMisc.lytBonuses." .. gearType, false)
	end
	widget.setVisible("lytMisc.lytBonuses." .. data, true)
end

function lineSelected(listName)
  local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
  self.selectedLine = widget.getListSelected("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses." .. listName)
end



function attack(btnName, data)

  -- Calculate the attack bonus
  local baseAttackBonus = self.irden.stats[self.characterStats[data.stat]] or 0
  local weaponAttackBonus = getBonusByTag(widget.getData("lytArmory.rg" .. data.type .. "Weapons." .. self.irden["gear"]["weapon"][data.type]).attackBonus).value
  local armourAttackBonus = 0
  local attackBonus = getBonusByTag(data.attackBonus).value
  local damageBonus = getBonusByTag(data.damageBonus).value

  local baseDamageBonus = math.max((addBonusToStat(baseAttackBonus, data.stat) + addBonusToStat(self.irden.stats[self.characterStats[data.dmgStat]] or 0, data.dmgStat)) // data.dmgDivider, 1)
  local weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.rg" .. data.type .. "Weapons." .. self.irden["gear"]["weapon"][data.type]).damageBonus).value
  local shieldDamageBonus = getBonusByTag(widget.getData("lytArmory.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus).value

  if data.type == "ranged" and widget.getChecked("lytArmory.cbxIsAutomatic") then
    baseDamageBonus = 0
    weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.rgrangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage).value
  end
  
  local damageBonuses = nil
  if not data.noDamage then
    damageBonuses = getBonuses({"DAMAGE"}, baseDamageBonus, "База", weaponDamageBonus, "Оружие", damageBonus, "Атака", shieldDamageBonus, "Щит")
  end

  self.attackDataToSend = {
    type = "actionroll", 
    dice = 20,
    rgseed = util.seedTime(),
    source = world.entityName(player.id()),
    action = data.desc,
    attackType = data.type,
    bonuses = getBonuses({"ATTACK", table.unpack(data.tags)}, baseAttackBonus, data.stat, weaponAttackBonus, "Оружие", attackBonus, "Атака"),
    damageBonuses = damageBonuses
  }

  --dirty hack after dropping bonuses
  if btnName == "btnRangedPiercing" then
    local rangedPiercingDebuff = findIndexAtValue(self.irden.bonusGroups["Общие"].bonuses, "name", "Бывший пробивной выстрел")
    if rangedPiercingDebuff then
      widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonusGroups["Общие"].bonuses[rangedPiercingDebuff].listId .. ".bonusIsActive", true)
      self.irden.bonusGroups["Общие"].bonuses[rangedPiercingDebuff].ready = true
    end
  end

  widget.setVisible("lytWhoAttack", true)
  populatePlayers()
  widget.setVisible("lytAttacks", false)
end

function populatePlayers()
  widget.clearListItems("lytWhoAttack.saPlayers.listPlayers")
  local players = world.playerQuery(world.entityPosition(player.id()), 100, {
    withoutEntityId = player.id(),
    order = "nearest",
    boundMode = "position"
  })

  -- Sort by name
  for k, p_id in ipairs(players) do
    players[k] = {
      id = p_id,
      name = world.entityName(p_id)
    }
  end

  table.sort(players, function(a, b) return a.name < b.name end)

  local li = widget.addListItem("lytWhoAttack.saPlayers.listPlayers")
  widget.setText("lytWhoAttack.saPlayers.listPlayers." .. li .. ".playerName", "Никто")
  
  for _, p in ipairs(players) do
    local li = widget.addListItem("lytWhoAttack.saPlayers.listPlayers")
    drawIcon("lytWhoAttack.saPlayers.listPlayers." .. li .. ".contactAvatar", p.id)
    widget.setText("lytWhoAttack.saPlayers.listPlayers." .. li .. ".playerName", p.name)
    widget.setData("lytWhoAttack.saPlayers.listPlayers." .. li, p.id)
  end

end

function drawIcon(canvasName, id)
	local playerCanvas = widget.bindCanvas(canvasName)
	local playerPortrait = world.entityPortrait(id, "bust")
	playerCanvas:clear()
	for _, layer in ipairs(playerPortrait) do
		playerCanvas:drawImage(layer.image, {-14, -18})
	end
end

function playerSelected(listName)
  local li = widget.getListSelected("lytWhoAttack.saPlayers.listPlayers")
  if li then
    local id = widget.getData("lytWhoAttack.saPlayers.listPlayers." .. li)
    
    self.attackDataToSend.target = id and world.entityName(id) or nil
    sendMessageToServer("statmanager", self.attackDataToSend)
  
    if id then
      local msg = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
      msg.defensePlayer = player.id()
      msg.attackDesc = self.attackDataToSend.action
      msg.attackType = self.attackDataToSend.attackType == "melee" and -1 or (self.attackDataToSend.attackType == "ranged" and 0 or 1)
      world.sendEntityMessage(id, "irdenInteract", _, msg)
    end
    
    widget.setVisible("lytWhoAttack", false)
    widget.setVisible("lytAttacks", true)
  end
end


function defense(btnName, data)

  local defenseParts = { self.irden.stats[data.defense_stat], data.stat_desc, 
    getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").defenseBonus).value, "Броня", getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").defenseBonus).value, "Амулет" }

  if has_value(data.tags, "PARRY") or has_value(data.tags, "BLOCK") then
    table.insert(defenseParts, getBonusByTag(widget.getSelectedData("lytArmory.rgShields").defenseBonus).value)
    table.insert(defenseParts, "Щит")
  end  
  
  sendMessageToServer("statmanager", {
    type = "actionroll", 
    dice = 20,
    rgseed = util.seedTime(),
    source = world.entityName(player.id()),
    target = self.defensePlayer and world.entityName(self.defensePlayer) or nil,
    action = widget.getData("lytAttacks." .. widget.getSelectedData("lytAttacks.rgAttackTypes").layout .. "." .. btnName).desc,
    bonuses = getBonuses({"DEFENSE", table.unpack(data.tags)}, table.unpack(defenseParts))
  })
end


function getBonuses (dataTags, ...)
  local bonuses = {}
  local sum = 0
  local args = {...}
  for i = 1, #args, 2 do
    if args[i] ~= 0 then
      table.insert(bonuses, args[i])
      table.insert(bonuses, args[i + 1])
      sum = sum + args[i]
    end
  end
  

  for groupName, group in pairs(self.irden.bonusGroups) do
    for i, bonus in ipairs(group.bonuses) do
      local bonusType = group.isCustom and "lytCustomBonuses" or "lytBaseBonuses"
      if bonus.ready and has_value(dataTags, bonus.tag) then
        table.insert(bonuses, bonus.value)
        table.insert(bonuses, bonus.name)
        sum = sum + bonus.value
        if bonus.oneTimed then
          widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", false)
          widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusName", "white")
          self.irden.bonusGroups[groupName].bonuses[i].ready = false
        end
      end
    end
  end

  return bonuses
end

function getBonusByTag(tag) 
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

function getActiveBonusesByTags(tags)
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


function clearBonuses()
  self.irden.bonusGroups = sb.jsonMerge(self.irden.bonusGroups, root.assetJson("/irden_bonuses.config")) 
  setHealthAndArmor()
  loadBonuses()
  loadAttacks()
end

function setHealthAndArmor()
  widget.setText("lytCharacter.tbxCurrentHp", self.irden.currentHp)
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", 20 + addBonusToStat(self.irden["stats"]["endurance"], "END")))
  local physArmour = addBonusToStat(getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").armourBonus).value, "ARM")
  local magArm = addBonusToStat(getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").blockBonus).value, "MAGARM")

  widget.setText("lytCharacter.lblArmour", string.format("Броня: %s / %s", physArmour, magArm))
  widget.setProgress("lytCharacter.prgCurrentArmour", physArmour / (magArm + physArmour) )
  changeHp()
  setResourseAttempts()
end

function addBonusToStat(base, stat)
  for groupName, bonusGroup in pairs(self.irden.bonusGroups) do
    for _, bonus in ipairs(bonusGroup.bonuses) do
      if bonus.tag == stat and bonus.ready then
        base = base + bonus.value
      end
    end
  end

  return base
end

--[[
  Fight scene functions
]]

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
    player.setProperty("irdeninitiative", calculateBonuses(initiative, bonuses))
  end



  if self.irden.fightName and self.irden.fightName ~= "" then
    promises:add(world.findUniqueEntity("irdenfighthandler_" .. self.irden.fightName), function(pos)
      -- we are already in a fight
      player.setProperty("irdenfightName", self.irden.fightName)

      promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.irden.fightName, "getFight"), function(currentFight)
        if not currentFight.players[player.uniqueId()] then
          rollInitiative()
        else
          sendMessageToServer("statmanager", {
            type = "return_to_fight",
            fightName = self.irden.fightName,
            initiative = currentFight.players[player.uniqueId()].initiative
          })
        end
        
        player.startQuest("irdeninitiative")
      end)
    end, function(error)
      rollInitiative()
      player.startQuest("irdeninitiative")
    end)
  end
end

function leaveFight()
  player.setProperty("irdenfightName", self.irden.fightName)
  widget.setText("lytCharacter.tbxFightName", "")
  self.irden.fightName = nil
  world.sendEntityMessage(player.id(), "leaveFight")
end

function clearFight()
  player.setProperty("irdenfightName", self.irden.fightName)
  world.sendEntityMessage(player.id(), "clearFight")
end

function nextTurn()
  player.setProperty("irdenfightName", self.irden.fightName)
  world.sendEntityMessage(player.id(), "nextTurn", player.uniqueId())
end



function resources(_, data)
  local type = data.type

  sendMessageToServer("statmanager", {
    type = "resourceEvent", 
    rgseed = util.seedTime(),
    action = data.action,
    source = world.entityName(player.id()),
    bonuses = getBonuses({"ALL", table.unpack(data.tags)}, self.irden.stats[self.characterStats[data.stat]], data.stat),
    data = data
  })
end


function showCurrentPlayer()
  player.setProperty("toShowCurrentPlayerIndicator", widget.getChecked("lytCharacter.btnShowCurrentPlayer"))
end

--[[ 
  Custom attacks
]]

function addAttack()
  local attackName = widget.getText("lytAttacks.lytAddNewAttack.tbxAttackName")
  if attackName and attackName ~= "" then
    local stat = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackTags")
    local dmgStat = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgDamageTags")
    local type = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackType")
    local newBonusTag = "CUST_ATTACK_" .. attackName .. "_" .. math.random(1000)
    local noDamage = widget.getChecked("lytAttacks.lytAddNewAttack.btnShouldHaveNoDamage")
    
    if not self.irden.bonusGroups["Особые атаки"] then
      self.irden.bonusGroups["Особые атаки"] = {
        isCustom = false,
        type = "actions",
        bonuses = {}
      }
    end

    if not self.irden.attacks then self.irden.attacks = {} end

    table.insert(self.irden.attacks, {
      type = type,
      desc = attackName,
      stat = stat,
      dmgStat = dmgStat,
      dmgDivider = tonumber(widget.getText("lytAttacks.lytAddNewAttack.tbxDamageDivider")) or 1,
      attackBonus = newBonusTag .. "_ATTACK",
      damageBonus = newBonusTag .. "_DAMAGE",
      tags = {"ALL", stat},
      noDamage = noDamage
    })


    if not noDamage then
      table.insert(self.irden.bonusGroups["Особые атаки"].bonuses, {
        name = attackName .. ": попадание",
        value = 0,
        tag = newBonusTag .. "_ATTACK",
        ready = true
      })
      table.insert(self.irden.bonusGroups["Особые атаки"].bonuses, {
        name = attackName .. ": урон",
        value = 0,
        tag = newBonusTag .. "_DAMAGE",
        ready = true
      })
    else
      table.insert(self.irden.bonusGroups["Особые атаки"].bonuses, {
        name = attackName,
        value = 0,
        tag = newBonusTag .. "_ATTACK",
        ready = true
      })
    end


    loadBonuses()
    loadAttacks()

    widget.setText("lytAttacks.lytAddNewAttack.tbxAttackName", "")
    changeAttackType(_, {layout = widget.getSelectedData("lytAttacks.rgAttackTypes").layout})
  end
end

function showMovement()
  self.movementType = (self.movementType % 3) + 1
  world.sendEntityMessage(player.id(), "irdenStatManagerToShowMovement", self.movementType)
  widget.setButtonImages("lytCharacter.btnShowMovement", {
    base = string.format("/interface/scripted/irdenstatmanager/staticons/movement%s.png", self.movementType),
    hover = string.format("/interface/scripted/irdenstatmanager/staticons/movement%s.png?brightness=-20", self.movementType)
  })

  if self.movementType > 2 then
    self.tech = player.equippedTech("legs")
    player.makeTechAvailable("irdenstatmanager")
    player.enableTech("irdenstatmanager")
    player.equipTech("irdenstatmanager")
  end
end


function changeNewBonus(_, data)
  widget.setText("lytMisc.lytAddNewSkill.lblBonusType", data.tooltip.name)
end


--[[
  Util Functions
]]

function calculateBonuses(value, bonuses)
  local sum = value
  for i = 1, #bonuses, 2 do
    sum = sum + bonuses[i]
  end
  return sum
end

function findIndexAtValue(t, attr, value)
  for i, v in ipairs(t) do
    if v[attr] == value then
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


function planetTime()
  local n = world.timeOfDay()
  local t = n * 24 * 3600
  local hours = t / 3600
  local minutes = (t / 60) % 60
  return (hours + 6) % 24, minutes
end

function printTime()
  hour, minute = planetTime()
	hour = string.format("%02d", math.floor(hour))
	minute = string.format("%02d", math.floor(minute))
  
  widget.setText("lytCharacter.lblResult", ""..hour..":"..minute)

end


function sendMessageToServer(message, data)
  data.silent = widget.getChecked("lytCharacter.btnOutloud")
  world.sendEntityMessage(0, message, data)
end


function update()
	printTime()
  animatedWidgets:update()
  promises:update()
end



function cursorOverride(screenPosition)
  if self.tooltipCanvas then
    self.tooltipCanvas:clear()
    widget.clearListItems("lytActiveBonuses.listActiveBonuses")
    local w = widget.getChildAt(screenPosition)

    if w then
      w = w:sub(2)
      local wData = widget.getData(w) or {}

      if type(wData) == "table" then

        if wData.activeBonuses then 
          drawActiveBonuses(wData.activeBonuses)
        end

        if wData.tooltip then
          local tooltip = wData.tooltip
          local wPos = widget.getPosition(w)
  
          self.tooltipCanvas:drawImage(tooltip.image, vec2.add(wPos, tooltip.imageOffset))
          self.tooltipCanvas:drawText(tooltip.name, {
            position = vec2.add(wPos, tooltip.labelOffset),
            verticalAnchor = "mid",
            horizontalAnchor = "mid"
          }, tooltip.fontSize)
        end 
      end

    end
  end
end

function drawActiveBonuses(data)
  local bonuses = getActiveBonusesByTags(data.tags)
  
  if has_value(data.tags, "ATTACK") then
    local attackType = widget.getSelectedData("lytAttacks.rgAttackTypes").type

    local weaponBonus = getBonusByTag(widget.getData("lytArmory.rg" .. attackType .. "Weapons." .. self.irden["gear"]["weapon"][attackType]).damageBonus).value
  
    if attackType == "ranged" and widget.getChecked("lytArmory.cbxIsAutomatic") then
      weaponBonus = getBonusByTag(widget.getData("lytArmory.rgrangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage).value
    end

    if weaponBonus ~= 0 then
      table.insert(bonuses, {
        name = "Урон оружия",
        value = weaponBonus
      })
    end

  elseif has_value(data.tags, "DEFENSE") then
    local armourBonus = getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").defenseBonus).value
    local amuletBonus = getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").defenseBonus).value

    if armourBonus ~= 0 then
      table.insert(bonuses, {
        name = "Броня",
        value = armourBonus
      })
    end
    if amuletBonus ~= 0 then
      table.insert(bonuses, {
        name = "Амулет",
        value = amuletBonus
      })
    end

    if has_value(data.tags, "PARRY") or has_value(data.tags, "BLOCK") then
      local shieldBonus = getBonusByTag(widget.getSelectedData("lytArmory.rgShields").defenseBonus).value
      if shieldBonus ~= 0 then
        table.insert(bonuses, {
          name = "Щит",
          value = shieldBonus
        })
      end
    end
  end


  for _, bonus in ipairs(bonuses) do 
    local li = widget.addListItem("lytActiveBonuses.listActiveBonuses")
    local bonusName = not not string.find(bonus.name, ": попадание") and "Попадание" or bonus.name
    bonusName = not not string.find(bonusName, ": урон") and "Урон" or bonusName
    widget.setText("lytActiveBonuses.listActiveBonuses." .. li .. ".bonusName", "* " .. bonusName)
    widget.setText("lytActiveBonuses.listActiveBonuses." .. li .. ".bonusValue", string.format('%s%d', bonus.value > 0 and "+" or "", bonus.value))
  end
end

function sortedKeys(query)
  local keys = {}
  for k,v in pairs(query) do
    table.insert(keys, k)
  end
  
  table.sort(keys)
  return keys
end



function uninit()
  self.irden["gear"].isAutomatic = widget.getChecked("lytArmory.cbxIsAutomatic")
  player.setProperty("irden", self.irden)

  if player.equippedTech("legs") and player.equippedTech("legs") == "irdenstatmanager" then
    player.unequipTech("irdenstatmanager")
    player.makeTechUnavailable("irdenstatmanager")
    world.sendEntityMessage(player.id(), "irdenStatManagerToShowMovement", 0)
    if self.tech and self.tech ~= "irdenstatmanager" then
      player.equipTech(self.tech)
    end
  end
end