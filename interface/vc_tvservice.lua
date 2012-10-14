
local ffi = require "ffi"

--[[
/*
 * TV service host API,
 * See vc_hdmi for HDMI related constants
 * See vc_sdtv for SDTV related constants
 */
--]]

require "common"
require "vcos"
require "vchi"
require "vc_tvservice_defs"
require "vc_hdmi"
require "vc_sdtv"


ffi.cdef[[

typedef void (*TVSERVICE_CALLBACK_T)(void *callback_data, uint32_t reason, uint32_t param1, uint32_t param2);



int vc_vchi_tv_init(VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections );

void vc_vchi_tv_stop( void );


void vc_tv_register_callback(TVSERVICE_CALLBACK_T callback, void *callback_data);

void vc_tv_unregister_callback(TVSERVICE_CALLBACK_T callback);


int vc_tv_enable_copyprotect(uint32_t cp_mode, uint32_t timeout);

int vc_tv_disable_copyprotect( void );

int vc_tv_show_info(uint32_t show);

int vc_tv_get_state(TV_GET_STATE_RESP_T *tvstate);

int vc_tv_power_off( void );

int vc_tv_test_mode_start(uint32_t colour, TV_TEST_MODE_T test_mode);

int vc_tv_test_mode_stop( void );

const char* vc_tv_notifcation_name(VC_HDMI_NOTIFY_T reason);



// SDTV Specific Routines
int vc_tv_sdtv_power_on(SDTV_MODE_T mode, SDTV_OPTIONS_T *options);



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


int vc_tv_hdmi_mode_supported(HDMI_RES_GROUP_T group,
                                               uint32_t mode);

int vc_tv_hdmi_audio_supported(uint32_t audio_format, uint32_t num_channels,
                                                EDID_AudioSampleRate fs, uint32_t bitrate);

int vc_tv_hdmi_get_av_latency( void );


int vc_tv_hdmi_set_hdcp_key(const uint8_t *key);

int vc_tv_hdmi_set_hdcp_revoked_list(const uint8_t *list, uint32_t num_keys);

int vc_tv_hdmi_set_spd(const char *manufacturer, const char *description, HDMI_SPD_TYPE_CODE_T type);

int vc_tv_hdmi_set_display_options(HDMI_ASPECT_T aspect, uint32_t left_bar_width, uint32_t right_bar_width, uint32_t top_bar_height, uint32_t bottom_bar_height, uint32_t overscan_flags);

int vc_tv_hdmi_ddc_read(uint32_t offset, uint32_t length, uint8_t *buffer);

int vc_tv_hdmi_set_attached(uint32_t attached);

int vc_tv_hdmi_set_property(uint32_t property, uint32_t param1, uint32_t param2);

int vc_tv_hdmi_get_property(uint32_t property, uint32_t *param1, uint32_t *param2);
]]
