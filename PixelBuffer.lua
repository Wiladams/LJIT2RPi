
local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local DMX = require "DisplayManX"

local ALIGN_UP = function(x,y)  
    return band((x + y-1), bnot(y-1))
end

local PixelBuffer = {}
local PixelBuffer_mt = {
	__index = PixelBuffer
}

PixelBuffer.new = function(width, height, imgtype)
	imgtype = imgtype or ffi.C.VC_IMAGE_RGB565

	local pitch = ALIGN_UP(width*sizeofpixel, 32);
	local aligned_height = ALIGN_UP(height, 16);

	local obj = {
		PixelFormat = imgtype;
		Width = width;
		Height = height;
		Pitch = pitch;
		Data = ffi.new("uint8_t[?]", pitch * height);
	}

	setmetatable(obj, PixelBuffer_mt);

	return obj;
end
