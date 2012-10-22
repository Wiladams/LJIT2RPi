
local ffi = require "ffi"

local host = require "BcmHost"

local bcm_host_lib = ffi.load("bcm_host")
local vcos_lib = ffi.load("vcos")
local vchi_lib = ffi.load("vchiq_arm")

require "vc_tvservice"

local TVService = {
	init = function(initialize_instance, connections, num_connections)
		local result = bcm_host_lib.vc_vchi_tv_init(initialise_instance, connections, num_connections );
		return result == 0 or false, result;
	end,

	stop = function()
		bcm_host_lib.vc_vchi_tv_stop( void );
		return true;
	end,

	register_callback = function(callback, callback_data)
		bcm_host_lib.vc_tv_register_callback(callback, callback_data);
		return true;
	end,

	unregister_callback = function(callback)
		bcm_host_lib.vc_tv_unregister_callback(callback);
		return true;
	end,

	enable_copyprotect = function(cp_mode, timeout)
		local result = bcm_host_lib.vc_tv_enable_copyprotect(cp_mode, timeout);
		return result == 0 or false, result;
	end,

	disable_copyprotect = function()
		local result = bcm_host_lib.vc_tv_disable_copyprotect( );
		return result == 0 or false, result;
	end,		

	show_info = function(show)
		local result = bcm_host_lib.vc_tv_show_info(show);
		return result == 0 or false, result;
	end,

	get_state = function(tvstate)
		local result = bcm_host_lib.vc_tv_get_state(tvstate);
		return result == 0 or false, result;
	end,

	power_off = function()
		local result = bcm_host_lib.vc_tv_power_off();
		return result == 0 or false, result;
	end,

	test_mode_start = function(colour, test_mode)			
		local result = bcm_host_lib.vc_tv_test_mode_start(colour, test_mode);
		return result == 0 or false, result;
	end,

	test_mode_stop = function()
		local result = bcm_host_lib.vc_tv_test_mode_stop();
		return result == 0 or false, result;
	end,

	notification_name = function(reason)
		local result = bcm_host_lib.vc_tv_notifcation_name(reason);
		if result ~= nil then 
			return ffi.string(result)
		end

		return false
	end,

	-- SDTV Specific Routines
	sdtv_power_on = function(mode, options)
		local status = bcm_host_lib.vc_tv_sdtv_power_on(mode, options);
		return result == 0 or false, result;
	end,

--[[
// HDMI Specific Routines
int vc_tv_hdmi_power_on_preferred( void );

int vc_tv_hdmi_power_on_preferred_3d( void );

int vc_tv_hdmi_power_on_best(uint32_t width, uint32_t height, uint32_t frame_rate,
                                              HDMI_INTERLACED_T scan_mode, EDID_MODE_MATCH_FLAG_T match_flags);

int vc_tv_hdmi_power_on_best_3d(uint32_t width, uint32_t height, uint32_t frame_rate,
                                              HDMI_INTERLACED_T scan_mode, EDID_MODE_MATCH_FLAG_T match_flags);

int vc_tv_hdmi_power_on_explicit(HDMI_MODE_T mode, HDMI_RES_GROUP_T group, uint32_t code);

int vc_tv_hdmi_get_supported_modes(HDMI_RES_GROUP_T group,
                                              TV_SUPPORTED_MODE_T *supported_modes,
                                              uint32_t max_supported_modes,
                                              HDMI_RES_GROUP_T *preferred_group,
                                              uint32_t *preferred_mode);


int vc_tv_hdmi_mode_supported(HDMI_RES_GROUP_T group, uint32_t mode);

int vc_tv_hdmi_audio_supported(uint32_t audio_format, uint32_t num_channels, EDID_AudioSampleRate fs, uint32_t bitrate);

int vc_tv_hdmi_get_av_latency( void );

int vc_tv_hdmi_set_hdcp_key(const uint8_t *key);

int vc_tv_hdmi_set_hdcp_revoked_list(const uint8_t *list, uint32_t num_keys);

int vc_tv_hdmi_set_spd(const char *manufacturer, const char *description, HDMI_SPD_TYPE_CODE_T type);

int vc_tv_hdmi_set_display_options(HDMI_ASPECT_T aspect, uint32_t left_bar_width, uint32_t right_bar_width, uint32_t top_bar_height, uint32_t bottom_bar_height, uint32_t overscan_flags);

int vc_tv_hdmi_ddc_read(uint32_t offset, uint32_t length, uint8_t *buffer);

int vc_tv_hdmi_set_attached(uint32_t attached);

int vc_tv_hdmi_set_property(uint32_t property, uint32_t param1, uint32_t param2);

int vc_tv_hdmi_get_property(uint32_t property, uint32_t *param1, uint32_t *param2);
--]]
}



local function tvservice_init()
	pvchi_instance = ffi.new("VCHI_INSTANCE_T[1]");
	pvchi_connections = ffi.new("VCHI_CONNECTION_T *[1]");
    
    	-- Assume bcm_host_init() has already been called
	-- bcm_host_init();
    
    	-- initialise vcos/vchi
    	--ffi.C.vcos_init();
    	
	local result = vchi_lib.vchi_initialise(pvchi_instance) 
	if result ~= VCHIQ_SUCCESS then
		return false, result
	end
	vchi_instance = pvchi_instance[0];

	-- create a vchi connection
	result = vchi_lib.vchi_connect( nil, 0, vchi_instance ) 
	if result ~= 0 then
		return false, result;
	end
    
	-- connect to tvservice
	result = vchi_lilb.vc_vchi_tv_init( vchi_instance, pvchi_connections, 1)
	if result ~= 0 then
		return false, result
	end
end


tvservice_init();

return TVService;
