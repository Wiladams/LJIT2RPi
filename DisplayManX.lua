
local ffi = require "ffi"

-- Display manager service API
local host = require "BcmHost"
local Native = host.Lib

-- Initialize module
Native.vc_dispman_init();
-- Call this instead of vc_dispman_init
--Native.vc_vchi_dispmanx_init (VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections );

DisplayManX = {
	rect_set = function(rect, x_offset, y_offset, width, height )
		local result = Native.vc_dispmanx_rect_set( rect, x_offset, y_offset, width, height );
		if result == 0 then 
			return true
		end
	
		return false, result
	end,
	
	resource_create = function(imgtype, width, height, native_image_handle)
		local nativehandle = ffi.new("int32_t[1]", nativeimage_handle);
		local handle = Native.vc_dispmanx_resource_create( imagetype, width, height, nativehandle );
		
		return handle
	end,

	-- Write the bitmap data to VideoCore memory
	resource_write_data = function(res, src_type, src_pitch, src_address, rect)
		local result = Native.vc_dispmanx_resource_write_data(res, src_type, src_pitch, src_address, rect );
	
		if result == 0 then
			return true
		end
		
		return false, result
	end,
	
	resource_write_data_handle = function(res, src_type, src_pitch,handle, offset, rect )
		local result = Native.vc_dispmanx_resource_write_data_handle( res, src_type, src_pitch, handle, offset, rect );
	
		if result == 0 then
			return true
		end
		
		return false, result;
	end,
	
	resource_read_data = function(handle, p_rect,dst_address,dst_pitch)
		local result = Native.vc_dispmanx_resource_read_data(handle, p_rect,dst_address,dst_pitch );
		if result == 0 then 
			return true
		end
		
		return false, result;
	end,
	
	-- Delete a resource
	resource_delete = function(res)
		local result = Native.vc_dispmanx_resource_delete( res );
		if result == 0 then
			return true;
		end
		
		return false, result;
	end,

	-- Displays
	-- Opens a display on the given device
	display_open = function(device)
		local handle =  Native.vc_dispmanx_display_open( device );
		return handle;
	end,

	-- Opens a display on the given device in the request mode
	display_open_mode = function(device, mode)
		local handle = Native.vc_dispmanx_display_open_mode( device, mode );
		return handle;
	end,

	-- Open an offscreen display
	display_open_offscreen = function(dest, orientation)
		local handle = Native.vc_dispmanx_display_open_offscreen( dest, orientation );
		return handle;
	end,
	
}


--[=[
ffi.cdef[[

// Stop the service from being used
void vc_dispmanx_stop( void );





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


// Take a snapshot of a display in its current state.
// This call may block for a time; when it completes, the snapshot is ready.
int vc_dispmanx_snapshot( DISPMANX_DISPLAY_HANDLE_T display, 
                                           DISPMANX_RESOURCE_HANDLE_T snapshot_resource, 
                                           VC_IMAGE_TRANSFORM_T transform );
]]
--]=]
