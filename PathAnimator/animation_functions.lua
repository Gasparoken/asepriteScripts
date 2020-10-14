-- Animation Functions
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

function lineal(x)
  return x
end

function sinusoidal(x)
  return (1 - math.cos(2 * math.pi * x)) / 2
end

function parabolic(x)
  return -4 * (x - 1) * x
end

function easyOutDamped(x)
  local maxAmp = 1.29
  if x == 0 then
    return 0
  else
    if x >= 0.87 then
      return 0.775
    else
      return (2^(-10 * x) * math.sin((8 * x - 0.75) * 2) + 1) / maxAmp
    end
  end
end

function easyOutDamped2(x)
  local maxAmp = 1.125
  if x == 0 then
    return 0
  else
    if x >= 0.48 then
      return 0.8889
    else
      return (2^(-18 * x) * math.sin((8 * x - 0.75) * 2) + 1) / maxAmp
    end
  end
end

function easyInOut(x)
  if x < 0.5 then
    return 4 * x * x * x
  else
    return 1 - (-2 * x + 2)^3 / 2
  end
end

function easyIn(x)
  return x * x * x
end

function easyOut(x)
  return 1 - (1 - x)^3;
end

-- Curve by layer:
function makeCurveFromLayer(layer, isRotationCurve)
  local curve = {}
  if layer.cels[1] == nil then
    app.alert(string.format("No image on layer '%s'. Please draw a stroke on the first frame.", layer.name))
    return nil
  end
  local image = layer.cels[1].image
  local amp = image.height - 1
  local time = image.width - 1
  if image == nil or amp < 1 or time < 1  then
    app.alert(string.format("No image on layer '%s'. Image size should be a minimum of 2x2 pixels.", layer.name))
    return nil
  end
  local maskColor = image.spec.transparentColor
  local errorFlag = true
  -- first pixel column (x == 0) is not considered, first column is an axis to know which is the 0.0 (bottom) to 1.0 (top).
  -- when IS a ROTATION CURVE first pixel column (x == 0) is an axis to know which is the '-pi' (bottom) and 'pi' (top) angles.
  for x=1, time, 1 do
    for y=0, amp, 1 do
      if image:getPixel(x, y) ~= maskColor and
         image:getPixel(x, y) ~= MASK_COLOR2 then
        if isRotationCurve then
          table.insert(curve, (amp - 2*y) / amp * math.pi)
        else
          table.insert(curve, (amp - y) / amp)
        end
        errorFlag = false
        break
      end
    end
    if errorFlag then
      app.alert(string.format("The image curve on layer '%s' hasn't continuity on X", layer.name))
      return nil
    end
  end
  return curve
end

function byLayer(x, vectorCurve)
  local xToIndex = x * (#vectorCurve-1) + 1
  -- Interpolate position between two vectorCurve elements
  local index0 = math.floor(xToIndex)
  local index1 = index0 + 1
  if index1 > #vectorCurve then
    return vectorCurve[#vectorCurve]
  end
  local slope = vectorCurve[index1] - vectorCurve[index0]
  local xFromIndex0 = (xToIndex - math.floor(xToIndex))
  return vectorCurve[index0] + slope * xFromIndex0
end