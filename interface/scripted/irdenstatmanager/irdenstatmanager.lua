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
  
  loadPreview()
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
    self.irden.bonuses = config.getParameter("bonuses")
    self.irden.currentHp = 20
  else
    local cHp = self.irden.currentHp
	  loadStats(self.irden["stats"])
    self.irden.currentHp = cHp
  end

  loadBonuses(self.irden["bonuses"])
  loadWeapons(self.irden["gear"])

  setHealthAndArmor()

  self.tooltipCanvas = widget.bindCanvas("tooltipCanvas")
end

function loadPreview()
	widget.setText("lytCharacter.lblName", world.entityName(player.id()))
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
  widget.clearListItems("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses")
  for i, bonus in ipairs(self.irden.bonuses) do
    local bonusType = bonus.isCustom and "lytCustomBonuses" or "lytBaseBonuses"
    local li = widget.addListItem("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses")
    widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
    widget.setData("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
    widget.setText("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusValue", bonus.value)
    widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusIsActive", bonus.ready)
    self.irden.bonuses[i].listId = li

    if bonus.ready then
      widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", "yellow")
    end
  end
end

function setBonus(name)
  if self.selectedLine then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    
    self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "listId", self.selectedLine)].ready = widget.getChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusIsActive")
    if widget.getChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusIsActive") then
      widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusName", "yellow")
    else
      widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusName", "white")
    end
  end

 setHealthAndArmor()
end

function deleteBonus(name)
  if self.selectedLine then
    local selectedTab = widget.getSelectedData("lytMisc.lytBonuses.rgBonusTypes")
    
    table.remove(self.irden.bonuses, findIndexAtValue(self.irden.bonuses, "listId", self.selectedLine))
    loadBonuses()
  end

 setHealthAndArmor()
end

function changeHp()
  local oldHP = (self.irden.currentHp or 0) / (20 + self.irden["stats"]["endurance"])

  self.irden.currentHp = tonumber(widget.getText("lytCharacter.tbxCurrentHp")) or 0
  local newValue = self.irden.currentHp / (20 + self.irden["stats"]["endurance"])

  if (newValue ~= oldHP or not self.firstDraw) then
    local aPrgCurrentHp = AnimatedWidget:bind("lytCharacter.prgCurrentHp")
    animatedWidgets:add(aPrgCurrentHp:process(oldHP, newValue, 1))
    self.firstDraw = true
  end
end

function roll20(_, dice)
  world.setProperty("statmanager", {
    type = "diceroll", 
    dice = self.irden["stats"]["rollany"],
    rgseed = util.seedTime(),
    source = world.entityName(player.id())
  })
end

function rollStat(_, data)
  world.setProperty("statmanager", {
    type = "statroll", 
    dice = 20,
    rgseed = util.seedTime(),
    action = data.name,
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
  handleSpecificGears(id, data.kind, data.type)
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
  for _, gearType in ipairs({"lytBaseBonuses", "lytCustomBonuses"}) do
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

function handleSpecificGears(id, kind, type)
  function enableDodge(isEnabled)
    --[[
    widget.setButtonEnabled("lytAttacks.lytMeleeAttack.btnMeleeDodge", isEnabled)
    widget.setButtonEnabled("lytAttacks.lytRangedAttack.btnRangedDodge", isEnabled)
    widget.setButtonEnabled("lytAttacks.lytMagicAttack.btnRangedDodge", isEnabled)
    ]]
  end

  -- 1. Melee weapons
  if type == "melee" then
    if id == "1" then -- Middle weapon
      widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", -1)
    elseif id == "2" then
      widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", -1)
      widget.setSelectedOption("lytArmory.lytDefense.rgShields", -1) -- No Sheild
    end
  elseif type == "ranged" then
  
    if findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение") then
      widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение")].listId .. ".bonusIsActive", false)
      self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение")].ready = false
    end

    if id == "1" then -- Middle weapon
      widget.setSelectedOption("lytArmory.lytWeapons.rgMeleeWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", -1)
    elseif id == "2" then
      widget.setSelectedOption("lytArmory.lytWeapons.rgMeleeWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", -1)
      widget.setSelectedOption("lytArmory.lytDefense.rgShields", -1) -- No Sheild
      
      if findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение") then
      
        widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение")].listId .. ".bonusIsActive", true)
        self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Тяжёлое оружие - уклонение")].ready = true
      end
      
    end

  elseif type == "magic" then
    if id == "1" then -- Middle weapon
      widget.setSelectedOption("lytArmory.lytWeapons.rgMeleeWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", -1)
      widget.setSelectedOption("lytArmory.lytDefense.rgShields", -1) -- No Sheild
    elseif id == "2" then
      widget.setSelectedOption("lytArmory.lytWeapons.rgMeleeWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", -1)
      widget.setSelectedOption("lytArmory.lytDefense.rgShields", -1) -- No Sheild
    end
    --[[
  elseif type == "shield" then
    if id == "2" then
      widget.setSelectedOption("lytArmory.lytWeapons.rgRangedWeapons", -1)
      widget.setSelectedOption("lytArmory.lytWeapons.rgMagicWeapons", -1)
      enableDodge(false)
    end
  ]]--
  elseif type == "armour" then
    if id == "2" then
      enableDodge(false)
    end
  elseif type == "amulet" then
    if id == "2" then
      enableDodge(false)
    end
  end
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
  local attackBonus = data.attackBonus
  local damageBonus = data.damageBonus

  local baseDamageBonus = 0
  local weaponDamageBonus = 0
  local shieldDamageBonus = 0
  local stat = ""


  if data.type == "melee" then
    stat = "STR"
    baseAttackBonus = self.irden.stats.strength
    weaponAttackBonus = widget.getData("lytArmory.lytWeapons.rgMeleeWeapons." .. self.irden["gear"]["weapon"]["melee"]).attackBonus

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.strength, "STR") + addBonusToStat(self.irden.stats.endurance, "END")) // 4, 1)
    weaponDamageBonus = widget.getData("lytArmory.lytWeapons.rgMeleeWeapons." .. self.irden["gear"]["weapon"]["melee"]).damageBonus
    shieldDamageBonus = widget.getData("lytArmory.lytDefense.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus
  elseif data.type == "ranged" then
    stat = "PER"
    baseAttackBonus = self.irden.stats.perception
    weaponAttackBonus = widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).attackBonus

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.reflexes, "REF") + addBonusToStat(self.irden.stats.perception, "PER")) // 4, 1)
    weaponDamageBonus = widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).damageBonus
    shieldDamageBonus = widget.getData("lytArmory.lytDefense.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus

    if widget.getChecked("lytArmory.lytWeapons.cbxIsAutomatic") then
      baseDamageBonus = 0
      weaponDamageBonus = widget.getData("lytArmory.lytWeapons.rgRangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage
    end

  elseif data.type == "magic" then
    stat = "MAG"
    baseAttackBonus = self.irden.stats.magic
    weaponAttackBonus = widget.getData("lytArmory.lytWeapons.rgMagicWeapons." .. self.irden["gear"]["weapon"]["magic"]).attackBonus

    baseDamageBonus = math.max((addBonusToStat(self.irden.stats.magic, "MAG") + addBonusToStat(self.irden.stats.willpower, "WIL")) // 4, 1)
    weaponDamageBonus = widget.getData("lytArmory.lytWeapons.rgMagicWeapons." .. self.irden["gear"]["weapon"]["magic"]).damageBonus
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
    widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Бывший пробивной выстрел")].listId .. ".bonusIsActive", true)
    self.irden.bonuses[findIndexAtValue(self.irden.bonuses, "name", "Бывший пробивной выстрел")].ready = true
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
      world.sendEntityMessage(id, "irdenInteract","ScriptPane", msg)
    end
    
    widget.setVisible("lytWhoAttack", false)
    widget.setVisible("lytAttacks", true)
  end
end


function defense(btnName, data)

  local defenseParts = { self.irden.stats[data.defense_stat], data.stat_desc, 
  widget.getSelectedData("lytArmory.lytDefense.rgArmour").defenseBonus, "Броня", widget.getSelectedData("lytArmory.lytDefense.rgAmulets").defenseBonus, "Амулет" }

  if has_value(data.tags, "PARRY") or has_value(data.tags, "BLOCK") then
    table.insert(defenseParts, widget.getSelectedData("lytArmory.lytDefense.rgShields").defenseBonus)
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
  

  for i, bonus in ipairs(self.irden.bonuses) do
    local bonusType = bonus.isCustom and "lytCustomBonuses" or "lytBaseBonuses"
    if widget.getChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive") and has_value(dataTags, bonus.tag) then
      table.insert(bonuses, bonus.value)
      table.insert(bonuses, bonus.name)
      sum = sum + bonus.value
      if bonus.oneTimed then
        widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", false)
        self.irden.bonuses[i].ready = false
      end
    end
  end

  return bonuses
end

function printResult (dataTags, ...)
  local str = ""
  local sum = 0
  local args = {...}
  for i = 1, #args, 2 do
    if args[i] ~= 0 then
      str = str .. string.format("%s%s^gray;[%s]^reset; ", args[i] >= 0 and "+" or "", args[i], args[i + 1])
      sum = sum + args[i]
    end
  end
  

  for i, bonus in ipairs(self.irden.bonuses) do
    local bonusType = bonus.isCustom and "lytCustomBonuses" or "lytBaseBonuses"
    if widget.getChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive") and has_value(dataTags, bonus.tag) then
      str = str .. string.format("%s%s^gray;[%s]^reset; ", bonus.value >= 0 and "+" or "", bonus.value, bonus.name)
      sum = sum + bonus.value
      if bonus.oneTimed then
        widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", false)
        self.irden.bonuses[i].ready = false
      end
    end
  end

  str = str .. string.format("= ^yellow;%s^reset;", math.max(sum, 1))

  return str
end

function dropBonuses()
  for i, bonus in ipairs(self.irden.bonuses) do
    if bonus.oneTimed then
      local bonusType = bonus.isCustom and "lytCustomBonuses" or "lytBaseBonuses"
      widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", false)
      self.irden.bonuses[i].ready = false
    end
  end
end

function addSkill()
  if widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillName"):len() > 0 and widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillValue"):len() > 0 then
    local bonus = {}

    bonus.name = widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillName")
    bonus.value = tonumber(widget.getText("lytMisc.lytAddNewSkill.tbxNewSkillValue"))
    bonus.oneTimed = not widget.getChecked("lytMisc.lytAddNewSkill.cbxIsPermanent")
    bonus.isCustom = true
    bonus.ready = true
    bonus.tag = widget.getSelectedData("lytMisc.lytAddNewSkill.rgBonusTags")

    local li = widget.addListItem("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses")
    widget.setText("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
    widget.setData("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
    widget.setFontColor("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses." .. li .. ".bonusName", "yellow")
    widget.setText("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses." .. li .. ".bonusValue", bonus.value)
    widget.setChecked("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses." .. li .. ".bonusIsActive", bonus.ready)

    bonus.listId = li

    table.insert(self.irden.bonuses, bonus)
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillName", "")
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillValue", "")

    widget.setVisible("lytMisc.lytBonuses", true)
    widget.setVisible("lytMisc.lytAddNewSkill", false)
    widget.setText("lytMisc.btnChangeLayout", "Добавить")
    setHealthAndArmor()
  end
end


function changeBonusLayout()
  local isDisplayingBonuses = widget.active("lytMisc.lytBonuses")
  widget.setVisible("lytMisc.lytBonuses", not isDisplayingBonuses)
  widget.setVisible("lytMisc.lytAddNewSkill", isDisplayingBonuses)
  widget.setText("lytMisc.btnChangeLayout", isDisplayingBonuses and "Бонусы" or "Добавить")
end

function clearSkills()
  self.irden.bonuses = config.getParameter("bonuses")
  setHealthAndArmor()
  loadBonuses(self.irden["bonuses"])
end

function setHealthAndArmor()
  widget.setText("lytCharacter.tbxCurrentHp", self.irden.currentHp)
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", 20 + addBonusToStat(self.irden["stats"]["endurance"], "END")))
  local physArmour = addBonusToStat(widget.getSelectedData("lytArmory.lytDefense.rgArmour").armourBonus, "ARM")
  local magArm = addBonusToStat(widget.getSelectedData("lytArmory.lytDefense.rgAmulets").blockBonus, "MAGARM")

  widget.setText("lytCharacter.lblArmour", string.format("Броня: %s / %s", physArmour, magArm))
  adjustArmourPG(physArmour, magArm)
end

function adjustArmourPG(p, m)
  widget.setProgress("lytCharacter.prgCurrentArmour", p / (m + p) )
end

function addBonusToStat(base, stat)
  for _, bonus in ipairs(self.irden.bonuses) do
    if bonus.tag == stat and bonus.ready then
      base = base + bonus.value
    end
  end

  return base
end





function uninit()
  self.irden["gear"].isAutomatic = widget.getChecked("lytArmory.lytWeapons.cbxIsAutomatic")
  player.setProperty("irden", self.irden)
end


--Util
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