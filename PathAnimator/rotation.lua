-- Rotation
-- Copyright (C) 2020 Gaspar Capello

EXPAND = 1

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
        -- local px = centeredImage:getPixel(x, y)
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi / 2 then
    -- print("angle == math.pi / 2")
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(centeredImage.width - 1 - y, x)
        -- if x >= centeredImage.width /2 -1 and x < centeredImage.width /2 and y == 5 then
        --   print(string.format("Px got from %d, %d  :  and draw on %d, %d  :  px = %x", centeredImage.width - 1 - y, x, x, y, px))
        -- end
        outputImg:drawPixel(x, y, px)
      end
    end
  elseif angle == math.pi * 3 / 2 then
    for y = 0 , centeredImage.height-1, 1 do
      for x = 0, centeredImage.width-1, 1 do
        local px = centeredImage:getPixel(y, centeredImage.height - 1 - x)
        -- local px = centeredImage:getPixel(x, y)
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

function resizeImage(image, expandK)
  local currentSprite = app.activeSprite
  local newSpr = Sprite(image.width, image.height)
  local cel = newSpr.layers[1]:cel(1)
  cel.image = image:clone()
  app.activeSprite = newSpr
  app.command.SpriteSize{
    ui=false,
    scale=expandK,
    method="nearest"
  }
  app.activeSprite = currentSprite
  local resizedImage = newSpr.layers[1]:cel(1).image:clone()
  newSpr:close()
  return resizedImage
end

function makeRotationLayerReference(layer, image, deltaDegrees)
  -- clean the cels
  for i=1, #layer.cels, 1 do
    app.activeSprite:deleteCel(layer, i)
  end
  local expandedRefImg
  if EXPAND == 1 then
    expandedRefImg = image:clone()
  else
    expandedRefImg = resizeImage(image, EXPAND)
  end
  local k = 1
  local progressSprite = nil
  for i=0, 360-deltaDegrees, deltaDegrees do
    local expandedImage = Rotar(expandedRefImg, i * math.pi / 180)
    if EXPAND == 1 then
      app.activeSprite:newCel(layer, k, expandedImage, Point(0 , 0))
    else
      app.activeSprite:newCel(layer, k, resizeImage(expandedImage, 1.0 / EXPAND, Point(0, 0)))
    end
    k = k+1
  end
  app.activeCel = layer:cel(1)
  app.useTool { tool="pencil",
                color = Color{r=255, g=255, b=255, a=255},
                points = { Point(0, 0) }
              }
  app.useTool { tool="eraser",
                points = { Point(0, 0) }
              }
end

function extractCelRotated(rotauxLayer, angle)
  if rotauxLayer == nil then
    app.alert(string.format("Internal error: no %s layer found as first argument of 'extractImageRotated()' function in 'rotation.lua'.", STRING_ROTAUX_LAYER))
    return nil
  end
  local deltaAngle = 2 * math.pi / #rotauxLayer.cels
  local celIndex = 1 + ((math.floor(angle / deltaAngle)) % #rotauxLayer.cels)
  if rotauxLayer:cel(celIndex) == nil then
    app.alert(string.format("Internal error: no cel index %d found in 'extractImageRotated()' function in 'rotation.lua'.", celIndex))
    return nil
  end
  return rotauxLayer:cel(celIndex)
end