local ffi = require "ffi"

local OMXVideo = require "OMX_Video"
--require "OMX_Audio"
local OMXOther = require "OMX_Other"


OMX = {}
OMX_mt = {
	__index = OMX,
}
