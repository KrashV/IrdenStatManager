require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/timer.lua"
require "/interface/scripted/animatedWidgets.lua"
require "/interface/scripted/irdenstatmanager/irdenutils.lua"
require "/interface/scripted/irdenstatmanager/attacks/ismattack.lua"
require "/interface/scripted/irdenstatmanager/fight/ismfight.lua"
require "/interface/scripted/irdenstatmanager/inventory/isminventory.lua"
require "/interface/scripted/irdenstatmanager/money/ismmoney.lua"
require "/interface/scripted/irdenstatmanager/resources/ismresources.lua"
require "/interface/scripted/irdenstatmanager/fightmanager/fightmanager.lua"


function init()
  math.randomseed(util.seedTime())
  player.setProperty("irden_stat_manager_ui_open", true)

  widget.setButtonEnabled("lytCharacter.btnClearFight", player.isAdmin())
  widget.setButtonEnabled("rgTabs.6", player.isAdmin())
  widget.setVisible("lytCharacter.btnHideStats", player.isAdmin())
  widget.setVisible("lytCharacter.btnEnterFightAsEnemy", player.isAdmin())

  widget.registerMemberCallback("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "setBonus", setBonus)
  widget.registerMemberCallback("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses", "deleteBonus", deleteBonus)
  widget.registerMemberCallback("lytWhoAttack.saPlayers", "playerSelected", playerSelected)

  self.irden = player.getProperty("irden") or {
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

  self.version = config.getParameter("version")
  self.defaultTitle = string.format("%s v%s", config.getParameter("gui").windowtitle.title, self.version)
  self.defaultSubtitle = config.getParameter("gui").windowtitle.subtitle
  pane.setTitle(self.defaultTitle, self.defaultSubtitle)

  self.confirmationLayout = "/interface/scripted/collections/collectionsgui.config:confirmationPaneLayout"

  self.characterStatsTextboxes = config.getParameter("characterStatsTextboxes")
  self.characterStats = config.getParameter("characterStats")
  self.tabs = config.getParameter("tabs")
  self.attackTypes = {"Melee", "Ranged", "Magic", "Other", "AddNew"}
  self.bonusImages = getBonusImages()
  self.selectedLine = nil

  self.movementType = 1
  
  variousFixes()

  self.irden.presets = self.irden.presets or {}
  self.irden.rollMode = tonumber(self.irden.rollMode) or 1
  self.rollModes = {"Broadcast", "Party", "Silent", "Local", "Fight"}
  self.rollModesTranslation = {"Общий", "Пати", "Втихую", "Близкий", "Бой"}

  self.weatherEffects = not not self.irden.weatherEffects
  widget.setChecked("lytCharacter.btnWeather", self.weatherEffects)
  self.irden.bonusGroups = loadCustomBonuses()
  local cHp = self.irden.currentHp
  self.eventStats = {}
  loadResources()
  loadStats(self.irden["stats"])
  self.irden.currentHp = cHp
  fixMyStupidityWithInventory()
  self.editMode = false

  load()

  self.tooltipCanvas = widget.bindCanvas("tooltipCanvas")
  self.positionCanvas = widget.bindCanvas("positionCanvas")

  
  handleOpening()
  createAttackQueue()
end


function load()
  loadPreview()
  loadArmory()
  loadBonuses()
  loadStatBonuses()
  loadButtonsForCustomPane()
  loadAttacks()
  loadWeapons(self.irden["gear"])
  setHealthAndArmor()
  loadInventory()
end

function handleOpening()
--[[
  local attackTypesSelect = {
    melee = -1,
    ranged = 0,
    magic = 1,
    other = 2
  }

  if config.getParameter("defensePlayerId") then 
    local attackType = config.getParameter("attackType")

    self.defensePlayerId = config.getParameter("defensePlayerId")
    self.defensePlayerUuid = config.getParameter("defensePlayerUuid")
    widget.setSelectedOption("lytAttacks.rgAttackTypes", attackTypesSelect[attackType] or -1)
    pane.setTitle(self.defaultTitle, string.format("Вас атакует ^magenta;%s, ^reset;используя ^orange;%s", world.entityName(self.defensePlayerId), config.getParameter("attackDesc")))
    if attackType ~= "other" then
      widget.setSelectedOption("rgTabs", 0)
    end

    
    local attackBonuses = config.getParameter("attackBonuses")
    if attackBonuses then
      for _, effect in ipairs(attackBonuses.effects) do
        local ind = findIndexAtValue(self.irden.bonusGroups["Эффекты"].bonuses, "name", effect)
        if ind then
          self.irden.bonusGroups["Эффекты"].bonuses[ind].ready = true
        end
      end

      for _, bonus in ipairs(attackBonuses.bonuses) do
        local groupName = "^red;Бонусы противников^reset;"
        if not self.irden.bonusGroups[groupName] then 
          self.irden.bonusGroups[groupName] = {
            isCustom = true,
            bonuses = {}
          } 
        end

        -- Save the author's name
        bonus.name = string.format("%s: %s", world.entityName(self.defensePlayerId), bonus.name)
        local ind = findIndexAtValue(self.irden.bonusGroups[groupName].bonuses, "name", bonus.name)
        if not ind then
          bonus.ready = true
          table.insert(self.irden.bonusGroups[groupName].bonuses, bonus)
        else
          self.irden.bonusGroups[groupName].bonuses[ind].ready = true
        end
      end

      load()
      if attackBonuses.isAutomatic then
        pane.dismiss()
      end
    end
  end
]]
end





function variousFixes()

  --Create overrides table
  self.irden.overrides = self.irden.overrides or {
    events = {}
  }

  -- Create crafts table
  self.irden.crafts = self.irden.crafts or {
    END = irdenUtils.getMaxStamina("END"),
    WIL = irdenUtils.getMaxStamina("WIL"),
    INT = irdenUtils.getMaxStamina("INT")
  }

  --Rename Особые атаки to Кастомные атаки
  if self.irden.bonusGroups["Особые атаки"] then 
    self.irden.bonusGroups["Кастомные атаки"] = self.irden.bonusGroups["Особые атаки"]
    self.irden.bonusGroups["Особые атаки"] = nil
  end
  -- Rename Магические
  if self.irden.bonusGroups["Магические атаки"] then 
    self.irden.bonusGroups["Атаки магией"] = self.irden.bonusGroups["Магические атаки"]
    self.irden.bonusGroups["Магические атаки"] = nil
  end
  self.irden.bonusGroups["Атаки магие"] = nil
  -- Rename Магические
  if self.irden.bonusGroups["Действия противника"] then
    self.irden.bonusGroups["Действия противника"] = nil
  end
end


function loadPreview()
	widget.setText("lytCharacter.lblName", world.entityName(player.id()))
  widget.setText("lytCharacter.tbxFightName", self.irden.fightName or "")
  widget.setChecked("lytCharacter.btnHideStats", self.irden.onlySum)
  setRollMode(self.irden.rollMode)
  widget.setChecked("lytCharacter.btnShowCurrentPlayer", player.getProperty("toShowCurrentPlayerIndicator", true))
  widget.setText("lytCharacter.tbxSkillName", "")
	drawCharacter()
end

function drawCharacter()
  local portrait = world.entityPortrait(player.id(), "full")
	for _, part in ipairs(portrait) do
		local li = widget.addListItem("lytCharacter.lstPreview")
		widget.setImage("lytCharacter.lstPreview." .. li .. ".image", part.image)
	end
end

function loadStats(stats)
  for widgetName, statName in pairs(self.characterStatsTextboxes) do
	  widget.setText("lytCharacter." .. widgetName, stats[statName] or "0")
  end
end

function loadStatBonuses()
  local statLabels = config.getParameter("characterStatBonuses")
  for _, lbl in ipairs(statLabels) do
    local bonus = irdenUtils.addBonusToStat(0, widget.getData("lytCharacter." .. lbl).stat)
    widget.setText("lytCharacter." .. lbl, bonus == 0 and "" or (bonus > 0 and "+" .. bonus or bonus))
  end
end

function loadWeapons(gear)
  widget.setSelectedOption("lytArmory.rgmeleeWeapons", gear["weapon"]["melee"])
  widget.setSelectedOption("lytArmory.rgrangedWeapons", gear["weapon"]["ranged"])
  widget.setSelectedOption("lytArmory.rgmagicWeapons", gear["weapon"]["magic"])

  widget.setSelectedOption("lytArmory.rgArmour", gear["armour"]["armour"])
  widget.setSelectedOption("lytArmory.rgShields", gear["armour"]["shield"])
  widget.setSelectedOption("lytArmory.rgAmulets", gear["armour"]["amulet"])
  widget.setChecked("lytArmory.cbxIsAutomatic", not not gear.isAutomatic)

  local movementBonus = widget.getSelectedData("lytArmory.rgArmour").movementBonus
  if (movementBonus) then
    world.sendEntityMessage(player.id(), "irdenGetArmourMovement", irdenUtils.getBonusByTag(movementBonus).value + irdenUtils.addBonusToStat(0, "MOVEMENT"))
  end
end


function loadButtonsForCustomPane()
  local customBonuses = root.assetJson("/interface/scripted/irdenstatmanager/ismcustombonuses.json")
  
  local rgBonusTags = {
    type = "radioGroup",
    position = {10, 60},
    toggleMode = false,
    callback = "changeNewBonus",
    buttons = {}
  }
  
  local positionX = 0
  local positionY = 60
  for _, bonus in ipairs(customBonuses) do
    bonus.position = {positionX, positionY}
    bonus.data.tooltip.labelOffset = {50, 48}
    bonus.data.tooltip.imageOffset = {10, 38}
    bonus.data.tooltip.image = "/interface/scripted/irdenstatmanager/ltooltip.png"
    table.insert(rgBonusTags.buttons, bonus)
    positionY = positionY - 20
    if positionY < -20 then
      positionY = 60
      positionX = positionX + 30
    end
  end

  rgBonusTags.buttons[1].selected = true
  widget.addChild("lytMisc.lytAddNewSkill", rgBonusTags, "rgBonusTags")
  widget.registerMemberCallback("lytMisc.lytAddNewSkill.rgBonusTags", "changeNewBonus", changeNewBonus)
end






function loadArmory()
  local inventoryBonuses = {}

  local function loadFromItem(item)
    if item and item.parameters.irden_stat_manager then
      local parms = item.parameters.irden_stat_manager
      
      if parms.type == "armour" and parms.armour then
        if parms.armour.armour then
          widget.setSelectedOption("lytArmory.rgArmour", parms.armour.armour)
        end
        if parms.armour.amulet then
          widget.setSelectedOption("lytArmory.rgAmulets", parms.armour.amulet)
        end
      elseif parms.type == "weapon" and parms.weapon then
        if parms.weapon.melee then
          widget.setSelectedOption("lytArmory.rgmeleeWeapons", parms.weapon.melee)
        end
        if parms.weapon.ranged then
          widget.setSelectedOption("lytArmory.rgrangedWeapons", parms.weapon.ranged)
          if parms.weapon.isAutomatic then
            widget.setChecked("lytArmory.cbxIsAutomatic", parms.weapon.isAutomatic)
          end
        end
        if parms.weapon.magic then
          widget.setSelectedOption("lytArmory.rgmagicWeapons", parms.weapon.magic)
        end
      elseif parms.type == "shield" and parms.shield then
        widget.setSelectedOption("lytArmory.rgShields", parms.shield)
      end

      if parms.bonuses then
        for _, bonus in ipairs(parms.bonuses) do
          bonus.ready = true
          bonus.oneTimed = false
          table.insert(inventoryBonuses, bonus)
        end
      end
    end
  end

  -- Armour
  for _, slot in ipairs({"head", "chest", "legs", "back"}) do
    loadFromItem(player.equippedItem(slot))
  end

  -- Items
  loadFromItem(player.primaryHandItem())
  loadFromItem(player.altHandItem())

  if #inventoryBonuses > 0 then
    self.irden.bonusGroups["__Предметное снаряжение"] = {
      invisible = false,
      readOnly = true,
      type = "stuff",
      isCustom = false,
      bonuses = inventoryBonuses
    }
  else
    self.irden.bonusGroups["__Предметное снаряжение"] = nil
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
      },
      other = {
        layout = "Other",
        position = {30, 80}
      }
    }

    for _, attack in ipairs(self.irden.attacks) do
      attackTypeMap[attack.type].position[2] = attackTypeMap[attack.type].position[2] - 20

      -- add metainfo to attack
      attack.activeBonuses = {
        name = attack.desc,
        tags = {"ALL", attack.stat, attack.dmgStat, attack.damageBonus, attack.attackBonus, "ATTACK", "DAMAGE", "DAMAGE_" .. attack.type}
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
    },
    other = {
      layout = "Other"
    }
  }

  local attackIndex = findIndexAtValue(self.irden.bonusGroups["Кастомные атаки"].bonuses, "tag", data.attackBonus)
  if attackIndex then
    table.remove(self.irden.bonusGroups["Кастомные атаки"].bonuses, attackIndex)
  end

  local damageIndex = findIndexAtValue(self.irden.bonusGroups["Кастомные атаки"].bonuses, "tag", data.damageBonus)
  if damageIndex then
    table.remove(self.irden.bonusGroups["Кастомные атаки"].bonuses, damageIndex)
  end

  local aIndx = findIndexAtValue(self.irden.attacks, "desc", data.desc)
  if aIndx then
    table.remove(self.irden.attacks, aIndx)
  end

  if #self.irden.attacks == 0 then
    self.irden.bonusGroups["Кастомные атаки"] = nil
  end


  loadBonuses()

  widget.removeChild("lytAttacks.lyt" .. attackTypeMap[data.type].layout .. "Attack.lytCustomAttack", data.buttonName)
  widget.removeChild("lytAttacks.lyt" .. attackTypeMap[data.type].layout .. "Attack.lytCustomAttack", data.buttonName .. "btn")
end


function loadBonuses(bonusName)
  widget.clearListItems("lytMisc.lytBonuses.lytCustomBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytStuffBonuses.saBonuses.listBonuses")
  widget.clearListItems("lytMisc.lytBonuses.lytActionsBonuses.saBonuses.listBonuses")

  local sourtedGroups = sortedKeys(self.irden.bonusGroups)

  for _, groupName in ipairs(sourtedGroups) do
    local group = self.irden.bonusGroups[groupName]

    if not group.invisible then
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

      if not group.hidden or bonusName and bonusName ~= "" then
        for j, bonus in ipairs(group.bonuses) do
          if not bonusName or bonusName == "" or string.find(bonus.name, bonusName) then
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
            handleBonusStatus(bonus, bonus.ready)
            self.irden.bonusGroups[groupName].bonuses[j].listId = li

            if bonus.ready then
              widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li .. ".bonusName", "yellow")
            end

            local widgetName = math.random(99999) .. groupName .. bonus.name

            if not group.readOnly then
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

            if group.isCustom then
              widget.addChild("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. li, {
                type = "image",
                position = {23, 4},
                maxSize = {10, 10},
                file = self.bonusImages[bonus.tag]
              })
            end
          end
        end
      end
      widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. groupListItem .. ".bonusIsActive", checkIfGroupIsFullyReady(groupName))
    end
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
        if not self.irden.bonusGroups[data.name].hidden then
          widget.setChecked("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", isChecked)
          widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusName", isChecked and "yellow" or "white")
        end
        handleBonusStatus(bonus, isChecked)
      end
    elseif data.type == "bonus" then
      local index = findIndexAtValue(self.irden.bonusGroups[data.group].bonuses, "listId", self.selectedLine)
      if index then
        self.irden.bonusGroups[data.group].bonuses[index].ready = isChecked
        widget.setFontColor("lytMisc.lytBonuses." .. selectedTab .. ".saBonuses.listBonuses." .. self.selectedLine .. ".bonusName", isChecked and "yellow" or "white")
        handleBonusStatus(self.irden.bonusGroups[data.group].bonuses[index], isChecked)
      end
    end
  end

 setHealthAndArmor()
 loadStatBonuses()
end

function handleBonusStatus(bonus, enable)
  if not bonus.status then return end

  local effects = status.getPersistentEffects("irden_effects")
  local bIndex = table.index(effects, bonus.status)

  if enable then
    if not bIndex then
      status.addPersistentEffect("irden_effects", bonus.status)
    end
  else
    if bIndex then
      table.remove(effects, bIndex)
      status.setPersistentEffects("irden_effects", effects)
    end
  end
  
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
 loadStatBonuses()
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
      loadStatBonuses()
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
      loadStatBonuses()
    end
  end
end


function addBonusGroup()
  local groupName = widget.getText("lytMisc.lytBonuses.lytCustomBonuses.tbxGroupName")

  if groupName ~= "" then
    if self.irden.bonusGroups[groupName] then
      irdenUtils.alert("^red;Такая группа уже существует!^reset;")
      return
    end


    self.irden.bonusGroups[groupName] = {
      name = groupName,
      isCustom = true,
      bonuses = {}
    }

    loadBonuses()
    widget.setText("lytMisc.lytBonuses.lytCustomBonuses.tbxGroupName", "")
  else
    irdenUtils.alert("^red;Введите имя группы!^reset;")
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

    if findIndexAtValue(self.irden.bonusGroups[self.currentGroup].bonuses, "name", bonus.name) then
      irdenUtils.alert("^red;Бонус %s в этой группе уже существует!^reset;")
      return
    end

    table.insert(self.irden.bonusGroups[self.currentGroup].bonuses, bonus)
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillName", "")
    widget.setText("lytMisc.lytAddNewSkill.tbxNewSkillValue", "")

    widget.setVisible("lytMisc.lytBonuses", true)
    widget.setVisible("lytMisc.lytAddNewSkill", false)
    loadBonuses()
    setHealthAndArmor()
    loadStatBonuses()
  else
    irdenUtils.alert("^red;Введите имя и значение бонуса!^reset;")
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


function checkOutLoud()
  self.irden.rollMode = (self.irden.rollMode % #self.rollModes) + 1
  setRollMode(self.irden.rollMode)
end

function setRollMode(mode)
  widget.setButtonImages("lytCharacter.btnOutloud", {
    base = string.format("/interface/scripted/irdenstatmanager/staticons/rollmodes/%s.png", self.rollModes[mode]),
    hover = string.format("/interface/scripted/irdenstatmanager/staticons/rollmodes/%s.png?brightness=-20", self.rollModes[mode])
  })
  widget.setText("lytCharacter.lblRollMode", self.rollModesTranslation[mode])
  player.setProperty("icc_current_roll_mode", self.rollModes[mode])
end

function changeHp()
  local maxHp = 20 + irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END") + irdenUtils.addBonusToStat(0, "MAX_HEALTH")
  local oldHP = (self.irden.currentHp or 0) / maxHp

  self.irden.currentHp = tonumber(widget.getText("lytCharacter.tbxCurrentHp")) or 0
  local newValue = self.irden.currentHp / maxHp

  if (newValue ~= oldHP or not self.firstDraw) then
    local aPrgCurrentHp = AnimatedWidget:bind("lytCharacter.prgCurrentHp")
    animatedWidgets:add(aPrgCurrentHp:process(oldHP, newValue, 1))
    self.firstDraw = true
  end
  
  local third = maxHp / 3
  local partImage = self.irden.currentHp == maxHp and "" or (self.irden.currentHp >= maxHp and "4" or (self.irden.currentHp == 0 and "0" or (self.irden.currentHp < third and "3" or (self.irden.currentHp > 2 * third and "1" or "2"))))

  widget.setButtonImage("lytCharacter.btnStatHp", string.format("/interface/scripted/irdenstatmanager/staticons/end%s.png", partImage))
end

function restoreHp()
  widget.setButtonImage("lytCharacter.btnStatHp", "/interface/scripted/irdenstatmanager/staticons/end.png")
  widget.setText("lytCharacter.tbxCurrentHp", 20 + irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END") + irdenUtils.addBonusToStat(0, "MAX_HEALTH"))
end

function roll20(_, dice)
  sendMessageToServer("statmanager", {
    type = "diceroll", 
    dice = tonumber(widget.getText("lytCharacter.tbxStatRollany")) or 0,
    source = world.entityName(player.id())
  })
end

function rollStat(_, data)
  local description = widget.getText("lytCharacter.tbxSkillName")
  sendMessageToServer("statmanager", {
    type = "statroll", 
    dice = 20,
    action = description ~= "" and description or data.name,
    source = world.entityName(player.id()),
    bonuses = getBonuses({"ALL", data.tag}, self.irden.stats[data.stat], data.tag)
  })
end

function statChange(widgetName, statName)
  self.irden["stats"][statName] = tonumber(widget.getText("lytCharacter." .. widgetName)) or 0
  setHealthAndArmor()
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", 20 + irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END")+ irdenUtils.addBonusToStat(0, "MAX_HEALTH")))
  self.irden.currentHp = 20 + self.irden["stats"]["endurance"] + irdenUtils.addBonusToStat(0, "MAX_HEALTH")
end

function gearChange(id, data)
  self.irden["gear"][data.kind][data.type] = id
  setHealthAndArmor()
end

function changeTab(id, data)
	for _, tab in ipairs(self.tabs) do
		widget.setVisible(tab, false)
	end
	widget.setVisible(data.tab, true)
end

function showAddAttackLayout(_, data)
  populateAttackEffects()
  changeAttackType(_, {layout = "lytAddNewAttack"})
  widget.setSelectedOption("lytAttacks.lytAddNewAttack.rgAttackType", data)
  widget.setText("lytAttacks.lytAddNewAttack.lblAttackType", widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackType").name)
end

function setAttackType(_, data)
  widget.setText("lytAttacks.lytAddNewAttack.lblAttackType", widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackType").name)
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

function string.uupper ( str ) return str:gsub ( "([a-zа-яё])", function ( c ) return string.char ( string.byte ( c ) - ( c == 'ё' and 16 or 32 ) ) end ) end
function string.llower ( str ) return str:gsub ( "([A-ZА-ЯЁ])", function ( c ) return string.char ( string.byte ( c ) + ( c == 'ё' and 16 or 32 ) ) end ) end

function searchBonus(txBox, text)
  local search = widget.getText("lytMisc.lytBonuses.tbxSearch")
  loadBonuses(search)
end


function attack(btnName, data)

  -- Calculate the attack bonus
  local baseAttackBonus = self.irden.stats[self.characterStats[data.stat]] or 0
  local weaponAttackBonus = data.type == "other" and {value = 0, name = 'Атака'} or irdenUtils.getBonusByTag(widget.getData("lytArmory.rg" .. data.type .. "Weapons." .. self.irden["gear"]["weapon"][data.type]).attackBonus)
  local armourAttackBonus = 0
  local attackBonus = irdenUtils.getBonusByTag(data.attackBonus)
  local damageBonus = irdenUtils.getBonusByTag(data.damageBonus)

  local baseDamageBonus = math.max((irdenUtils.addBonusToStat(baseAttackBonus, data.stat) + irdenUtils.addBonusToStat(self.irden.stats[self.characterStats[data.dmgStat]] or 0, data.dmgStat)) // data.dmgDivider, 1)
  local weaponDamageBonus = data.type == "other" and {value = 0, name = 'Атака'} or irdenUtils.getBonusByTag(widget.getData("lytArmory.rg" .. data.type .. "Weapons." .. self.irden["gear"]["weapon"][data.type]).damageBonus)
  local shieldDamageBonus = irdenUtils.getBonusByTag(widget.getData("lytArmory.rgShields." .. self.irden["gear"]["armour"]["shield"]).damageBonus)

  if data.type == "ranged" and widget.getChecked("lytArmory.cbxIsAutomatic") then
    baseDamageBonus = 0
    weaponDamageBonus = irdenUtils.getBonusByTag(widget.getData("lytArmory.rgrangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage)
  end
  
  local damageBonuses = nil
  if data.fixedDamage then
    damageBonuses = getBonuses({"DAMAGE", "DAMAGE_" .. data.type}, damageBonus.value, data.desc)
  elseif not data.noDamage then
    damageBonuses = getBonuses({"DAMAGE", "DAMAGE_" .. data.type}, baseDamageBonus, "База", weaponDamageBonus.value, weaponDamageBonus.name, damageBonus.value, damageBonus.name, shieldDamageBonus.value, shieldDamageBonus.name)
  end

  self.attackDataToSend = {
    type = "actionroll", 
    dice = 20,
    rgseed = util.seedTime(),
    source = world.entityName(player.id()),
    action = data.desc,
    attackBonuses = data.attackBonuses,
    attackType = data.type,
    richDescription = data.richDescription,
    bonuses = getBonuses({"ATTACK", "ATTACK_" .. data.type, table.unpack(data.tags)}, baseAttackBonus, data.stat, weaponAttackBonus.value, weaponAttackBonus.name, attackBonus.value, attackBonus.name),
    damageBonuses = damageBonuses
  }
  
  widget.setVisible("lytAttacks", false)
  widget.setVisible("lytWhoAttack", true)
  self.specificCase = {btnName = btnName, data = data}
  populatePlayers()
end

function populatePlayers()
  widget.removeAllChildren("lytWhoAttack.saPlayers")
  widget.setData("lytWhoAttack.saPlayers", {players = 0})
  widget.setText("lytWhoAttack.lblAttackName", self.attackDataToSend.action)

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

  -- Sort by name
  -- table.sort(players, function(a, b) return a.name < b.name end)
  
  if #players == 0 then
    sendAttacks()
  else
    local btnPos = {5, 0}
    local lblPos = {21, 6}
    local cnvPos = {3, 57}
    local dstPos = {39, 42}

    local imageTemplate = {
      type = "button",
      callback = "playerSelected",
      zlevel = 16,
      checkable = true,
      base = "/interface/scripted/irdenstatmanager/players/background.png",
      hover = "/interface/scripted/irdenstatmanager/players/background.png?saturation=-20",
      baseImageChecked = "/interface/scripted/irdenstatmanager/players/background_selected.png",
      hoverImageChecked = "/interface/scripted/irdenstatmanager/players/background_selected.png?saturation=-20",
      position = btnPos,
      data = null
    }

    local nameTemplate = {
      type = "label",
      value = "Никто",
      position = vec2.add(imageTemplate.position, lblPos), 
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

    local distanceTemplate = {
      type = "label",
      zlevel = 17,
      value = "0",
      hAnchor = "right",
      fontSize = 12,
      position = dstPos,
      mouseTransparent = true
    }

    widget.addChild("lytWhoAttack.saPlayers", imageTemplate, "choice_" .. 0)
    widget.addChild("lytWhoAttack.saPlayers", nameTemplate)
    canvasTemplate.rect = {2 + btnPos[1], 16 + btnPos[2], 37 + btnPos[1], 51 + btnPos[2]}
    widget.addChild("lytWhoAttack.saPlayers", canvasTemplate, "canvas_" .. 0)
    local canvas = widget.bindCanvas("lytWhoAttack.saPlayers.canvas_" .. 0)
    canvas:clear()
    canvas:drawImage("/interface/scripted/irdenstatmanager/players/noone.png", {2, 2})

    btnPos = vec2.add(btnPos, {45, 0})
    local i = 1
    for _, p in ipairs(players) do

      -- Player image
      canvasTemplate.rect = {2 + btnPos[1], 16 + btnPos[2], 37 + btnPos[1], 51 + btnPos[2]}
      widget.addChild("lytWhoAttack.saPlayers", canvasTemplate, "canvas_" .. i)
      drawIcon("lytWhoAttack.saPlayers." .. "canvas_" .. i, p.id, 2)

      -- Button image
      imageTemplate.position = btnPos
      imageTemplate.data = {
        id = p.id,
        name = p.name
      }
      widget.addChild("lytWhoAttack.saPlayers", imageTemplate, "choice_" .. i)

      -- Player name
      nameTemplate.value = p.name
      nameTemplate.position = vec2.add(imageTemplate.position, lblPos)
      widget.addChild("lytWhoAttack.saPlayers", nameTemplate)

      -- Distance to player
      local distance = getDistanceToPlayer(p.id)
      distanceTemplate.value = tostring(distance)
      distanceTemplate.position = vec2.add(imageTemplate.position, dstPos)
      widget.addChild("lytWhoAttack.saPlayers", distanceTemplate)

      btnPos = vec2.add(btnPos, {45, 0})
      widget.setData("lytWhoAttack.saPlayers", {players = i})
      i = i + 1
      if i % 5 == 0 then
        btnPos[1] = 5
        btnPos[2] = btnPos[2] - 60
      end
    end
  end
end

function getDistanceToPlayer(pId)
  local mPosition = world.entityPosition(player.id())
  local mouthOffset = world.distance(mPosition, world.entityMouthPosition(player.id()))
  local movementBonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").movementBonus).value + irdenUtils.addBonusToStat(0, "MOVEMENT")

  local distanceInBlocks = movementBonus * 5

  local distance = vec2.sub(world.entityPosition(pId), mPosition)
  local blockDistance = vec2.mag(world.distance(distance, mouthOffset)) / distanceInBlocks
  return blockDistance < 0.3 and "X" or math.floor(blockDistance + 1)
end


function drawIcon(canvasName, id, scale)
  scale = scale or 1
	local playerCanvas = widget.bindCanvas(canvasName)
	local playerPortrait = world.entityPortrait(id, "bust")
	playerCanvas:clear()
	for _, layer in ipairs(playerPortrait) do
		playerCanvas:drawImage(layer.image, vec2.mul({-14, -18}, scale), scale)
	end
end

function playerSelected(btnName, data)
  if not data then
    local totalTargets = widget.getData("lytWhoAttack.saPlayers").players 
    for i = 1, totalTargets do 
      widget.setChecked("lytWhoAttack.saPlayers.choice_" .. i, false)
    end
  else
    widget.setChecked("lytWhoAttack.saPlayers.choice_" .. 0, false)
  end

end

function sendAttacks()
  local targets = widget.getData("lytWhoAttack.saPlayers").players
  local selectedTargets = {}
  for i = 1, targets do 
    if widget.getChecked("lytWhoAttack.saPlayers.choice_" .. i) then
      local data = widget.getData("lytWhoAttack.saPlayers.choice_" .. i)
      table.insert(selectedTargets, {target = data.id, targetName = data.name})

      local msg = {}
      msg.defensePlayerUuid = player.uniqueId()
      msg.defensePlayerId = player.id()
      msg.attackDesc = self.attackDataToSend.action
      msg.attackType = self.attackDataToSend.attackType
      msg.attackBonuses = self.attackDataToSend.attackBonuses
      msg.bonuses = self.attackDataToSend.bonuses
      msg.damageBonuses = self.attackDataToSend.damageBonuses
      msg.richDescription = self.attackDataToSend.richDescription

      world.sendEntityMessage(data.id, "irdenInteractv2", _, msg)
    end
  end

  self.attackDataToSend.target = #selectedTargets > 0 and selectedTargets or nil
  self.attackDataToSend.targetName = ""

  timers:add(0.2, function() 
    sendMessageToServer("statmanager", self.attackDataToSend) end)

  handleSpecificCases(self.specificCase.btnName, self.specificCase.data)

  if self.irden.fightName and player.hasActiveQuest("irdeninitiative") then
    promises:add(
      player.confirm({
        title = self.irden.fightName,
        --subtitle = "Передать ход",
        sourceEntityId = player.id(),
        okCaption = "Да",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Передать ход?"
      }), function (result)
        if result then
          nextTurn()
        end
      end)
  end

  widget.setVisible("lytWhoAttack", false)
  widget.setVisible("lytAttacks", true)
end

function cancelAttack()
  widget.setVisible("lytWhoAttack", false)
  widget.setVisible("lytAttacks", true)
end

function defense(btnName, data)

  local defenseParts = { self.irden.stats[data.defense_stat], data.stat_desc }
  local defenseBonus = irdenUtils.getBonusByTag(data.defenseBonus)

  if widget.getSelectedData("lytArmory.rgArmour").defenseBonus ~= "ARMOUR_LIGHT_DODGE" or has_value(data.tags, "DODGE") then
    local bonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").defenseBonus)
    table.insert(defenseParts, bonus.value)
    table.insert(defenseParts, bonus.name)
  end

  if widget.getSelectedData("lytArmory.rgAmulets").defenseBonus ~= "ARMOUR_AMULET_BLOCK" or has_value(data.tags, "BLOCK") then
    local bonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").defenseBonus)
    table.insert(defenseParts, bonus.value)
    table.insert(defenseParts, bonus.name)
  end

  if has_value(data.tags, "PARRY") or has_value(data.tags, "BLOCK") then
    local bonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgShields").defenseBonus)
    table.insert(defenseParts, bonus.value)
    table.insert(defenseParts, bonus.name)
  end

    table.insert(defenseParts, defenseBonus.value)
    table.insert(defenseParts, defenseBonus.name)

  
  sendMessageToServer("statmanager", {
    type = "actionroll", 
    dice = 20,
    source = world.entityName(player.id()),
    target = self.defensePlayerUuid or nil,
    action = widget.getData("lytAttacks." .. widget.getSelectedData("lytAttacks.rgAttackTypes").layout .. "." .. btnName).desc,
    defenseAction = self.defenseAttackDescription,
    targetName = self.defensePlayerId and world.entityName(self.defensePlayerId) or "",
    bonuses = getBonuses({"DEFENSE", table.unpack(data.tags)}, table.unpack(defenseParts))
  })
  handleSpecificCases(btnName, data)
end

function handleSpecificCases(btnName, data)

  local function confirm(title, subtitle, message, okCaption, cancelCaption, callback)
    promises:add(
      player.confirm({
        title = title or "Подтверждение",
        subtitle = subtitle,
        sourceEntityId = player.id(),
        okCaption = okCaption or "Да",
        cancelCaption = cancelCaption or "Нет",
        paneLayout = self.confirmationLayout,
        message = message
      }), callback)
  end

  local function enableBonus(group, name)
    local bonus = findIndexAtValue(self.irden.bonusGroups[group].bonuses, "name", name)
    if bonus then
      if self.irden.bonusGroups[group].bonuses[bonus].listId then
        widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonusGroups[group].bonuses[bonus].listId .. ".bonusIsActive", true)
        widget.setFontColor("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonusGroups[group].bonuses[bonus].listId .. ".bonusName", "yellow")
      end
      self.irden.bonusGroups[group].bonuses[bonus].ready = true
    end
  end

  if btnName == "btnRangedPiercing" then
    local rangedPiercingDebuff = findIndexAtValue(self.irden.bonusGroups["Общие"].bonuses, "name", "Бывший пробивной выстрел")
    if rangedPiercingDebuff then
      widget.setChecked("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonusGroups["Общие"].bonuses[rangedPiercingDebuff].listId .. ".bonusIsActive", true)
      widget.setFontColor("lytMisc.lytBonuses.lytBaseBonuses.saBonuses.listBonuses." .. self.irden.bonusGroups["Общие"].bonuses[rangedPiercingDebuff].listId .. ".bonusName", "yellow")
      self.irden.bonusGroups["Общие"].bonuses[rangedPiercingDebuff].ready = true
    end
  elseif data.type == "melee" and data.attackBonus then
    confirm(self.irden.fightName, _, "Запарировано?", _, _, function(result) 
      if result then
        enableBonus("Противник", "Парирование")
      end
    end)
  elseif btnName == "btnMeleeDodge" then
    confirm(self.irden.fightName, _, "Уклонился?", _, _, function(result) 
      if result then
        enableBonus("Общие", "Успешное уклонение")
      end
    end)
  elseif data.type == "magic" and data.attackBonus then
    confirm(self.irden.fightName, _, "Успешное контрзаклинание?", _, _, function(result) 
      if result then
        enableBonus("Противник", "Контрзаклинание")
      end
    end)
  end
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
        if bonus.value ~= 0 then
          table.insert(bonuses, bonus.value)
          table.insert(bonuses, bonus.name)
          sum = sum + bonus.value
        end
        if bonus.oneTimed then
          if bonus.listId then
            widget.setChecked("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusIsActive", false)
            widget.setFontColor("lytMisc.lytBonuses." .. bonusType .. ".saBonuses.listBonuses." .. bonus.listId .. ".bonusName", "white")
          end
          self.irden.bonusGroups[groupName].bonuses[i].ready = false
          handleBonusStatus(self.irden.bonusGroups[groupName].bonuses[i], false)
        end
      end
    end
  end

  return bonuses
end


function resetBaseBonuses()
  self.irden.bonusGroups = sb.jsonMerge(self.irden.bonusGroups, root.assetJson("/irden_bonuses.config"))
  status.clearPersistentEffects("irden_effects")
  setHealthAndArmor()
  loadBonuses()
  loadAttacks()
end

function subtractHP(value, kind)
  local physArmour = irdenUtils.addBonusToStat(irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").armourBonus).value, "ARM")
  local magArm = irdenUtils.addBonusToStat(irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").blockBonus).value, "MAGARM")

  local blocked = kind == "PHYS" and physArmour or (kind == "MAG" and magArm or 0)
  local subhp = math.max(value - blocked, 1)

  if subhp then
    local currhp = tonumber(widget.getText("lytCharacter.tbxCurrentHp")) or 0
    if kind ~= "HEAL" then
      widget.setText("lytCharacter.tbxCurrentHp", math.max(0, currhp - subhp))
    else
      local maxHp = 20 + irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END") + irdenUtils.addBonusToStat(0, "MAX_HEALTH")
      widget.setText("lytCharacter.tbxCurrentHp", math.min(maxHp, currhp + subhp))
    end
  end
end

function editHP(textbox, kind)
  local value = tonumber(widget.getText("lytCharacter." .. textbox))
  if value then 
    subtractHP(value, kind)
  end
  widget.setText("lytCharacter." .. textbox, "")
  widget.blur("lytCharacter." .. textbox)
end

function setHealthAndArmor()
  local maxHp = 20 + irdenUtils.addBonusToStat(self.irden["stats"]["endurance"], "END") + irdenUtils.addBonusToStat(0, "MAX_HEALTH")
  self.irden.currentHp = math.min(self.irden.currentHp, maxHp)
  widget.setText("lytCharacter.tbxCurrentHp", self.irden.currentHp)
  widget.setText("lytCharacter.lblMaxHP", string.format("HP:       / %s", maxHp))
  local physArmour = irdenUtils.addBonusToStat(irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").armourBonus).value, "ARM")
  local magArm = irdenUtils.addBonusToStat(irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").blockBonus).value, "MAGARM")

  widget.setText("lytCharacter.lblPhysArmour", physArmour)
  widget.setText("lytCharacter.lblMagArmour", magArm)

  local movementBonus = widget.getSelectedData("lytArmory.rgArmour").movementBonus
  world.sendEntityMessage(player.id(), "irdenGetArmourMovement", irdenUtils.getBonusByTag(movementBonus).value + irdenUtils.addBonusToStat(0, "MOVEMENT"))
  changeHp()
  setResourseAttempts()
  setStamina()
end

function restoreStamina()
  for type, value in pairs(self.irden.crafts) do
    self.irden.crafts[type] = irdenUtils.getMaxStamina(type) or 0
    local prgWIdget = AnimatedWidget:bind("lytCharacter.prg" .. type .. "Craft")
    animatedWidgets:add(prgWIdget:process(0, self.irden.crafts[type], 1))
  end
  widget.setVisible("lytCharacter.imgSerbia", true)
end

function changeStamina(_, data)
  local maxStamina = irdenUtils.getMaxStamina(data.type)
  maxStamina = maxStamina ~= 0 and maxStamina or 1
  local oldValue = self.irden.crafts[data.type]
  local newValue
  if data.mode == "add" then
    newValue = math.min(oldValue + 1, maxStamina)
  else
    newValue = math.max(oldValue - 1, 0)
  end

  self.irden.crafts[data.type] = newValue
  local prgWIdget = AnimatedWidget:bind("lytCharacter.prg" .. data.type .. "Craft")
  animatedWidgets:add(prgWIdget:process(oldValue / maxStamina, newValue / maxStamina, 0.5))
  widget.setVisible("lytCharacter.imgSerbia", false)
end

function setStamina()
  for type, value in pairs(self.irden.crafts) do 
    local maxStamina = irdenUtils.getMaxStamina(type) or 0
    maxStamina = maxStamina ~= 0 and maxStamina or 1
    local prgWIdget = AnimatedWidget:bind("lytCharacter.prg" .. type .. "Craft")
    self.irden.crafts[type] = math.min(value, maxStamina)
    animatedWidgets:add(prgWIdget:process(1, self.irden.crafts[type] / maxStamina, 0.5))
  end
end


function showCurrentPlayer()
  player.setProperty("toShowCurrentPlayerIndicator", widget.getChecked("lytCharacter.btnShowCurrentPlayer"))
end

--[[ 
  Custom attacks
]]

function attackFixedDamage()
  local fixedDamage = widget.getChecked("lytAttacks.lytAddNewAttack.btnfixedDamage")
  widget.setVisible("lytAttacks.lytAddNewAttack.tbxFixedDamage", fixedDamage)
  hideDamageTags(not fixedDamage and not widget.getChecked("lytAttacks.lytAddNewAttack.btnShouldHaveNoDamage"))
end

function hideDamage()
  hideDamageTags(not widget.getChecked("lytAttacks.lytAddNewAttack.btnShouldHaveNoDamage") and not widget.getChecked("lytAttacks.lytAddNewAttack.btnfixedDamage"))
end

function hideDamageTags(toHide)
  widget.setVisible("lytAttacks.lytAddNewAttack.rgDamageTags", toHide)
  widget.setVisible("lytAttacks.lytAddNewAttack.lblPlus", toHide)
  widget.setVisible("lytAttacks.lytAddNewAttack.lblDiv", toHide)
  widget.setVisible("lytAttacks.lytAddNewAttack.tbxDamageDivider", toHide)
end

function addAttack()
  local attackName = widget.getText("lytAttacks.lytAddNewAttack.tbxAttackName")
  if attackName and attackName ~= "" then
    local stat = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackTags")
    local dmgStat = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgDamageTags")
    local type = widget.getSelectedData("lytAttacks.lytAddNewAttack.rgAttackType").type
    local newBonusTag = "CUST_ATTACK_" .. attackName .. "_" .. math.random(1000)
    local noDamage = widget.getChecked("lytAttacks.lytAddNewAttack.btnShouldHaveNoDamage")
    local fixedDamage = widget.getChecked("lytAttacks.lytAddNewAttack.btnfixedDamage") and widget.getText("lytAttacks.lytAddNewAttack.tbxFixedDamage") ~= "" and tonumber(widget.getText("lytAttacks.lytAddNewAttack.tbxFixedDamage")) or nil
    local richDescription = widget.getText("lytAttacks.lytAddNewAttack.tbxAttackDescription") ~= "" and widget.getText("lytAttacks.lytAddNewAttack.tbxAttackDescription") or nil
    
    local attackBonuses = {}
    for _, li in ipairs(self.possibleAttackEffects or {}) do 
      if widget.getChecked("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li .. ".bonusIsActive") then
        table.insert(attackBonuses, widget.getData("lytAttacks.lytAddNewAttack.lytAttackEffects.saBonuses.listBonuses." .. li))
      end
    end

    if not self.irden.bonusGroups["Кастомные атаки"] then
      self.irden.bonusGroups["Кастомные атаки"] = {
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
      richDescription = richDescription,
      tags = {"ALL", stat},
      noDamage = noDamage,
      fixedDamage = fixedDamage,
      attackBonuses = attackBonuses
    })


    if not noDamage then
      table.insert(self.irden.bonusGroups["Кастомные атаки"].bonuses, {
        name = attackName .. ": попадание",
        value = 0,
        tag = newBonusTag .. "_ATTACK",
        ready = true
      })
      table.insert(self.irden.bonusGroups["Кастомные атаки"].bonuses, {
        name = attackName .. ": урон",
        value = fixedDamage or 0,
        tag = newBonusTag .. "_DAMAGE",
        ready = true
      })
    else
      table.insert(self.irden.bonusGroups["Кастомные атаки"].bonuses, {
        name = attackName,
        value = 0,
        tag = newBonusTag .. "_ATTACK",
        ready = true
      })
    end


    loadBonuses()
    loadAttacks()

    widget.setText("lytAttacks.lytAddNewAttack.tbxAttackName", "")
    widget.setText("lytAttacks.lytAddNewAttack.tbxAttackDescription", "")
    changeAttackType(_, {layout = widget.getSelectedData("lytAttacks.rgAttackTypes").layout})
  else
    irdenUtils.alert("^red;Введите имя атаки!^reset;")
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
  local adv = widget.getSelectedOption("rgAdvantage")
  if adv == 0 then data.advantage = nil else data.advantage = adv < 0 end
  data.rgseed = util.seedTime()
  data.rollMode = self.rollModes[self.irden.rollMode]
  data.weatherEffects = not widget.getChecked("lytCharacter.btnWeather")
  data.version = self.version
  data.onlySum = widget.getChecked("lytCharacter.btnHideStats") 
  if player.hasActiveQuest("irdeninitiative") then
    data.fight = player.getProperty("irdenfightName")
  end

  if data.rollMode == "Local" then
    if root.getConfiguration then 
      local radius = root.getConfiguration("icc_proximity_radius") or 100
      local uniqueIds = {}
      for _, pId in ipairs(world.playerQuery(world.entityPosition(player.id()), radius)) do 
        table.insert(uniqueIds, world.entityUniqueId(pId))
      end
      data.uniqueIds = uniqueIds
    end
  elseif data.rollMode == "Fight" then
    if player.hasActiveQuest("irdeninitiative") and self.irden.fightName then
      promises:add(world.sendEntityMessage("irdenfighthandler_" .. self.irden.fightName, "getFight"), function(fight) 
        local uniqueIds = {}
        for _, fighter in pairs(fight.players) do 
          table.insert(uniqueIds, fighter.uniqueId)
        end
        data.uniqueIds = uniqueIds
        world.sendEntityMessage(0, message, data)
      end)
      return
    end
  end
  world.sendEntityMessage(0, message, data)
end


function update(dt)
	printTime()
  --drawCharacter()
  animatedWidgets:update()
  promises:update()
  timers:update(dt)
end



function cursorOverride(screenPosition)
  if self.tooltipCanvas then
    self.tooltipCanvas:clear()
    widget.clearListItems("lytActiveBonuses.listActiveBonuses")
    widget.setVisible("lytActiveBonuses", false)
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
  
          if tooltip.craftBar then
            local text = tooltip.craftBar.type .. ": " .. self.irden.crafts[tooltip.craftBar.type] .. " / " .. irdenUtils.getMaxStamina(tooltip.craftBar.type)

            self.tooltipCanvas:drawText(text, {
              position = vec2.add(wPos, vec2.div(widget.getSize(w), 2)),
              verticalAnchor = "mid",
              horizontalAnchor = "mid"
            }, tooltip.craftBar.fontSize, tooltip.craftBar.color)
          else
            self.tooltipCanvas:drawImage(tooltip.image, vec2.add(wPos, tooltip.imageOffset))
            self.tooltipCanvas:drawText(tooltip.name, {
              position = vec2.add(wPos, tooltip.labelOffset),
              verticalAnchor = "mid",
              horizontalAnchor = "mid"
            }, tooltip.fontSize, tooltip.color)
          end
        end 
      end

    end
  end
end

function drawActiveBonuses(data)
  local bonuses = {}
  
  bonuses = irdenUtils.getActiveBonusesByTags(data.tags or {})

  if has_value(data.tags, "ATTACK") then
    local attackType = widget.getSelectedData("lytAttacks.rgAttackTypes").type
    local weaponBonus = attackType ~= "other" and irdenUtils.getBonusByTag(widget.getData("lytArmory.rg" .. attackType .. "Weapons." .. self.irden["gear"]["weapon"][attackType]).damageBonus).value or 0
  
    if attackType == "ranged" and widget.getChecked("lytArmory.cbxIsAutomatic") then
      weaponBonus = irdenUtils.getBonusByTag(widget.getData("lytArmory.rgrangedWeapons." .. self.irden["gear"]["weapon"]["ranged"]).autoDamage).value
    end

    if weaponBonus ~= 0 then
      table.insert(bonuses, {
        name = "Урон оружия",
        value = weaponBonus
      })
    end

  elseif has_value(data.tags, "DEFENSE") then
    local armourBonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgArmour").defenseBonus).value
    local amuletBonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgAmulets").defenseBonus).value

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
      local shieldBonus = irdenUtils.getBonusByTag(widget.getSelectedData("lytArmory.rgShields").defenseBonus).value
      if shieldBonus ~= 0 then
        table.insert(bonuses, {
          name = "Щит",
          value = shieldBonus
        })
      end
    end
  end


  if #bonuses > 0 then widget.setVisible("lytActiveBonuses", true) end

  for _, bonus in ipairs(bonuses) do 
    local li = widget.addListItem("lytActiveBonuses.listActiveBonuses")
    local bonusName = not not string.find(bonus.name, ": попадание") and "Попадание" or bonus.name
    bonusName = not not string.find(bonusName, ": урон") and "Урон" or bonusName
    widget.setText("lytActiveBonuses.listActiveBonuses." .. li .. ".bonusName", bonusName)
    widget.setText("lytActiveBonuses.listActiveBonuses." .. li .. ".bonusValue", string.format('%s%d', bonus.value > 0 and "+" or "", bonus.value))
    widget.setImage("lytActiveBonuses.listActiveBonuses." .. li .. ".bonusImage", self.bonusImages[bonus.tag] or "")
  end

  widget.setSize("lytActiveBonuses.background", {100, widget.getSize("lytActiveBonuses.listActiveBonuses")[2] + 24})
  widget.setPosition("lytActiveBonuses", self.positionCanvas:mousePosition())
  widget.setText("lytActiveBonuses.lblBonuses", data.name)
end

function getBonusImages()
  local images = {}
  local customBonuses = root.assetJson("/interface/scripted/irdenstatmanager/ismcustombonuses.json")
  for _, button in ipairs(customBonuses) do 
    images[button.data.tag] = button.baseImage
  end
  return images
end

function selfBonus(_, data)
  for _, bonus in ipairs(data.bonuses) do 
    local ind = findIndexAtValue(self.irden.bonusGroups[bonus.group].bonuses, "name", bonus.name)
    if ind then
      self.irden.bonusGroups[bonus.group].bonuses[ind].ready = true
    end
  end
  loadBonuses()
end


function loadCustomBonuses()
  local baseBonuses = root.assetJson("/irden_bonuses.config")
  self.irden.bonusGroups = self.irden.bonusGroups or {}
  -- For each group in custom bonuses do
  for groupName, group in pairs(self.irden.bonusGroups) do 
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


function saveCustomBonuses()
  local customBonuses = {}
  local baseBonuses = root.assetJson("/irden_bonuses.config")

  -- For each group in custom bonuses do
  for groupName, group in pairs(self.irden.bonusGroups) do 
    -- If group does not exist at the base, add it whole
    if not baseBonuses[groupName] then
      customBonuses[groupName] = group
    else
      customBonuses[groupName] = {
        isCustom = group.isCustom,
        type = group.type,
        hidden = group.hidden,
        bonuses = {}
      }

      -- Loop through each bonus in the group
      for _, bonus in ipairs(group.bonuses) do
        bonus.listId = nil

        -- If bonus does not exist in the base group (somehow), add it
        local ind = findIndexAtValue(baseBonuses[groupName].bonuses, "name", bonus.name)
        if not ind then
          table.insert(customBonuses[groupName].bonuses, bonus)
        else
          -- Else compare bonus value and its state, otherwise ignore
          if bonus.value ~= baseBonuses[groupName].bonuses[ind].value or bonus.ready then
            table.insert(customBonuses[groupName].bonuses, bonus)
          end
        end
      end

      --If there's no bonuses in the group, don't save it
      if #customBonuses[groupName].bonuses == 0 then
        customBonuses[groupName] = nil
      end
    end
  end
  return customBonuses
end

-- Presets
function savePreset()
  local presetId = widget.getSelectedOption("lytCharacter.rgPresets")
  local preset = {
    weapon = {
      melee = widget.getSelectedOption("lytArmory.rgmeleeWeapons"),
      ranged = widget.getSelectedOption("lytArmory.rgrangedWeapons"),
      magic = widget.getSelectedOption("lytArmory.rgmagicWeapons")
    },
    armour = {
      armour = widget.getSelectedOption("lytArmory.rgArmour"),
      shield = widget.getSelectedOption("lytArmory.rgShields"),
      amulet =  widget.getSelectedOption("lytArmory.rgAmulets")
    },
    isAutomatic = widget.getChecked("lytArmory.cbxIsAutomatic"),
    stats = copy(self.irden.stats)
  }

  self.irden.presets["" .. presetId] = preset
end

function changePreset(id)
  if self.irden.presets[id] then
    loadWeapons(self.irden.presets[id])
    if self.irden.presets[id].stats and next(self.irden.presets[id].stats) ~= nil then
      loadStats(self.irden.presets[id].stats)
    else
      loadStats(self.irden.stats)
    end
  end
end


function registerItem()
  player.interact("ScriptPane", root.assetJson("/interface/scripted/irdenstatmanager/ismitemregister/ismitemregister.json"))
end


function uninit()
  self.irden["gear"].isAutomatic = widget.getChecked("lytArmory.cbxIsAutomatic")
  self.irden.bonusGroups = saveCustomBonuses()
  self.irden.bonusGroups["__Предметное снаряжение"] = nil
  self.irden.onlySum = player.isAdmin() and widget.getChecked("lytCharacter.btnHideStats") or false
  self.irden.weatherEffects = widget.getChecked("lytCharacter.btnWeather")
  player.setProperty("irden", self.irden)

  if player.equippedTech("legs") and player.equippedTech("legs") == "irdenstatmanager" then
    player.unequipTech("irdenstatmanager")
    player.makeTechUnavailable("irdenstatmanager")
    world.sendEntityMessage(player.id(), "irdenStatManagerToShowMovement", 0)
    if self.tech and self.tech ~= "irdenstatmanager" then
      player.equipTech(self.tech)
    end
  end
  player.setProperty("irden_stat_manager_ui_open", nil)
end