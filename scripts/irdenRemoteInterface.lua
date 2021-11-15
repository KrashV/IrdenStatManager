require"/scripts/messageutil.lua"

local old = init;

function init()
  old()
  message.setHandler( "irdenInteract", simpleHandler(player.interact) )
end
