function init()
  self.interface = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
end

function activate()
  local players = world.playerQuery(activeItem.ownerAimPosition(), 1, {
    order = "nearest"
  })
  self.interface.aimPlayer = players[1]
  player.interact("ScriptPane", self.interface)
end