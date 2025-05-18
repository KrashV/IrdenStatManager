require "/scripts/messageutil.lua"

function init()
  self.confirmationLayout = "/interface/scripted/irdenstatmanager/export/confirmImport/confirmImport.config:confirmationPaneLayout"
end

function import()
  local text = widget.getText("tbxImport")

  if text == "" then
    return
  end

  local success, result = pcall(sb.parseJson, text)
  if not success then
    interface.queueMessage("Невозможно распарсить JSON")
    pane.dismiss()
    return
  else
    if not result["stats"] then
      interface.queueMessage("Неверный формат JSON")
      pane.dismiss()
      return
    end


    promises:add(
      player.confirm({
        title = "Импортировать данные?",
        subtitle ="Это действие перезапишет ваши текущие данные.",
        sourceEntityId = player.id(),
        okCaption = "Да",
        icon = "/interface/popup/warning.png",
        cancelCaption = "Нет",
        paneLayout = self.confirmationLayout,
        message = "Вы уверены, что хотите продолжить?"
      }), function (ok)
        if ok then
          player.setProperty("irden", result)
          interface.queueMessage("Импорт данных завершен")
          pane.dismiss()
        end
      end)
  end
end

function update(dt)
  promises:update()
end