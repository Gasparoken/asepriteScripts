-- Copyright (C) 2020 Gaspar Capello

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
