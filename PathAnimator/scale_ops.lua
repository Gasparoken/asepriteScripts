-- Scale Ops
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

dofile('./constants.lua')
dofile('./animation_functions.lua')

function resizeImage(image, scaleFactor)
 local currentSprite = app.activeSprite
 local newSpr = Sprite(image.width, image.height)
 local cel = newSpr.layers[1]:cel(1)
 cel.image = image:clone()
 app.activeSprite = newSpr
 app.command.SpriteSize{
   ui=false,
   scale=scaleFactor,
   method="nearest"
 }
 app.activeSprite = currentSprite
 local resizedImage = newSpr.layers[1]:cel(1).image:clone()
 newSpr:close()
 return resizedImage
end

scaledCurve = nil
function applyScaleFunction(currentFrame, framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
  local currentFrameN = (currentFrame - 1) / (framesCountToFill - 1)
  local funcValue
  local deltaScale = finalScale - initialScale
  if scaleFunction == SCALE_SINUSOIDAL then
    funcValue = sinusoidal(currentFrameN)
  elseif scaleFunction == SCALE_PARABOLIC then
    funcValue = parabolic(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUTDAMPED then
    funcValue = easyOutDamped(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUTDAMPED2 then
    funcValue = easyOutDamped2(currentFrameN)
  elseif scaleFunction == SCALE_EASYINOUT then
    funcValue = easyInOut(currentFrameN)
  elseif scaleFunction == SCALE_EASYIN then
    funcValue = easyIn(currentFrameN)
  elseif scaleFunction == SCALE_EASYOUT then
    funcValue = easyOut(currentFrameN)
  elseif scaleFunction == SCALE_BYLAYER then
    if scaleFunLayer == nil then
      app.alert(string.format("Error: on function timeNToIndex(), in 'scale_ops.lua'. Neither selected layer contains '%s' in its name.", STRING_SCALE_LAYER))
      return nil
    end
    if scaledCurve == nil then
     scaledCurve = makeCurveFromLayer(scaleFunLayer, false)
    end
    funcValue = byLayer(currentFrameN, scaledCurve)
  else
    funcValue = lineal(currentFrameN)
  end
  return funcValue * deltaScale + initialScale
end

function makeScaleVector(framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
 local scaleVector = {}
 for i=1, framesCountToFill, 1 do
  table.insert(scaleVector, applyScaleFunction(i, framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale))
 end
 return scaleVector
end

