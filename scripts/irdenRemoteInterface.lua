require"/scripts/messageutil.lua"

local old = init;

function init()
  old()
  
  message.setHandler( "irdenInteract", function(a, b, c, data, e)
    local config = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
    config.defensePlayer = data.defensePlayer
    config.attackDesc = data.attackDesc
    config.attackType = data.attackType
    player.interact("ScriptPane", config)
  end)
end
