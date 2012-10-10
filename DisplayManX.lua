
local ffi = require "ffi"

-- Display manager service API
local host = require "BcmHost"
local Native = host.Lib

-- Initialize module
--Native.vc_dispman_init();

-- Call this instead of vc_dispman_init
--Native.vc_vchi_dispmanx_init (VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections );


--[=[
ffi.cdef[[

// Stop the service from being used
void vc_dispmanx_stop( void );


//xxx hack to get the image pointer from a resource handle, will be obsolete real soon
uint32_t vc_dispmanx_resource_get_image_handle( DISPMANX_RESOURCE_HANDLE_T res);


]]
--]=]

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
		local pformats = ffi.new("uint32_t [256]");
		local result = Native.vc_dispmanx_query_image_formats( pformats );
		if result == 0 then
			return pformats
		end

		return false, result
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
		device = device or DISPMANX_ID_MAIN_LCD
		local handle =  Native.vc_dispmanx_display_open( device );
		if handle == DISPMANX_NO_HANDLE then
			return false
		end

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


-- Class for updates
ffi.cdef[[
struct DMXUpdate {
	DISPMANX_UPDATE_HANDLE_T	Handle;
};

struct DMXDisplay {
	DISPMANX_DISPLAY_HANDLE_T	Handle;
};

struct DMXElement {
	DISPMANX_ELEMENT_HANDLE_T	Handle;
	DISPMANX_DISPLAY_HANDLE_T	DisplayHandle;
	int32_t				Layer;
	VC_RECT_T *			DestinationRect;
	DISPMANX_RESOURCE_HANDLE_T	ResourceHandle;
	VC_RECT_T *			SourceRect;
	DISPMANX_PROTECTION_T		Protection;
	VC_DISPMANX_ALPHA_T *		Alpha;
	DISPMANX_CLAMP_T *		Clamp;
	DISPMANX_TRANSFORM_T		Transform;
};

struct DMXResource {
	DISPMANX_RESOURCE_HANDLE_T	Handle;
	uint32_t			ImagePtr;
};		
]]


--[[
	The Display is the hook into the graphics
	system.  There may be a couple of displays
	connected to the device (composite, HDMI).

	There are a very few functions that operate
	on the display directly, such as setting the 
	background, and getting information.

	Perhaps the most important function is 
	AddElement, as this is how you get to display
	some graphics.
--]]
DMXDisplay = ffi.typeof("struct DMXDisplay");
DMXDisplay_mt = {
	__gc = function(self)
		print("GC: DMXDisplay");
		DisplayManX.display_close(self.Handle);
	end,

	__new = function(ct, screen)
		local handle, err = DisplayManX.display_open(screen);
		if not handle then
			return false, err
		end

		local obj = ffi.new(ct, handle)
		return obj;
	end,

	__index = {
		AddElement = function(self, element)
			local update,err = DMXUpdate(10);

			if not update then
				return false, err
			end

			local elementHandle, err = DisplayManX.element_add(update.Handle,
				self.Handle,
				element.Layer,
				element.DestinationRect,
				element.ResourceHandle,
				element.SourceRect,
				element.Protection,
				element.Alpha,
				element.Clamp,
				element.Transform);

			if not elementHandle then
				return false, err
			end
			
			element.Handle = elementHandle;

			return update:SubmitSync();
		end,

		GetInfo = function(self)
			return DisplayManX.get_info(self.Handle);
		end,

		SetBackground = function(self, red, green, blue)
			local update, err = DMXUpdate(10);
			if not update then
				return nil, err
			end

			DisplayManX.set_background(update.Handle, self.Handle, red, green, blue)
			return update:SubmitSync();
		end,
	},
}
ffi.metatype(DMXDisplay, DMXDisplay_mt);


--[[
	The essential display element.
	Elements are regions of the display where drawing
	occurs.  They might be thought of as the building
	blocks for a "Window".
--]]
DMXElement = ffi.typeof("struct DMXElement");
DMXElement_mt = {
	__gc = function(self)
		print("GC: DMXElement");
		if self.Handle == DISPMANX_NO_HANDLE then
			return true
		end

		local update = DMXUpdate(10);
		DisplayManX.element_remove(updata.Handle, self.Handle);
		return update:SubmitSync();
	end,

	__new = function(ct, Layer, DestinationRect, ResourceHandle, SourceRect, Protection, Alpha, Clamp, Transform)
		local ElementHandle = DISPMANX_NO_HANDLE;
		local DisplayHandle = DISPMANX_NO_HANDLE;
		Layer = Layer or 2000;
		Protection = Protection or DISPMANX_PROTECTION_NONE;
		Transform = Transform or ffi.C.VC_IMAGE_ROT0;

		-- Create the data structure
		local obj = ffi.new("struct DMXElement", ElementHandle, DisplayHandle, Layer, DestinationRect, ResourceHandle, SourceRect, Protection, Alpha, Clamp, Transform);
		
		return obj;
	end,

	__index = {
	},
}
ffi.metatype(DMXElement, DMXElement_mt);



DMXResource = ffi.typeof("struct DMXResource");
DMXResource_mt = {
	__gc = function(self)
		print("GC: DMXResource");
		DisplayManX.resource_delete(self.Handle);
	end,

	__new = function(ct, imgtype, width, height)
		local handle, imgptr = DisplayManX.resource_create(imgtype, width, height);
		if not handle then
			return nil, imgptr
		end

		local obj = ffi.new(ct, handle, imgptr);
		return obj;
	end,

	__index = {
		WriteData = function(self, imgtype, pitch, image, dst_rect)
			return DisplayManX.resource_write_data(self.Handle, imgtype, pitch, image, dst_rect);
		end,
	},
}
ffi.metatype(DMXResource, DMXResource_mt);


DMXUpdate = ffi.typeof("struct DMXUpdate");
DMXUpdate_mt = {
	__gc = function(self)

	end,

	__new = function(ct, priority)
		priority = priority or 10
		local handle, err = DisplayManX.update_start(priority);
		if not handle then 
			return nil, err
		end

		local obj = ffi.new(ct, handle);
		return obj;
	end,

	__index = {
		Submit = function(self, cb_func, cb_arg)
			return DisplayManX.update_submit(self.Handle, cb_func, cb_arg); 
		end,

		SubmitSync = function(self)
			return DisplayManX.update_submit_sync(self.Handle);
		end,

	},
}
ffi.metatype(DMXUpdate, DMXUpdate_mt);



DisplayManX.DMXUpdate = DMXUpdate;
DisplayManX.DMXDisplay = DMXDisplay;
DisplayManX.DMXResource = DMXResource;
DisplayManX.DMXElement = DMXElement;

return DisplayManX

