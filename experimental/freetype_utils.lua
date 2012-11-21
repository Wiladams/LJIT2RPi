local ffi = require "ffi"

local lib = ffi.load("libfreetype.so.6")
require "freetype"

return {
	Native = lib,
}
