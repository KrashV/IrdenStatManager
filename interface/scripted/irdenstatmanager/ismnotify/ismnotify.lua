function init()
  local text = config.getParameter("text")
  local sound = config.getParameter("sound")

  if starExtensions and starExtensions.version() then
    interface.queueMessage(text)
  end

  pane.playSound(sound)

  pane.dismiss()
end