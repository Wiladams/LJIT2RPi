

-- A simple demo using dispmanx to display an overlay
package.path = package.path..";../../?.lua;"


local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local bcm = require "BcmHost"
local DMX = require "DisplayManX"


WIDTH   = 400
HEIGHT  = 400

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

local RECT_VARS_T = ffi.typeof("RECT_VARS_T");
local VC_RECT_T = ffi.typeof("VC_RECT_T");
local VC_DISPMANX_ALPHA_T = ffi.typeof("VC_DISPMANX_ALPHA_T");


local gRectVars = RECT_VARS_T();

function FillRect( imgtype, image, pitch, aligned_height,  x,  y,  w,  h, val)

    local         row;
    local         col;
    local srcPtr = ffi.cast("int16_t *", image);
    local line = ffi.cast("uint16_t *",srcPtr + y * rshift(pitch,1) + x);

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
    
    local alpha = VC_DISPMANX_ALPHA_T( bor(ffi.C.DISPMANX_FLAGS_ALPHA_FROM_SOURCE, ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS), 120, 0 );

    vars = gRectVars;

    
    print(string.format("Open display[%i]...", screen) );
    vars.display = DMX.display_open( screen );


    vars.info = DMX.get_info(vars.display);
    assert(vars.info);
    
    print(string.format("Display is %d x %d", vars.info.width, vars.info.height) );

    vars.image = ffi.C.calloc( 1, pitch * height );
    assert(vars.image);

    FillRect( imgtype, vars.image, pitch, aligned_height,  0,  0, width,      height,      0xFFFF );
    FillRect( imgtype, vars.image, pitch, aligned_height,  0,  0, width,      height,      0xF800 );
    FillRect( imgtype, vars.image, pitch, aligned_height, 20, 20, width - 40, height - 40, 0x07E0 );
    FillRect( imgtype, vars.image, pitch, aligned_height, 40, 40, width - 80, height - 80, 0x001F );

    vars.resource, vars.vc_image_ptr = DMX.resource_create(imgtype, width, height);
    assert( vars.resource > 0);

	
    DMX.rect_set( dst_rect, 0, 0, width, height);

    assert(DMX.resource_write_data(  vars.resource, imgtype, pitch, vars.image, dst_rect ));
	
    vars.update = DMX.update_start( 10 );
    assert( vars.update );

    DMX.rect_set( src_rect, 0, 0, lshift(width, 16), lshift(height, 16) );
    DMX.rect_set( dst_rect, ( vars.info.width - width ) / 2, ( vars.info.height - height ) / 2, width, height );

    vars.element = DMX.element_add(    vars.update,
                                                vars.display,
                                                2000,               -- layer
                                                dst_rect,
                                                vars.resource,
                                                src_rect,
                                                DISPMANX_PROTECTION_NONE,
                                                alpha,
                                                nil,             -- clamp
                                                ffi.C.VC_IMAGE_ROT0 );

    assert(DMX.update_submit_sync( vars.update ));

    print( "Sleeping for 10 seconds..." );
    ffi.C.sleep( 10 );

    vars.update = DMX.update_start( 10 );
    assert(vars.update);
    
    assert(DMX.element_remove(vars.update, vars.element));
    assert(DMX.update_submit_sync(vars.update));
    assert(DMX.resource_delete(vars.resource));	
    assert(DMX.display_close(vars.display));

end

main();
