
-- Common image types used by the vc_image library.
local ffi = require "ffi"

ffi.cdef[[
//enums of display input format
typedef enum
{
   VCOS_DISPLAY_INPUT_FORMAT_INVALID = 0,
   VCOS_DISPLAY_INPUT_FORMAT_RGB888,
   VCOS_DISPLAY_INPUT_FORMAT_RGB565
} VCOS_DISPLAY_INPUT_FORMAT_T;


typedef VCOS_DISPLAY_INPUT_FORMAT_T DISPLAY_INPUT_FORMAT_T;

// Enum determining how image data for 3D displays has to be supplied
typedef enum
{
   DISPLAY_3D_UNSUPPORTED = 0,   // default
   DISPLAY_3D_INTERLEAVED,       // For autosteroscopic displays
   DISPLAY_3D_SBS_FULL_AUTO,     // Side-By-Side, Full Width (also used by some autostereoscopic displays)
   DISPLAY_3D_SBS_HALF_HORIZ,    // Side-By-Side, Half Width, Horizontal Subsampling (see HDMI spec)
   DISPLAY_3D_FORMAT_MAX
} DISPLAY_3D_FORMAT_T;

//enums of display types
typedef enum
{
   DISPLAY_INTERFACE_MIN,
   DISPLAY_INTERFACE_SMI,
   DISPLAY_INTERFACE_DPI,
   DISPLAY_INTERFACE_DSI,
   DISPLAY_INTERFACE_LVDS,
   DISPLAY_INTERFACE_MAX

} DISPLAY_INTERFACE_T;

/* display dither setting, used on B0 */
typedef enum {
   DISPLAY_DITHER_NONE   = 0,   /* default if not set */
   DISPLAY_DITHER_RGB666 = 1,
   DISPLAY_DITHER_RGB565 = 2,
   DISPLAY_DITHER_RGB555 = 3,
   DISPLAY_DITHER_MAX
} DISPLAY_DITHER_T;

//info struct
typedef struct
{
   //type
   DISPLAY_INTERFACE_T type;
   //width / height
   uint32_t width;
   uint32_t height;
   //output format
   DISPLAY_INPUT_FORMAT_T input_format;
   //interlaced?
   uint32_t interlaced;
   /* output dither setting (if required) */
   DISPLAY_DITHER_T output_dither;
   /* Pixel frequency */
   uint32_t pixel_freq;
   /* Line rate in lines per second */
   uint32_t line_rate;
   // Format required for image data for 3D displays
   DISPLAY_3D_FORMAT_T format_3d;
} DISPLAY_INFO_T;

]]
