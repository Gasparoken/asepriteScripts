-- Path Finder
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

explorationVector = { Point( 1, -1),
                      Point( 1,  0),
                      Point( 1,  1),
                      Point( 0,  1),
                      Point(-1,  1),
                      Point(-1,  0),
                      Point(-1, -1),
                      Point( 0, -1) }

-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================

function findWhiteDot(celToExplore)
-- Encontrar el punto inicial (blanco)
  if celToExplore == nil then
    app.alert("Internal error: the input argument celToExplore is 'nil' on function findWhiteDot(), in path_finder.lua.")
    return nil
  end
  local imageToExplore = celToExplore.image
  local w = imageToExplore.width
  local h = imageToExplore.height
  local startPixel = nil
  for y=0, h-1, 1 do
    for x=0, w-1, 1 do
        local px = imageToExplore:getPixel(x, y)
        if px == 0xFFFFFFFF then
          startPixel = Point(celToExplore.position.x + x, celToExplore.position.y + y)
          break
        end
    end
  end
  return startPixel
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================
function isEnd(pathImage, x, y)
  local pxFounded = 0
  local maskColor = app.activeSprite.spec.transparentColor
  for i,point in ipairs(explorationVector) do
    if x + point.x >= 0 and
       y + point.y >= 0 and
       x + point.x < pathImage.width and
       y + point.y < pathImage.height  then
      if pathImage:getPixel(x + point.x, y + point.y) ~= maskColor and
         pathImage:getPixel(x + point.x, y + point.y) ~= MASK_COLOR2 then
        pxFounded = pxFounded + 1
      end
    end
  end
  if pxFounded == 1 then
    return Point(x, y)
  end
  return nil
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================
function findEndDots(celToExplore)
-- Encontrar el punto inicial (blanco)
  local maskColor = app.activeSprite.spec.transparentColor
  local endDots = {}
  local imageToExplore = celToExplore.image
  local w = imageToExplore.width
  local h = imageToExplore.height
  for y=0, h-1, 1 do
    for x=0, w-1, 1 do
      local point = nil
      if imageToExplore:getPixel(x, y) ~= maskColor and
         imageToExplore:getPixel(x, y) ~= MASK_COLOR2 then
        point = isEnd(imageToExplore, x, y)
        if point ~= nil then
          table.insert(endDots, point + celToExplore.position)
          if #endDots > 2 then
            return nil
          end
        end
      end
    end
  end
  if #endDots == 2 then
    return endDots
  else
    return nil
  end
end

function nextPathPoint(pathLayer, currentPoint, previousPoint)
  local maskColor = app.activeSprite.spec.transparentColor
  local pathImage = pathLayer.cels[1].image
  local imagePosition = pathLayer.cels[1].position
  currentPoint = currentPoint - imagePosition
  if previousPoint ~= nil then
    previousPoint = previousPoint - imagePosition
  end
  local pxFounded = 0
  local nextPoint = nil
  for i,point in ipairs(explorationVector) do
    if (currentPoint.x + point.x) >= 0 and
       (currentPoint.y + point.y) >= 0 and
       (currentPoint.x + point.x) < pathImage.width and
       (currentPoint.y + point.y) < pathImage.height then
      if previousPoint ~= nil then
        if previousPoint.x == (currentPoint.x + point.x) and
           previousPoint.y == (currentPoint.y + point.y) then
          -- do nothing
        else
          if pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= maskColor and
             pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= MASK_COLOR2 then
            return Point(currentPoint.x + point.x, currentPoint.y + point.y) + imagePosition
          end
        end
      else
        if pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= maskColor and
           pathImage:getPixel(currentPoint.x + point.x, currentPoint.y + point.y) ~= MASK_COLOR2 then
          return Point(currentPoint.x + point.x, currentPoint.y + point.y) + imagePosition
        end
      end
    end
  end
  return nil
end
-- ===================== -- ===================== -- =====================
-- ===================== -- ===================== -- =====================

function getPath(pathLayer)
  local startPixel = findWhiteDot(pathLayer.cels[1])
  if startPixel == nil then
    local endDots = findEndDots(pathLayer.cels[1])
    if endDots == nil then
      return nil
    end
    startPixel = endDots[1]
  end

  local image = pathLayer.cels[1].image
  local maxRepetitions = image.width * image.height
  local nextPoint = nil
  local previousPoint = nil
  local outputPath = { startPixel }
  local j = 1
  while true do
    nextPoint = nextPathPoint(pathLayer, outputPath[j], previousPoint)
    if nextPoint ~= nil then
      table.insert(outputPath, nextPoint)
      previousPoint = outputPath[j]
      j = j + 1
    else
      -- we reach the end of the path
      break
    end
    if j > maxRepetitions then
      break
    end
  end
  return outputPath
end

function distance(point1, point2)
  return math.sqrt((point1.x - point2.x)^2 + (point1.y - point2.y)^2)
end

function isPosibleConcatenatePaths(path1, path2)
-- returns 0 if the paths are no compatible to each other (all ends are too far to connect each other)
-- returns 1 if path1 can follow path2
-- returns 2 if path1 can follow reversed path2
-- returns 3 if reversed path1 can follow path2
-- returns 4 if reversed path1 can follow reversed path2
-- returns nil if any path is no valid
  if #path1 < 2 or #path2 < 2 then
    return nil
  end
  local path1End1 = path1[1]
  local path1End2 = path1[#path1]
  local path2End1 = path2[1]
  local path2End2 = path2[#path2]

  local d1 = distance(path1[1],      path2[1])      -- 
  local d2 = distance(path1[1],      path2[#path2]) -- 
  local d3 = distance(path1[#path1], path2[1])      --
  local d4 = distance(path1[#path1], path2[#path2]) --
  
  if d3 < 2 then
    return 1
  elseif d4 < 2 then
    return 2
  elseif d1 < 2 then
    return 3
  elseif d2 < 2 then
    return 4
  else
    return 0
  end
  
end

function concatenatePaths(path1, path2, concatType)
  local tempPath1 = {}
  if concatType == 2 then
    -- reversePath2 = true
    for i=#path2, 1, -1 do
      table.insert(path1, path2[i])
    end
    return path1
  elseif concatType == 3 then
    local tempPath1 = {}
    -- reversePath1 = true
    for i=#path1, 1, -1 do
      table.insert(tempPath1, path1[i])
    end
    for i=1, #path2, 1 do
      table.insert(tempPath1, path2[i])
    end
    return tempPath1
  elseif concatType == 4 then
    -- reversePath1 = true
    -- reversePath2 = true
    local tempPath1 = {}
    reversePath1 = true
    for i=#path1, 1, -1 do
      table.insert(tempPath1, path1[i])
    end
    for i=#path2, 1, -1 do
      table.insert(tempPath1, path2[i])
    end
    return tempPath1
  else
    if concatType ~= 1 then
      return nil
    end
    for i=1, #path2, 1 do
      table.insert(path1, path2[i])
    end
    return path1
  end
end

curve = nil
function timeNToIndex(timeN, timeVectorN, translationFunction, translationLayer)
  local funcValue
  if translationFunction == FUNC_SINUSOIDAL then
    funcValue = sinusoidal(timeN)
  elseif translationFunction == FUNC_PARABOLIC then
    funcValue = parabolic(timeN)
  elseif translationFunction == FUNC_EASYOUTDAMPED then
    funcValue = easyOutDamped(timeN)
  elseif translationFunction == FUNC_EASYOUTDAMPED2 then
    funcValue = easyOutDamped2(timeN)
  elseif translationFunction == FUNC_EASYINOUT then
    funcValue = easyInOut(timeN)
  elseif translationFunction == FUNC_EASYIN then
    funcValue = easyIn(timeN)
  elseif translationFunction == FUNC_EASYOUT then
    funcValue = easyOut(timeN)
  elseif translationFunction == FUNC_BYLAYER then
    if translationLayer == nil then
      app.alert(string.format("Error: on function timeNToIndex(), in 'path_finder.lua'. Neither selected layer contains '%s' in its name.", STRING_FUNCTION_LAYER))
      return nil
    end
    if curve == nil then
      curve = makeCurveFromLayer(translationLayer, false)
    end
    funcValue = byLayer(timeN, curve)
  else
    funcValue = lineal(timeN)
  end
  for i=1, #timeVectorN, 1 do
      if funcValue <= timeVectorN[i] then
        return i
      end
  end
end

function angleCalculation(point0, point1, codeRefNumber)
  if point0 == nil or point1 == nil then
    app.alert(string.format("Error: on angleCalculation() in 'path_finder.lua'. Error number: %d", codeRefNumber))
    return nil
  end
  local angle = nil
  local oposite = point1.x - point0.x
  local adyacent = point1.y - point0.y
  local hipo = math.sqrt(oposite^2 + adyacent^2)
  if hipo == 0 then
    angle = 0
  else
    if adyacent == 0 then
      if oposite > 0 then
        angle = 3 * math.pi / 2
      else
        angle = math.pi / 2
      end
    elseif adyacent > 0 then
      angle = math.pi + math.asin(oposite / hipo)
    else
      if oposite >= 0 then
        angle = 2 * math.pi - math.asin(oposite / hipo)
      else
        angle = -math.asin(oposite / hipo)
      end
    end
  end
  return angle
end

function conformPathTimedIndices(timeVectorN, frameCount, translationFun, translationLayer, C)
  local pathVectorIndices = {}
  for i=1, frameCount, 1 do
    local timeN = (i - 1.0) / (frameCount - 1.0)
    table.insert(pathVectorIndices, math.floor(timeNToIndex(timeN, timeVectorN, translationFun, translationLayer)) + C)
  end
  return pathVectorIndices
end

function makeRotationInstructionVector(pathVectorExtended, timeVectorN, framesCountToFill, rotationType, translationFun, translationLayer, rotFunLayer, lookAtLayer, C, startingFrame, initialAngle)  
  local outputRotationInstructionVector = {}
  local pathVectorIndices = conformPathTimedIndices(timeVectorN, framesCountToFill, translationFun, translationLayer, C)

  if rotationType == ROTATION_PATH then
    for i=1, #pathVectorIndices, 1 do
      table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]-C], pathVectorExtended[pathVectorIndices[i]+C], 1) + initialAngle)
    end
  elseif rotationType == ROTATION_BYLAYER then
    if rotFunLayer == nil then
      app.alert(string.format("Error: no  layer which contains '%s' was selected. So 'BY LAYER' rotation type is not possible.", STRING_ROTATION_LAYER))
      return nil
    end
    if #rotFunLayer.cels == 0 or rotFunLayer.cels[1].image == nil then
      app.alert(string.format("Error: layer named '%s' doesn't contains an image.", rotFunLayer.name))
      return nil
    end
    -- Make angle according rotation function layer:
    local rotCurve = makeCurveFromLayer(rotFunLayer, true)
    for i=1, #pathVectorIndices, 1 do
      local timeFraction = (i - 1 ) / (#pathVectorIndices - 1)
      table.insert(outputRotationInstructionVector, rotCurve[math.floor(timeFraction * (#rotCurve - 1) + 1)] + initialAngle)
    end
  elseif rotationType == ROTATION_LOOKAT then
    if lookAtLayer == nil then
      app.alert(string.format("Error: no  layer named '%s' was selected. So 'LOOK AT' rotation type is not possible.", STRING_LOOKED_LAYER))
      return nil
    end
    if #lookAtLayer.cels == 0 or lookAtLayer.cels[1].image == nil then
      app.alert(string.format("Error: layer named '%s' doesn't contains an image. Please, at least, make an image first", lookAtLayer.name))
      return nil
    end
    if #lookAtLayer.cels == 1 then
      -- look all the time to an image on tahat unique cel
      local imageCenterPoint = Point(math.floor(lookAtLayer.cels[1].image.width / 2), math.floor(lookAtLayer.cels[1].image.height / 2))
      local pointToBeLookedAt = lookAtLayer.cels[1].position + imageCenterPoint
      for i=1, #pathVectorIndices, 1 do
        table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]], pointToBeLookedAt, 2) + initialAngle)
      end
    elseif #lookAtLayer.cels > 1 then
      -- 'look at' angle es computed only on filled cels, otherwise angle is 0.
      for i=1, #pathVectorIndices, 1 do
        if lookAtLayer:cel(startingFrame - 1 + i) == nil then
          table.insert(outputRotationInstructionVector, initialAngle)
        else
          local imageCenterPoint = Point(math.floor(lookAtLayer:cel(startingFrame - 1 + i).image.width / 2), math.floor(lookAtLayer:cel(startingFrame - 1 + i).image.height / 2))
          local pointToBeLookedAt = lookAtLayer:cel(startingFrame - 1 + i).position + imageCenterPoint
          table.insert(outputRotationInstructionVector, angleCalculation(pathVectorExtended[pathVectorIndices[i]], pointToBeLookedAt, 3) + initialAngle)
        end
      end
    end

  end
  
  if outputRotationInstructionVector == nil or #outputRotationInstructionVector == 0 then
    app.alert("Something was wrong on 'makeRotationInstructionVector' function.")
    return nil
  end

  return outputRotationInstructionVector
end

function makePath(pathVectorExtended, timeVectorN, frameCount, translationFun, translationLayer, C)
  local outputCoordinatesVector = {}
  local pathVectorIndices = conformPathTimedIndices(timeVectorN, frameCount, translationFun, translationLayer, C)

  for i=1, #pathVectorIndices, 1 do
    table.insert(outputCoordinatesVector, pathVectorExtended[pathVectorIndices[i]])
  end

  if outputCoordinatesVector == nil or #outputCoordinatesVector == 0 then
    app.alert("Something is going wrong.")
    return nil
  end

  return outputCoordinatesVector
end




