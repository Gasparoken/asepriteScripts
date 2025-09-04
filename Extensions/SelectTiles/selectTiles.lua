-- Command to select all tiles placed on the tilemap layer equal to
-- the foreground color (primary tile)
local function selectTiles()
  app.transaction(
    "Select tiles",
    function()
      if not app.isUIAvailable or app.sprite == nil then
        app.alert("WARNING: You should open a sprite first.")
        return nil
      end
      local layer = app.layer
      local cel = app.cel
      if not layer.isTilemap or not cel or app.site.tilemapMode == TilemapMode.PIXELS then
        app.alert("WARNING: You should focus a tilemap layer and the Tilemap Mode should be active.")
        return nil
      end
      local tileset = layer.tileset
      local ti = app.fgTile
      local tilemapImage = cel.image
      local celPos = cel.position
      local tileMatchPositions= {}
      for y=0, tilemapImage.height-1 do
        for x=0, tilemapImage.width-1 do
          if tilemapImage:getPixel(x, y) == ti then
            table.insert(tileMatchPositions, Point(x, y))
          end
        end
      end
      local tileW = tileset.grid.tileSize.width
      local tileH = tileset.grid.tileSize.height
      local selection = Selection()
      for i=1, #tileMatchPositions do
        local rect = Rectangle(celPos.x + tileMatchPositions[i].x * tileW,
                               celPos.y + tileMatchPositions[i].y * tileH,
                               tileW, tileH)
        selection:add(rect)
      end
      app.sprite.selection = selection
  end)
end

function init(plugin)
  plugin:newCommand{
    id="selectTiles",
    title="Fg Tiles on Tilemap",
    group="select_complex",
    onclick=function()
      selectTiles()
    end
  }
end