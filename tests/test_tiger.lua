-- #!/usr/local/bin/luajit

package.path = package.path..";../?.lua"

local ffi = require "ffi"
local C = ffi.C;
local bit = require "bit"
local bor = bit.bor
local band = bit.band


-- Bring in the necessary UI stuff

local OpenVGApp = require "OpenVGApp"


local rpiui = require "rpiui"
local EGL = rpiui.EGL;
local OpenVG = rpiui.OpenVG;
local VG = EGL.Lib;
local PS = require "PSLoader";


local viewWidth = 640;
local viewHeight = 480;



local app = OpenVGApp.init(viewWidth, viewHeight, 10, 10);

local screenWidth, screenHeight = app.Display:GetSize();

local tigerModel = require "tiger";
local tigerscene = {
	Width = viewWidth;
	Height = viewHeight;
	rotateN = 0.0;
	rotateFactor = 3;
	ClearColor = ffi.new("VGfloat[4]", 1,1,1,1);

	Elements = { 
		PS.construct(tigerModel.Commands, tigerModel.CommandCount, tigerModel.Points, tigerModel.PointCount);
	}
}



--[[
	Render
--]]
local function renderbegin(vgapp, scene)
	VG.vgSetfv(ffi.C.VG_CLEAR_COLOR, 4, scene.ClearColor);
	VG.vgClear(0, 0, scene.Width, scene.Height);

	VG.vgLoadIdentity();
end

local function renderend(vgapp, scene)
	vgapp.Window:SwapBuffers();	-- force EGL to recognize resize
end

local function render(vgapp, scene)
	renderbegin(vgapp, scene);

        VG.vgTranslate(scene.Width * 0.5, scene.Height * 0.5);
        VG.vgRotate(scene.rotateN);
        VG.vgTranslate(-scene.Width * 0.5, -scene.Height * 0.5);

	for _, element in ipairs(scene.Elements) do
		local scale = scene.Width / (tigerModel.MaxX - tigerModel.MinX);
		VG.vgScale(scale, scale);
		VG.vgTranslate(-tigerModel.MinX, -tigerModel.MinY + 0.5 * (scene.Height / scale - (tigerModel.MaxY - tigerModel.MinY)));
		element:render();
		--assert(tonumber(VG.vgGetError()) == tonumber(ffi.C.VG_NO_ERROR));
	end

	renderend(vgapp, scene);
end



app.OnIdle = function(vgapp)
--print("DoIdle");
	render(vgapp, tigerscene);
	tigerscene.rotateN = tigerscene.rotateN + (1.0 * tigerscene.rotateFactor);
end

local XIncrement = 5;
local YIncrement = 5;

app.OnKeyUp = function(kbd, keycode)
--print("KEY: ", keycode);

  	-- Halt the loop if they press the "Esc" key
  	if keycode == KEY_ESC then
    		return app:Stop();
  	end

	local x = app.Window.X
	local y = app.Window.Y;

	-- Move the window around the screen
	-- using the keyboard arrow keys
	if keycode == KEY_RIGHT then
		x = app.Window.X + XIncrement;
	end

	if keycode == KEY_LEFT then
		x = app.Window.X - XIncrement;
	end

	if keycode == KEY_HOME then
		x = 0
	end

	if keycode == KEY_END then 
		x = screenWidth - app.Window.Width;
	end

	if keycode == KEY_UP then
		y = y - YIncrement;
	end

	if keycode == KEY_DOWN then
		y = y + YIncrement
	end

	if keycode == KEY_PAGEUP then
		y = 0;
	end

	if keycode == KEY_PAGEDOWN then
		y = screenHeight - app.Window.Height 
	end

	-- Move the window
	app.Window:MoveTo(x,y);

	-- Change direction of rotation when space
	-- bar is pressed
	if keycode == KEY_SPACE then
		tigerscene.rotateFactor = -1 * tigerscene.rotateFactor;
	end
end


app:Run();
