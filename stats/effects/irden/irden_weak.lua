function init()
  self.mouthPosition = status.statusProperty("mouthPosition") or {0,0}
    self.mouthBounds = {self.mouthPosition[1], self.mouthPosition[2], self.mouthPosition[1], self.mouthPosition[2]}
    animator.setParticleEmitterOffsetRegion("lessdmg", self.mouthBounds)
  animator.setParticleEmitterActive("lessdmg", true)
end

function update(dt)

end

function uninit()
  
end