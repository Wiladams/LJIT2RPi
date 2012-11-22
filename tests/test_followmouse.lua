package.path = package.path..";../?.lua"

-- Bring in the necessary UI stuff
local OpenVGApp = require "OpenVGApp"

local viewWidth = 64;
local viewHeight = 64;


local app = OpenVGApp.init(viewWidth, viewHeight, 10, 10);
local screenWidth, screenHeight = OpenVGApp.Display:GetSize();

local startx = screenWidth/2 - viewWidth/2;
local starty = screenHeight/2 - viewHeight/2;

app.Window:MoveTo(startx, starty);


app.OnMouseMove = function(mouse, axis, value)
	print("Move: ", axis, value);

	local x = app.Window.X
	local y = app.Window.Y;

	if axis == REL_X then
		x = x + value;
	elseif axis == REL_Y then
		y = y + value;
	end

	-- Move the window
	app.Window:MoveTo(x,y);
end

app:Run();


