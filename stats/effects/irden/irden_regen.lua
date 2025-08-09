function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterActive("healing", config.getParameter("particles", true))

end


function uninit()
  
end
