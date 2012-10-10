
local ffi = require "ffi"

-- Display manager service API
local host = require "BcmHost"
local Native = host.Lib

-- Initialize module
--Native.vc_dispman_init();

-- Call this instead of vc_dispman_init
--Native.vc_vchi_dispmanx_init (VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections );

DisplayManX = {
	rect_set = function(rect, x_offset, y_offset, width, height )
		local result = Native.vc_dispmanx_rect_set( rect, x_offset, y_offset, width, height );
		return result == 0 or false, result;
	end,
	
	-- Miscellany
	-- Take a snapshot of a display in its current state.
	-- This call may block for a time; when it completes, the snapshot is ready.
	snapshot = function(display, snapshot_resource, transform)
		local result = Native.vc_dispmanx_snapshot( display, snapshot_resource, transform );
		return result == 0 or false, result
	end,

	-- Query the image formats supported in the VMCS build
	query_image_formats = function()
		local supported_formats = ffi.new("uint32_t[256]");
		local result = Native.vc_dispmanx_query_image_formats( supported_formats );
		return result, psupported
	end,

	resource_create = function(imgtype, width, height)
		local phandle = ffi.new("uint32_t[1]");
		local resource = Native.vc_dispmanx_resource_create( imgtype, width, height, phandle );
		
		if resource >0  then
			return resource, phandle[0]
		end

		return false, resource
	end,

	-- Write the bitmap data to VideoCore memory
	resource_write_data = function(res, src_type, src_pitch, src_address, rect)
		local result = Native.vc_dispmanx_resource_write_data(res, src_type, src_pitch, src_address, rect );
	
		return result == 0 or false, result;
	end,
	
	resource_write_data_handle = function(res, src_type, src_pitch,handle, offset, rect )
		local result = Native.vc_dispmanx_resource_write_data_handle( res, src_type, src_pitch, handle, offset, rect );
	
		return result == 0 or false, result;
	end,
	
	resource_read_data = function(handle, p_rect,dst_address,dst_pitch)
		local result = Native.vc_dispmanx_resource_read_data(handle, p_rect,dst_address,dst_pitch );
		
		return result == 0 or false, result;
	end,
	
	-- Delete a resource
	resource_delete = function(res)
		local result = Native.vc_dispmanx_resource_delete( res );
		
		return result == 0 or false, result;
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


	-- Change the mode of a display
	reconfigure = function(display, mode)	
		local result = Native.vc_dispmanx_display_reconfigure( display, mode );
		return result == 0 or false, result
	end,

	-- Sets the desstination of the display to be the given resource
	set_destination = function(display, dest)
		local result = Native.vc_dispmanx_display_set_destination( display, dest );
		return result == 0 or false, result
	end,

	-- Set the background colour of the display
	set_background = function(update, display, red, green, blue)
		local result = Native.vc_dispmanx_display_set_background( update, display, red, green, blue );
		return result == 0 or false, result
	end,

	-- get the width, height, frame rate and aspect ratio of the display
	get_info = function(display)
		pinfo = ffi.new("DISPMANX_MODEINFO_T");
		local result = Native.vc_dispmanx_display_get_info( display, pinfo );
		if result ~= 0 then
			return false, result
		end

		return pinfo
	end,

	-- Closes a display
	display_close = function(display)
		local result = Native.vc_dispmanx_display_close( display );
		return result == 0 or false, result
	end,

	-- Updates
	-- Start a new update, DISPMANX_NO_HANDLE on error
	update_start = function(priority)	
		local result = Native.vc_dispmanx_update_start( priority );
		if result == DISPMANX_NO_HANDLE then
			return false, result
		end
		return result
	end,

	-- Ends an update
	update_submit = function(update, cb_func, cb_arg)
		local result = Native.vc_dispmanx_update_submit( update, cb_func, cb_arg );
		return result ==0 or false, result
	end,

	-- End an update and wait for it to complete
	update_submit_sync = function(update)
		local result = Native.vc_dispmanx_update_submit_sync(update);
		return result == 0 or false, result
	end,

	
	-- Element Management
	-- Add an element to a display as part of an update
	element_add = function(update, display,layer, dest_rect, src, src_rect, protection, alpha, clamp, transform)

		local handle = Native.vc_dispmanx_element_add ( update, display, layer, dest_rect, src,src_rect, protection, alpha, clamp, transform );

		return handle
	end,

	-- Change the source image of a display element
	element_change_source = function(update, element, src)
		local result = Native.vc_dispmanx_element_change_source( update, element,src );
		return result == 0 or false, result
	end,

	-- Change the layer number of a display element
	element_change_layer = function(update, element, layer)
		local result = Native.vc_dispmanx_element_change_layer ( update, element, layer );
		return result == 0 or false, result
	end,

	-- Signal that a region of the bitmap has been modified
	element_modified = function(update, element, rect)
		local result = Native.vc_dispmanx_element_modified( update, element, rect );
		return result == 0 or false, result
	end,

	-- Remove a display element from its display
	element_remove = function(update, element)
		local result = Native.vc_dispmanx_element_remove(update, element);
		return result == 0 or false, result
	end,

	-- New function added to VCHI to change attributes, set_opacity does not work there.
	element_change_attributes = function(update,element,change_flags,layer,opacity,dest_rect,src_rect,mask,transform)
		local result = Native.vc_dispmanx_element_change_attributes( update, 
                                                            element,
                                                            change_flags,
                                                            layer,
                                                            opacity,
                                                            dest_rect,
                                                            src_rect,
                                                            mask,
                                                            transform );
		return result == 0 or false, result
	end,
}


return DisplayManX

--[=[
ffi.cdef[[

// Stop the service from being used
void vc_dispmanx_stop( void );


//xxx hack to get the image pointer from a resource handle, will be obsolete real soon
uint32_t vc_dispmanx_resource_get_image_handle( DISPMANX_RESOURCE_HANDLE_T res);


]]
--]=]
