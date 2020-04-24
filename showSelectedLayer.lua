local spr = app.activeSprite
if spr == nil then
  return
end

local selectedLayer = app.activeLayer
if selectedLayer == nil then
  return
end

local hideAllLayerExceptSelectedOnee = false
for i = 1,#spr.layers do
  if spr.layers[i] ~= selectedLayer then
    if string.find(spr.layers[i].data, 'xxx') == nil then
      -- we must hide all layers except the selected one
      hideAllLayerExceptSelectedOnee = true
    end
    break
  end
end

if hideAllLayerExceptSelectedOnee then
  for i = 1,#spr.layers do
    spr.layers[i].isVisible = false
    spr.layers[i].data = spr.layers[i].data .. 'xxx'
  end
  selectedLayer.isVisible = true
else
  for i = 1,#spr.layers do
    spr.layers[i].isVisible = true
    spr.layers[i].data = string.gsub(spr.layers[i].data, 'xxx', '')
  end
end
