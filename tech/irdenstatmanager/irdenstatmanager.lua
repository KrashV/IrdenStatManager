function init()
  message.setHandler("irdenStatManagerGetAimPosition", function(_, isLocal, data)
    return tech.aimPosition()
  end)
end