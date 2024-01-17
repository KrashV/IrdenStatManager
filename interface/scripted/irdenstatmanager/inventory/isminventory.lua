function loadInventory()
  local shownGroup = widget.getSelectedData("lytInventory.rgItemType")
  widget.setText("lytInventory.lblHeader", shownGroup and shownGroup.name or "Инвентарь")

  widget.clearListItems("lytInventory.saItems.listItems")
  widget.registerMemberCallback("lytInventory.saItems.listItems", "removeInventoryItem", removeInventoryItem)
  widget.registerMemberCallback("lytInventory.saItems.listItems", "addInventoryItemAmount", addInventoryItemAmount)
  widget.registerMemberCallback("lytInventory.saItems.listItems", "subtractInventoryItemAmount", subtractInventoryItemAmount)

  self.irden.inventory = self.irden.inventory or jarray()
  if #self.irden.inventory == 0 then
    self.irden.inventory = jarray()
  end

  local sortedInventory = copy(self.irden.inventory)
  table.sort(sortedInventory, function(itemA, itemB) return itemA.name < itemB.name end)

  for _, item in ipairs(sortedInventory) do
    if not shownGroup or shownGroup.group == item.group then
      local li = widget.addListItem("lytInventory.saItems.listItems")
      local data = {
        group = item.group,
        name = item.name,
        defaultTooltip = item.description
      }
      widget.setData("lytInventory.saItems.listItems." .. li .. ".background", {
        defaultTooltip = item.description
      })
      widget.setText("lytInventory.saItems.listItems." .. li .. ".itemName", item.name)
      widget.setText("lytInventory.saItems.listItems." .. li .. ".itemAmount", item.amount)
      widget.setImage("lytInventory.saItems.listItems." .. li .. ".groupImage", "/interface/scripted/irdenstatmanager/inventory/groups/" .. item.group .. ".png")
      
      widget.setData("lytInventory.saItems.listItems." .. li .. ".btnDeleteItem", data)
      widget.setData("lytInventory.saItems.listItems." .. li .. ".btnAddItemAmount", data)
      widget.setData("lytInventory.saItems.listItems." .. li .. ".btnSubItemAmount", data)
    end
  end
end

function fixMyStupidityWithInventory()
  if self.irden.inventory then
    for i, item in ipairs(self.irden.inventory) do 
      if type(item.group) == "table" then
        self.irden.inventory[i].group = item.group.group
      end
    end
  end
end

function createInventoryItem()
  local name = widget.getText("lytInventory.tbxItemName")
  local group = widget.getSelectedData("lytInventory.rgItemType")
  local description = widget.getText("lytInventory.tbxItemDescription")
  local amount = 1

  if not group then
    irdenUtils.alert("^red;Выберите группу")
    return
  end

  if name == "" then
    irdenUtils.alert("^red;Введите имя предмета")
    return
  end
  
  if findInventoryItem(name, group.group) then
    irdenUtils.alert("^red;Такой предмет уже существует в этой группе")
    return
  end

  table.insert(self.irden.inventory, {
    name = name,
    group = group.group,
    amount = amount,
    description = description ~= "" and description or nil
  })
  widget.setText("lytInventory.tbxItemName", "")
  widget.setText("lytInventory.tbxItemDescription", "")
  loadInventory()
end

function filterInventoryItems()
  loadInventory()
end

function addInventoryItemAmount(_, data)
  local ind = findInventoryItem(data.name, data.group)
  if ind then
    self.irden.inventory[ind].amount = self.irden.inventory[ind].amount + 1
    loadInventory()
  end
end

function subtractInventoryItemAmount(_ ,data)
  local ind = findInventoryItem(data.name, data.group)
  if ind then
    self.irden.inventory[ind].amount = math.max(self.irden.inventory[ind].amount - 1, 0)
    loadInventory()
  end
end

function removeInventoryItem(_, data)
  local ind = findInventoryItem(data.name, data.group)
  if ind then
    table.remove(self.irden.inventory, ind)
    loadInventory()
  end
end

function findInventoryItem(name, group)
  for i, item in ipairs(self.irden.inventory) do 
    if item.group == group and item.name == name then
      return i
    end
  end
end