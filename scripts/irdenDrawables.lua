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

    self.irden = player.getProperty("irden") or {
        stats = {
          rollany = 0,
          strength = 0,
          endurance = 0,
          perception = 0,
          reflexes = 0,
         
          magic = 0,
          willpower = 0,
          intellect = 0,
          determination = 0
        },
        gear = {
          weapon = {
            melee = -1,
            ranged = -1,
            magic = -1
          },
          armour = {
            shield = -1,
            armour = -1,
            amulet = -1
          }
        },
        bonusGroups = root.assetJson("/irden_bonuses.config") or {},
        currentHp = 20,
        rollMode = 1,
        weatherEffects = true,
        presets = {},
        overrides = {
          events = {}
        },
        crafts = {
          END = 1,
          WIL = 1,
          INT = 1
        },
        eventAttempts = {},
        inventory = {}
      }
    self.irden.bonusGroups = irdenUtils.loadCustomBonuses()

    local movementBonus = root.assetJson("/interface/scripted/collections/collectionsgui.config").gui.lytArmory.children.rgArmour.buttons[self.irden.gear.armour.armour + 2].data.movementBonus
    self.movement = 3 - (irdenUtils.getBonusByTag(movementBonus).value + irdenUtils.addBonusToStat(0, "MOVEMENT"))

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

function update(...)
    
    if _ENV["starExtensions"] and starExtensions.version() then
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
                position = camera.worldToScreen(vec2.add(mPosition, { 0, 2 })),
                color = self.numberColor,
                fullbright = true,
                scale = 3
            }

            interface.drawDrawable(drawable1, {0, 0}, 1)

            if distanceInBlocks ~= stanartDistanceInBlocks then
                local drawable2 = {
                    image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
                    position = camera.worldToScreen(vec2.add(mPosition, { 0, 3.0 })),
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                }

                local drawable3 = {
                    image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
                    position = camera.worldToScreen(vec2.add(mPosition, { 1.0, 2 })),
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                }

                interface.drawDrawable(drawable2, {0, 0}, 1)
                interface.drawDrawable(drawable3, {0, 0}, 1)
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

                interface.drawDrawable({
                    image = "/interface/scripted/irdenstatmanager/numbers/arrow.png",
                    position = aimPosition,
                    color = self.numberColor,
                    fullbright = true,
                    scale = 4
                }, {0, 0}, 1)
            else
                difference = vec2.sub(player.aimPosition(), mPosition)
                aimPosition = camera.worldToScreen(player.aimPosition())
            end


            interface.drawDrawable({
                line = { camera.worldToScreen(mouthPosition), { aimPosition[1], camera.worldToScreen(mouthPosition)[2] } },
                position = { 0, 0 },
                color = self.lineColor,
                fullbright = true,
                width = 2
            }, {0, 0}, 1)

            interface.drawDrawable({
                line = { { aimPosition[1], camera.worldToScreen(mouthPosition)[2] }, aimPosition },
                position = { 0, 0 },
                color = self.lineColor,
                fullbright = true,
                width = 2
            }, {0, 0}, 1)


            local blockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / distanceInBlocks
            local n = blockDistance < 0.3 and "X" or math.min(math.floor(blockDistance + 1), 9)

            interface.drawDrawable({
                image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", n),
                position = aimPosition,
                color = self.numberColor,
                fullbright = true,
                scale = 4
            }, {0, 0}, 1)

            if distanceInBlocks ~= stanartDistanceInBlocks then
                local standartBlockDistance = vec2.mag(vec2.sub(difference, mouthOffset)) / stanartDistanceInBlocks
                local v = blockDistance < 0.3 and "X" or math.min(math.floor(standartBlockDistance + 1), 9)

                interface.drawDrawable({
                    image = string.format("/interface/scripted/irdenstatmanager/numbers/%s.png", v),
                    position = { aimPosition[1], aimPosition[2] + 45 },
                    color = self.numberColor,
                    fullbright = true,
                    scale = 4
                }, {0, 0}, 1)

                interface.drawDrawable({
                    image = "/interface/scripted/irdenstatmanager/numbers/armored.png",
                    position = { aimPosition[1] + 30, aimPosition[2] },
                    color = self.numberColor,
                    fullbright = true,
                    scale = 3
                }, {0, 0}, 1)
            end
        end
    end
    timers:update(...)
    promises:update()
end
