function init()
  message.setHandler("irdenStatManagerGetAimPosition", function(_, isLocal, data)
    if isLocal then
      return tech.aimPosition()
    end
  end)
  self.pressedLMB = false
  self.pressedRMB = false
end

function update(args)
  if self.pressedLMB then
    if not args.moves.primaryFire then
      world.sendEntityMessage(entity.id(), "irdenStatManagerPointer", tech.aimPosition())
    end
  end

  self.pressedLMB = args.moves.primaryFire
end