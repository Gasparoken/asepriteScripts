local spr = app.activeSprite
local originalSelectedLayer = app.activeLayer
local originalSelectedFrame = app.activeFrame

function duplicatePenultimateCel(layer)
  local framesCount = #app.activeSprite.frames
  if layer:cel(framesCount-1) ~= nil then
    local image = Image(layer:cel(framesCount-1).image, spr.colorMode)
    spr:newCel(layer, framesCount)
    layer:cel(framesCount).image = image
    layer:cel(framesCount).position = layer:cel(framesCount-1).position
  end
end

app.transaction(
  function()
    local framesCount = #app.activeSprite.frames
    for i,layer in ipairs(spr.layers) do
      if layer:cel(framesCount) ~= nil then
        spr:newEmptyFrame()
        for i,layer in ipairs(spr.layers) do
          duplicatePenultimateCel(layer)
        end
        app.activeLayer = originalSelectedLayer
        app.activeFrame = originalSelectedFrame
        break
      end
    end
  end
)
