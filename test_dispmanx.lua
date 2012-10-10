

-- A simple demo using dispmanx to display an overlay

local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local DMX = require "DisplayManX"


ALIGN_UP = function(x,y)  
    return band((x + y-1), bnot(y-1))
end


function FillRect( image, imgtype, pitch, aligned_height,  x,  y,  w,  h, val)
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

function Run(width, height)
    width = width or 200
    height = height or 200

    local imgtype =ffi.C.VC_IMAGE_RGB565;
    local pitch = ALIGN_UP(width*2, 32);
    local aligned_height = ALIGN_UP(height, 16);
    
    local alpha = VC_DISPMANX_ALPHA_T( bor(ffi.C.DISPMANX_FLAGS_ALPHA_FROM_SOURCE, ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS), 120, 0 );

    local vars = {}
    
    local screen = 0;
    print(string.format("Open display[%i]...", screen) );
    vars.display = DMXDisplay( screen );


    vars.info = vars.display:GetInfo();
    
    print(string.format("Display is %d x %d", vars.info.width, vars.info.height) );

    vars.image = ffi.C.calloc( 1, pitch * height );

    FillRect( vars.image, imgtype,  pitch, aligned_height,  0,  0, width,      height,      0xFFFF );
    FillRect( vars.image, imgtype,  pitch, aligned_height,  0,  0, width,      height,      0xF800 );
    FillRect( vars.image, imgtype,  pitch, aligned_height, 20, 20, width - 40, height - 40, 0x07E0 );
    FillRect( vars.image, imgtype,  pitch, aligned_height, 40, 40, width - 80, height - 80, 0x001F );

    vars.resource = DMXResource(imgtype, width, height);

	
    local dst_rect = VC_RECT_T(0, 0, width, height);

    vars.resource:WriteData(imgtype, pitch, vars.image, dst_rect);
	

    local src_rect = VC_RECT_T( 0, 0, lshift(width, 16), lshift(height, 16) );
    dst_rect = VC_RECT_T( (vars.info.width - width ) / 2, ( vars.info.height - height ) / 2, width, height );

    vars.update = DMXUpdate( 10 );
 
    vars.element = DMX.element_add(vars.update.Handle,
				   vars.display.Handle,
				   2000,               -- layer
                                   dst_rect,
                                   vars.resource.Handle,
                                   src_rect,
                                   DISPMANX_PROTECTION_NONE,
                                   alpha,
                                   nil,             -- clamp
                                   ffi.C.VC_IMAGE_ROT0 );

    vars.update:SubmitSync();

    local seconds = 1
    print( string.format("Sleeping for %d seconds...", seconds ));
    ffi.C.sleep( seconds );

    vars.update = DMXUpdate(10);
     
    assert(DMX.element_remove(vars.update.Handle, vars.element));
    vars.update:SubmitSync();

end


Run(400, 200);
