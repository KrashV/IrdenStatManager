local soundInterval = 0.3
local lastSoundTime = 0

function init()
    script.setUpdateDelta(1)
    animator.setParticleEmitterOffsetRegion("prick", mcontroller.boundBox())
    animator.setParticleEmitterActive("prick", false)
    lastSoundTime = 0
end

function update(dt)
    local isMoving = mcontroller.yVelocity() > 0 or mcontroller.xVelocity() ~= 0

    if isMoving then
        animator.setParticleEmitterActive("prick", true)

        if os.clock() - lastSoundTime >= soundInterval then
            animator.playSound("prick")
            lastSoundTime = os.clock()
        end
    else
        animator.setParticleEmitterActive("prick", false)
        animator.stopAllSounds("prick")
        lastSoundTime = 0
    end
end

function uninit()
    animator.setParticleEmitterActive("prick", false)
    animator.stopAllSounds("prick")
end