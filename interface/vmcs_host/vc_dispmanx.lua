

package.path = package.path.. ";../vcos/?.lua;../vctypes/?.lua;../vmcs_host/?.lua;../vchi/?.lua;"

local ffi = require "ffi"


-- Display manager service API


require "vcos"
require "vc_image_types"
require "vc_dispservice_x_defs"
require "vc_dispmanx_types"
require "vchi"

ffi.cdef[[
// Same function as above, to aid migration of code.
int vc_dispman_init( void );

// Stop the service from being used
void vc_dispmanx_stop( void );

// Set the entries in the rect structure
int vc_dispmanx_rect_set( VC_RECT_T *rect, uint32_t x_offset, uint32_t y_offset, uint32_t width, uint32_t height );

// Resources
// Create a new resource
DISPMANX_RESOURCE_HANDLE_T vc_dispmanx_resource_create( VC_IMAGE_TYPE_T type, uint32_t width, uint32_t height, uint32_t *native_image_handle );

// Write the bitmap data to VideoCore memory
int vc_dispmanx_resource_write_data( DISPMANX_RESOURCE_HANDLE_T res, VC_IMAGE_TYPE_T src_type, int src_pitch, void * src_address, const VC_RECT_T * rect );
int vc_dispmanx_resource_write_data_handle( DISPMANX_RESOURCE_HANDLE_T res, VC_IMAGE_TYPE_T src_type, int src_pitch, VCHI_MEM_HANDLE_T handle, uint32_t offset, const VC_RECT_T * rect );
int vc_dispmanx_resource_read_data(DISPMANX_RESOURCE_HANDLE_T handle,
                              const VC_RECT_T* p_rect,
                              void *   dst_address,
                              uint32_t dst_pitch );
// Delete a resource
int vc_dispmanx_resource_delete( DISPMANX_RESOURCE_HANDLE_T res );

// Displays
// Opens a display on the given device
DISPMANX_DISPLAY_HANDLE_T vc_dispmanx_display_open( uint32_t device );

// Opens a display on the given device in the request mode
DISPMANX_DISPLAY_HANDLE_T vc_dispmanx_display_open_mode( uint32_t device, uint32_t mode );

// Open an offscreen display
DISPMANX_DISPLAY_HANDLE_T vc_dispmanx_display_open_offscreen( DISPMANX_RESOURCE_HANDLE_T dest, VC_IMAGE_TRANSFORM_T orientation );

// Change the mode of a display
int vc_dispmanx_display_reconfigure( DISPMANX_DISPLAY_HANDLE_T display, uint32_t mode );

// Sets the desstination of the display to be the given resource
int vc_dispmanx_display_set_destination( DISPMANX_DISPLAY_HANDLE_T display, DISPMANX_RESOURCE_HANDLE_T dest );

// Set the background colour of the display
int vc_dispmanx_display_set_background( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_DISPLAY_HANDLE_T display,
                                                                       uint8_t red, uint8_t green, uint8_t blue );
// get the width, height, frame rate and aspect ratio of the display
int vc_dispmanx_display_get_info( DISPMANX_DISPLAY_HANDLE_T display, DISPMANX_MODEINFO_T * pinfo );

// Closes a display
int vc_dispmanx_display_close( DISPMANX_DISPLAY_HANDLE_T display );

// Updates
// Start a new update, DISPMANX_NO_HANDLE on error
DISPMANX_UPDATE_HANDLE_T vc_dispmanx_update_start( int32_t priority );

// Add an elment to a display as part of an update
DISPMANX_ELEMENT_HANDLE_T vc_dispmanx_element_add ( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_DISPLAY_HANDLE_T display,
                                                                     int32_t layer, const VC_RECT_T *dest_rect, DISPMANX_RESOURCE_HANDLE_T src,
                                                                     const VC_RECT_T *src_rect, DISPMANX_PROTECTION_T protection, 
                                                                     VC_DISPMANX_ALPHA_T *alpha,
                                                                     DISPMANX_CLAMP_T *clamp, DISPMANX_TRANSFORM_T transform );
// Change the source image of a display element
int vc_dispmanx_element_change_source( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_ELEMENT_HANDLE_T element,
                                                        DISPMANX_RESOURCE_HANDLE_T src );
// Change the layer number of a display element
int vc_dispmanx_element_change_layer ( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_ELEMENT_HANDLE_T element,
                                                        int32_t layer );
// Signal that a region of the bitmap has been modified
int vc_dispmanx_element_modified( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_ELEMENT_HANDLE_T element, const VC_RECT_T * rect );

// Remove a display element from its display
int vc_dispmanx_element_remove( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_ELEMENT_HANDLE_T element );

// Ends an update
int vc_dispmanx_update_submit( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_CALLBACK_FUNC_T cb_func, void *cb_arg );

// End an update and wait for it to complete
int vc_dispmanx_update_submit_sync( DISPMANX_UPDATE_HANDLE_T update );

// Query the image formats supported in the VMCS build
int vc_dispmanx_query_image_formats( uint32_t *supported_formats );

//New function added to VCHI to change attributes, set_opacity does not work there.
int vc_dispmanx_element_change_attributes( DISPMANX_UPDATE_HANDLE_T update, 
                                                            DISPMANX_ELEMENT_HANDLE_T element,
                                                            uint32_t change_flags,
                                                            int32_t layer,
                                                            uint8_t opacity,
                                                            const VC_RECT_T *dest_rect,
                                                            const VC_RECT_T *src_rect,
                                                            DISPMANX_RESOURCE_HANDLE_T mask,
                                                            VC_IMAGE_TRANSFORM_T transform );

//xxx hack to get the image pointer from a resource handle, will be obsolete real soon
uint32_t vc_dispmanx_resource_get_image_handle( DISPMANX_RESOURCE_HANDLE_T res);

//Call this instead of vc_dispman_init
void vc_vchi_dispmanx_init (VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections );

// Take a snapshot of a display in its current state.
// This call may block for a time; when it completes, the snapshot is ready.
int vc_dispmanx_snapshot( DISPMANX_DISPLAY_HANDLE_T display, 
                                           DISPMANX_RESOURCE_HANDLE_T snapshot_resource, 
                                           VC_IMAGE_TRANSFORM_T transform );
]]

