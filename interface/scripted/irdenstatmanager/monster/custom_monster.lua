require "/monsters/monster.lua"

function init()
    self.parentEntity = config.getParameter("parentEntity")

    monster.setName(world.entityName(self.parentEntity) or "Boss")
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

    message.setHandler("isHealthbarMonster", function(_, playerId)
        if playerId == self.parentEntity then
            return nil
        end
        return true
    end)

    monster.setDamageBar("special")
    status.setPersistentEffects("invincibilityTech", {
        { stat = "breathProtection", amount = 1 },
        { stat = "biomeheatImmunity", amount = 1 },
        { stat = "biomecoldImmunity", amount = 1 },
        { stat = "biomeradiationImmunity", amount = 1 },
        { stat = "lavaImmunity", amount = 1 },
        { stat = "poisonImmunity", amount = 1 },
        { stat = "tarImmunity", amount = 1 },
        { stat = "invulnerable", amount = 1 },
        { stat = "healthMultiplier", amount = 1 }
    })
    self.health = status.resource("health")
end

function update(dt)
    mcontroller.setPosition(world.entityPosition(self.parentEntity))
    if not world.entityExists(self.parentEntity) then
        destroy()
    end
end

function updateHealth(currentHealth, maxHealth)
    local healthPercentage = (maxHealth - currentHealth) / maxHealth
    local currentHp = self.health - (self.health * healthPercentage)
    status.setResource("health", currentHp)
    return true
end

function destroy()
    monster.setDropPool(nil)
    monster.setDeathParticleBurst(nil)
    monster.setDeathSound(nil)
    self.deathBehavior = nil
    self.shouldDie = true
    status.addEphemeralEffect("monsterdespawn")
end

function uninit()
    monster.setDamageBar("none")
end