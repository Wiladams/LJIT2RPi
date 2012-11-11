package.path = package.path..";../?.lua"

local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMX.DMXDisplay();

local screenWidth, screenHeight = Display:GetSize();
local ratio = screenWidth / screenHeight;
local displayHeight = 320;
local displayWidth = 640;


-- Create resource used for capturing screen
local resource = DMXResource(displayWidth, displayHeight);

-- Do the snapshot
Display:Snapshot(resource);

-- Get the pixel data so it can be copied
-- to multiple views
local pixeldata, err = resource:ReadPixelData();


local viewCount = 20
local views = {}

for i=1,viewCount do
	local x = math.random(0,screenWidth -1);
	local y = math.random(0,screenHeight - 1);

--print(string.format("[%d, %d]", x, y));

	x = x - displayWidth/2
	if x < 0 then
		x = 0 
	elseif x > screenWidth-1 - (displayWidth/2)+1 then 
		x = screenWidth-1-displayWidth 
	end
	
	y = y - displayHeight/2
	if y < 0 then 
		y = 0 
	elseif y > screenHeight-1 - (displayHeight/2)+1 then 
		y = screenHeight-1-displayHeight 
	end

print(string.format("[%d, %d]", x, y));

	local view = Display:CreateView(displayWidth, displayHeight, x, y)
	view:CopyPixelBuffer(pixeldata);
	table.insert(views, view);
	
	-- Wait a bit
	ffi.C.sleep(1);
end

ffi.C.sleep(3);


	
