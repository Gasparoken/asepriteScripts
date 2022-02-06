-- Path Walker
-- Copyright (C) 2020-2022 Gaspar Capello

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
dofile('./layer_ops.lua')
dofile('./animation_functions.lua')
dofile('./path_finder.lua')
dofile('./rotation.lua')
dofile('./scale_ops.lua')

function areDifferentImages(image1, image2)
  if image1.width ~= image2.width or image1.height ~= image2.height then
    return true
  end
  for y=0, image1.height - 1, 1 do
    for x=0, image1.width - 1, 1 do
      if image1:getPixel(x, y) ~= image2:getPixel(x, y) then
        return true
      end
    end
  end
  return false
end

function orderDrawingLayerCollectionAccordingStackIndex(layers)
  local layersCopy = {}
  for i,layer in ipairs(layers) do
    table.insert(layersCopy, layer)
  end
  local orderedLayerVector = {}
  local layerWithGreaterStackIndex = nil
  local minStackIndexFound = 1000000
  for i=1, #layersCopy, 1 do
    local removeElement = 0
    for j=1, #layersCopy, 1 do
      if minStackIndexFound > layersCopy[j].stackIndex then
        minStackIndexFound = layersCopy[j].stackIndex
        layerWithGreaterStackIndex = layersCopy[j]
        removeElement = j
      end
    end
    table.insert(orderedLayerVector, layerWithGreaterStackIndex)
    if removeElement ~= 0 then
      table.remove(layersCopy, removeElement)
    end
    minStackIndexFound = 1000000
  end
  return orderedLayerVector
end


function animateIt(selectedLayers, startTime, aniDuration, translationFunction,
                   rotationType, initialAngle, startPathPos, loopPath,
                   scaleFunction, initialScale, finalScale, makeNewResultLayer)
  app.transaction(
    function()
      ------------------------------------------------------------------------------------------------------
      --1 Capture resultLayerCollection and rotationAuxLayerCollection from app.activeSprit
      ------------------------------------------------------------------------------------------------------
      local sprite = app.activeSprite

      if sprite == nil then
        app.alert("Error: You should open a sprite first.")
        return false
      end

      local resultLayerCollection = {}
      local rotationAuxLayerCollection = {}
      for i, layer in ipairs(sprite.layers) do
        if layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
          table.insert(rotationAuxLayerCollection, layer)
        end
      end
      for i=#app.activeSprite.layers, 1, -1 do
        if app.activeSprite.layers[i].name:find(STRING_RESULT_LAYER) ~= nil then
          table.insert(resultLayerCollection, app.activeSprite.layers[i])
        end
      end
      -- print("1-DONE")
      ------------------------------------------------------------------------------------------------------
      --2 Make layer collections with selectedLayers
      ------------------------------------------------------------------------------------------------------
      local startPathLayer = nil -- with a white dot
      local pathLayerCollection = {}
      local pathCollection = {} -- layers with strokes without white dot
      local trasFunLayer = nil
      local rotFunLayer = nil
      local scaleFunLayer = nil
      local lookAtLayer = nil
      local drawingLayerCollection = {}
      local resultLayer = nil
      -- If oneResultLayerWasSelected == true means that this 'animateIt' function was used to re-animate a particular 'resultLayer'

      local oneResultLayerWasSelected = (#selectedLayers == 1 and selectedLayers[1].name:find(STRING_RESULT_LAYER) ~= nil)
      if oneResultLayerWasSelected then
        resultLayer = selectedLayers[1]
        -- ignore all configurations and use the ResultLayer configuration
        local confString = readConfigurationFromLayer(resultLayer)
        makeNewResultLayer = false
        if confString ~= nil then
          startTime = extractStatTimeFromConf(confString)
          aniDuration = extractDurationFromConf(confString)
          translationFunction = extractTranslationFunctionFromConf(confString)
          rotationType = extractRotationTypeFromConf(confString)
          initialAngle = extractInitialAngleFromConf(confString)
          startPathPos = extractStartPathPosFromConf(confString)
          loopPath = extractLoopPathFromConf(confString)
          scaleFunction = extractScaleFunctionFromConf(confString)
          initialScale = extractInitialScaleFromConf(confString)
          finalScale = extractFinalScaleFromConf(confString)
        end
        if rotationType == ROTATION_BYLAYER then
          rotFunLayer = extractRotFunLayerFromLayerConf(confString)
          if rotFunLayer == nil then
            app.alert(string.format("Rotational Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        drawingLayerCollection = extractDrawingLayersFromLayerConf(resultLayer.data)
        if #drawingLayerCollection == 0 then
          app.alert("Error: no drawing layers are found on ResultLayer configuration.")
          return false
        end
        if translationFunction == FUNC_BYLAYER then
          trasFunLayer = extractTranslationFunLayerFromLayerConf(confString)
          if trasFunLayer == nil then
            app.alert(string.format("Translation Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        if scaleFunction == SCALE_BYLAYER then
          scaleFunLayer = extractScaleFunLayerFromConf(confString)
          if scaleFunLayer == nil then
            app.alert(string.format("Scale Function not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end
        if rotationType == ROTATION_LOOKAT then
          lookAtLayer = extractLookAtLayerFromLayerConf(confString)
          if lookAtLayer == nil then
            app.alert(string.format("Look At Layer not found from configuration (config is in the first non empty cel of custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        end

        pathLayerCollection = extractPathLayersFromLayerConf(resultLayer.data)
        if #pathLayerCollection == 0 then
          if rotationType ~= ROTATION_LOOKAT and rotationType ~= ROTATION_BYLAYER then
            app.alert(string.format("Path layer not found from configuration (config is in the custom data of the '%s' layer).", STRING_RESULT_LAYER))
            return false
          end
        else
          if findWhiteDot(pathLayerCollection[1].cels[1]) ~= nil then
            startPathLayer = pathLayerCollection[1]
          end
        end
      else
        for i, layer in ipairs(selectedLayers) do
          if layer.name:find(STRING_PATH_LAYER) ~= nil  then
            if startPathLayer == nil then
              local startPoint = findWhiteDot(layer.cels[1])
              if startPoint ~= nil then
                startPathLayer = layer
                table.insert(pathLayerCollection, 1, layer) -- startPathLayer is the first element
              else
                table.insert(pathLayerCollection, layer)
              end
            else
              table.insert(pathLayerCollection, layer)
            end
          elseif layer.name:find(STRING_FUNCTION_LAYER) ~= nil then
            trasFunLayer = layer
          elseif layer.name:find(STRING_RESULT_LAYER) ~= nil then
            -- do nothing
          elseif layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
            -- do nothing
          elseif layer.name:find(STRING_ROTATION_LAYER) ~= nil then
            rotFunLayer = layer
          elseif layer.name:find(STRING_SCALE_LAYER) ~= nil then
            scaleFunLayer = layer
          elseif layer.name:find(STRING_LOOKED_LAYER) ~= nil then
            lookAtLayer = layer
          else
            if #layer.cels ~= 0 then
              table.insert(drawingLayerCollection, layer)
            end
          end
        end
      end

      -- Dummy calculation to convert strings to numbers:
      initialAngle = initialAngle * 2 / 2
      initialScale = initialScale * 2 / 2
      finalScale = finalScale * 2 / 2
      aniDuration = aniDuration * 2 / 2
      startTime = startTime * 2 / 2

      local generateStillPath = false -- when the user selects NO PATH layer, AND the user selects "Rotation: LookAt" or "Rotation: By Layer"
                                      -- we have to generate a "still path" to allow apply this 
      -- local temp = 0 -- temp = 0  -->  whitePointIsInStartPathLayer = true
      if startPathLayer == nil then
        if #pathLayerCollection == 0 then
          if rotationType == ROTATION_LOOKAT or rotationType == ROTATION_BYLAYER then
            -- Here, we have NO PATH, but we can generate a path to allow an object to still in the same position along the rotation animation,
            -- So we can generate the angles in rotation types: 'Look At' or 'By Layer' rotation Functions
            generateStillPath = true
          else
            app.alert(string.format("Error: no layer which name contains '%s' or '%s' string.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
            app.alert(string.format("Please, select a layer which name contains '%s' or '%s' string, and at least an image layer.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
            return false
          end
        end
      end
      
      for i=1, #pathLayerCollection, 1 do
        local path = getPath(pathLayerCollection[i])
        if path == nil then
          app.alert(string.format("Error: Bad path in layer: '%s'. No end points were found on it.", pathLayerCollection[i].name))
          app.alert(string.format("A well-formed path is made from a 1-pixel-thick stroke, with Pixel Perfect mode ON. Optional: put a white point at the desired beginning."))
          return false
        end
        table.insert(pathCollection, path)
      end
      -- print("2-DONE")
      ------------------------------------------------------------------------------------------------------
      --3 Add needed aditional frames to the sprite
      ------------------------------------------------------------------------------------------------------
      local frameDuration = sprite.frames[1].duration
      local startFrame = startTime / frameDuration + 1
      local framesCountToFill = aniDuration / frameDuration
      local neededFrameCount = startFrame + framesCountToFill - 1
      for i=#sprite.frames, neededFrameCount - 1, 1 do
        sprite:newEmptyFrame()
      end
      -- print("3-DONE")
      ------------------------------------------------------------------------------------------------------
      --4 Make an ID string to identify which ResultLayer in the active sprite was used to make the current animation
      ------------------------------------------------------------------------------------------------------
      local loopPathString
      local makeNewResultLayerString
      if loopPath == true then
        loopPathString = "true"
      else
        loopPathString = "false"
      end
      if makeNewResultLayer == true then
        makeNewResultLayerString = "true"
      else
        makeNewResultLayerString = "false"
      end

      local resultLayerIdString = generateLayerIDString(pathLayerCollection , drawingLayerCollection)
      local drawingLayersIdString = generateDrawingLayerIDString(drawingLayerCollection)

      -- print("4-DONE")
      ------------------------------------------------------------------------------------------------------
      --5 Find among resultLayerCollection if the previous ID string matchs with some ResultLayer, if not, make a new one
      ------------------------------------------------------------------------------------------------------
      if not oneResultLayerWasSelected then
        for i,layer in ipairs(resultLayerCollection) do
          if layer.data == resultLayerIdString and not makeNewResultLayer then
            resultLayer = layer
            break
          end
        end
        if resultLayer == nil then
          resultLayer = sprite:newLayer()
          resultLayer.name = STRING_RESULT_LAYER
          sprite:newCel(resultLayer, startFrame)
          resultLayer.data = resultLayerIdString
        end
      end
      -- print("5-DONE")
      ------------------------------------------------------------------------------------------------------
      --6 Make a new configuration string according the current input options. An example of configuration string = §f1§t2.0§s0.0§r0§a90.0§ltrue§p50.0§yTFUN1§
      ------------------------------------------------------------------------------------------------------
      local initialScalePerCent = initialScale * 100.0
      local finalScalePerCent = finalScale * 100.0
      local confString  = "§f" .. translationFunction .. "§" ..
                          "s" .. startTime .. "§" ..
                          "t" .. aniDuration .."§" ..
                          "r" .. rotationType .. "§" ..
                          "a" .. initialAngle .. "§" ..
                          "l" .. loopPathString .. "§" ..
                          "p" .. startPathPos .. "§" ..
                          "h" .. scaleFunction .. "§" ..
                          "i" .. initialScalePerCent .. "§" ..
                          "c" .. finalScalePerCent .. "§" ..
                          "n" .. makeNewResultLayerString .. "§"
      
      if scaleFunLayer ~= nil then
        confString = confString .. "k" .. scaleFunLayer.name .. "§"
      end
      if trasFunLayer ~= nil then
        confString = confString .. "y" .. trasFunLayer.name .. "§"
      end
      if rotFunLayer ~= nil then
        confString = confString .. "j" .. rotFunLayer.name .. "§"
      end
      if lookAtLayer ~= nil then
        confString = confString .. "o" .. lookAtLayer.name .. "§"
      end
      -- At the end of the current function, it'll asign the config string to ResultLayer
      -- print("6-DONE")
      ------------------------------------------------------------------------------------------------------
      --7 Make a flatten image, which be moved along the path.
      ------------------------------------------------------------------------------------------------------
      local layersToMergeDown = {}
      drawingLayerCollection = orderDrawingLayerCollectionAccordingStackIndex(drawingLayerCollection)

      local FRAME_LIMIT = 99999999
      local minFrame = FRAME_LIMIT
      local maxFrame = 1
      for i=1, #drawingLayerCollection, 1 do
        table.insert(layersToMergeDown, sprite:newLayer())
        for j=1, #app.activeSprite.frames, 1 do
          if drawingLayerCollection[i]:cel(j) ~= nil and j < minFrame then
            minFrame = j
            break
          end
        end
        for j=#app.activeSprite.frames, 1, -1 do
          if drawingLayerCollection[i]:cel(j) ~= nil and j > maxFrame then
            maxFrame = j
            break
          end
        end
      end

      if minframe == FRAME_LIMIT then
        app.alert("Error: the selected layers are empty. Please Select a layer with images.")
        return false
      end
      
      for i=1, #drawingLayerCollection, 1 do
        for j=minFrame, maxFrame, 1 do
          if drawingLayerCollection[i]:cel(j) ~= nil then
            local position = drawingLayerCollection[i]:cel(j).position
            local image = drawingLayerCollection[i]:cel(j).image
            local frame = drawingLayerCollection[i]:cel(j).frame
            sprite:newCel(layersToMergeDown[i], frame, image, position)
          end
        end
      end
      for i=1, #drawingLayerCollection-1, 1 do
        app.command.MergeDownLayer()
      end
      local auxLayer = app.activeLayer
      local imageToMove = auxLayer:cel(minFrame).image:clone()
      local imageToMovePos = auxLayer:cel(minFrame).position
      if imageToMove == nil then
        sprite:deleteLayer(auxLayer)
        app.alert("Error: selected image layers do not make an image.")
        return false
      end
      
      -- print("7-DONE")
      ------------------------------------------------------------------------------------------------------
      --8 Make a concatenated path with all the path layers selected (if possible to concatenate), named 'weldedPath'.
      ------------------------------------------------------------------------------------------------------
      local startPath = nil
      if generateStillPath then
        local imageCenterPoint = imageToMovePos + Point(imageToMove.width / 2, imageToMove.height / 2)
        startPath = { imageCenterPoint, imageCenterPoint }
      else
        startPath = getPath(pathLayerCollection[1])
      end
      if startPath == nil then
        app.alert(string.format("Error: bad path in layer: '%s'. No end points were found on it.", pathLayerCollection[1].name))
        app.alert(string.format("A well-formed path is made from a 1-pixel-thick stroke, with Pixel Perfect mode ON. Optional: put a white point at the desired beginning."))
        sprite:deleteLayer(auxLayer)
        return false
      end
      local weldedPath = startPath -- original weldedPath
      -- Starting Paths Collection: has a white dot (the starting dot)
      for i=2, #pathCollection, 1 do
        local concatType = isPosibleConcatenatePaths(weldedPath, pathCollection[i])
        if concatType == 0 or concatType == nil  then
          app.alert(string.format("Error: Bad path trayectory in layer: '%s'", pathCollection[i].name))
          sprite:deleteLayer(auxLayer)
          return false
        end
        weldedPath = concatenatePaths(weldedPath, pathCollection[i], concatType)
      end

      if weldedPath == nil then
        app.alert("Error: error on concatenatePaths(). It returned 'nil'.")
        sprite:deleteLayer(auxLayer)
        return false
      end
      if #weldedPath < 1 then
        app.alert("Error: no path were formed.")
        sprite:deleteLayer(auxLayer)
        return false
      end
      -- print("8-DONE")
      ------------------------------------------------------------------------------------------------------
      --9 Make time vector, which is the representation of the time taken to walk the 'weldedPath' at constant speed of 1px/seg.
      ------------------------------------------------------------------------------------------------------
      -- timeVector (is a direct function of space distance between adyacent pixels):
      local timeVector = { 0 }
      if generateStillPath then
        table.insert(timeVector, 1)
      else
        -- weldPath == 1 if the path is a single pixel, so we'll need to avoid division by zero in next calculations
        if #weldedPath == 1 then
          timeVector[1] = 0
        else
          for i=1, #weldedPath-1, 1 do
            local deltaT = math.sqrt(math.abs(weldedPath[i].x - weldedPath[i+1].x) + math.abs(weldedPath[i].y - weldedPath[i+1].y) )
            table.insert(timeVector, timeVector[i] + deltaT)
          end
        end
      end
      -- Get the index which matches with
      -- the start percentage (Start Path Pos %)  -------------
      --                                                       |  
      --                                                   pathStartIndex
      -- original    weldedPath:      beginning |-----------------^-----------------------------* end
      --
      --
      -- OPTION 1:
      -- re-arranged weldedPath:  new beginning ^-----------------------------*|----------------- new end    when CYCLIC
      --                                                                      ^ 
      --                                                                pathJumpIndex
      --
      -- OPTION 2:
      -- re-arranged weldedPath:  new beginning ^-----------------------------* end                          when NON CYCLIC
      -- in this case 'pathJumpIndex' will be equal to the end index of 'weldedPath'  (i.e. pathJumpIndex = #weldedPath)
      --
      local totalTravelTime = timeVector[#timeVector]
      local pathStartIndex = 1
      for i=1, #timeVector, 1 do
        if timeVector[i]/totalTravelTime >= startPathPos / 100.0 then
          pathStartIndex = i
          break
        end
      end
      if pathStartIndex < 1 or pathStartIndex > #timeVector then
        app.alert("Error: 'pathStartIndex' is < 1 or 'pathStartIndex' > timeVector elements count.")
        sprite:deleteLayer(auxLayer)
        return false
      end

      -- weldedPath re-arrange:
      local auxVector = {}
      -- cyclic path loop:
      for i=pathStartIndex, #weldedPath, 1 do
        table.insert(auxVector, weldedPath[i])
      end
      if loopPath and #weldedPath > 1 then
        -- Non cyclic path loop
        for i=1, pathStartIndex-1, 1 do
          table.insert(auxVector, weldedPath[i])
        end
      end
      weldedPath = auxVector -- modified welded path

      local pathJumpIndex = 0
      if loopPath and #weldedPath > 1 then
        pathJumpIndex = #weldedPath - pathStartIndex + 1 -- index which path jumps from a middle point of the path to the beginning
      else
        pathJumpIndex = #weldedPath
      end

      -- Recalculate timeVector, we need to do it again because if the path is cyclic (loopPath == true) the time increment is not linear on 'pathJumpIndex'
      timeVector = { 0 }
      local deltaT
      if generateStillPath or #weldedPath == 1 then
        table.insert(timeVector, 1)
        pathJumpIndex = 2
        -- Conditioning weldedPath to match data input in next functions
        if #weldedPath == 1 then
          weldedPath = { weldedPath[1], weldedPath[1] }
        end
      else
        for i=1, #weldedPath-1, 1 do
          if i == pathJumpIndex then
            deltaT = 1
          else
            deltaT = math.sqrt(math.abs(weldedPath[i].x - weldedPath[i+1].x) + math.abs(weldedPath[i].y - weldedPath[i+1].y) )
          end
          table.insert(timeVector, timeVector[i] + deltaT)
        end
      end

      -- Get the normalized time vector ( i.e. from 0.0 to 1.0 )
      local timeVectorN = {}
      totalTravelTime = timeVector[#timeVector]
      for i=1, #timeVector, 1 do
        table.insert(timeVectorN, timeVector[i]/totalTravelTime)
      end

      local pathTrackingConstant = math.max(5, math.floor(imageToMove.height * K_PATH_TO_IMAGE_CONSTANT) - math.floor(imageToMove.height * K_PATH_TO_IMAGE_CONSTANT)%2 + 1)
        -- C is the step count to calculate the tangent slope on the path in the element pathVector[pathVectorIndices[i]]
        -- The weldedPath will be extended at both vector ends C elements to simplify iterations on
        -- 'makeRotationInstructionVector()' and 'makePath()' functions.
      local C = (pathTrackingConstant-1) / 2
      local weldedPathExtended = {}
      if #weldedPath-C >= 1 then
        for i=#weldedPath-C, #weldedPath, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[i])
          else
            table.insert(weldedPathExtended, weldedPath[1])
          end
        end
        for i=1, #weldedPath, 1 do
          table.insert(weldedPathExtended, weldedPath[i])
        end
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[i])
          else
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          end
        end
      else
        -- Very short paths (fill the weldedPath ends with dummy points):
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          else
            table.insert(weldedPathExtended, weldedPath[1])
          end
        end
        for i=1, #weldedPath, 1 do
          table.insert(weldedPathExtended, weldedPath[i])
        end
        for i=1, C, 1 do
          if loopPath then
            table.insert(weldedPathExtended, weldedPath[1])
          else
            table.insert(weldedPathExtended, weldedPath[#weldedPath])
          end
        end
      end
      -- print("9-DONE")
      ------------------------------------------------------------------------------------------------------
      --10 Make rotation instruction vector. To do it first we need to check if some RotAux Layer exists an represents the imageToMove
      ------------------------------------------------------------------------------------------------------
      local rotauxLayer = nil
      local rotationInstructionVector = nil
      local deltaAngleCount = nil
      if rotationType ~= ROTATION_NONE and #auxLayer.cels == 1 then
        -- Check if some RotAux layer represents the imageToMove (the flatten image did at step 7):
        local recalculateRotations = false
        -- print("10.1-DONE")
        for i,layer in ipairs(rotationAuxLayerCollection) do
          if layer.data == drawingLayersIdString then
            if layer:cel(1) == nil then
              recalculateRotations = true
              break
            end
            rotauxLayer = layer
            recalculateRotations = areDifferentImages(rotauxLayer:cel(1).image, imageToMove)
            break
          end
        end
        -- print("10.2-DONE")
        if rotauxLayer == nil then
          rotauxLayer = sprite:newLayer()
          rotauxLayer.name = STRING_ROTAUX_LAYER
          rotauxLayer.data = drawingLayersIdString
          sprite:newCel(rotauxLayer, 1, imageToMove, Point(0, 0))
        end
        -- print("10.5-DONE")
        local deltaAngle = 2.8125 / 2
        deltaAngleCount = math.floor(360 / deltaAngle)
        if deltaAngleCount > #sprite.frames then
          for i=#sprite.frames, deltaAngleCount-1, 1 do
            sprite:newEmptyFrame()
          end
        end
        -- makeRotationLayerReference(rotauxLayer, imageToMove, deltaAngle)
        -- If 'recalculateRotations' == true , recalculate 'RotAux' layer to make each rotated image.
        if recalculateRotations then
          -- Clear all cels of rotauxLayer
          for i=1, #rotauxLayer.cels, 1 do
            if rotauxLayer.cels[i] ~= nil then
              sprite:deleteCel(rotauxLayer, rotauxLayer.cels[i].frameNumber)
            end
          end
          -- Make only the first frame in rotauxLayer:
          sprite:cel(rotauxLayer, 1, imageToMove, Point(0, 0))
        end
        -- print("10.7-DONE")
        rotationInstructionVector = makeRotationInstructionVector(weldedPathExtended,
                                                                  timeVectorN,
                                                                  framesCountToFill,
                                                                  rotationType,
                                                                  translationFunction,
                                                                  trasFunLayer,
                                                                  rotFunLayer,
                                                                  lookAtLayer,
                                                                  C,
                                                                  startFrame,
                                                                  initialAngle * math.pi / 180)
        if rotationInstructionVector == nil then
          return false
        end
        -- print("10.8-DONE")
        local deltaAngleRad = deltaAngle * math.pi / 180
        for i=1, #rotationInstructionVector, 1 do
          local angleIndex = 1 + math.floor(rotationInstructionVector[i] / deltaAngleRad) % deltaAngleCount
          if rotauxLayer:cel(angleIndex) == nil then
            sprite:newCel(rotauxLayer, angleIndex, Rotar(imageToMove, (angleIndex - 1) * deltaAngleRad), Point(0, 0))
          end
        end
      elseif rotationType ~= ROTATION_NONE and #auxLayer.cels ~= 1 then
        rotationInstructionVector = makeRotationInstructionVector(weldedPathExtended,
                                                                  timeVectorN,
                                                                  framesCountToFill,
                                                                  rotationType,
                                                                  translationFunction,
                                                                  trasFunLayer,
                                                                  rotFunLayer,
                                                                  lookAtLayer,
                                                                  C,
                                                                  startFrame,
                                                                  initialAngle * math.pi / 180)
      end
      -- print("10-DONE")
      ------------------------------------------------------------------------------------------------------
      --11 Make the translation final coordinates
      ------------------------------------------------------------------------------------------------------
      local translationCoordinatesVector = makePath(weldedPathExtended, timeVectorN, framesCountToFill, translationFunction, trasFunLayer, C)
      -- print("11-DONE")
      ------------------------------------------------------------------------------------------------------
      --12 Make the scale vector
      ------------------------------------------------------------------------------------------------------
      local scaleVector = {}
      if initialScale ~= 1.0 or finalScale ~= 1.0 then
        scaleVector = makeScaleVector(framesCountToFill, scaleFunction, scaleFunLayer, initialScale, finalScale)
      end
      -- print("12-DONE")
      ------------------------------------------------------------------------------------------------------
      --13 Make ResultLayer to compose position + rotation of the imageToMove
      ------------------------------------------------------------------------------------------------------
      if #resultLayer.cels ~= 0 then
        for i=1, #resultLayer.cels, 1 do
          if resultLayer:cel(i) ~= nil then
            sprite:deleteCel(resultLayer, i)
          end
        end
      end

      if rotationType == ROTATION_NONE and initialAngle ~= 0 and #auxLayer.cels == 1 then
        imageToMove = Rotar(imageToMove, initialAngle * math.pi / 180)
      end
      local celWithRotatedImageAtDesiredAngle = nil
      local imageSelfCenter = Point((imageToMove.width - 0.5) / 2, (imageToMove.height - 0.5) / 2)
      local scaledImageToMove = nil
      for i=1, framesCountToFill, 1 do
        if rotationType ~= ROTATION_NONE and #auxLayer.cels == 1 then
          -- Rotation / No animation
          celWithRotatedImageAtDesiredAngle = extractCelRotated(rotauxLayer, rotationInstructionVector[i], deltaAngleCount)
          imageToMove = celWithRotatedImageAtDesiredAngle.image
          if #scaleVector ~= 0 then
            imageToMove = resizeImage(imageToMove, scaleVector[i])
          end
          imageSelfCenter = Point((imageToMove.width - 0.5) / 2, (imageToMove.height - 0.5) / 2)
          if imageToMove == nil then
            sprite:newCel(resultLayer, startFrame + i - 1)
          else
            sprite:newCel(resultLayer, startFrame + i - 1, imageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType ~= ROTATION_NONE and #auxLayer.cels > 1 then
          -- Rotation / Animation
          local auxLayerFrameCorrespondence = minFrame + ((i - 1) % (#auxLayer.cels))
          if auxLayer:cel(auxLayerFrameCorrespondence) ~= nil then
            local auxLayerImage = auxLayer:cel(auxLayerFrameCorrespondence).image:clone()
            if #scaleVector ~= 0 then
              auxLayerImage = resizeImage(auxLayerImage, scaleVector[i])
            end
            auxLayerImage = Rotar(auxLayerImage, rotationInstructionVector[i])
            imageSelfCenter = Point(auxLayerImage.width / 2, auxLayerImage.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, auxLayerImage, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType == ROTATION_NONE and #auxLayer.cels > 1 then
          -- No Rotation / Animation
          local auxLayerFrameCorrespondence = minFrame + ((i - 1) % (#auxLayer.cels))
          if auxLayer:cel(auxLayerFrameCorrespondence) ~= nil then
            local auxLayerImage = auxLayer:cel(auxLayerFrameCorrespondence).image:clone()
            if #scaleVector ~= 0 then
              auxLayerImage = resizeImage(auxLayerImage, scaleVector[i])
            end
            imageSelfCenter = Point(auxLayerImage.width / 2, auxLayerImage.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, auxLayerImage, translationCoordinatesVector[i] - imageSelfCenter)
          end
        elseif rotationType == ROTATION_NONE and #auxLayer.cels == 1 then
          -- No Rotation / No animation
          if #scaleVector ~= 0 then
            scaledImageToMove = resizeImage(imageToMove, scaleVector[i])
            imageSelfCenter = Point(scaledImageToMove.width / 2, scaledImageToMove.height / 2)
            sprite:newCel(resultLayer, startFrame + i - 1, scaledImageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          elseif scaledImageToMove == nil then
            sprite:newCel(resultLayer, startFrame + i - 1, imageToMove, translationCoordinatesVector[i] - imageSelfCenter)
          end
        end
      end
      -- print("13-DONE")
      ------------------------------------------------------------------------------------------------------
      --14 Assign configuration string to the resultLayer
      ------------------------------------------------------------------------------------------------------
      resultLayer:cel(startFrame).data = confString
      -- print("14-DONE")
      sprite:deleteLayer(auxLayer)
      return true
    end
  )
end

function animateResultLayer(layer)
  animateIt({layer}, 0, 1, 0, 0, 0, 0, false, nil, 1, 1, false)
end


function reAnimateSelected(selectedLayers)
  local check = 0
  for i, layer in ipairs(selectedLayers) do
    if layer.name:find(STRING_RESULT_LAYER) ~= nil then
      check = check + 1
    end
  end

  if check ~= #selectedLayers then
    app.alert(string.format("Error: to apply 'Re-animate Selected Layers', you have to select ONLY layers which contains '%s' in its name.", STRING_RESULT_LAYER))
    return false
  end

  for i, layer in ipairs(selectedLayers) do
    animateResultLayer(layer)
  end
end