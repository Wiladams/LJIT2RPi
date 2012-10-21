
local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor
local lshift = bit.lshift;



local rpiui = require "rpiui"

local GLES = rpiui.GLES;
local EGL = rpiui.EGL;
local OpenVG = rpiui.OpenVG;
local egl = require "egl"


local screenWidth = 640;
local screenHeight = 480;

print("EGL API: ", EGL.EGL_OPENVG_API);

local mainWindow = EGL.Window.new(screenWidth, screenHeight, nil, EGL.EGL_OPENVG_API);
--local mainWindow = EGL.Window.new(screenWidth, screenHeight, nil, EGL.EGL_OPENGLES_API);
--local mainWindow = EGL.Window.new(screenWidth, screenHeight, nil);

local RenderClass = require"Drawing"


print("-- EGL --");
print("Vendor: ", mainWindow.Display:Vendor());
print("ClientAPIs: ", mainWindow.Display:ClientAPIs());
print(string.format("Current API: 0x%x", mainWindow.Display:CurrentAPI()));
print("Extensions: ");
print(mainWindow.Display:Extensions());

-- Create the renderer so we can do some drawing
local Renderer = RenderClass.new(mainWindow.Display, screenWidth, screenHeight);



local drawLines = function()
	--Renderer:Begin();
	  Renderer:StrokeWidth(1);
	  Renderer:SetStroke(250,250,250,1);
	  Renderer:Line(1,1, screenWidth/2, screenHeight/2);
	--Renderer:End();
end

local drawRectangles = function(count)
    count = count or 100;


    --Renderer:Begin();
    for i=1,count do
        local width = math.random(10,250);
        local height = math.random(10,250);
	local x = math.random(0,screenWidth -1-width);
	local y = math.random(0,screenHeight - 1-height);
	  
	local red = math.random(0,255);
	local green = math.random(0,255);
	local blue = math.random(0,255);

	Renderer:Fill(red, green, blue, 1);
	--print(x,y,width, height, ": ", red, green, blue);
	Renderer:Rect(x,y,width,height);
    end
    --Renderer:End();

end

local drawEllipses = function()
	Renderer:PushTransform();

	--Renderer:Begin();
	  Renderer:Translate(screenWidth/2, screenHeight/2);
	  Renderer:Fill(44, 77, 232, 1);		-- Big blue marble
	  Renderer:Circle(0, 0, screenHeight/2);	-- The "world"
	--Renderer:End();

	Renderer:PopTransform();
end

local tick = function(ticker, tickCount)
	print("Tick: ", tickCount);

	
	Renderer:Begin();
	  Renderer:Background(0, 0, 0);				   -- Black background

	  drawRectangles(255);
	  drawEllipses();
  	  drawLines();
	Renderer:End();
end


glViewport(0,0,screenWidth,screenHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();

local ratio = screenWidth/screenHeight;
glFrustumf(-ratio, ratio, -1, 1, 1, 10);


-- Now, finally do some drawing
tick(RealDisplay, 1);


-- Sleep for a few seconds so we can see the results
local seconds = 3
print( string.format("Sleeping for %d seconds...", seconds ));
ffi.C.sleep( seconds )

