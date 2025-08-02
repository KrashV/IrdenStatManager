function init()
  animator.setParticleEmitterOffsetRegion("defense", mcontroller.boundBox())
  animator.setParticleEmitterActive("defense", true)
  effect.setParentDirectives("border=1;80808040;00000000")
end

function uninit()

end
