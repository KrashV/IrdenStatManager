require "/scripts/vec2.lua"
require "/scripts/messageutil.lua"
require "/scripts/util.lua"
require "/scripts/utf8.lua"

-- RPC Promise Mock
RPCPromise = {}

function RPCPromise:new(o)
  local obj = o or {}
  obj.hasSucceeded = false
  obj.processingTime = 0

  setmetatable(obj, self)
  self.__index = self
  return obj
end

function RPCPromise:finished()
end

function RPCPromise:succeeded()
  return self.hasSucceeded
end

function RPCPromise:result()
  return nil
end

-- Move Promise - subclass of RPCPromise
-- We only need the :finished method to rewrite, as it is called every tick

MovePromise = RPCPromise:new()

function MovePromise:finished()
  local currentPos = widget.getPosition(self.name)
  if vec2.eq(currentPos, self.destination) then self.hasSucceeded = true; return true end

  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration
  widget.setPosition(self.name, vec2.lerp(t, self.destination, self.start))
end

-- ProcessPromise - subclass of RPCPromise
-- Again, we only need the :finish method to rewrite

ProcessPromise = RPCPromise:new()

function ProcessPromise:finished()
  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration

  widget.setProgress(self.name, util.lerp(t, self.endValue, self.startValue))

  if t <= 0.001 then self.hasSucceeded = true return true end
end

-- Rotate the promise widget
RotateImagePromise = RPCPromise:new()

function RotateImagePromise:finished()
  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration
  local angle = util.lerp(t, self.endValue, self.startValue)

  if self.rotationCenter then
    widget.setPosition(self.name, vec2.add(self.startPosition, vec2.sub(self.rotationCenter, vec2.rotate(self.rotationCenter, angle))))
  end

  widget.setImageRotation(self.name, angle)
  if t <= 0 then self.hasSucceeded = true return true end
end

-- Scale the promise widget
ScaleImagePromise = RPCPromise:new()

function ScaleImagePromise:finished()
  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration
  local size = util.lerp(t, self.endValue, self.startValue)

  if self.scalingCenter then
    widget.setPosition(self.name, vec2.add(self.startPosition, vec2.sub(self.scalingCenter, vec2.mul(self.scalingCenter, size))))
  end

  widget.setImageScale(self.name, size)
  if t <= 0 then self.hasSucceeded = true return true end
end

-- Scale the promise widget
SetSizePromise = RPCPromise:new()

function SetSizePromise:finished()
  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration
  local size = {util.lerp(t, self.endSize[1], self.startSize[1]), util.lerp(t, self.endSize[2], self.startSize[2])}

  widget.setSize(self.name, size)
  if t <= 0 then self.hasSucceeded = true return true end
end


-- Set text letter by letter
SetTextPromise = RPCPromise:new()

function SetTextPromise:finished()
  self.processingTime = self.processingTime + script.updateDt()
  local t = (self.duration - self.processingTime) / self.duration
  local len = math.floor(util.lerp(t, 1, utf8.len(self.text)))

  widget.setText(self.name, utf8.sub(self.text, 1, utf8.len(self.text) - len))
  if t <= 0 then self.hasSucceeded = true return true end
end





-- Animated Widget wrapper
AnimatedWidget = {}
AnimatedWidget.__index = AnimatedWidget


function AnimatedWidget:bind(wid)
  local awid = {}
  setmetatable(awid, AnimatedWidget)
  awid.name = wid
  return awid
end

function AnimatedWidget:move(destination, duration)
  return MovePromise:new{ name = self.name, start = widget.getPosition(self.name), destination = destination, duration = duration }
end

function AnimatedWidget:process(oldValue, newValue, duration)
  return ProcessPromise:new{ name = self.name, startValue = oldValue, endValue = newValue, duration = duration}
end

function AnimatedWidget:rotate(oldValue, newValue, duration, rotationCenter)
  return RotateImagePromise:new{ name = self.name, startValue = oldValue, endValue = newValue, duration = duration, rotationCenter = rotationCenter, startPosition = widget.getPosition(self.name)}
end

function AnimatedWidget:scale(oldValue, newValue, duration, scalingCenter)
  return ScaleImagePromise:new{ name = self.name, startValue = oldValue, endValue = newValue, duration = duration, scalingCenter = scalingCenter, startPosition = widget.getPosition(self.name)}
end

function AnimatedWidget:setSize(newSize, duration)
  return SetSizePromise:new{ name = self.name, startSize = widget.getSize(self.name), endSize = newSize, duration = duration}
end

function AnimatedWidget:setText(text, duration)
  return SetTextPromise:new{ name = self.name, text = text, duration = duration }
end

animatedWidgets = PromiseKeeper.new()