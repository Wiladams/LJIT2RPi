--[[
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
--]]

-- A simple demo using dispmanx to display an overlay
package.path = package.path..";../../?.lua;"


local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local rshift = bit.rshift

local bcm = require "BcmHost"
local Native = bcm.Lib;

WIDTH   = 200
HEIGHT  = 200

ALIGN_UP = function(x,y)  
	return band((x + y-1), bnot(y-1))
end

ffi.cdef[[
typedef struct
{
    DISPMANX_DISPLAY_HANDLE_T   display;
    DISPMANX_MODEINFO_T         info;
    void                       *image;
    DISPMANX_UPDATE_HANDLE_T    update;
    DISPMANX_RESOURCE_HANDLE_T  resource;
    DISPMANX_ELEMENT_HANDLE_T   element;
    uint32_t                    vc_image_ptr;

} RECT_VARS_T;
]]

local RECT_VARS_t = ffi.typeof("RECT_VARS_T");
local VC_RECT_T = ffi.typeof("VC_RECT_T");
local VC_DISPMANX_ALPHA_T = ffi.typeof("VC_DISPMANX_ALPHA_T");


local gRectVars = RECT_VARS_T();

function FillRect( imgtype, image, pitch, aligned_height,  x,  y,  w,  h, val)

    local         row;
    local         col;

    local line = ffi.cast("uint16_t *",image + y * rshift(pitch,1) + x);

    row = 0;
    while ( row < h ) do
	col = 0; 
        while ( col < w) do
            line[col] = val;
	    col = col + 1;
        end
        line = line + rshift(pitch,1);
	row = row + 1;
    end
end

function main()

    local vars = gRectVars;
    local screen = 0;
    local src_rect = VC_RECT_T();
    local dst_rect = VC_RECT_T();
    local imgtype =ffi.C.VC_IMAGE_RGB565;
    local width = WIDTH; 
    local height = HEIGHT;
    local pitch = ALIGN_UP(width*2, 32);
    local aligned_height = ALIGN_UP(height, 16);
    
    local alpha = VC_DISPMANX_ALPHA_T( bor(DISPMANX_FLAGS_ALPHA_FROM_SOURCE, DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS), 120, 0 );

    vars = gRectVars;

    
    print(string.format("Open display[%i]...", screen) );
    vars.display = Native.vc_dispmanx_display_open( screen );

--[[
	local ret;
    ret = Native.vc_dispmanx_display_get_info( vars.display, vars.info);
    assert(ret == 0);
    print(string.format("Display is %d x %d", vars.info.width, vars.info.height) );

    vars.image = ffi.C.calloc( 1, pitch * height );
    assert(vars.image > 0);

    FillRect( imgtype, vars.image, pitch, aligned_height,  0,  0, width,      height,      0xFFFF );
    FillRect( imgtype, vars.image, pitch, aligned_height,  0,  0, width,      height,      0xF800 );
    FillRect( imgtype, vars.image, pitch, aligned_height, 20, 20, width - 40, height - 40, 0x07E0 );
    FillRect( imgtype, vars.image, pitch, aligned_height, 40, 40, width - 80, height - 80, 0x001F );

    vars.resource = Native.vc_dispmanx_resource_create( imgtype, width, height, vars.vc_image_ptr );
    assert( vars.resource > 0);
	
    Native.vc_dispmanx_rect_set( dst_rect, 0, 0, width, height);
    ret = Native.vc_dispmanx_resource_write_data(  vars.resource, imgtype, pitch, vars.image, dst_rect );
    assert( ret == 0 );
	
    vars.update = Native.vc_dispmanx_update_start( 10 );
    assert( vars.update > 0 );

    Native.vc_dispmanx_rect_set( src_rect, 0, 0, lshift(width, 16), lshift(height, 16) );

    Native.vc_dispmanx_rect_set( dst_rect, ( vars.info.width - width ) / 2,
                                     ( vars.info.height - height ) / 2,
                                     width,
                                     height );

    vars.element = Native.vc_dispmanx_element_add(    vars.update,
                                                vars.display,
                                                2000,               -- layer
                                                dst_rect,
                                                vars.resource,
                                                src_rect,
                                                DISPMANX_PROTECTION_NONE,
                                                alpha,
                                                nil,             -- clamp
                                                VC_IMAGE_ROT0 );

    ret = Native.vc_dispmanx_update_submit_sync( vars.update );
    assert( ret == 0 );

    print( "Sleeping for 10 seconds..." );
    sleep( 10 );

    vars.update = Native.vc_dispmanx_update_start( 10 );
    assert( vars.update > 0);
    
	ret = Native.vc_dispmanx_element_remove( vars.update, vars.element );
    assert( ret == 0 );
    
	ret = Native.vc_dispmanx_update_submit_sync( vars.update );
    assert( ret == 0 );
    
	ret = Native.vc_dispmanx_resource_delete( vars.resource );
    assert( ret == 0 );
	
    ret = Native.vc_dispmanx_display_close( vars.display );
    assert( ret == 0 );
--]]
    return 0;
end

main();
