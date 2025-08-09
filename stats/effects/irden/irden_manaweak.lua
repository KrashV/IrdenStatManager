function init()
  animator.setParticleEmitterOffsetRegion("manaweak", mcontroller.boundBox())
  animator.setParticleEmitterActive("manaweak", config.getParameter("particles", true))

end


function uninit()
  
end
