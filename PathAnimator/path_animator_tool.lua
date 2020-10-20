-- Path Animator Tool
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
dofile('./path_walker.lua')

local sprite = app.activeSprite
if sprite == nil then
  app.alert("WARNING: You should open a sprite first.")
  return nil
end

local HELP = "?"
-- -==== UI Interfase ====---
-- ========================--

local dlgHelp = Dialog { title="Path Animator Help:" }
dlgHelp:label   {   text= "1st: make a Layer named: ".. STRING_PATH_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "2nd: active Pixel Perfect and draw some stroke on it."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "3th: paint one pixel stroke end to white (start pixel)."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "4th: draw some item in other layer."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "5th: select both layers and press 'Animate it'"
}
dlgHelp:separator()
dlgHelp:newrow()
dlgHelp:label   {   text= "Path layer must contain the string: " .. STRING_PATH_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "You can concatenate paths from several layers." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "One path layer have to contain a white pixel (start pixel)" 
}
dlgHelp:separator()
dlgHelp:label   {   text= "You can select a layer which name contains: ".. STRING_FUNCTION_LAYER .. "." 
}
dlgHelp:newrow()
dlgHelp:label   {   text= "It will used to determine the way to walk on the path when"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "translation is 'By Layer'."
}
dlgHelp:separator()
dlgHelp:label   {   text= "At least, one layer with an image has to be selected to make"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "this tool work."
}
dlgHelp:newrow()
dlgHelp:label   {   text= "Many image layers can be selected, this tool can compose"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "all these layers in a new one named: " .. STRING_RESULT_LAYER .. ", which"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "will show the animation results."
}
dlgHelp:separator()
dlgHelp:label   {   text= "Duration and Start Time units are seconds (decimal dot"
}
dlgHelp:newrow()
dlgHelp:label   {   text= "is permited)."
}
local defaultConfString = readConfigurationFromSelectedLayers(app.range.layers)

local startTime = DEFAULT_STARTTIME_STRING
local duration = DEFAULT_DURATION_STRING
local translationFun = TFUNprefix .. FUNC_LINEAL
local rotationType = ROTATIONprefix .. ROTATION_NONE
local initialAngle = DEFAULT_INITIALANGLE_STRING
local startPathPos = DEFAULT_PATH_START_POS_STRING
local loopPath = DEFAULT_LOOP_PATH
local scaleFun = SFUNprefix .. SCALE_NONE
local initialScale = DEFAULT_INITIAL_SCALE
local finalScale = DEFAULT_FINAL_SCALE
local makeNewResultLayer = DEFAULT_MAKE_NEW_RESULT_LAYER
local makeNewResultLayerEnabled = false
if defaultConfString ~= nil then
  startTime = extractStatTimeFromConf(defaultConfString)
  duration = extractDurationFromConf(defaultConfString)
  translationFun = TFUNprefix .. extractTranslationFunctionFromConf(defaultConfString)
  rotationType = ROTATIONprefix .. extractRotationTypeFromConf(defaultConfString)
  initialAngle = extractInitialAngleFromConf(defaultConfString)
  startPathPos = extractStartPathPosFromConf(defaultConfString)
  loopPath = extractLoopPathFromConf(defaultConfString)
  scaleFun = SFUNprefix .. extractScaleFunctionFromConf(defaultConfString)
  initialScale = extractInitialScaleFromConf(defaultConfString)
  finalScale = extractFinalScaleFromConf(defaultConfString)
  makeNewResultLayer = extractMakeNewResultLayerFromConf(defaultConfString)
  makeNewResultLayerEnabled = true
end

local reAnimateIntention = true
for i,layer in ipairs(app.range.layers) do
  if layer.name:find(STRING_RESULT_LAYER) == nil then
    reAnimateIntention = false
    break
  end
end
-- startTime = "0"
-- duration = "10"
-- translationFun = TFUNprefix .. FUNC_LINEAL
-- rotationType = ROTATIONprefix .. ROTATION_PATH
-- initialAngle = "0"
local dlg1 = Dialog{ title="Path Animator Tool" }
if reAnimateIntention then
  
  dlg1:button  {  text = "Re-animate selected ResultLayers",
                  onclick =
                    function()
                      local tempLayer = app.range.layers[1]
                      reAnimateSelected(app.range.layers)
                      if tempLayer ~= nil then
                        app.activeLayer = tempLayer
                      end
                      app.activeFrame = 1
                      dlg1:close()
                    end
  }
  dlg1:newrow()
  dlg1:button  {  text = "Close",
                  onclick=
                    function()
                      dlg1:close()
                    end
  }
  dlg1:show    {   wait=true
  }
  return nil
end
-- Memorize original layers selected, before to run Path Animator Tool
local originalLayerStackIndices = {}
local celWithImageFound = false
local commandLayersFound = false
for i,layer in ipairs(app.range.layers) do
  table.insert(originalLayerStackIndices, layer.stackIndex)
  if layer.name:find(STRING_PATH_LAYER) == nil and
     layer.name:find(STRING_FUNCTION_LAYER) == nil and
     layer.name:find(STRING_RESULT_LAYER) == nil and
     layer.name:find(STRING_ROTATION_LAYER) == nil and
     layer.name:find(STRING_LOOKED_LAYER) == nil and
     layer.name:find(STRING_ROTAUX_LAYER) == nil and
     layer.name:find(STRING_SCALE_LAYER) == nil and
     #layer.cels >= 1 then
    celWithImageFound = true
  end
  if layer.name:find(STRING_PATH_LAYER) ~= nil or
     layer.name:find(STRING_LOOKED_LAYER) ~= nil then
    commandLayersFound = true
  end
end
if not commandLayersFound and not celWithImageFound then
  app.alert(string.format("Error: selected layers don't contain %s or %s in their names. Even, selected layers are empty.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
  return nil
elseif not commandLayersFound and celWithImageFound then
  app.alert(string.format("Error: selected layers don't contains %s neither %s in their names.", STRING_PATH_LAYER, STRING_LOOKED_LAYER))
  return nil
elseif commandLayersFound and not celWithImageFound then
  app.alert("Error: one or more selected layers are empty. Please Select a layer with images.")
  return nil
end
-- Dialogo:
local dlg = Dialog{ title="Path Animator Tool" }
dlg:button  {   text = HELP,
                onclick =
                function()
                  dlgHelp:show()
                end
}
dlg:number  {   id="startTime",
                text=startTime,
                decimals=3
}
dlg:number  {   id="aniDuration",
                text=duration,
                decimals=3
}
dlg:newrow()
-- Loop Path:
-- A path has a beginning (white point) and an end (the other path end).
-- A path can be thinked like a road from 0% to 100%.
-- In the other hand, a path can be thinked as a cycle which can be repeated many times
-- Some times, we need to cyclically travel a path with differents images in the same path, but with different cycle start points
-- For example: we need 3 images to cylically travel a circunference. Ok, so we need to check LOOP PATH and each image
-- congigured a PATH START % of 0% , 33.33% and 66.67%.
dlg:check  {  id="loopPath",
              text="Loop Path ?",
              selected=loopPath
}
dlg:newrow()
dlg:number  {   id="startPathPos",
                text=startPathPos,
                decimals=3
}
dlg:newrow()
dlg:combobox  { id="translationFunction",
                option=translationFun,
                options={ TFUNprefix .. FUNC_LINEAL,
                          TFUNprefix .. FUNC_BYLAYER,
                          TFUNprefix .. FUNC_EASYIN,
                          TFUNprefix .. FUNC_EASYOUT,
                          TFUNprefix .. FUNC_EASYOUTDAMPED,
                          TFUNprefix .. FUNC_EASYOUTDAMPED2,
                          TFUNprefix .. FUNC_EASYINOUT,
                          TFUNprefix .. FUNC_SINUSOIDAL,
                          TFUNprefix .. FUNC_PARABOLIC }
}
dlg:newrow()

dlg:combobox  { id="rotation",
                option=rotationType,
                options={ ROTATIONprefix .. ROTATION_NONE,
                          ROTATIONprefix .. ROTATION_PATH,
                          ROTATIONprefix .. ROTATION_LOOKAT,
                          ROTATIONprefix .. ROTATION_BYLAYER }
}
dlg:newrow()
dlg:number  {   id="initialAngle",
                text=initialAngle,
                decimals=3
}
dlg:newrow()

dlg:combobox  { id="scaleFunction",
                option=scaleFun,
                options={ SFUNprefix .. SCALE_NONE,
                          SFUNprefix .. SCALE_LINEAL,
                          SFUNprefix .. SCALE_BYLAYER,
                          SFUNprefix .. SCALE_EASYIN,
                          SFUNprefix .. SCALE_EASYOUT,
                          SFUNprefix .. SCALE_EASYOUTDAMPED,
                          SFUNprefix .. SCALE_EASYOUTDAMPED2,
                          SFUNprefix .. SCALE_EASYINOUT,
                          SFUNprefix .. SCALE_SINUSOIDAL,
                          SFUNprefix .. SCALE_PARABOLIC }
}
dlg:newrow()
dlg:number  {   id="initialScale",
                text=initialScale,
                decimals=3
}
dlg:newrow()
dlg:number  {   id="finalScale",
                text=finalScale,
                decimals=3
}
dlg:newrow()
dlg:check  {  id="makeNewResultLayer",
              text="Make new ResultLayer",
              enabled=makeNewResultLayerEnabled,
              selected=makeNewResultLayer
}
dlg:newrow()
dlg:button  {   text = "Animate it",
                focus=true,
                onclick =
                  function()
                    -- Make animation!
                    local rotation = dlg.data.rotation:gsub(ROTATIONprefix, "")
                    local translationFunction = dlg.data.translationFunction:gsub(TFUNprefix, "")
                    local startTime = dlg.data.startTime
                    local duration = dlg.data.aniDuration
                    local initialAngle = dlg.data.initialAngle
                    local startPathPos = dlg.data.startPathPos
                    local loopPath = dlg.data.loopPath
                    local scaleFunction = dlg.data.scaleFunction:gsub(SFUNprefix, "")
                    local initialScale = dlg.data.initialScale
                    local finalScale = dlg.data.finalScale
                    local makeNewResultLayer = dlg.data.makeNewResultLayer
                    if startTime == DEFAULT_STARTTIME_STRING then
                      startTime = 0.0
                    end
                    if duration == 0 then
                      duration = 2.0
                    end
                    if initialAngle == DEFAULT_INITIALANGLE_STRING then
                      initialAngle = 0
                    end
                    if startPathPos == nil or startPathPos == "" or startPathPos == DEFAULT_PATH_START_POS_STRING then
                      startPathPos = 0.0
                    end
                    if initialScale == DEFAULT_INITIAL_SCALE then
                      initialScale = 1.0
                    end
                    if finalScale == DEFAULT_FINAL_SCALE then
                      finalScale = 1.0
                    end
                    
                    local success = animateIt(app.range.layers,
                                              startTime,
                                              duration,
                                              translationFunction,
                                              rotation,
                                              initialAngle,
                                              startPathPos,
                                              loopPath,
                                              scaleFunction,
                                              initialScale,
                                              finalScale,
                                              makeNewResultLayer)
                    app.activeFrame = 1
                    dlg:close()
                  end
}
dlg:newrow()
dlg:button  {   text = "Close",
                onclick=
                    function()
                      dlg:close()
                    end
}
dlg:show    {   wait=true
}
selectOriginalLayers(originalLayerStackIndices)