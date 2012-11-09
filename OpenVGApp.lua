
local ffi = require "ffi"
local C = ffi.C;
local bit = require "bit"
local bor = bit.bor
local band = bit.band


-- Bring in the necessary UI stuff
local rpiui = require "rpiui"

local Keyboard = require "Keyboard"
local EventLoop = require "EventLoop"

local GLES = rpiui.GLES;
local EGL = rpiui.EGL;
local OpenVG = rpiui.OpenVG;
local egl = require "egl"
local VG = EGL.Lib;



OpenVGApp = {}

OpenVGApp.init = function(width, height)
	width = width or 640;
	height = height or 480;

	-- Setup the event loop stuff
	OpenVGApp.Loop = EventLoop.new(15);
	OpenVGApp.Keyboard = Keyboard.new();


	OpenVGApp.Loop:AddObservable(OpenVGApp.Keyboard);
	OpenVGApp.Loop.OnIdle = OpenVGApp.Idle;
	OpenVGApp.Keyboard.OnKeyUp = OpenVGApp.KeyUp;
	
	-- Create the Main Window
	OpenVGApp.Window = EGL.Window.new(width, height, nil, EGL.EGL_OPENVG_API);

	return OpenVGApp;
end


OpenVGApp.Render = function(self)
	if self.OnRender then
		self.OnRender(self)
	end
end

OpenVGApp.Idle = function(loop)
	if OpenVGApp.OnIdle then
		OpenVGApp.OnIdle(OpenVGApp);
	end
end

OpenVGApp.KeyUp = function(kbd, keycode)
  	-- Halt the loop if they press the "Esc" key
  	if OpenVGApp.OnKeyUp then
		OpenVGApp.OnKeyUp(kbd, keycode);
	else
		if keycode == KEY_ESC then
    			OpenVGApp.Stop();
  		end
	end
end

OpenVGApp.Stop = function(self)
	self.Loop:Halt();
end

OpenVGApp.Run = function(self)
	self.Loop:Run(15);
end

return OpenVGApp
