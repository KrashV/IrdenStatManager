require"/scripts/messageutil.lua"
require"/scripts/vec2.lua"

local oldInit = init;
local oldUpdate = update;

function init()
  oldInit()
  self.movement = 15
  self.showMovement = false
  self.lineColor = "#3ffe13"
  self.numberColor = "white"

  self.showPointer = false
  self.pointerPosition = {0, 0}


  message.setHandler( "irdenInteract", simpleHandler(function(_, data, _)
    local config = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
    config.defensePlayer = data.defensePlayer
    config.attackDesc = data.attackDesc
    config.attackType = data.attackType
    player.interact("ScriptPane", config)
  end))

  message.setHandler( "irdenGetArmourMovement", localHandler(function(newMovement)
    self.movement = newMovement ~= 0 and newMovement or self.movement
  end))  
  
  message.setHandler( "irdenStatManagerToShowMovement", localHandler(function(toShow)
    self.showMovement = toShow
    self.showPointer = false
  end))

  message.setHandler( "irdenStatManagerPointer", localHandler(function(pointerPosition)
    self.showPointer = not self.showPointer
    self.pointerPosition = pointerPosition
  end))
end


function update(...)
  oldUpdate(...)

  localAnimator.clearDrawables()
  if self.showMovement then
    promises:add(world.sendEntityMessage(player.id(), "irdenStatManagerGetAimPosition"), function(currentAimPosition) 

      local mPosition = world.entityPosition(player.id())
      local difference = {0, 0}

      if self.showPointer then
        difference = vec2.sub(self.pointerPosition, mPosition)

        localAnimator.addDrawable({
          image = "/interface/scripted/irdenstatmanager/numbers/arrow.png",
          position = difference,
          color = self.numberColor,
          fullbright = true
        }, "overlay")
      else
        difference = vec2.sub(currentAimPosition, mPosition)
      end
      local mouthOffset = vec2.sub(mPosition, world.entityMouthPosition(player.id()))

      localAnimator.addDrawable({
        line = { mouthOffset, {difference[1],  mouthOffset[2]} },
        position = {0, 0},
        color = self.lineColor,
        fullbright = true,
        width = 1
      }, "overlay")

      localAnimator.addDrawable({
        line = { {difference[1],  mouthOffset[2]}, difference },
        position = {0, 0},
        color = self.lineColor,
        fullbright = true,
        width = 1
      }, "overlay")

      
      local blockDifference = math.floor((vec2.mag(vec2.sub(difference, mouthOffset)) // self.movement ) + 1)

      localAnimator.addDrawable({
        image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", math.min(blockDifference, 9)),
        position = {difference[1],  mouthOffset[2]},
        color = self.numberColor,
        fullbright = true
      }, "overlay")

    end)
  end

  promises:update()
end