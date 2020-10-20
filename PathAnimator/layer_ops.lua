-- Layer Operations
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

function generateLayerIDString(pathLayerCollection, drawingLayerCollection)
    local resultLayerIdString = ""
    for i,layer in ipairs(pathLayerCollection) do
        if layer ~= startPathLayer then
            resultLayerIdString = resultLayerIdString .. layer.name .. "«"
        end
    end
    for i,layer in ipairs(drawingLayerCollection) do
      resultLayerIdString = resultLayerIdString .. layer.name .. "§"
    end
    return resultLayerIdString
end

function generateDrawingLayerIDString(drawingLayerCollection)
    local resultLayerIdString = ""
    for i,layer in ipairs(drawingLayerCollection) do
        resultLayerIdString = resultLayerIdString .. layer.name .. "§"
    end
    return resultLayerIdString
end

function selectOriginalLayers(selectedLayerStackIndices)
    if #selectedLayerStackIndices == 0 then
        return nil
    end
    local originalSelectedLayers = {}
    for i=1, #selectedLayerStackIndices, 1 do
        for j,layer in ipairs(app.activeSprite.layers) do
            if layer.stackIndex == selectedLayerStackIndices[i] then
                table.insert(originalSelectedLayers, layer)
            end
        end
    end
    app.range.layers = originalSelectedLayers
end

function readConfigurationFromLayer(layer)
    if layer == nil then
        return nil
    end
    local firstFoundedCel = nil
    local firstFrameNumberWithCel = layer.cels[1].frame.frameNumber
    for i=firstFrameNumberWithCel, firstFrameNumberWithCel + #layer.cels - 1, 1 do
        if layer:cel(i) ~= nil then
            firstFoundedCel = layer:cel(i)
            if firstFoundedCel == nil or firstFoundedCel.data == nil or firstFoundedCel.data == "" then
                return nil
            end
            return firstFoundedCel.data
        end
    end
    return nil
end

function findLayer(sprite, nameToFind)
    for i,layer in ipairs(sprite.layers) do
        if layer.name == nameToFind then
            return layer
        end
    end
    return nil
end

function extractDrawingLayersFromLayerConf(layerData)
    local layerSeriesString = layerData
    while true do
        if layerSeriesString:find("«") == nil then
            break
        end
        layerSeriesString = layerSeriesString:sub(layerSeriesString:find("«")+2, layerSeriesString:len())
    end
    local drawingLayersCollection = {}
    local safecounter = 200
    if layerSeriesString:find("§") == nil then
        return drawingLayersCollection
    end
    while true do
        local layerString = layerSeriesString:sub(1, layerSeriesString:find("§")-1)
        for i,layer in ipairs(app.activeSprite.layers) do
            if layer.name == layerString then
                table.insert(drawingLayersCollection, layer)
                break
            end
        end
        layerSeriesString = layerSeriesString:sub(layerSeriesString:find("§")+2, layerSeriesString:len())
        if layerSeriesString == nil or layerSeriesString == "" or safecounter <= 0 or layerSeriesString:find("§") == nil then
            break
        end
        safecounter = safecounter - 1
    end
    return drawingLayersCollection
end

function extractTranslationFunLayerFromLayerConf(layerData)
    if layerData:find("§y") == nil then
        return nil
    end
    local translationFunctionLayerNameString = layerData:sub(layerData:find("§y")+3, layerData:len())
    if translationFunctionLayerNameString == nil or translationFunctionLayerNameString == "" then
        app.alert("Error: no rotational layer function found.")
        return nil
    end
    translationFunctionLayerNameString = translationFunctionLayerNameString:sub(1, translationFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == translationFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractRotFunLayerFromLayerConf(layerData)
    if layerData:find("§j") == nil then
        return nil
    end
    local rotFunctionLayerNameString = layerData:sub(layerData:find("§j")+3, layerData:len())
    if rotFunctionLayerNameString == nil or rotFunctionLayerNameString == "" then
        app.alert("Error: no rotational layer function found.")
        return nil
    end
    rotFunctionLayerNameString = rotFunctionLayerNameString:sub(1, rotFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == rotFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractPathLayersFromLayerConf(layerData)
    if layerData:find("«") == nil then
        return nil
    end
    local pathLayersNames = {}
    local layerDataString = layerData:sub(1, layerData:len())
    local safetyCounter = 200
    while safetyCounter > 0 do
        local pathName = layerDataString:sub(1, layerDataString:find("«")-1)
        table.insert(pathLayersNames, pathName)
        layerDataString = layerDataString:sub(layerDataString:find("«")+2, layerDataString:len())
        if layerDataString:find("«") == nil  then
            break
        end
        safetyCounter = safetyCounter - 1
    end
    if safetyCounter <= 0 then
        app.alert("Error: extractPathLayersFromLayerConf() function.")
        return nil
    end
    local layers = {}
    for i=1, #pathLayersNames, 1 do
        for j,layer in ipairs(app.activeSprite.layers) do
            if layer.name == pathLayersNames[i] then
                table.insert(layers, layer)
                break
            end
        end
    end
    return layers
end

function extractLookAtLayerFromLayerConf(confString)
    if confString:find("§o") == nil then
        return nil
    end
    local lookAtLayerString = confString:sub(confString:find("§o")+3, confString:len())
    if lookAtLayerString == nil or lookAtLayerString == "" then
        app.alert("Error: no LOOK AT LAYER was found")
        return nil
    end
    lookAtLayerString = lookAtLayerString:sub(1, lookAtLayerString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == lookAtLayerString then
            return layer
        end
    end
    return nil
end

function readConfigurationFromSelectedLayers(selectedLayers)
    local startPathLayer = nil -- whit white dot
    local lookAtLayer = nil
    local pathLayerCollection = {}
    local drawingLayerCollection = {}
    for i, layer in ipairs(selectedLayers) do
        if layer.name:find(STRING_PATH_LAYER) ~= nil  then
            table.insert(pathLayerCollection, layer)
        elseif layer.name:find(STRING_FUNCTION_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_RESULT_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_ROTAUX_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_ROTATION_LAYER) ~= nil then
            -- do nothing
        elseif layer.name:find(STRING_LOOKED_LAYER) ~= nil then
            lookAtLayer = layer
        else
            if #layer.cels ~= 0 then
                table.insert(drawingLayerCollection, layer)
            end
        end
    end
    if #pathLayerCollection == 0 and lookAtLayer == nil then
        return nil
    end

    local resultLayerIdString = generateLayerIDString(pathLayerCollection , drawingLayerCollection)
    if resultLayerIdString == nil then
        return nil
    end
    local resultLayer = nil
    for i=#app.activeSprite.layers, 1, -1 do
        if app.activeSprite.layers[i].data == resultLayerIdString then
            resultLayer = app.activeSprite.layers[i]
            break
        end
    end
    if resultLayer == nil then
        return nil
    end
    return resultLayer.cels[1].data
end

function extractStatTimeFromConf(configurationString)
    if configurationString:find("§s") == nil then
        return DEFAULT_STARTTIME_STRING
    end
    local startTimeString = configurationString:sub(configurationString:find("§s")+3, configurationString:len())
    if startTimeString == nil or startTimeString == "" then
        return DEFAULT_STARTTIME_STRING
    else
        return startTimeString:sub(1, startTimeString:find("§")-1)
    end
end

function extractDurationFromConf(configurationString)
    if configurationString:find("§t") == nil then
        return DEFAULT_DURATION_STRING
    end
    local durationString = configurationString:sub(configurationString:find("§t")+3, configurationString:len())
    if durationString == nil or durationString == "" then
        return DEFAULT_DURATION_STRING
    else
        return durationString:sub(1, durationString:find("§")-1)
    end
end

function extractTranslationFunctionFromConf(configurationString)
    if configurationString:find("§f") == nil then
        return FUNC_LINEAL
    end
    local translationFunctionString = configurationString:sub(configurationString:find("§f")+3, configurationString:len())
    if translationFunctionString == nil or translationFunctionString == "" then
        return FUNC_LINEAL
    else
        return translationFunctionString:sub(1, translationFunctionString:find("§")-1)
    end
end

function extractRotationTypeFromConf(configurationString)
    if configurationString:find("§r") == nil then
        return ROTATION_NONE
    end
    local rotationTypeString = configurationString:sub(configurationString:find("§r")+3, configurationString:len())
    if rotationTypeString == nil or rotationTypeString == "" then
        return ROTATION_NONE
    else
        return rotationTypeString:sub(1, rotationTypeString:find("§")-1)
    end
end

function extractInitialAngleFromConf(configurationString)
    if configurationString:find("§a") == nil then
        return DEFAULT_INITIALANGLE_STRING
    end
    local initialAngleString = configurationString:sub(configurationString:find("§a")+3, configurationString:len())
    if initialAngleString == nil or initialAngleString == "" then
        return DEFAULT_INITIALANGLE_STRING
    else
        return initialAngleString:sub(1, initialAngleString:find("§")-1)
    end
end

function extractLoopPathFromConf(configurationString)
    if configurationString:find("§l") == nil then
        return DEFAULT_LOOP_PATH
    end
    local loopPath = configurationString:sub(configurationString:find("§l")+3, configurationString:len())
    if loopPath == nil or loopPath == "" then
        return DEFAULT_LOOP_PATH
    else
        if loopPath:sub(1, loopPath:find("§")-1) == "true" then
            return true
        else
            return false
        end
    end
end

function extractScaleFunctionFromConf(configurationString)
    if configurationString:find("§h") == nil then
        return SCALE_NONE
    end
    local scaleFunctionString = configurationString:sub(configurationString:find("§h")+3, configurationString:len())
    if scaleFunctionString == nil or scaleFunctionString == "" then
        return SCALE_NONE
    else
        return scaleFunctionString:sub(1, scaleFunctionString:find("§")-1)
    end
end

function extractScaleFunLayerFromConf(configurationString)
    if configurationString:find("§k") == nil then
        return nil
    end
    local scaleFunctionLayerNameString = configurationString:sub(configurationString:find("§k")+3, configurationString:len())
    if scaleFunctionLayerNameString == nil or scaleFunctionLayerNameString == "" then
        app.alert("Error: no scale layer function found.")
        return nil
    end
    scaleFunctionLayerNameString = scaleFunctionLayerNameString:sub(1, scaleFunctionLayerNameString:find("§")-1)
    for i,layer in ipairs(app.activeSprite.layers) do
        if layer.name == scaleFunctionLayerNameString then
            return layer
        end
    end
    return nil
end

function extractInitialScaleFromConf(configurationString)
    if configurationString:find("§i") == nil then
        return DEFAULT_INITIAL_SCALE
    end
    local initialScale = configurationString:sub(configurationString:find("§i")+3, configurationString:len())
    if initialScale == nil or initialScale == "" then
        return DEFAULT_INITIAL_SCALE
    else
        return initialScale:sub(1, initialScale:find("§")-1)
    end
end

function extractFinalScaleFromConf(configurationString)
    if configurationString:find("§c") == nil then
        return DEFAULT_FINAL_SCALE
    end
    local finalScale = configurationString:sub(configurationString:find("§c")+3, configurationString:len())
    if finalScale == nil or finalScale == "" then
        return DEFAULT_FINAL_SCALE
    else
        return finalScale:sub(1, finalScale:find("§")-1)
    end
end

function extractStartPathPosFromConf(configurationString)
    if configurationString:find("§p") == nil then
        return DEFAULT_PATH_START_POS_STRING
    end
    local startPathPos = configurationString:sub(configurationString:find("§p")+3, configurationString:len())
    if startPathPos == nil or startPathPos == "" then
        return DEFAULT_PATH_START_POS_STRING
    else
        return startPathPos:sub(1, startPathPos:find("§")-1)
    end
end

function extractMakeNewResultLayerFromConf(configurationString)
    if configurationString:find("§n") == nil then
        return DEFAULT_MAKE_NEW_RESULT_LAYER
    end
    local makeNewResultLayer = configurationString:sub(configurationString:find("§n")+3, configurationString:len())
    if makeNewResultLayer == nil or makeNewResultLayer == "" then
        return DEFAULT_MAKE_NEW_RESULT_LAYER
    else
        if makeNewResultLayer:sub(1, makeNewResultLayer:find("§")-1) == "true" then
            return true
        else
            return false
        end
    end
end