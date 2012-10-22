
local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMXDisplay();
local screenWidth, screenHeight = Display:GetSize();
local ratio = screenWidth / screenHeight;
local displayHeight = 70;
local displayWidth = displayHeight * ratio;


-- Create the view that will display the snapshot
local displayView = Display:CreateView(displayWidth, displayHeight, 0, screenHeight-displayHeight-1)



local function WritePPM(filename, pixbuff)
    local r, c, val;

    local fp = io.open(filename, "wb")
    if not fp then
        return false
    end

    local header = string.format("P6\n%d %d\n255\n", pixbuff.Width, pixbuff.Height)
    fp:write(header);

    local data = ffi.string(pixbuff.Data, pixbuff.Width*pixbuff.Height * 3);
    fp:write(data);


--[[
    for r = 0, pixbuff.Height-1 do
		for c = 0, pixbuff.Width-1 do
			local offset = (r*pixbuff.Width)+c
			local pix = pixbuff.Data[offset]:ToArray();
			fp:write(pix);
		end
    end
--]]

    fp:close();
end

-- Do the snapshot
displayView:Hide();	
Display:Snapshot(displayView.Resource);
displayView:Show();

ffi.C.sleep(5);

--WritePPM("desktop_"..i..".ppm", pixmap);
	
