require "/scripts/messageutil.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/timer.lua"
require "/interface/scripted/irdenstatmanager/irdenutils.lua"

function init()
    player.setProperty("irden_stat_manager_ui_open", false)
    self.standartMovement = 3
    self.showLevel = 0
    self.lineColor = "#3ffe13"
    self.numberColor = "white"
    self.movementMultiplier = 5

    self.isOpenSB = root.assetOrigin and root.assetOrigin("/opensb/coconut.png")
    if self.isOpenSB then
        self.drawCanvas = interface.bindCanvas("drawISMRulerCanvas")
    end

    self.irden = irdenUtils.loadIrden()

    local movementBonus = root.assetJson("/interface/scripted/collections/collectionsgui.config").gui.lytArmory.children.rgArmour.buttons[self.irden.gear.armour.armour + 2].data.movementBonus
    
    self.movement = irdenUtils.getBonusByTag(movementBonus).value + irdenUtils.addBonusToStat(0, "MOVEMENT")

    getPlayers()

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

    --message.setHandler("irdenStatManagerToShowMovement", localHandler(function(showLevel)
    --    self.showLevel = showLevel
    --    self.showPointer = false
    --end))

    message.setHandler("irdenGetArmourMovement", localHandler(function(newMovement)
        self.movement = newMovement ~= 0 and newMovement or self.movement
    end))

    message.setHandler("irdenStatManagerToShowMovement", localHandler(function(showLevel)
        self.showLevel = showLevel
        self.showPointer = false
    end))


    message.setHandler("ism_your_turn", simpleHandler(function(fightName)
        local conf = root.assetJson("/interface/scripted/irdenstatmanager/ismnotify/ismnotify.config")
        conf.text = string.format("^gray;[^red;%s^gray;]^reset;: Твой ход!", fightName)
        conf.sound = "/sfx/tech/mech_horn_charge.ogg"
        player.interact("ScriptPane", conf)
    end))

end

function getPlayers()
    self.pIds = world.playerQuery(player.aimPosition(), 50, {withoutEntityId = player.id()})
    timers:add(0.5, function() getPlayers() end)
end


function drawDrawable(drawable)
    if self.isOpenSB then
        if drawable.image then
            self.drawCanvas:drawImage(drawable.image, vec2.div(drawable.position, interface.scale()), drawable.scale / interface.scale(), drawable.color)
        elseif drawable.line then 
            self.drawCanvas:drawLine(vec2.div(drawable.line[1], interface.scale()), vec2.div(drawable.line[2], interface.scale()), drawable.color, drawable.width)
        end
    else
        interface.drawDrawable(drawable, {0, 0}, 1)
    end
end


function update(...)
    if self.drawCanvas then
        self.drawCanvas:clear()
    end

    if _ENV["starExtensions"] and starExtensions.version() or self.isOpenSB then
        if input.bindDown("irden", "ruler") then
            self.showLevel = self.showLevel ~= 3 and 3 or 0
        end
    end

    if self.showLevel == 0 then
        return
    elseif self.showLevel > 1 then
        -- Show players around
        local pId = player.id()
        local mPosition = world.entityPosition(pId)
        local mouthPosition = world.entityMouthPosition(pId)
        local mouthOffset = vec2.sub(mPosition, world.entityMouthPosition(pId))
        local distanceInBlocks = self.movement * self.movementMultiplier
        local stanartDistanceInBlocks = self.standartMovement * self.movementMultiplier

        for _, p in ipairs(self.pIds) do
            local entityPos = world.entityPosition(p)
            if entityPos == nil then return end
            local distance = vec2.sub(entityPos, mPosition)
            local blockDistance = vec2.mag(vec2.sub(distance, mouthOffset)) / distanceInBlocks
            local standartBlockDistance = vec2.mag(vec2.sub(distance, mouthOffset)) / stanartDistanceInBlocks

            local n = blockDistance < 0.3 and "X" or math.min(math.floor(blockDistance + 1), 9)
            local v = standartBlockDistance < 0.3 and "X" or math.min(math.floor(standartBlockDistance + 1), 9)

            local drawable1 = {
                image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", n),
                position = camera.worldToScreen(vec2.add(entityPos, { 0, 2 })),
                color = self.numberColor,
                fullbright = true,
                scale = 3
            }

            drawDrawable(drawable1)

            if distanceInBlocks ~= stanartDistanceInBlocks then
                local drawable2 = {
                    image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
                    position = camera.worldToScreen(vec2.add(entityPos, { 0, 3.0 })),
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                }

                local drawable3 = {
                    image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
                    position = camera.worldToScreen(vec2.add(entityPos, { 1.0, 2 })),
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                }

                drawDrawable(drawable2)
                drawDrawable(drawable3)
            end
        end

        if self.showLevel > 2 then
            -- Show ruler
            local difference = { 0, 0 }
            local aimPosition = { 0, 0 }

            if input.mouseDown("MouseLeft") then
                self.showPointer = not self.showPointer
                self.pointerPosition = player.aimPosition()
            end

            if self.showPointer then
                difference = vec2.sub(self.pointerPosition, mPosition)
                aimPosition = camera.worldToScreen(self.pointerPosition)

                drawDrawable({
                    image = "/interface/scripted/irdenstatmanager/numbers/arrow.png",
                    position = aimPosition,
                    color = self.numberColor,
                    fullbright = true,
                    scale = 4
                })
            else
                difference = vec2.sub(player.aimPosition(), mPosition)
                aimPosition = camera.worldToScreen(player.aimPosition())
            end


            drawDrawable({
                line = { camera.worldToScreen(mouthPosition), { aimPosition[1], camera.worldToScreen(mouthPosition)[2] } },
                position = { 0, 0 },
                color = self.lineColor,
                fullbright = true,
                width = 2
            })

            drawDrawable({
                line = { { aimPosition[1], camera.worldToScreen(mouthPosition)[2] }, aimPosition },
                position = { 0, 0 },
                color = self.lineColor,
                fullbright = true,
                width = 2
            })


            local blockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / distanceInBlocks
            local n = blockDistance < 0.3 and "X" or math.min(math.floor(blockDistance + 1), 9)

            drawDrawable({
                image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", n),
                position = aimPosition,
                color = self.numberColor,
                fullbright = true,
                scale = 4
            })

            if distanceInBlocks ~= stanartDistanceInBlocks then
                local standartBlockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / stanartDistanceInBlocks
                local v = blockDistance < 0.3 and "X" or math.min(math.floor(standartBlockDistance + 1), 9)

                drawDrawable({
                    image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
                    position = { aimPosition[1], aimPosition[2] + 45 },
                    color = self.numberColor,
                    fullbright = true,
                    scale = 4
                })

                drawDrawable({
                    image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
                    position = { aimPosition[1] + 30, aimPosition[2] },
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                })
            end
        end
    end
    timers:update(...)
    promises:update()
end
