
local ffi = require "ffi"

local EGL = require "egl"
local vgu = require "vgu"


EGL.Lib = ffi.load("EGL");




EglDisplay = {}
EglDisplay_mt = {
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



return {
	Lib = EGL.Lib,
	Display = EglDisplay,
	}
	