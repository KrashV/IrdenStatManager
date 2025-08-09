function init()
  animator.setParticleEmitterOffsetRegion("poison", mcontroller.boundBox())
  animator.setParticleEmitterActive("poison", true)
  effect.setParentDirectives("fade=6B9E61=0.4")
end

function uninit()

end
