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


--================================================================--
--======================= ROTAR SCRIPT ===========================--
--================================================================--


-- Input: layer range with some image.
-- Output: a new layer named 'RotationResult' with the sufficient frames to accomplish RPS and turns.

-- Warnings:
-- This script assumes constant frame rate, otherwise, the angles and RPS won't match to expected.
-- If the RPS is too fast for the frame rate, the rotation animation will seem slower or erratic than expected.
-- To solve the last issue, you shall study one of these options:
--   1 - Increase the frame rate (decrement frame duration).
--   2 - Decrement the RPS number.
--   3 - Add shadows and custom effects as you wish in each frame.

local ROTATED_LAYER_RESULT = "RotationResult"
local sprite = app.activeSprite

if not app.isUIAvailable then
    return nil
 end
 
if sprite == nil then
  app.alert("WARNING: You should open a sprite first.")
  return nil
end

function Rotar(image2Rot, angle)
    local maskColor = image2Rot.spec.transparentColor
    local maxSize = math.floor(image2Rot.width * 1.416)
    if math.floor(image2Rot.height * 1.416) > maxSize then
      maxSize = math.floor(image2Rot.height * 1.416)
    end
    if maxSize%2 == 1 then
      maxSize = maxSize + 1
    end
    -- maxSize is a even number
    local centeredImage = Image(maxSize, maxSize)
    -- center image2Rot in the new image 'centeredImage'
    local image2RotPosition = Point((centeredImage.width - image2Rot.width) / 2, (centeredImage.height - image2Rot.height) / 2)
    for y=image2RotPosition.y, image2RotPosition.y + image2Rot.height - 1, 1 do
      for x=image2RotPosition.x, image2RotPosition.x + image2Rot.width - 1, 1 do
        centeredImage:drawPixel(x, y, image2Rot:getPixel(x - image2RotPosition.x, y - image2RotPosition.y))
      end
    end
  
    local pivot = Point(centeredImage.width / 2 - 0.5 + (image2Rot.width % 2) * 0.5, centeredImage.height / 2 - 0.5 + (image2Rot.height % 2) * 0.5)
    local outputImg = Image(centeredImage.width, centeredImage.height)
  
    if angle == 0 then
      for y = 0 , centeredImage.height-1, 1 do
        for x = 0, centeredImage.width-1, 1 do
          local px = centeredImage:getPixel(x, y)
          outputImg:drawPixel(x, y, px)
        end
      end
    elseif angle == math.pi / 2 then
      for y = 0 , centeredImage.height-1, 1 do
        for x = 0, centeredImage.width-1, 1 do
          local px = centeredImage:getPixel(centeredImage.width - 1 - y, x)
          outputImg:drawPixel(x, y, px)
        end
      end
    elseif angle == math.pi * 3 / 2 then
      for y = 0 , centeredImage.height-1, 1 do
        for x = 0, centeredImage.width-1, 1 do
          local px = centeredImage:getPixel(y, centeredImage.height - 1 - x)
          outputImg:drawPixel(x, y, px)
        end
      end
    elseif angle == math.pi then
      for y = 0 , centeredImage.height-1, 1 do
        for x = 0, centeredImage.width-1, 1 do
          local px = centeredImage:getPixel(centeredImage.width - 1 - x, centeredImage.height - 1 - y)
          outputImg:drawPixel(x, y, px)
        end
      end
    else
      for y = 0 , centeredImage.height-1, 1 do
        for x = 0, centeredImage.width-1, 1 do
          local oposite = pivot.x - x
          local adyacent = pivot.y - y
          local hypo = math.sqrt(oposite^2 + adyacent^2)
          if hypo == 0.0 then
            local px = centeredImage:getPixel(x, y)
            outputImg:drawPixel(x, y, px)
          else
            local currentAngle = math.asin(oposite / hypo)
            local resultAngle
            local u
            local v
            if adyacent < 0 then
              resultAngle = currentAngle + angle
              v = - hypo * math.cos(resultAngle)
            else
              resultAngle = currentAngle - angle
              v = hypo * math.cos(resultAngle)
            end
            u = hypo * math.sin(resultAngle)
            if centeredImage.width / 2 - u >= 0 and
              centeredImage.height / 2 - v >= 0 and
              centeredImage.height / 2 - v < centeredImage.height and
              centeredImage.width / 2 - u < centeredImage.width then
              local px = centeredImage:getPixel(centeredImage.width / 2 - u, centeredImage.height / 2 - v)
              if px ~= maskColor then
                outputImg:drawPixel(x, y, px)
              end
            end
          end
        end
      end
    end
    return outputImg
  end

---==== UI Interfase ====---
--========================--

local layers = {}
-- Copying the original selected layers:
local imageFound = false
for i,layer in ipairs(app.range.layers) do
  if layer.name:find(ROTATED_LAYER_RESULT) == nil then
    table.insert(layers, layer)
    if layer:cel(1) ~= nil and layer:cel(1).image ~= nil then
      imageFound = true
    end
  end
end
if not imageFound then
  app.alert("Error: no layer with an image has been selected. Please select a layer or range of layers with some image.")
  return nil
end

--Abrir dialogo selección de pivot y angulo a girar
local turnDirection
local dlg = Dialog()
dlg:label{  id= "label",
            text= "Rotation Tool"
}
dlg:newrow()          
dlg:entry{  id= "rps",
            label= "Rev per Second:"
}
dlg:newrow()          
dlg:entry{  id= "turns",
            label= "Turn Count:"
}
dlg:newrow()
dlg:button{   text="Turn L",
              onclick=
                function()
                    turnDirection = 1
                    dlg:close()
                end
}
dlg:button{ text="Turn R",
            onclick=
              function()
                  turnDirection = -1
                  dlg:close()
              end
}
dlg:show{ wait=true
}

-- Flattening the image
local layersToMergeDown = {}

for i=1, #layers, 1 do
  table.insert(layersToMergeDown, sprite:newLayer())
end
for i=1, #layers, 1 do
  if layers[i]:cel(1) ~= nil then
    local position = layers[i]:cel(1).position
    local image = layers[i]:cel(1).image
    local frame = layers[i]:cel(1).frame
    sprite:newCel(layersToMergeDown[i], frame, image, position)
  end
end
for i=1, #layers-1, 1 do
  app.command.MergeDownLayer()
end
local auxLayer = app.activeLayer
local imageToRotate = auxLayer:cel(1).image:clone()
if imageToRotate == nil then
  sprite:deleteLayer(auxLayer)
  app.alert("Error: selected layers do not make an image.")
  return false
end
local imageToRotatePos = auxLayer:cel(1).position
local imageToRotateCenter = Point(imageToRotate.width / 2, imageToRotate.height / 2)
sprite:deleteLayer(auxLayer)

local frameDuration = sprite.frames[1].duration


local UIdata = dlg.data
local outputName = ROTATED_LAYER_RESULT
for i,layer in ipairs(sprite.layers) do
    if layer.name:find(ROTATED_LAYER_RESULT) ~= nil then
      outputName = layer.name
      sprite:deleteLayer(layer)
      break
    end
end
local outputLayer = sprite:newLayer()
outputLayer.name = outputName

local k = 1
local rotatedImageCenter = nil
local angularStepPerFrame = turnDirection * frameDuration * UIdata.rps * math.pi * 2
for i=0, (turnDirection * 2 * math.pi - angularStepPerFrame), angularStepPerFrame do
    local rotatedImage = Rotar(imageToRotate, i)
    rotatedImagePos = Point(imageToRotatePos.x - rotatedImage.width / 2, imageToRotatePos.y - rotatedImage.height / 2) + imageToRotateCenter
    if sprite.frames[k] == nil then
      sprite:newEmptyFrame(k)
    end
    app.activeSprite:newCel(outputLayer, k, rotatedImage, rotatedImagePos)
    k = k + 1
end

local celsCount = #outputLayer.cels
local turns = math.floor(UIdata.turns)
for i=1, turns-1, 1 do
    for k=1, celsCount, 1 do
        if sprite.frames[i * celsCount + k] == nil then
            sprite:newEmptyFrame(i * celsCount + k)
        end
        app.activeSprite:newCel(outputLayer, i * celsCount + k, outputLayer:cel(k).image, outputLayer:cel(k).position)
    end
end
local fractionalTurnsCelCount = math.floor((UIdata.turns - turns) * celsCount)
for k=1, fractionalTurnsCelCount, 1 do
    if sprite.frames[k].next == nil then
        sprite:newEmptyFrame(i+1)
    end
    app.activeSprite:newCel(outputLayer, turns * celsCount + k, outputLayer:cel(k).image, outputLayer:cel(k).position)
end

app.activeFrame = 1
app.range.layers = layers