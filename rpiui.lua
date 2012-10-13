package.path = package.path..";khronos/?.lua"


local ffi = require "ffi"

local BCMHost = require "BcmHost"

require "khrplatform"



--[[
	GLESv2 must be loaded before EGL or there will be 
	an error: 
		/opt/vc/lib/libEGL.so: undefined symbol: glPointSizePointerOES

	this symbol is located in the libGLESv2.so library, thus it needs
	to be loaded first.
--]]
local GLESv1 = require "GLESMan"
local GLESv2 = require "GLES2Man";

local EGL = require "egl_utils";


local OpenVG = require "OpenVG_Utils";

--local mmal_Lib = ffi.load("mmal");
--local openmaxil_Lib = ffi.load("openmaxil");
--local vchiq_arm_Lib = ffi.load("vchiq_arm");
--local WFC_Lib = ffi.load("WFC");


return {
	-- Modules
	BCMHost = BCMHost;

	GLES = GLESv1;
	GLES2 = GLESv2;

	EGL = EGL;
	OpenVG = OpenVG;
}
