package.path = package.path..";..\\?.lua;..\\Win32\\?.lua";

local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor

local NativeWindow = require "User32Window"
local EGL = require "egl_utils"

local OpenVG = require "OpenVG"
local OpenVGUtils = require "OpenVG_Utils"
local ogm = require "OglMan"
local RenderClass = require"Drawing"




local dpy = EglDisplay.new(nil, EGL.EGL_OPENVG_API);
assert(dpy, "EglDisplay not created");

local screenWidth = 640;
local screenHeight = 480;



local Renderer = RenderClass.new(dpy, screenWidth, screenHeight);



local drawLines = function()
	Renderer:StrokeWidth(1);
	Renderer:SetStroke(250,250,250,1);
	Renderer:Line(1,1, screenWidth/2, screenHeight/2);

end

local drawRectangles = function()
	Renderer:Fill(230, 23, 23, 1);
	Renderer:Rect(10,10,100,100);
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
	drawRectangles();
	drawLines();

	Renderer:End();
end



-- Create a window
local winParams = {
	ClassName = "EGLWindow",
	Title = "EGL Window",
	Origin = {10,10},
	Extent = {screenWidth, screenHeight},
	FrameRate = 3,

	OnTickDelegate = tick;
};


-- create an EGL window surface
local win = NativeWindow.new(winParams)
assert(win, "Window not created");

local surf = dpy:CreateWindowSurface(win:GetHandle())

-- Make the context current
dpy:MakeCurrent();

glViewport(0,0,screenWidth,screenHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();

local ratio = screenWidth/screenHeight;
glFrustum(-ratio, ratio, -1, 1, 1, 10);


-- Now, finally do some drawing
win:Run();


-- free up the display
dpy:free();
