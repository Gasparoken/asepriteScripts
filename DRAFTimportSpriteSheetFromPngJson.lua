-- json.lua can be found here: https://github.com/aseprite/json.lua
-- This script work up to 99 frames. To extend to several frames some modification is required.
local json = dofile('/...../json.lua')
local sheet1 = json.decode(io.open('/......./sheet.json'):read('a')) -- exported sprite sheet should be generated with --split-layers set
local framesAmount = #(sheet1.frames)
local reBuiltSprite = Sprite(sheet1.frames[1].sourceSize.w, sheet1.frames[1].sourceSize.h, ColorMode.RGB)
local spriteSheet = Image{ fromFile="/........../sheet.png" } -- exported sprite sheet should be generated with --split-layers set
local lay = 1
repeat
	local layerName = sheet1.meta.layers[lay].name
	local layer = reBuiltSprite.layers[lay]
	for i=1, #sheet1.frames do
		if string.find(sheet1.frames[i].filename, layerName) ~= nil then
			local sample = sheet1.frames[i]
			local dotAseIndex = string.find(sample.filename, ".ase")
			local frame = (string.sub(sample.filename, dotAseIndex - 2, dotAseIndex - 1)) + 1 --  <-- here we take 2 digits (thats why 99 frames are the top, additional modifications is needed for more digits)
            for f=#reBuiltSprite.frames, frame-1 do
                reBuiltSprite:newEmptyFrame()
            end
			local image = Image(sample.frame.w, sample.frame.h)
			for y=0,image.height-1 do
				for x=0,image.width-1 do
					image:drawPixel(x, y, spriteSheet:getPixel(sample.frame.x + x, sample.frame.y + y))
				end
			end
			reBuiltSprite:newCel(layer, frame, image, Point(sample.spriteSourceSize.x, sample.spriteSourceSize.y))
		end
	end
	if lay < #sheet1.meta.layers then
		reBuiltSprite:newLayer()
	end
	lay = lay + 1
until(lay > #sheet1.meta.layers)