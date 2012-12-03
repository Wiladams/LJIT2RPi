
local ffi = require "ffi"
local C = ffi.C;
local bit = require "bit"
local bor = bit.bor
local band = bit.band


-- Bring in the necessary UI stuff
local rpiui = require "rpiui"
local DMX = require "DisplayManX"

local Keyboard = require "Keyboard"
local Mouse = require ("Mouse");
local EventLoop = require "EventLoop"

local GLES = rpiui.GLES;
local EGL = rpiui.EGL;
local OpenVG = rpiui.OpenVG;
local egl = require "egl"
local VG = EGL.Lib;



OpenVGApp = {
	-- Setup Display object
	Display = DMX.DMXDisplay();

	-- Setup the event loop stuff
	Loop = EventLoop.new(15);
}

OpenVGApp.init = function(width, height, x, y)
	width = width or 640;
	height = height or 480;



	-- Add the keyboard
	OpenVGApp.Keyboard = Keyboard.new();
	OpenVGApp.Keyboard.OnKeyUp = OpenVGApp.KeyUp;
	OpenVGApp.Keyboard.OnKeyDown = OpenVGApp.KeyDown;
	OpenVGApp.Loop:AddObservable(OpenVGApp.Keyboard);

	-- Add the mouse
	OpenVGApp.Mouse, err = Mouse.new();

	if OpenVGApp.Mouse then
		OpenVGApp.Mouse.OnButtonPressed = OpenVGApp.MouseDown;
		OpenVGApp.Mouse.OnButtonReleased = OpenVGApp.MouseUp;
		OpenVGApp.Mouse.OnMouseMove = OpenVGApp.MouseMove;
		OpenVGApp.Mouse.OnMouseWheel = OpenVGApp.MouseWheel;
		OpenVGApp.Loop:AddObservable(OpenVGApp.Mouse);
	end

	-- Other interesting things with the loop
	OpenVGApp.Loop.OnIdle = OpenVGApp.Idle;
	
	-- Create the Main Window
	OpenVGApp.Window = EGL.Window.new(width, height, x,y, nil, EGL.EGL_OPENVG_API);

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

OpenVGApp.KeyDown = function(kbd, keycode)
  	if OpenVGApp.OnKeyDown then
		OpenVGApp.OnKeyDown(kbd, keycode);
	end
end

OpenVGApp.KeyUp = function(kbd, keycode)
  	-- Halt the loop if they press the "Esc" key
  	if OpenVGApp.OnKeyUp then
		OpenVGApp.OnKeyUp(kbd, keycode);
	else
		if keycode == KEY_ESC then
    			OpenVGApp:Stop();
  		end
	end
end

-- Mouse Events
OpenVGApp.MouseDown  = function(mouse, button)
	if OpenVGApp.OnMouseDown then
		OpenVGApp.OnMouseDown(mouse, button);
	end
end

OpenVGApp.MouseUp = function(mouse, button)
	if OpenVGApp.OnMouseUp then
		OpenVGApp.OnMouseUp(mouse, button);
	end
end

OpenVGApp.MouseMove = function(mouse, axis, value)
	if OpenVGApp.OnMouseMove then 
		OpenVGApp.OnMouseMove(mouse, axis, value);
	end
end

OpenVGApp.MouseWheel = function(mouse, value)
	if OpenVGApp.OnMouseWheel then
		OpenVGApp.OnMouseWheel(mouse, value);
	end
end



-- Application Control

OpenVGApp.Stop = function(self)
	OpenVGApp.Loop:Halt();
end

OpenVGApp.Run = function(self)
	OpenVGApp.Loop:Run(15);
end

return OpenVGApp
