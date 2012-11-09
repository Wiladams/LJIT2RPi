package.path = package.path..";../?.lua"

local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMXDisplay();
local screenWidth, screenHeight = Display:GetSize();
local ratio = screenWidth / screenHeight;
local displayHeight = 320;
local displayWidth = 640;
--local displayHeight = 70;
--local displayWidth = displayHeight * ratio;






local function WritePPM(filename, pixbuff)
    local r, c, val;

    local fp = io.open(filename, "wb")
    if not fp then
        return false
    end

    local header = string.format("P6\n%d %d\n255\n", pixbuff.Width, pixbuff.Height)
    fp:write(header);

    for row=0,pixbuff.Height-1 do
	local dataPtr = ffi.cast("char *",pixbuff.Data) + pixbuff.Pitch*row
    	local data = ffi.string(dataPtr, pixbuff.Width*3);
    	fp:write(data);
    end

    fp:close();
end



-- Create the resource that will be used
-- to copy the screen into.  Do this so that
-- we can reuse the same chunk of memory
local resource = DMXResource(displayWidth, displayHeight, ffi.C.VC_IMAGE_RGB888);

local p_rect = VC_RECT_T(0,0,displayWidth, displayHeight);
local pixdata = resource:CreateCompatiblePixmap(displayWidth, displayHeight);

local framecount = 120


for i=1,framecount do
	-- Do the snapshot
	Display:Snapshot(resource);


	local pixeldata, err = resource:ReadPixelData(pixdata, p_rect);
	if pixeldata then
		-- Write the data out
		local filename = string.format("screencast/desktop_%06d.ppm", i);
		print("Writing: ", filename);

		WritePPM(filename, pixeldata);
	end

	--ffi.C.sleep(1);
end


	
