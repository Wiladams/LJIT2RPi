
local ffi = require "ffi"

--[[
/*
 * TV service command enumeration and parameter types.
 */
--]]

require "common"
require "message"
require "vc_hdmi"

TVSERVICE_MSGFIFO_SIZE = 1024
TVSERVICE_CLIENT_NAME = MAKE_FOURCC("TVSV")
TVSERVICE_NOTIFY_NAME = MAKE_FOURCC("TVNT")

TVSERVICE_MAX_CALLBACKS = 2

ffi.cdef[[
//TV service commands
typedef enum {
   VC_TV_GET_STATE = 0,
   VC_TV_HDMI_ON_PREFERRED,
   VC_TV_HDMI_ON_BEST,
   VC_TV_HDMI_ON_EXPLICIT,
   VC_TV_SDTV_ON,
   VC_TV_OFF,
   VC_TV_QUERY_SUPPORTED_MODES,
   VC_TV_QUERY_MODE_SUPPORT,
   VC_TV_QUERY_AUDIO_SUPPORT,
   VC_TV_ENABLE_COPY_PROTECT,
   VC_TV_DISABLE_COPY_PROTECT,
   VC_TV_SHOW_INFO,
   VC_TV_GET_AV_LATENCY,
   VC_TV_HDCP_SET_KEY,
   VC_TV_HDCP_SET_SRM,
   VC_TV_SET_SPD,
   VC_TV_SET_DISPLAY_OPTIONS,
   VC_TV_TEST_MODE_START,
   VC_TV_TEST_MODE_STOP,
   VC_TV_DDC_READ,
   VC_TV_SET_ATTACHED,
   VC_TV_SET_PROP,
   VC_TV_GET_PROP,
   //Add more commands here
   VC_TV_END_OF_LIST
} VC_TV_CMD_CODE_T;
]]

ffi.cdef[[
//If you change this, remember to change the padding in TV_QUERY_SUPPORTED_MODES parameter
static const int TV_MAX_SUPPORTED_MODES = 60;

//Parameters for each command (padded to multiple of 16 bytes)
//See vc_hdmi.h and vc_sdtv.h for details

//GET_STATE
//Parameters: none
//Reply: state (flags of VC_HDMI_NOTIFY_T and VC_SDTV_NOTIFY_T)
//       current width
//       current height
//       current refresh rate
//       current scan mode
typedef struct {
   uint32_t state;     /**<TV state is a union of bitmask of VC_HDMI_NOTIFY_T and VC_SDTV_NOTIFY_T */
   uint32_t width;     /**<Current display width if TV is on */
   uint32_t height;    /**<Current display height if TV is on */
   uint16_t frame_rate;/**<Current refresh rate is TV is on */
   uint16_t scan_mode; /**<Current scanmode 0 for progressive, 1 for interlaced */
} TV_GET_STATE_RESP_T;


//Generic single returned interpreted based on the command
typedef struct {
   int32_t ret; //Single return value
} TV_GENERAL_RESP_T;

//HDMI_ON_PREFERRED
//Parameters: 3d mode (on/off)
//Reply: single return value interpreted as HDMI_RESULT_T or SDTV equivalent (all single reply value will be of this form)
typedef struct {
   uint32_t in_3d;
} TV_HDMI_ON_PREFERRED_PARAM_T;

//HDMI_ON_BEST
//Parameters: width, height, frame rate, scan mode, matching flag (EDID_MODE_MATCH_FLAG_T), 3d mode (on/off)
//Reply: single return value interpreted as HDMI_RESULT_T or SDTV equivalent
typedef struct {
   uint32_t width;
   uint32_t height;
   uint32_t frame_rate;
   uint32_t scan_mode;
   uint32_t match_flags;
   uint32_t in_3d;
} TV_HDMI_ON_BEST_PARAM_T;

//HDMI_ON_EXPLICIT
//Parameters: hdmi_mode, standard, mode
//Reply: same as above
typedef struct {
   uint32_t hdmi_mode; //DVI or HDMI
   uint32_t group;
   uint32_t mode;
} TV_HDMI_ON_EXPLICIT_PARAM_T;

//SDTV_ON
//Parameters: SDTV mode, aspect ratio
//Reply: Same as above
typedef struct {
   uint32_t mode;
   uint32_t aspect;
} TV_SDTV_ON_PARAM_T;

//TV_OFF
//Parameters: none
//Reply: none

//TV_QUERY_SUPPORTED_MODES
//Parameters: standard (CEA/DMT)
//Reply: how many modes there are and the array of supported modes, and the preferred modes
//       (sent back via bulk transfer)
typedef struct {
   uint32_t group;
} TV_QUERY_SUPPORTED_MODES_PARAM_T;

typedef struct {
   uint16_t scan_mode : 1; /**<1 is interlaced, 0 for progressive */
   uint16_t native    : 1; /**<1 means native mode, 0 otherwise */
   uint16_t code      : 7; /**<mode code */
   uint16_t frame_rate;    /**<frame rate */
   uint16_t width;         /**<frame width */
   uint16_t height;        /**<frame height */
} TV_SUPPORTED_MODE_T;

typedef struct {
   TV_SUPPORTED_MODE_T supported_modes[TV_MAX_SUPPORTED_MODES];
   uint32_t num_supported_modes;
   uint32_t preferred_group;
   uint32_t preferred_mode;
} TV_QUERY_SUPPORTED_MODES_RESP_T;

//TV_QUERY_MODE_SUPPORT
//Parameters: stardard, mode
//Reply: yes/no
//but the return value meaning is reversed (zero is unsupported, non-zero is supported)
typedef struct {
   uint32_t group;
   uint32_t mode;
} TV_QUERY_MODE_SUPPORT_PARAM_T;

//TV_QUERY_AUDIO_SUPPORT
//Parameters: audio format, no. of channels, sampling frequency, bitrate/sample size
//Reply: single value interpreted as flags EDID_AUDIO_SUPPORT_FLAG_T
typedef struct {
   uint32_t audio_format; //EDID_AudioFormat (if format is eExtended, add EDID_AudioCodingExtension to the audio format)
   uint32_t num_channels; // 1-8
   uint32_t fs;           // EDID_AudioSampleRate
   uint32_t bitrate;      // EDID_AudioSampleSize if format == PCM, bitrate otherwise
} TV_QUERY_AUDIO_SUPPORT_PARAM_T;

//TV_ENABLE_COPY_PROTECT
//Parameters: copy protect mode (for HDMI it will always be HDCP), timeout
//Reply: single return value - cp result arrive via callback
typedef struct {
   uint32_t cp_mode;
   uint32_t timeout;
} TV_ENABLE_COPY_PROTECT_PARAM_T;

//TV_DISABLE_COPY_PROTECT
//Parameters: none
//Reply: single value return - results arrive via callback

//TV_SHOW_INFO
//Parameters: visible
//Reply: none
typedef struct {
   uint32_t visible; //0 to hide the screen
} TV_SHOW_INFO_PARAM_T;

//TV_GET_AV_LATENCY
//Parameters: none
//Reply: single value interpreted as latency in ms


//TV_HDCP_SET_KEY
//Parameters: key block buffer (fixed size HDCP_KEY_BLOCK_SIZE)
//Reply: none, key validity result arrives via callback
typedef struct {
   uint8_t key[HDCP_KEY_BLOCK_SIZE];
} TV_HDCP_SET_KEY_PARAM_T;

//TV_HDCP_SET_SRM
//Parameters: num of keys, pointer to revocation list (transferred as buffer)
//Reply: none, callback indicates no. of keys set
typedef struct {
   uint32_t num_keys;
} TV_HDCP_SET_SRM_PARAM_T;

//TV_SET_SPD
//Parameters: name [8], description [16], type
//Reply: none
static const int TV_SPD_NAME_LEN = 8;
static const int TV_SPD_DESC_LEN = 16;

typedef struct {
   char manufacturer[TV_SPD_NAME_LEN];
   char description[TV_SPD_DESC_LEN];
   uint32_t type;
} TV_SET_SPD_PARAM_T;

//TV_SET_DISPLAY_OPTIONS
//Parameters: aspect ratio (HDMI_ASPECT_T), vert bar present (bool),
//            left bar width, right bar width, horiz bar present (bool)
//            top bar height, bottom bar height
//Reply: none
typedef struct {
   uint32_t aspect;
   uint32_t vertical_bar_present;
   uint32_t left_bar_width;
   uint32_t right_bar_width;
   uint32_t horizontal_bar_present;
   uint32_t top_bar_height;
   uint32_t bottom_bar_height;
   uint32_t overscan_flags;
} TV_SET_DISPLAY_OPTIONS_PARAM_T;

//TV_TEST_MODE_START
//Parameters: rgb colour, test mode
//Reply: none

//Actual enums used for test mode
typedef enum {
   TV_TEST_MODE_DISABLED        = 0, //Test mode disabled
   TV_TEST_MODE_SOLID_BACKGND   = 1, //Solid background colur
   TV_TEST_MODE_SOLID_VERTICAL  = 2, //Vertical bars
   TV_TEST_MODE_SHADED_VERTICAL = 3, //Shaded vertical bars
   TV_TEST_MODE_SHADED_WHITE_V  = 4, //White vertical bars
   TV_TEST_MODE_SHADED_WHITE_H  = 5, //White horizontal bars
   TV_TEST_MODE_SHADED_RGB      = 6, //Shaded RGB + white bars
   TV_TEST_MODE_WALKING         = 7, //Walking one across 24-bit RGB
   TV_TEST_MODE_DELAYED         = 8, //Delayed shaded RGB bars
   TV_TEST_MODE_HVD             = 9, //Horizontal G, Vert. B, Diag. R bars
   TV_TEST_MODE_ODD_CH          =10, //Odd field crosshairs
   TV_TEST_MODE_EVEN_CH         =11, //Even field crosshairs
   TV_TEST_MODE_32x32           =12, //32x32 white grid
   TV_TEST_MODE_WYCGMRBK_SOLID  =13, //Solid blah blah
   TV_TEST_MODE_WYCGMRBK_SHADED =14, //Shaded blah blah
   TV_TEST_MODE_32x32_DIAGONAL  =15  //32x32 white diagonal grid
} TV_TEST_MODE_T;

typedef struct {
   uint32_t colour; //RGB colour
   uint32_t test_mode; //one of the TV_TEST_MODE_T enums above
} TV_TEST_MODE_START_PARAM_T;

//TV_TEST_MODE_STOP
//Parameters: none
//Reply: none

//TV_DDC_READ
//Parameters: offset, length
//Reply: length of data actually read (so zero means error),
//and fills in the passed in buffer if no error
typedef struct {
   uint32_t offset;
   uint32_t length;
} TV_DDC_READ_PARAM_T;

//TV_SET_ATTACHED
//Parameters: uint32_t attached or not (0 = hotplug low, 1 = hotplug high)

//TV_SET_PROP
//Parameters: parameter type, param1, param2
//Reply: 0 = set successful, non-zero if error (int32_t) 
typedef struct {
   uint32_t prop; /**<HDMI_PROPERTY_T */
   uint32_t param1; /**<param 1 */
   uint32_t param2; /**<param 2 */
} TV_SET_PROP_PARAM_T;

//TV_GET_PROP
//Parameters: parameter type (uint32_t)
//Reply param1/param2 of the passed in property and return code
typedef struct {
   int32_t  ret; /**<Return code */
   uint32_t prop; /**<HDMI_PROPERTY_T */
   uint32_t param1; /**<param 1 */
   uint32_t param2; /**<param 2 */
} TV_GET_PROP_PARAM_T;
]]

--[[
/*
Copyright (c) 2012, Broadcom Europe Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
--]]
