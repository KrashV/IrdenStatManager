function init()
  self.item = nil
  self.type = nil
  self.itemBonuses = {}
  widget.registerMemberCallback("lytItemBonuses.saBonuses.listBonuses", "deleteBonus", deleteBonus)
  loadButtonsForCustomPane()
  self.bonusImages = getBonusImages()
end

function leftClickItemSlot(slot)
	local newItem = player.swapSlotItem()
	local currentItem = widget.itemSlotItem(slot)
	
	if (newItem or currentItem) then
		widget.setItemSlotItem(slot, newItem)
    saveDataToItem(currentItem)
		player.setSwapSlotItem(currentItem)
    drop()
		loadItem(newItem)
	end
end

function loadItem(item)
  self.item = item
  if item then
    loadDataFromItem(item)
    if string.find(root.itemType(item.name), "armor") then
      -- It's an armour: show the armour radio group
      self.type = "armour"
      widget.setVisible("lytArmour", true)
      widget.setVisible("btnAddBonuses", true)
    else
      -- It's an item: show the weapons and shields radio group
      self.type = "weapon"
      widget.setVisible("lytItems", true)
      widget.setVisible("btnAddBonuses", true)
    end
    
    widget.setVisible("lytItemBonuses", true)
  else
    drop()
  end
end

function drop()
  self.type = nil
  self.itemBonuses = {}
  widget.clearListItems("lytItemBonuses.saBonuses.listBonuses")
  widget.setVisible("lytArmour", false)
  widget.setVisible("lytItems", false)
  widget.setVisible("btnAddBonuses", false)
  widget.setVisible("lytBonuses", false)
  widget.setVisible("lytItemBonuses", false)
end

function loadDataFromItem(item)
  if item and item.parameters.irden_stat_manager then
    local parms = item.parameters.irden_stat_manager
    if parms.type == "armour" then
      widget.setSelectedOption("lytArmour.rgArmour", parms.armour.armour)
      widget.setSelectedOption("lytArmour.rgAmulets", parms.armour.amulet)
    elseif parms.type == "weapon" then
      widget.setSelectedOption("lytItems.rgmeleeWeapons", parms.weapon.melee)
      widget.setSelectedOption("lytItems.rgrangedWeapons", parms.weapon.ranged)
      widget.setChecked("lytItems.cbxIsAutomatic", not not parms.weapon.isAutomatic)
      widget.setSelectedOption("lytItems.rgmagicWeapons", parms.weapon.magic)
    elseif parms.type == "shield" then
      widget.setSelectedOption("lytItems.rgShields", parms.shield)
    end
    self.itemBonuses = parms.bonuses or {}
    loadItemBonuses()
  end
end

function saveDataToItem(item)
  if not item then return end
  local irden_stat_manager = nil
  if self.type == "armour" then
    local armour = widget.getSelectedOption("lytArmour.rgArmour")
    if armour  ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "armour"
      irden_stat_manager.armour = irden_stat_manager.armour or {}
      irden_stat_manager.armour.armour = armour
    end
    local amulet = widget.getSelectedOption("lytArmour.rgAmulets")
    if amulet  ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "armour"
      irden_stat_manager.armour = irden_stat_manager.armour or {}
      irden_stat_manager.armour.amulet = amulet
    end


  elseif self.type == "weapon" then
    local melee = widget.getSelectedOption("lytItems.rgmeleeWeapons")
    if melee  ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "weapon"
      irden_stat_manager.weapon = irden_stat_manager.weapon or {}
      irden_stat_manager.weapon.melee = melee
    end

    local ranged = widget.getSelectedOption("lytItems.rgrangedWeapons")
    if ranged  ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "weapon"
      irden_stat_manager.weapon = irden_stat_manager.weapon or {}
      irden_stat_manager.weapon.ranged = ranged
      if widget.getChecked("lytItems.cbxIsAutomatic") then
        irden_stat_manager.weapon.isAutomatic = true
      end
    end

    local magic = widget.getSelectedOption("lytItems.rgmagicWeapons")
    if magic  ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "weapon"
      irden_stat_manager.weapon = irden_stat_manager.weapon or {}
      irden_stat_manager.weapon.magic = magic
    end

    local shield = widget.getSelectedOption("lytItems.rgShields")
    if shield ~= -1 then
      irden_stat_manager = irden_stat_manager or {}
      irden_stat_manager.type = "shield"
      irden_stat_manager.shield = shield
    end
  end

  if #self.itemBonuses > 0 then
    irden_stat_manager = irden_stat_manager or {}
    for i, bonus in ipairs(self.itemBonuses) do 
      self.itemBonuses[i].listId = nil
    end
    irden_stat_manager.bonuses = self.itemBonuses 
  end

  item.parameters.irden_stat_manager = irden_stat_manager
  return item
end

function openBonusPane()
  widget.setVisible("lytBonuses", true)
  widget.setVisible("lytArmour", false)
  widget.setVisible("lytItems", false)
  widget.setVisible("btnAddBonuses", false)
  widget.setVisible("lytItemBonuses", false)
end

function closeBonusPane()
  widget.setVisible("lytBonuses", false)
  widget.setVisible(self.type == "armour" and "lytArmour" or "lytItems", true)
  widget.setVisible("btnAddBonuses", true)
  widget.setVisible("lytItemBonuses", true)
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
  widget.addChild("lytBonuses", rgBonusTags, "rgBonusTags")
  widget.registerMemberCallback("lytBonuses.rgBonusTags", "changeNewBonus", changeNewBonus)
end

function changeNewBonus(_, data)
  widget.setText("lytBonuses.lblBonusType", data.tooltip.name)
end

function addBonusToItem()
  local bonusName = widget.getText("lytBonuses.tbxNewSkillName")
  local bonusValue = tonumber(widget.getText("lytBonuses.tbxNewSkillValue"))

  if not bonusValue or not bonusName then return end

  local bonus = {
    name = bonusName,
    value = bonusValue,
    tag = widget.getSelectedData("lytBonuses.rgBonusTags").tag
  }
  table.insert(self.itemBonuses, bonus)
  closeBonusPane()
  addBonusToList(bonus)
end

function lineSelected(listName)
  self.selectedLine = widget.getListSelected("lytItemBonuses.saBonuses.listBonuses")
end

function addBonusToList(bonus)
  local li = widget.addListItem("lytItemBonuses.saBonuses.listBonuses")
  widget.setText("lytItemBonuses.saBonuses.listBonuses." .. li .. ".bonusName", bonus.name)
  widget.setText("lytItemBonuses.saBonuses.listBonuses." .. li .. ".bonusValue", bonus.value)
  widget.setImage("lytItemBonuses.saBonuses.listBonuses." .. li .. ".bonusImage", self.bonusImages[bonus.tag] or "")
  bonus.listId = li
end

function deleteBonus(_, data)
  if self.selectedLine then
    local index = findIndexAtValue(self.itemBonuses, "listId", self.selectedLine)
    if index then
      table.remove(self.itemBonuses, index)
    end
    loadItemBonuses()
  end
end


function loadItemBonuses()
  widget.clearListItems("lytItemBonuses.saBonuses.listBonuses")
  if #self.itemBonuses > 0 then
    for _, bonus in ipairs(self.itemBonuses) do
      addBonusToList(bonus) 
    end
  end
end

function getBonusImages()
  local images = {}
  local customBonuses = root.assetJson("/interface/scripted/irdenstatmanager/ismcustombonuses.json")
  for _, button in ipairs(customBonuses) do 
    images[button.data.tag] = button.baseImage
  end
  return images
end


function findIndexAtValue(t, attr, value)
  for i, v in ipairs(t) do
    if v[attr] == value then
      return i
    end
  end
end

function uninit()
  local item = widget.itemSlotItem("itemSlot")
  if item then
    player.giveItem(saveDataToItem(item))
  end
end