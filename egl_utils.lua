
local ffi = require "ffi"
local bit = require "bit"
local lshift = bit.lshift

local DMX = require "DisplayManX"
local EGL = require "egl"
local vgu = require "vgu"


EGL.Lib = ffi.load("EGL");


local EglDisplay = {}
local EglDisplay_mt = {
	__index = EglDisplay,
}

EglDisplay.new = function(api, dispid)
	local dpy
	
	if not dispid then
		dpy = EGL.Lib.eglGetDisplay(EGL.EGL_DEFAULT_DISPLAY);
	else
		return nil
	end
	
	local obj = {
		Handle = dpy;
	}
	
	setmetatable(obj, EglDisplay_mt);
	
	obj:Initialize();
	
	--print("BINDING TO API: ", api);
	if api then
		-- api = api or EGL.EGL_OPENVG_API
		assert(obj:BindToAPI(api), "Could not bind to API");
	end
	assert(obj:ChooseConfig(), "Could not choose config");
	assert(obj:CreateContext(), "Could not create context");
	
	return obj
end

EglDisplay.free = function(self)
	local res = EGL.Lib.eglTerminate(self.Handle);	
end

EglDisplay.Initialize = function(self)
	local pmajor = ffi.new("EGLint[1]");
	local pminor = ffi.new("EGLint[1]");
	local res = EGL.Lib.eglInitialize(self.Handle, nil, nil);
	assert(res ~= EGL.EGL_FALSE);
	
	return self, pmajor[0], pminor[0];
end

EglDisplay.BindToAPI = function(self, api)
	api = api or EGL.EGL_OPENVG_API

	local res = EGL.Lib.eglBindAPI(api);
	
	if res == EGL_FALSE then
		return nil
	end
	
	return self
end

EglDisplay.ChooseConfig = function(self, attribute_list)
	attribute_list = attribute_list or ffi.new("EGLint[11]", 
		EGL.EGL_RED_SIZE, 8,		
		EGL.EGL_GREEN_SIZE, 8,		
		EGL.EGL_BLUE_SIZE, 8,		
		EGL.EGL_ALPHA_SIZE, 8,		
		EGL.EGL_SURFACE_TYPE, EGL.EGL_WINDOW_BIT,	
		EGL.EGL_NONE);
	
	local pconfig = ffi.new("EGLConfig[10]");
	local pnum_config = ffi.new("EGLint[1]");

	local res = EGL.Lib.eglChooseConfig(self.Handle, attribute_list, pconfig, 10, pnum_config);

	assert(res == EGL.EGL_TRUE);

	local num_config = pnum_config[0]
	print("EglDisplay.ChooseConfig(): num: ", num_config);

	self.Config = pconfig[0];

	return self.Config;
end

EglDisplay.CreateContext = function(self, config)
	config = config or self.Config
	
	local ctx = EGL.Lib.eglCreateContext(self.Handle, config, EGL.EGL_NO_CONTEXT, nil);
	self.Context = ctx;
	return ctx;
end


EglDisplay.CreateWindowSurface = function(self, nativewindow, config)
	config = config or self.Config
	
	local srf = EGL.Lib.eglCreateWindowSurface(self.Handle, config, nativewindow, nil);
	self.Surface = srf
	
	return srf;
end



EglDisplay.CreateWindow = function(self, width, height, config)
	config = config or self.config

	return EGLWindow.new(self, width , height)
end

EglDisplay.MakeCurrent = function(self, surface, context)
	surface = surface or self.Surface;
	context = context or self.Context;
	
	-- connect the context to the surface
	local res = EGL.Lib.eglMakeCurrent(self.Handle, surface, surface, context);
	return res
end

EglDisplay.SwapBuffers = function(self, surface)
    surface = surface or self.Surface;
    local res = EGL.Lib.eglSwapBuffers(self.Handle, surface);
    
    return res;
end





--[[
	Representation of a window
--]]
--[[
Create a native window.  This is essentially
the lowest level window 'handle'.  EGL then 
uses this handle to create a managed 'window'.
--]]

local function createNativeWindow(dmxdisplay, width, height)

    local dst_rect = VC_RECT_T(0,0,width, height);   
    local src_rect = VC_RECT_T(0,0, lshift(width, 16), lshift(height,16));      

    --local alpha = VC_DISPMANX_ALPHA_T(ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS,255,0);
    --local dmxview = dmxdisplay:CreateElement(dst_rect, nil, src_rect, 0, DISPMANX_PROTECTION_NONE, alpha);     
    local dmxview = dmxdisplay:CreateElement(dst_rect, nil, src_rect);     
    assert(dmxview, "FAILURE: Did not create dmxview");

    -- create an EGL window surface
    local nativewindow = ffi.new("EGL_DISPMANX_WINDOW_T");
    nativewindow.element = dmxview.Handle;
    nativewindow.width = width;
    nativewindow.height = height;

    return nativewindow;
end


local EGLWindow = {}
local EGLWindow_mt = {
	__index = EGLWindow,
}

EGLWindow.new = function(width, height, config, api)

	config = config or {background = {153, 153, 153}};

	local obj = {
		Width = width;
		Height = height;
	}

	-- Create the display object
	obj.Display = EglDisplay.new(api);

	-- create nativewindow
	local dmxdisplay = DMX.DMXDisplay();
	obj.NativeWindow = createNativeWindow(dmxdisplay, width, height);

	-- create window surface
	obj.Surface = obj.Display:CreateWindowSurface(obj.NativeWindow);
	obj.Display:MakeCurrent();

	setmetatable(obj, EGLWindow_mt);

	if config.background then
		obj:SetBackgroundColor(config.background[1], config.background[2], config.background[3], config.background[3]);
	end

	obj:Clear();
	obj:SwapBuffers();

	return obj
end

EGLWindow.Clear = function(self)
	glClear(GL_COLOR_BUFFER_BIT);
end

EGLWindow.SetBackgroundColor = function(self, red, green, blue, alpha)
    alpha = alpha or 1.0;

    glClearColor(red/256, green/256, blue/256, alpha);

end

EGLWindow.SwapBuffers = function(self)
	self.Display:SwapBuffers();
end

EGL.Display = EglDisplay
EGL.Window = EGLWindow;

return EGL

--[[
return {
	Lib = EGL.Lib,
	Display = EglDisplay,
	Window = EGLWindow,
	}
--]]
