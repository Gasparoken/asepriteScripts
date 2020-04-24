local spr = app.activeSprite
if spr == nil then
  return
end

local selectedLayer = app.activeLayer
if selectedLayer == nil then
  return
end

local hideAllLayerExceptSelecteds = false
for i = 1,#spr.layers do
  if string.find(spr.layers[i].data, 'xxx') == nil then
    -- we must hide all layers except the selected one
    hideAllLayerExceptSelecteds = true
  end
  break
end

if hideAllLayerExceptSelecteds then
  for i = 1,#spr.layers do
    spr.layers[i].isVisible = false
    spr.layers[i].data = spr.layers[i].data .. 'xxx'
  end
  for i= 1, #app.range.layers do
    app.range.layers[i].isVisible = true
  end
else
  for i = 1,#spr.layers do
    spr.layers[i].isVisible = true
    spr.layers[i].data = string.gsub(spr.layers[i].data, 'xxx', '')
  end
end
