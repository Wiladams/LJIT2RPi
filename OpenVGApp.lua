
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

local PS = require "PSLoader";



local screenWidth = 640;
local screenHeight = 480;
local rotateN = 0.0;
local rotateFactor = 1;





--[[
	Render
--]]
local function renderbegin(scene, w, h)
	local clearColor = ffi.new("VGfloat[4]", 1,1,1,1);
	VG.vgSetfv(ffi.C.VG_CLEAR_COLOR, 4, clearColor);
	VG.vgClear(0, 0, w, h);

	VG.vgLoadIdentity();
end

local function renderend(scene, w, h)
	mainWindow:SwapBuffers();	-- force EGL to recognize resize
end

local function render(scene, w, h)
	local scale = w / (tigerModel.MaxX - tigerModel.MinX);

	renderbegin(scene, w, h);


        VG.vgTranslate(w * 0.5, h * 0.5);
        VG.vgRotate(rotateN);
        VG.vgTranslate(-w * 0.5, -h * 0.5);

	VG.vgScale(scale, scale);
	VG.vgTranslate(-tigerModel.MinX, -tigerModel.MinY + 0.5 * (h / scale - (tigerModel.MaxY - tigerModel.MinY)));

	scene:render();
	--assert(tonumber(VG.vgGetError()) == tonumber(ffi.C.VG_NO_ERROR));

	renderend(scene, w, h);
end





OpenVGApp = {}

OpenVGApp.init = function(width, height)
	width = width or 640;
	height = height or 480;

	OpenVGApp.Loop = EventLoop.new(15);
	OpenVGApp.Keyboard = Keyboard.new();


	OpenVGApp.Loop:AddObservable(OpenVGApp.Keyboard);
	OpenVGApp.Loop.OnIdle = OpenVGApp.Idle;
	OpenVGApp.Keyboard.OnKeyUp = OpenVGApp.KeyUp;
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
