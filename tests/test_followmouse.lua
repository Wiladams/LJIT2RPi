package.path = package.path..";../?.lua"

-- Bring in the necessary UI stuff
local OpenVGApp = require "OpenVGApp"

local viewWidth = 32;
local viewHeight = 32;


local app = OpenVGApp.init(viewWidth, viewHeight, 10, 10);
local screenWidth, screenHeight = OpenVGApp.Display:GetSize();

local midScreenX = screenWidth/2;
local midScreenY = screenHeight/2;

-- Place the window in the center of the screen
local startx = midScreenX - viewWidth;
local starty = midScreenY - viewHeight;

local mouseX = midScreenX;
local mouseY = midScreenY;

app.Window:MoveTo(startx, starty);


app.OnMouseMove = function(mouse, axis, value)
--	print("Move: ", axis, value);

	if axis == REL_X then
		mouseX = mouseX + value;
		if mouseX < 0 then mouseX = 0; end
		if mouseX >= screenWidth-viewWidth then mouseX = screenWidth-1-viewWidth; end
	elseif axis == REL_Y then
		mouseY = mouseY + value;
		if mouseY < 0 then mouseY = 0; end
		if mouseY >= screenHeight-viewHeight then mouseY = screenHeight-1-viewHeight; end
	end

	-- Move the window
	app.Window:MoveTo(mouseX, mouseY);
end

app:Run();


