
local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor
local lshift = bit.lshift;

local DMX = require "DisplayManX"


local rpiui = require "rpiui"

local GLES = rpiui.GLES;
local EGL = rpiui.EGL;
local OpenVG = rpiui.OpenVG;

local RenderClass = require"Drawing"


-- Create the EGL Display Object
local RealDisplay = EGL.Display.new();
assert(RealDisplay, "EglDisplay not created");



local screenWidth = 640;
local screenHeight = 480;


-- Create the renderer so we can do some drawing
local Renderer = RenderClass.new(RealDisplay, screenWidth, screenHeight);



local drawLines = function()
	Renderer:StrokeWidth(1);
	Renderer:SetStroke(250,250,250,1);
	Renderer:Line(1,1, screenWidth/2, screenHeight/2);

end

local drawRectangles = function(count)
    count = count or 100;

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
end

local drawEllipses = function()
	Renderer:PushTransform();

	Renderer:Translate(screenWidth/2, screenHeight/2);
	Renderer:Fill(44, 77, 232, 1);				   -- Big blue marble
	Renderer:Circle(0, 0, screenHeight/2);		-- The "world"
	Renderer:Fill(255, 255, 255, 1);					-- White text

	Renderer:PopTransform();
end

local tick = function(ticker, tickCount)
	print("Tick: ", tickCount);

	Renderer:Begin();

	Renderer:Background(0, 0, 0);				   -- Black background

	drawEllipses();
	drawRectangles(255);
	drawLines();

	Renderer:End();
end


function createNativeWindow(width, height)

	-- get the DMX display first
	local Display = DMX.DMXDisplay();
	assert(Display, "Could not initialize DMXDisplay");

   	local dst_rect = VC_RECT_T(0,0,width, height);   
   	local src_rect = VC_RECT_T(0,0, lshift(width, 16), lshift(height,16));      

   	local View = Display:CreateElement(dst_rect, nil, src_rect);     

	-- create an EGL window surface
  	local nativewindow = ffi.new("EGL_DISPMANX_WINDOW_T");
  	nativewindow.element = View.Handle;
   	nativewindow.width = width;
   	nativewindow.height = height;

	return nativewindow;
end

local nativewindow = createNativeWindow(screenWidth, screenHeight);
local surf = RealDisplay:CreateWindowSurface(nativewindow)

-- Make the context current
RealDisplay:MakeCurrent();


glViewport(0,0,screenWidth,screenHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();

local ratio = screenWidth/screenHeight;
glFrustumf(-ratio, ratio, -1, 1, 1, 10);


-- Now, finally do some drawing
tick(RealDisplay, 1);


    -- Sleep for a second so we can see the results
    local seconds = 5
    print( string.format("Sleeping for %d seconds...", seconds ));
    ffi.C.sleep( seconds )

-- free up the display
RealDisplay:free();
