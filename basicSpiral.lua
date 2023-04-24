-- Spiral
function spiral(func, turns, center)
    local angles = {}
    -- angle vector:
    local angle = 0
    while angle <= math.pi*2*turns do
      table.insert(angles, angle)
      angle = angle + math.pi*2/128
    end
    local x, y, r
    local spiralPoints = {}
    for i=1, #angles, 1 do
      r = func(angles[i])
      x = r * math.cos(angles[i]) + center.x
      y = r * math.sin(angles[i]) + center.y
      table.insert(spiralPoints, Point(x, y))
    end
    return spiralPoints
end

local spiralFunc =  function(angle)
                      return angle*18/math.pi
                    end
local center = Point(app.activeSprite.width, app.activeSprite.height)/2
local spiral = spiral(spiralFunc, 3, center)
app.useTool {tool='pencil', points=spiral}