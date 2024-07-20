require "/scripts/messageutil.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

local oldInit = init;
local oldUpdate = update;

function init()
    oldInit()
    player.setProperty("irden_stat_manager_ui_open", false)
    self.standartMovement = 3
    self.movement = 3
    self.showLevel = 0
    self.lineColor = "#3ffe13"
    self.numberColor = "white"
    self.movementMultiplier = 5

    self.showPointer = false
    self.pointerPosition = { 0, 0 }

    self.attackQueue = nil

    message.setHandler("irdenInteractv2", simpleHandler(function(_, data, _)
        if not player.getProperty("irden_stat_manager_ui_open") then
            local config = root.assetJson("/interface/scripted/collections/collectionsgui.config")
            player.interact("ScriptPane", config)
        end
        self.attackQueue = self.attackQueue or {}
        table.insert(self.attackQueue, data)
    end))

    message.setHandler("irden_get_action_queue", localHandler(function()
        local queue = copy(self.attackQueue)
        self.attackQueue = nil
        return queue
    end))

    message.setHandler("irdenInteract", simpleHandler(function(_, data, _)
        local config = root.assetJson("/interface/scripted/irdenstatmanager/irdenstatmanager.config")
        player.interact("ScriptPane", sb.jsonMerge(config, data))
    end))

    message.setHandler("irdenGetArmourMovement", localHandler(function(newMovement)
        self.movement = newMovement ~= 0 and newMovement or self.movement
    end))

    message.setHandler("irdenStatManagerToShowMovement", localHandler(function(showLevel)
        self.showLevel = showLevel
        self.showPointer = false
    end))

    message.setHandler("irdenStatManagerPointer", localHandler(function(pointerPosition)
        self.showPointer = not self.showPointer
        self.pointerPosition = pointerPosition
    end))

    message.setHandler("ism_your_turn", simpleHandler(function(fightName)
        local conf = root.assetJson("/interface/scripted/irdenstatmanager/ismnotify/ismnotify.config")
        conf.text = string.format("^gray;[^red;%s^gray;]^reset;: Твой ход!", fightName)
        conf.sound = "/sfx/tech/mech_horn_charge.ogg"
        player.interact("ScriptPane", conf)
    end))
end

function update(...)
    oldUpdate(...)

    if self.showLevel > 1 then
        localAnimator.clearDrawables()
        -- Show players around
        local pId = player.id()
        local mPosition = world.entityPosition(pId)
        local mouthOffset = vec2.sub(mPosition, world.entityMouthPosition(pId))
        local distanceInBlocks = self.movement * self.movementMultiplier
        local stanartDistanceInBlocks = self.standartMovement * self.movementMultiplier

for _, p in ipairs(world.playerQuery(mPosition, 50, { withoutEntityId = pId })) do
    local entityPos = world.entityPosition(p)
    local distance = vec2.sub(entityPos, mPosition)
    local blockDistance = vec2.mag(vec2.sub(distance, mouthOffset)) / distanceInBlocks
    local standartBlockDistance = vec2.mag(vec2.sub(distance, mouthOffset)) / stanartDistanceInBlocks

    local n = blockDistance < 0.3 and "X" or math.min(math.floor(blockDistance + 1), 9)
    local v = standartBlockDistance < 0.3 and "X" or math.min(math.floor(standartBlockDistance + 1), 9)

    local drawable1 = {
        image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", n),
        position = vec2.add(distance, { 0, 2 }),
        color = self.numberColor,
        fullbright = true
    }

    localAnimator.addDrawable(drawable1, "overlay")

    if distanceInBlocks ~= stanartDistanceInBlocks then
        local drawable2 = {
            image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
            position = vec2.add(distance, { 0, 3.5 }),
            color = self.numberColor,
            fullbright = true
        }

        local drawable3 = {
            image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
            position = vec2.add(distance, { 1, 2 }),
            color = self.numberColor,
            fullbright = true
        }

        localAnimator.addDrawable(drawable2, "overlay")
        localAnimator.addDrawable(drawable3, "overlay")
    end
end

        if self.showLevel > 2 then
            localAnimator.clearDrawables()
            -- Show ruler
            promises:add(world.sendEntityMessage(pId, "irdenStatManagerGetAimPosition"), function(currentAimPosition)
                local difference = { 0, 0 }

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


                localAnimator.addDrawable({
                    line = { mouthOffset, { difference[1], mouthOffset[2] } },
                    position = { 0, 0 },
                    color = self.lineColor,
                    fullbright = true,
                    width = 1
                }, "overlay")

                localAnimator.addDrawable({
                    line = { { difference[1], mouthOffset[2] }, difference },
                    position = { 0, 0 },
                    color = self.lineColor,
                    fullbright = true,
                    width = 1
                }, "overlay")


                local blockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / distanceInBlocks
                local n = blockDistance < 0.3 and "X" or math.min(math.floor(blockDistance + 1), 9)

                localAnimator.addDrawable({
                    image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", n),
                    position = { difference[1], mouthOffset[2] },
                    color = self.numberColor,
                    fullbright = true
                }, "overlay")

                if distanceInBlocks ~= stanartDistanceInBlocks then
                    local standartBlockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / stanartDistanceInBlocks
                    local v = blockDistance < 0.3 and "X" or math.min(math.floor(standartBlockDistance + 1), 9)

                    localAnimator.addDrawable({
                        image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
                        position = { difference[1], mouthOffset[2] + 1.5 },
                        color = self.numberColor,
                        fullbright = true
                    }, "overlay")

                    localAnimator.addDrawable({
                        image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
                        position = { difference[1] + 1.2, mouthOffset[2] },
                        color = self.numberColor,
                        fullbright = true
                    }, "overlay")
                end
            end)
        end
    end

    promises:update()
end
