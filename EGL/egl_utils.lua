
local ffi = require "ffi"
local EGL = require "EGL"
local vgu = require "vgu"

EglDisplay = {}
EglDisplay_mt = {
	__index = EglDisplay,
}

EglDisplay.new = function(dispid, api)
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
	obj:BindToAPI(api);
	obj:ChooseConfig();
	obj:CreateContext();
	
	return obj
end

EglDisplay.free = function(self)
	local res = EGL.Lib.eglTerminate(self.Handle);	
end

EglDisplay.Initialize = function(self)
	local pmajor = ffi.new("EGLint[1]");
	local pminor = ffi.new("EGLint[1]");
	local res = EGL.Lib.eglInitialize(self.Handle, pmajor, pminor);
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
	
	local pconfig = ffi.new("EGLConfig[1]");
	local pnum_config = ffi.new("EGLint[1]");

	local res = EGL.Lib.eglChooseConfig(self.Handle, attribute_list, pconfig, 1, pnum_config);
	
	assert(res == EGL.EGL_TRUE);

	self.Config = pconfig[0];
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
	assert(res == EGL.EGL_TRUE);
end

EglDisplay.SwapBuffers = function(self, surface)
	surface = surface or self.Surface;
	local res = EGL.Lib.eglSwapBuffers(self.Handle, surface);
end



return {
	Lib = EGL.Lib,
	Display = EglDisplay,
	}
	