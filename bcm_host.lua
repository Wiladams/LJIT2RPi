
local ffi = require "ffi"

ffi.cdef [[
void bcm_host_init(void);
void bcm_host_deinit(void);

int32_t graphics_get_display_size( const uint16_t display_number, uint32_t *width, uint32_t *height);
]]

require "libc"

require "vc_dispmanx"
require "vc_tvservice"
require "vcgencmd"

--[[

require "interface/vmcs_host/vc_cec"
require "interface/vmcs_host/vc_cecservice"
--]]



return {
	
}
