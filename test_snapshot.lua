
local ffi = require "ffi"
local DMX = require "DisplayManX"

local Display = DMXDisplay();

local width = 640;
local height = 480;
local layer = 0;	-- keep the snapshot view on top

-- Create a resource to copy image into
local pixmap = DMX.DMXResource(width,height);

-- create a view with the snapshot as
-- the backing store
local mainView = DMX.DMXView.new(Display, 200, 200, width, height, layer, pformat, pixmap);

for i=1,20 do
	-- Do the snapshot
	mainView:Hide();	
	Display:Snapshot(pixmap);
	mainView:Show();

	ffi.C.sleep(1);

	
end