function init()
  animator.setParticleEmitterOffsetRegion("retry2", mcontroller.boundBox())
  animator.setParticleEmitterActive("retry2", true)
end

function update(dt)

end

function uninit()
  
end

function update(dt)
  player.emote("Plain")
end