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


-- Input: This function rotates an image in the first cel of a selected layer.
-- Output: a new layer with the sufficient frames to accomplish RPM and time rotation.

-- Warnings:
-- This script assumes constant frame rate, otherwise, the angles and RPM won't match to expected.
-- If the RPM is too fast for the frame rate, the rotation animation will seem slower or erratic than expected.
-- To solve the last issue, you shall study one of these options:
--   1 - Increase the frame rate (lesser frame duration).
--   2 - Decrement the RPM number.
--   3 - Add shadows and custom effects as you wish in each frame.

sprite = app.activeSprite

if not app.isUIAvailable then
    return
 end
 
 if sprite == nil then
    app.alert("WARNING: You should open a sprite first.")
    return
 end

--================================================================--
--=================== Useful internal functions ==================--
function round(x)
    if x%2 ~= 0.5 then
      return math.floor(x+0.5)
    end
    return x-0.5
end

function activeFrameNumber()
    local f = app.activeFrame
    if f == nil then
      return 1
    else
      return f
    end
end

function findLayer(nameToFind)
    for i,layer in ipairs(sprite.layers) do
        if sprite.layers[i].name == nameToFind then
            return sprite.layers[i]
        end
    end
    return nil
end

function createLayerIfNotFound(layerName)
    local newLayer
    newLayer = findLayer(layerName)
    if newLayer == nil then
        newLayer = sprite:newLayer()
        newLayer.name = layerName
    end
    return newLayer
end

function SetActiveCel(layerName, frameNumber)
    if findLayer(layerName) == nil then
        app.activeLayer = createLayerIfNotFound(layerName)
    end
    app.activeLayer = findLayer(layerName)
    app.activeFrame = frameNumber
    if app.activeCel == nil then
        sprite:newCel(app.activeLayer, activeFrameNumber())
    end
end

-- It returns an Image which its bounds will be deltaSize pixels bigger than the original Image,
-- then it put the original Image in the center of the output Image.
function SetImageSize(image, deltaSize)
    -- the added pixels will be mask color.
    -- deltaSize should be two even numbers (  deltaSize=Size(even_w, even_h)  )
    local output = Image(image.width + deltaSize.width, image.height + deltaSize.height)
    for y=0 , image.height-1, 1 do
        for x=0 , image.width-1, 1 do
            local pixel = image:getPixel(x, y)
            output:putPixel(x + deltaSize.width/2 , y + deltaSize.height/2, pixel)
        end
    end
    return output
end

--================================================================--
--==================== Main rotation functions ===================--

function Rotar(image2Rot,imagePos, pivot, angle, expandConstant)
    local refImg = image2Rot:clone()
    local rows = refImg.height
    local columns = refImg.width

    local outputImg
    if expandConstant <= 1 or expandConstant == nil then
        outputImg = Image(sprite.width, sprite.height)
    else
        outputImg = Image(sprite.width * expandConstant, sprite.height* expandConstant)
    end
    
    for y = 0 , rows-1, 1 do
        for x = 0, columns-1, 1 do
            local currentRefPx = refImg:getPixel(x,y)
            local pivotRel = Point(x + imagePos.x - pivot.x, pivot.y - y - imagePos.y)
            if app.pixelColor.rgbaA(currentRefPx) ~= 0 then
                if math.abs(pivotRel.x) <= 0.3 then
                    outputImg:putPixel(pivot.x, pivot.y - pivotRel.y)
                else
                    local hipo = math.sqrt( pivotRel.x*pivotRel.x + pivotRel.y*pivotRel.y )
                    local angle2 = angle + math.atan(pivotRel.y / pivotRel.x)
                    if pivotRel.x < 0 then
                        angle2 = angle2 + math.pi
                    end
                    outputImg:putPixel(pivot.x + hipo * math.cos(angle2) , pivot.y - hipo * math.sin(angle2) , currentRefPx)
                end
            end
        end
    end
    return outputImg
end

function RotarMod(image2Rot, imagePos, pivot, angle)
    local EXPAND = 5 -- Expansion constant (image size scale factor, it must be odd number and >= 3)
                     -- greater --> better results, but more processing time
                     -- lesser  --> worse  results, but less processing time
    local refImg = image2Rot:clone()

    local rows = refImg.height
    local columns = refImg.width
    local outputImg = Image(sprite.width, sprite.height)
    local expandedRefImg = Image(refImg.width*EXPAND, refImg.height*EXPAND)

    -- Fill the empty expandedRefImg with the scaled original image
    -- It's like a SpriteSize command, but applied in a single Image, instead of a whole sprite.
    for y=0, rows-1, 1 do
        for x=0, columns-1, 1 do
            local currentRefPx = refImg:getPixel(x,y)
            for j=0, EXPAND-1, 1 do
                for i=0, EXPAND-1, 1 do
                    expandedRefImg:putPixel(x*EXPAND+i, y*EXPAND+j, currentRefPx)
                end
            end
        end
    end

    local expandedOutputImg = Image(sprite.width*EXPAND, sprite.height*EXPAND)
    expandedOutputImg = Rotar(expandedRefImg, Point(imagePos.x*EXPAND, imagePos.y*EXPAND), Point(pivot.x*EXPAND, pivot.y*EXPAND), angle, EXPAND)

    -- Filling the mask holes
    for y=1, expandedOutputImg.height-2, 1 do
        for x=1, expandedOutputImg.width-3, 1 do
            local currentRefPx = expandedOutputImg:getPixel(x,y)
            local le = expandedOutputImg:getPixel(x-1,y)
            local ri = expandedOutputImg:getPixel(x+1,y)
            local up = expandedOutputImg:getPixel(x,y-1)
            local bo = expandedOutputImg:getPixel(x,y+1)
            if currentRefPx == app.pixelColor:rgba(0,0,0,0) then
                if ri==le then
                    expandedOutputImg:putPixel(x,y,ri)
                elseif up==bo then
                    expandedOutputImg:putPixel(x,y,up)
                elseif expandedOutputImg:getPixel(x+1,y+1) == expandedOutputImg:getPixel(x-1,y-1) then
                    expandedOutputImg:putPixel(x,y,expandedOutputImg:getPixel(x+1,y+1))
                elseif expandedOutputImg:getPixel(x-1,y+1) == expandedOutputImg:getPixel(x+1,y-1) then
                    expandedOutputImg:putPixel(x,y,expandedOutputImg:getPixel(x-1,y+1))
                end
                if currentRefPx == ri and le == expandedOutputImg:getPixel(x+2,y) then
                    expandedOutputImg:putPixel(x,y,le)
                    expandedOutputImg:putPixel(x+1,y,le)
                end
            end
        end
    end

    -- Picking by pixel voting:
    for y = 0 , sprite.height-1, 1 do
        for x = 0, sprite.width-1, 1 do
            local xExpanded = x * EXPAND + (EXPAND-1)/2
            local yExpanded = y * EXPAND + (EXPAND-1)/2

            local currentRefPx = expandedOutputImg:getPixel(xExpanded,yExpanded)
            local up = expandedOutputImg:getPixel(xExpanded,yExpanded-1)
            local bo = expandedOutputImg:getPixel(xExpanded,yExpanded+1)
            local le = expandedOutputImg:getPixel(xExpanded-1,yExpanded)
            local ri = expandedOutputImg:getPixel(xExpanded+1,yExpanded)
            
            local pxCol = {currentRefPx, up, bo, le, ri}
            local votos = {0, 0, 0, 0}

            local maxElementIndex = 1
            local maxElement = 0
            for i=1, #pxCol-1, 1 do
                for j=i+1, #pxCol, 1 do
                    if j>i then
                        if pxCol[i] == pxCol[j] then
                            votos[i] = votos[i] + 1
                            if votos[i]>maxElement then
                                maxElementIndex = i
                                maxElement = votos[i]
                            end
                        end
                    end
                end
            end
            outputImg:putPixel(x , y , pxCol[maxElementIndex])
        end
    end
    return outputImg
end

--================================================================--
--========================= UI Interfase =========================--

local imageToRotate = sprite.layers[1]:cel(1).image
local imageCel = sprite.layers[1]:cel(1)

-- If layer count is greater than 1 we have to pick which Layer will be processed
if #sprite.layers > 1 then
    local dlg = Dialog()
    dlg:label   {   id= "label",
                    text= "-= Rotator =-"
                }
    dlg:newrow()          
    dlg:label   {   id= "label2",
                    text= "Pick a Layer:"
                }    
    dlg:newrow()
    for i = 1, #sprite.layers do
        dlg:button  {   text=sprite.layers[i].name,
                        onclick=
                            function()
                                imageToRotate = sprite.layers[i]:cel(1).image
                                imageCel = sprite.layers[i]:cel(1)
                                dlg:close()
                            end
                    }
        dlg:newrow()
    end
    dlg:show    {   wait=true
                }
end

-- Pivot and RPM selection
local turnDirection
local dlg = Dialog()
dlg:label   {   id= "label",
                text= "-= Rotator =-"
            }
dlg:newrow()          
dlg:entry   {   id= "x",
                label= "Pivot X:"
            }
dlg:entry   {   id= "y",
                label= "Pivot Y:"
            }
dlg:newrow() 
-- dlg:entry   {   id= "angle",
--                 label= "Degrees:"
--             }
-- dlg:newrow()
dlg:entry   {   id= "rpm",
                label= "RPMs:"
            }
dlg:newrow()
dlg:entry   {   id= "duration",
                label= "Total time:"
            }
dlg:newrow()
dlg:button  {   text="Turn L",
                onclick=
                    function()
                        turnDirection = 1
                        dlg:close()
                    end
            }
dlg:button  {   text="Turn R",
                onclick=
                    function()
                        turnDirection = -1
                        dlg:close()
                    end
}
dlg:show    {   wait=true
            }

--================================================================--
--========================= Script Start =========================--
local UIdata = dlg.data
local layerCloseGate = true
if UIdata.duration ~= nil then
    local outputLayer
    local k = ""
    while layerCloseGate do
        if findLayer("Output" .. k) == nil then
            outputLayer = createLayerIfNotFound("Output" .. k)
            layerCloseGate = false
        end
        if k=="" then
            k=0
        end
        k=k+1
    end

    local frameDuration = sprite.frames[1].duration
    for i=1, UIdata.duration/frameDuration - 1, 1 do
        if sprite.frames[i].next == nil then
            sprite:newEmptyFrame(i+1)
        end
    end

    local outputCel = sprite:newCel(outputLayer, 1, imageToRotate, Point(imageCel.position.x, imageCel.position.y))
    for i=1, #sprite.frames - 1, 1 do
        local outputImg = RotarMod(imageToRotate, imageCel.position, Point(UIdata.x, UIdata.y), i * turnDirection * frameDuration * UIdata.rpm * math.pi / 30)
        outputCel = sprite:newCel(outputLayer, i + 1, outputImg, Point(0, 0))
    end
end