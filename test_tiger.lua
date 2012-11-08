
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


local screenWidth = 640;
local screenHeight = 480;


local app = OpenVGApp.init(screenWidth, screenHeight);


local tigerModel = require "tiger";
local tigerscene = {
	Width = screenWidth;
	Height = screenHeight;
	rotateN = 0.0;
	rotateFactor = 1;
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

app.OnKeyUp = function(kbd, keycode)

  	-- Halt the loop if they press the "Esc" key
  	if keycode == KEY_ESC then
    		return app:Stop();
  	end

	-- Change direction of rotation when space
	-- bar is pressed
	if keycode == KEY_SPACE then
		tigerscene.rotateFactor = -1 * tigerscene.rotateFactor;
	end
end


app:Run();
