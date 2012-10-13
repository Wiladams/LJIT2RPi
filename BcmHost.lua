
local ffi = require "ffi"

require "bcm_host"


local lib = ffi.load("bcm_host");

--[[
	The bcm_host_init() function must be called
	before any other functions in the library can be
	utilized.  This will be done automatically
	if the developer does:
		require "bcm_host"
--]]

lib.bcm_host_init();





local GetDisplaySize = function(display_number)
	display_number = display_number or 0
	local pWidth = ffi.new("uint32_t[1]");
	local pHeight = ffi.new("uint32_t[1]");
	
	local err = lib.graphics_get_display_size(display_number, pWidth, pHeight);
	
	-- Return immediately if there was an error
	if err ~= 0 then
		return false, err
	end
	
	return pWidth[0], pHeight[0];
end

return {
	Lib = lib,

	GetDisplaySize = GetDisplaySize,
}
