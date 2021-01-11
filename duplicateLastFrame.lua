spr = app.activeSprite

function duplicatePenultimateCel(layer)
 local framesCount = #app.activeSprite.frames
 if layer:cel(framesCount-1) ~= nil then
  local image = Image(layer:cel(framesCount-1).image)
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
    break
   end
  end
 end
)
