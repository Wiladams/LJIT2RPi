package.path = package.path..";interface/vctypes/?.lua;interface/vchi/?.lua;interface/vcos/?.lua;interface/vcos/pthreads/?.lua;interface/vmcs_host/?.lua"

local ffi = require "ffi"

ffi.cdef [[
void bcm_host_init(void);
void bcm_host_deinit(void);

int32_t graphics_get_display_size( const uint16_t display_number, uint32_t *width, uint32_t *height);
]]

<<<<<<< HEAD
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

=======
>>>>>>> Level 2 simplifaction API

require "vc_dispmanx"

--[[

require "interface/vmcs_host/vc_tvservice"
require "interface/vmcs_host/vc_cec"
require "interface/vmcs_host/vc_cecservice"
require "interface/vmcs_host/vcgencmd"
--]]



