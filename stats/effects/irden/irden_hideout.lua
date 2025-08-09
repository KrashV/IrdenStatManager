function init()
  animator.setParticleEmitterOffsetRegion("hideout", mcontroller.boundBox())
  animator.setParticleEmitterActive("hideout", true)
  effect.setParentDirectives("border=1;DAFF7F50;00000000")
end

function uninit()

end
