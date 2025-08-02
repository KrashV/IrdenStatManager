function init()
  animator.setParticleEmitterOffsetRegion("electro", mcontroller.boundBox())
  animator.setParticleEmitterActive("electro", true)
  animator.playSound("spark", 2)
  
end

function update(dt)

end

function uninit()
  
end
