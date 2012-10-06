local ffi = require "ffi"

ffi.cdef [[
void bcm_host_init(void);
void bcm_host_deinit(void);

int32_t graphics_get_display_size( const uint16_t display_number, uint32_t *width, uint32_t *height);
]]

ffi.C.bcm_host_init();

--[[
require "interface/vmcs_host/vc_dispmanx"
require "interface/vmcs_host/vc_tvservice"
require "interface/vmcs_host/vc_cec"
require "interface/vmcs_host/vc_cecservice"
require "interface/vmcs_host/vcgencmd"
--]]
