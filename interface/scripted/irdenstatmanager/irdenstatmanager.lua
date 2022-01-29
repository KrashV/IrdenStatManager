require "/scripts/util.lua"
require "/interface/scripted/animatedWidgets.lua"

function init()
  math.randomseed(util.seedTime())

  

  widget.registerMemberCallback("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "deleteBonus", deleteBonus)

  self.irden = player.getProperty("irden")

  self.characterStats = config.getParameter("characterStats")
  self.tabs = config.getParameter("tabs")
  self.attackTypes = {"Melee", "Ranged", "Magic"}
  self.selectedLine = nil

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

function loadStats(stats)
  for widgetName, statName in pairs(self.characterStats) do
	  widget.setText("lytCharacter." .. widgetName, stats[statName] or "0")
  end
end

function loadWeapons(gear)
  widget.setSelectedOption("lytArmory.lytWeapons.rgMeleeWeapons", gear["weapon"]["melee"])
  widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", gear["weapon"]["ranged"])
  widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", gear["weapon"]["magic"])

  widget.setSelectedOption("lytArmory.lytDefense.rgArmour", gear["armour"]["armour"])
  widget.setSelectedOption("lytArmory.lytDefense.rgShields", gear["armour"]["shield"])
  widget.setSelectedOption("lytArmory.lytDefense.rgAmulets", gear["armour"]["amulet"])
  widget.setChecked("lytArmory.lytWeapons.cbxIsAutomatic", not not self.irden["gear"].isAutomatic)
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
        widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusValue", bonus.value)
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
      self.irden.bonusGroups[data.group].bonuses[findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "listId", self.selectedLine)].ready = isChecked
      widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusName", isChecked and "yellow" or "white")
    end
  end

 setHealthAndArmor()
end

function deleteBonus(_, data)
  if self.selectedLine then
    if data.type == "group" then
      self.irden.bonusGroups[data.name] = nil
    elseif data.type == "bonus" then
      table.remove(self.irden.bonusGroups[data.group].bonuses, findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "listId", self.selectedLine))
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
    local value = self.irden.bonusGroups[data.group].bonuses[index].value
    self.irden.bonusGroups[data.group].bonuses[index].value = value + 1
    widget.setText("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusValue", value + 1)
    setHealthAndArmor()
  end
end

function changeBonus.down(_, data)
  if self.selectedLine and data then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "name", data.bonus)
    local value = self.irden.bonusGroups[data.group].bonuses[index].value
    self.irden.bonusGroups[data.group].bonuses[index].value = value - 1
    widget.setText("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusValue", value - 1)
    setHealthAndArmor()
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
    bonus.tag = widget.getSelectedData("lytMisc.lytAddNewSkill.rgBonusTags")

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
end

function roll20(_, dice)
  world.setProperty("statmanager", {
    type = "diceroll", 
    dice = tonumber(widget.getText("lytCharacter.tbxStatRollany")) or 0,
    rgseed = util.seedTime(),
    source = world.entityName(player.id())
  })
end

function rollStat(_, data)
  local description = widget.getText("lytCharacter.tbxSkillName")
  world.setProperty("statmanager", {
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
  setHealthAndArmor()
end

function changeTab(id, data)
	for _, tab in ipairs(self.tabs) do
		widget.setVisible(tab, false)
	end
	widget.setVisible(data, true)
end

function changeAttackType(id, data)
  for _, attackType in ipairs(self.attackTypes) do
		widget.setVisible("lytAttacks.lyt" .. attackType .. "Attack", false)
	end
	widget.setVisible("lytAttacks." .. data, true)
end

function changeBonusType(id, data)
  for _, gearType in ipairs({"lytBaseBonuses", "lytCustomBonuses", "lytStuffBonuses", "lytActionsBonuses"}) do
		widget.setVisible("lytMisc.lytBonuses." .. gearType, false)
	end
	widget.setVisible("lytMisc.lytBonuses." .. data, true)
end

function changeGearType(id, data)
  for _, gearType in ipairs({"Weapons", "Defense"}) do
		widget.setVisible("lytArmory.lyt" .. gearType, false)
	end
	widget.setVisible("lytArmory." .. data, true)
end

function lineSelected(listName)
  local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
  self.selectedLine = widget.getListSelected("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses." .. listName)
end

function attack(btnName, data)

  -- Calculate the attack bonus
  local baseAttackBonus = 0
  local weaponAttackBonus = 0
  local armourAttackBonus = 0
  local attackBonus = getBonusByTag(data.attackBonus).value
  local damageBonus = getBonusByTag(data.damageBonus).value

  local baseDamageBonus = 0
  local weaponDamageBonus = 0
  local shieldDamageBonus = 0
  local stat = ""


  if data.type == "melee" then
    stat = "STR"
    baseAttackBonus = self.irden.stats.strength
    weaponAttackBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgMeleeWeapons." .. self.irden["gear"]["weapon"]["melee"]).attackBonus).value

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.strength, "STR") + addBonusToStat(self.irden.stats.endurance, "END")) // 4, 1)
    weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgMeleeWeapons." .. self.irden["gear"]["weapon"]["melee"]).damageBonus).value
    shieldDamageBonus = getBonusByTag(widget.getData("lytArmory.lytDefense.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus).value
  elseif data.type == "ranged" then
    stat = "PER"
    baseAttackBonus = self.irden.stats.perception
    weaponAttackBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).attackBonus).value

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.reflexes, "REF") + addBonusToStat(self.irden.stats.perception, "PER")) // 4, 1)
    weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).damageBonus).value
    shieldDamageBonus = getBonusByTag(widget.getData("lytArmory.lytDefense.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus).value

    if widget.getChecked("lytArmory.lytWeapons.cbxIsAutomatic") then
      baseDamageBonus = 0
      weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage).value
    end

  elseif data.type == "magic" then
    stat = "MAG"
    baseAttackBonus = self.irden.stats.magic
    weaponAttackBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgMagicWeapons." .. self.irden["gear"]["weapon"]["magic"]).attackBonus).value

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.magic, "MAG") + addBonusToStat(self.irden.stats.willpower, "WIL")) // 4, 1)
    weaponDamageBonus = getBonusByTag(widget.getData("lytArmory.lytWeapons.rgMagicWeapons." .. self.irden["gear"]["weapon"]["magic"]).damageBonus).value
    shieldDamageBonus = 0
  end
  
  self.btnName = btnName
  
  self.attackDataToSend = {
    type = "actionroll", 
    dice = 20,
    rgseed = util.seedTime(),
    source = world.entityName(player.id()),
    action = widget.getData("lytAttacks." .. widget.getSelectedData("lytAttacks.rgAttackTypes") .. "." .. btnName).desc,
    bonuses = getBonuses({"ATTACK", table.unpack(data.tags)}, baseAttackBonus, stat, weaponAttackBonus, "Оружие", attackBonus, "Атака"),
    damageBonuses = getBonuses({"DAMAGE"}, baseDamageBonus, "База", weaponDamageBonus, "Оружие", damageBonus, "Атака", shieldDamageBonus, "Щит")
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
  
  local li = widget.addListItem("lytWhoAttack.saPlayers.listPlayers")
  widget.setText("lytWhoAttack.saPlayers.listPlayers." .. li .. ".playerName", "В воздух")
  
  for _, p_id in ipairs(players) do
    local li = widget.addListItem("lytWhoAttack.saPlayers.listPlayers")
    drawIcon("lytWhoAttack.saPlayers.listPlayers." .. li .. ".contactAvatar", p_id)
    widget.setText("lytWhoAttack.saPlayers.listPlayers." .. li .. ".playerName", world.entityName(p_id))
    widget.setData("lytWhoAttack.saPlayers.listPlayers." .. li, p_id)
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
    
    world.setProperty("statmanager", self.attackDataToSend)
  
    if id then
      local msg = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
      msg.defensePlayer = player.id()
      msg.attackDesc = widget.getData("lytAttacks." .. widget.getSelectedData("lytAttacks.rgAttackTypes") .. "." .. self.btnName).desc
      msg.attackType = widget.getSelectedOption("lytAttacks.rgAttackTypes")
      world.sendEntityMessage(id, "irdenInteract", _, msg)
    end
    
    widget.setVisible("lytWhoAttack", false)
    widget.setVisible("lytAttacks", true)
  end
end


function defense(btnName, data)

  local defenseParts = { self.irden.stats[data.defense_stat], data.stat_desc, 
  getBonusByTag(widget.getSelectedData("lytArmory.lytDefense.rgArmour").defenseBonus).value, "Броня", getBonusByTag(widget.getSelectedData("lytArmory.lytDefense.rgAmulets").defenseBonus).value, "Амулет" }

  if has_value(data.tags, "PARRY") or has_value(data.tags, "BLOCK") then
    table.insert(defenseParts, getBonusByTag(widget.getSelectedData("lytArmory.lytDefense.rgShields").defenseBonus).value)
    table.insert(defenseParts, "Щит")
  end  
  
  world.setProperty("statmanager", {
    type = "actionroll", 
    dice = 20,
    rgseed = util.seedTime(),
    source = world.entityName(player.id()),
    target = self.defensePlayer and world.entityName(self.defensePlayer) or nil,
    action = widget.getData("lytAttacks." .. widget.getSelectedData("lytAttacks.rgAttackTypes") .. "." .. btnName).desc,
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


function clearSkills()
  self.irden.bonusGroups = root.assetJson("/irden_bonuses.config")
  setHealthAndArmor()
  loadBonuses()
end

function setHealthAndArmor()
  widget.setText("lytCharacter.tbxCurrentHp", self.irden.currentHp)
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", 20 + addBonusToStat(self.irden["stats"]["endurance"], "END")))
  local physArmour = addBonusToStat(getBonusByTag(widget.getSelectedData("lytArmory.lytDefense.rgArmour").armourBonus).value, "ARM")
  local magArm = addBonusToStat(getBonusByTag(widget.getSelectedData("lytArmory.lytDefense.rgAmulets").blockBonus).value, "MAGARM")

  widget.setText("lytCharacter.lblArmour", string.format("Броня: %s / %s", physArmour, magArm))
  adjustArmourPG(physArmour, magArm)
  changeHp()
end

function adjustArmourPG(p, m)
  widget.setProgress("lytCharacter.prgCurrentArmour", p / (m + p) )
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
  if self.irden.fightName and self.irden.fightName ~= "" then
    local fights = world.getProperty("currentFight") or {}
    local currentFight = fights[self.irden.fightName] or {
      players = {},
      started = false,
      currentPlayer = nil,
      done = false
    }

    local initiative = math.random(20)
    local bonuses = getBonuses({"ALL", "INITIATIVE"}, 0, "INITIATIVE")

    if not currentFight.players[player.uniqueId()] then
      world.setProperty("statmanager", {
        type = "initiative", 
        dice = 20,
        rgseed = util.seedTime(),
        initiative = initiative,
        action = "Инициативы",
        source = world.entityName(player.id()),
        bonuses = bonuses
      })
    end
    
    player.setProperty("irdeninitiative", calculateBonuses(initiative, bonuses))
    player.setProperty("irdenfightName", self.irden.fightName)
    player.startQuest("irdeninitiative")
  end
end

function leaveFight()
  player.setProperty("irdenfightName", self.irden.fightName)
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

  world.setProperty("statmanager", {
    type = "resourceEvent", 
    rgseed = util.seedTime(),
    action = data.action,
    source = world.entityName(player.id()),
    bonuses = getBonuses({"ALL", data.tag}, self.irden.stats[data.stat], data.tag),
    data = data
  })
end


function showCurrentPlayer()
  player.setProperty("toShowCurrentPlayerIndicator", widget.getChecked("lytCharacter.btnShowCurrentPlayer"))
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

function uninit()
  self.irden["gear"].isAutomatic = widget.getChecked("lytArmory.lytWeapons.cbxIsAutomatic")
  player.setProperty("irden", self.irden)
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

function update()
	printTime()
  animatedWidgets:update()
end



function cursorOverride(screenPosition)
  if self.tooltipCanvas then
    self.tooltipCanvas:clear()

    local w = widget.getChildAt(screenPosition)
    if w then
      w = w:sub(2)
      local wData = widget.getData(w) or {}
      if type(wData) ~= "table" or not wData.tooltip then return end

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



function sortedKeys(query)
  local keys = {}
  for k,v in pairs(query) do
    table.insert(keys, k)
  end
  
  table.sort(keys)
  return keys
end