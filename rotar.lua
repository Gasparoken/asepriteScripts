-- Copyright (C) 2020-2023 Gaspar Capello

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

local DEFAULT_RPS_TEXT = "RevolutionsPerSecond:_1"
local DEFAULT_TURNS_TEXT = "TurnsCount:_1"
local DEFAULT_PIVOT_X_TEXT = "PivotX:_center"
local DEFAULT_PIVOT_Y_TEXT = "PivotY:_center"
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
  local centeredImage = Image(maxSize, maxSize, image2Rot.colorMode)
  -- center image2Rot in the new image 'centeredImage'
  local image2RotPosition = Point((centeredImage.width - image2Rot.width) / 2, (centeredImage.height - image2Rot.height) / 2)
  for y=image2RotPosition.y, image2RotPosition.y + image2Rot.height - 1, 1 do
    for x=image2RotPosition.x, image2RotPosition.x + image2Rot.width - 1, 1 do
      centeredImage:drawPixel(x, y, image2Rot:getPixel(x - image2RotPosition.x, y - image2RotPosition.y))
    end
  end

  local pivot = Point(centeredImage.width / 2 - 0.5 + (image2Rot.width % 2) * 0.5, centeredImage.height / 2 - 0.5 + (image2Rot.height % 2) * 0.5)
  local outputImg = Image(centeredImage.width, centeredImage.height, image2Rot.colorMode)

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
local dlg = Dialog{ title="Rotation Tool                             " }
dlg:newrow()
dlg:entry{  id= "rps",
            text= DEFAULT_RPS_TEXT
}
dlg:newrow()
dlg:entry{  id= "turns",
            text= DEFAULT_TURNS_TEXT
}
dlg:newrow()
dlg:entry{  id= "pivotX",
            text= DEFAULT_PIVOT_X_TEXT
}
dlg:entry{  id= "pivotY",
            text= DEFAULT_PIVOT_Y_TEXT
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

app.transaction(
  function()
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

    -- Conditioning dialog input data:
    local rps = 1.0
    if UIdata.rps:find(DEFAULT_RPS_TEXT) == nil then
      rps = UIdata.rps * 1.0
    end
    local turns = 1.0
    if UIdata.turns:find(DEFAULT_TURNS_TEXT) == nil then
      turns = UIdata.turns * 1.0
    end
    local pivot = Point(imageToRotatePos.x + imageToRotateCenter.x, imageToRotatePos.y + imageToRotateCenter.y)
    if UIdata.pivotX:find(DEFAULT_PIVOT_X_TEXT) == nil then
      pivot.x = math.floor(UIdata.pivotX)
    end
    if UIdata.pivotY:find(DEFAULT_PIVOT_Y_TEXT) == nil then
      pivot.y = math.floor(UIdata.pivotY)
    end

    local a = imageToRotatePos.x + imageToRotateCenter.x - pivot.x
    local b = imageToRotatePos.y + imageToRotateCenter.y - pivot.y
    local pivotToImageCenterDist = math.sqrt(a*a + b*b)
    local initialAngle = 0
    if pivotToImageCenterDist >= 2 then
      if a == 0 then
        if b > 0 then
          initialAngle = -math.pi /2
        else
          initialAngle = math.pi /2
        end
      elseif b == 0 then
        if a >= 2 then
          initialAngle = 0
        else
          initialAngle = math.pi
        end
      elseif a > 0 then
        initialAngle = math.atan(-b/a)
      elseif a < 0 then
        initialAngle = math.atan(-b/a) + math.pi
      end
    end

    local rotatedCachedImages = {}
    local rotatedCachedImagePositions = {}
    local rotatedCachedImagesCount = 0
    local angularStepPerFrame = turnDirection * 2 * math.pi * frameDuration * rps
    local maxAngle

    local wholeTurns = math.floor(turns)
    if turns >= 1 then
      rotatedCachedImagesCount = math.floor(1 / frameDuration)
      maxAngle = turnDirection * 2 * math.pi - angularStepPerFrame
    else
      rotatedCachedImagesCount = math.floor((turns - wholeTurns) / frameDuration)
      maxAngle = turnDirection * 2 * math.pi * (turns - wholeTurns) - angularStepPerFrame
    end

    -- Making the rotated images and positions
    for i=0, maxAngle, angularStepPerFrame do
      local rotatedImage = Rotar(imageToRotate, i)
      table.insert(rotatedCachedImages, rotatedImage)
      local rotatedImagePos = pivot - Point(rotatedImage.width / 2 - pivotToImageCenterDist * math.cos(i+initialAngle), rotatedImage.height / 2 + pivotToImageCenterDist * math.sin(i+initialAngle))
      table.insert(rotatedCachedImagePositions, rotatedImagePos)
    end

    -- Filling the cels of the whole turns
    local oneTurnCelCount = 1 / frameDuration / rps
    if turns >= 1 then
      for i=0, wholeTurns-1, 1 do
        for k=1, oneTurnCelCount, 1 do
          if sprite.frames[i * oneTurnCelCount + k] == nil then
            sprite:newEmptyFrame(i * oneTurnCelCount + k)
          end
          app.activeSprite:newCel(outputLayer, i * oneTurnCelCount + k, rotatedCachedImages[k], rotatedCachedImagePositions[k])
        end
      end
    end

    -- Filling the last cels, which represent the fractional remainder of the "turns" defined in the Rotation Tool dialog
    local fractionalCelsCount = math.floor((turns - wholeTurns) / frameDuration / rps)
    for k=1, fractionalCelsCount, 1 do
      if sprite.frames[wholeTurns * oneTurnCelCount + k] == nil then
        sprite:newEmptyFrame(wholeTurns * oneTurnCelCount + k)
      end
      app.activeSprite:newCel(outputLayer, wholeTurns * oneTurnCelCount + k, rotatedCachedImages[k], rotatedCachedImagePositions[k])
    end

    app.activeFrame = 1
    app.range.layers = layers
  end
)