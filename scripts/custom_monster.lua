require "/monsters/monster.lua"

function init()
    self.parentEntity = config.getParameter("parentEntity")
    message.setHandler("dreadwingDeath", function()
    end)
    message.setHandler("despawn", function()
    end)
    message.setHandler("killIt", function()
        monster.setDropPool(nil)
        monster.setDeathParticleBurst(nil)
        monster.setDeathSound(nil)
        self.deathBehavior = nil
        self.shouldDie = true
        status.addEphemeralEffect("monsterdespawn")
    end)
    vehicle.setInteractive(false)
    monster.setDamageBar("special")
    status.setPersistentEffects("invincibilityTech", {
        { stat = "breathProtection", amount = 1 },
        { stat = "biomeheatImmunity", amount = 1 },
        { stat = "biomecoldImmunity", amount = 1 },
        { stat = "biomeradiationImmunity", amount = 1 },
        { stat = "lavaImmunity", amount = 1 },
        { stat = "poisonImmunity", amount = 1 },
        { stat = "tarImmunity", amount = 1 },
        { stat = "invulnerable", amount = 1 }
    })
    monster.setName(world.entityName(self.parentEntity) or "Boss")
end

function update(dt)
    mcontroller.setPosition(world.entityMouthPosition(self.parentEntity))
    if not world.entityExists(self.parentEntity) then
        monster.setDropPool(nil)
        monster.setDeathParticleBurst(nil)
        monster.setDeathSound(nil)
        self.deathBehavior = nil
        self.shouldDie = true
        status.addEphemeralEffect("monsterdespawn")
    end
end

function uninit()
    monster.setDamageBar("none")
end