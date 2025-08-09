function init()
  animator.setParticleEmitterOffsetRegion("mot", mcontroller.boundBox())
  animator.setParticleEmitterActive("mot", true)
  effect.setParentDirectives("")
end

function uninit()

end
