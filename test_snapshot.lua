
local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMXDisplay();
local screenWidth, screenHeight = Display:GetSize();
local ratio = screenWidth / screenHeight;
local displayHeight = 70;
local displayWidth = displayHeight * ratio;


-- Create the view that will display the snapshot
local displayView = Display:CreateView(displayWidth, displayHeight, 0, screenHeight-displayHeight-1)


-- Do the snapshot
displayView:Hide();	
Display:Snapshot(displayView.Resource);
displayView:Show();

ffi.C.sleep(5);

	
