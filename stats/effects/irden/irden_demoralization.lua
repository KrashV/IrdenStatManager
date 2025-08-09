function init()
  animator.setParticleEmitterOffsetRegion("dem", mcontroller.boundBox())
  animator.setParticleEmitterActive("dem", true)
  effect.setParentDirectives("fade=FF0000=0.4")
end

function uninit()

end
