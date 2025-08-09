function init()
  animator.setParticleEmitterOffsetRegion("frozen", mcontroller.boundBox())
  effect.setParentDirectives("fade=00BBFF=0.05")
  animator.setParticleEmitterActive("frozen", true)
end

function update(dt)

end

function uninit()
  
end