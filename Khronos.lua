package.path = package.path..";EGL/?.lua"


local ffi = require "ffi"

local BCMHost = require "bcm_host"

require "khrplatform"

--print(package.path);

local EGL = require "egl";

--[[
	GLESv2 must be loaded before EGL or there will be 
	an error: 
		/opt/vc/lib/libEGL.so: undefined symbol: glPointSizePointerOES

	this symbol must be located in the GLESv2 library, thus it needs
	to be loaded first.
--]]

local	GLESv2_Lib = ffi.load("GLESv2");
EGL.Lib = ffi.load("EGL");


return {
	-- Libraries
	GLESv2Lib = GLESv2Lib;

	-- Modules
	EGL = EGL;
	BCMHost = BCMHost;
}
