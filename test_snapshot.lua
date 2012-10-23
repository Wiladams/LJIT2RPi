
local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMXDisplay();
local screenWidth, screenHeight = Display:GetSize();
local ratio = screenWidth / screenHeight;
local displayHeight = 320;
local displayWidth = 640;
--local displayHeight = 70;
--local displayWidth = displayHeight * ratio;


-- Create the view that will display the snapshot
local displayView = Display:CreateView(
	displayWidth, displayHeight, 
	0, screenHeight-displayHeight-1,
	0, ffi.C.VC_IMAGE_RGB888)


-- Do the snapshot
displayView:Hide();	
Display:Snapshot(displayView.Resource);
displayView:Show();


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


local pixeldata, err = displayView.Resource:ReadPixelData();
if pixeldata then
	-- Write the data out
	local filename = "desktop.ppm"
	print("Writing: ", filename);

	WritePPM(filename, pixeldata);
end

ffi.C.sleep(5);

	
