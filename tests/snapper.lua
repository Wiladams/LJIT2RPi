package.path = package.path..";../?.lua"

local ffi = require "ffi"

local Keyboard = require "Keyboard"
local EventLoop = require "EventLoop"

local DMX = require "DisplayManX"

local Display = DMXDisplay();
--Display:SetBackground(0,0,0);

local screenWidth, screenHeight = Display:GetSize();

local displayHeight = screenHeight;
local displayWidth = screenWidth;


-- Setup an event loop and keyboard
local loop = EventLoop.new();
local kbd = Keyboard.new();



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

local function TakeSnapshot()
	-- Create resource used for capturing screen
	local resource = DMXResource(displayWidth, displayHeight, ffi.C.VC_IMAGE_RGB888);

	-- Do the snapshot
	Display:Snapshot(resource);


	local pixeldata, err = resource:ReadPixelData();
	if pixeldata then
		-- Write the data out
		local filename = "media/desktop.ppm"

		WritePPM(filename, pixeldata);
	end

	print("File Written: ", filename);
end


OnKeyUp = function(kbd, keycode)
	if keycode == KEY_SYSRQ then
		TakeSnapshot();
	end
  
  	-- Halt the loop if they press the "Esc" key
  	if keycode == KEY_ESC then
    		loop:Halt();
  	end
end



-- Setup some keyboard with event handlers
kbd.OnKeyUp = OnKeyUp;

loop:AddObservable(kbd);

loop:Run(15);


	
