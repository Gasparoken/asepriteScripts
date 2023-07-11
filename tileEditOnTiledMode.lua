-- Copyright (C) 2023 Gaspar Capello

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
--======================= TILE EDIT SCRIPT =======================--
--================================================================--

-- Purpose: individual edition of a tile from a tilemap layer via
--          separate sprite in Tiled Mode.
-- 1. On a tilemap layer, select the desired tile to edit (Marquee tool,
--    double-click the desired tile).
-- 2. Run the script, a new sprite is created with the tile image
--    and Tiled Mode ON on both axis. You can edit the image.
-- 3. When finish editing, press OK on the "Edit Tile" dialog.
-- 4. The tile and tileset will be updated.

local spr = app.sprite
if spr == nil then
  return app.alert("Error: No sprite.")
end
local originalLayer = app.layer
if not originalLayer.isTilemap then
  return app.alert("Error: active layer isn't a tilemap layer.")
end
local selection = spr.selection.bounds
if selection.isEmpty then
  return app.alert("Error: No selection.")
end
local currentCel = app.cel
local originalFrame = app.frame
local pixelOffset = selection.origin - currentCel.position
local tileSize = app.layer.tileset.grid.tileSize
local tilePos = Point(pixelOffset.x / tileSize.width,
                      pixelOffset.y / tileSize.height)

app.command.Copy {}
local newSpr = Sprite(selection.width, selection.height, spr.colorMode)
newSpr:setPalette(Palette(spr.palettes[1]))
newSpr:newCel(app.layer, 1)
app.command.Paste {}

local TilemapModeChanged = false
if newSpr.layers[1]:cel(1).image.isEmpty then
  TilemapModeChanged = true
  app.sprite = spr
  app.command.ToggleTilesMode {}
  app.command.Copy {}
  app.sprite = newSpr
  app.command.Paste {}
end
app.command.TiledMode {axis="both"}
app.command.FitScreen {}

local dlg = Dialog("Tile Edit")

local function setTile()
  app.sprite = spr
  local cel = originalLayer:cel(originalFrame)
  local tileIndex = cel.image:getPixel(tilePos.x, tilePos.y)
  originalLayer.tileset:tile(tileIndex).image = Image(newSpr.layers[1]:cel(1).image)
  if TilemapModeChanged then
    app.command.ToggleTilesMode {}
  end
  newSpr:close()
  dlg:close()
end

local function back()
  newSpr:close()
  app.sprite = spr
  if TilemapModeChanged then
    app.command.ToggleTilesMode {}
  end
  dlg:close()
end

dlg:button {id="ok",
            text="OK",
            onclick=setTile}
dlg:button {id="cancel",
            text="Cancel",
            onclick=back}
dlg:show{
  wait=false,
  bounds=Rectangle(0, 0 , 100 * app.uiScale, 45 * app.uiScale)
}