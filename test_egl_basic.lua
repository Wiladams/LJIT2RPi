
local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor
local lshift = bit.lshift;

local DMX = require "DisplayManX"


local Khronos = require "Khronos"

local GLES = Khronos.GLES;
local EGL = Khronos.EGL;
local OpenVG = Khronos.OpenVG;

local RenderClass = require"Drawing"


local screenWidth = 640;
local screenHeight = 480;


-- Create the EGL Display Object
local egldisplay = EGL.Display.new(nil, EGL.EGL_OPENGL_API);
assert(egldisplay, "EglDisplay not created");

local dmxdisplay;
local dmxview;

function createNativeWindow(width, height)
	-- get the DMX display first
	dmxdisplay = DMX.DMXDisplay();
	assert(dmxdisplay, "Could not initialize DMXDisplay");

   	local dst_rect = VC_RECT_T(0,0,width, height);   
   	local src_rect = VC_RECT_T(0,0, lshift(width, 16), lshift(height,16));      

   	dmxview = dmxdisplay:CreateElement(dst_rect, nil, src_rect);     
	assert(dmxview, "Could not create DMX Display Element");

	-- create an EGL window surface
  	local nativewindow = ffi.new("EGL_DISPMANX_WINDOW_T");
  	nativewindow.element = dmxview.Handle;
   	nativewindow.width = width;
   	nativewindow.height = height;

	return nativewindow;
end

local nativewindow = createNativeWindow(screenWidth, screenHeight);
local surf = egldisplay:CreateWindowSurface(nativewindow)

-- Make the context current
egldisplay:MakeCurrent();


glViewport(0,0,screenWidth,screenHeight);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();

local ratio = screenWidth/screenHeight;
glFrustumf(-ratio, ratio, -1, 1, 1, 10);


-- Now, finally do some drawing


    -- Sleep for a second so we can see the results
    local seconds = 5
    print( string.format("Sleeping for %d seconds...", seconds ));
    ffi.C.sleep( seconds )

-- free up the display
egldisplay:free();
