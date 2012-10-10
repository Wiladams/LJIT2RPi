

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

-- This is a very simple graphics rendering routine.
-- It will fill in a rectangle, and that's it.
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

-- The main function of the example
function Run(width, height)
    width = width or 200
    height = height or 200


    -- Get a connection to the display
    local Display = DMXDisplay();
    Display:SetBackground(5, 15, 65);

    local info = Display:GetInfo();
    
    print(string.format("Display is %d x %d", info.width, info.height) );

    -- Create an image to be displayed
    local imgtype =ffi.C.VC_IMAGE_RGB565;
    local pitch = ALIGN_UP(width*2, 32);
    local aligned_height = ALIGN_UP(height, 16);
    local image = ffi.C.calloc( 1, pitch * height );

    FillRect( image, imgtype,  pitch, aligned_height,  0,  0, width,      height,      0xFFFF );
    FillRect( image, imgtype,  pitch, aligned_height,  0,  0, width,      height,      0xF800 );
    FillRect( image, imgtype,  pitch, aligned_height, 20, 20, width - 40, height - 40, 0x07E0 );
    FillRect( image, imgtype,  pitch, aligned_height, 40, 40, width - 80, height - 80, 0x001F );

    local BackingStore = DMXResource(width, height, imgtype);

	
    local dst_rect = VC_RECT_T(0, 0, width, height);

    -- Copy the image that was created into 
    -- the backing store
    BackingStore:CopyImage(imgtype, pitch, image, dst_rect);

 
    -- Create the view that will actually 
    -- display the resource
    local src_rect = VC_RECT_T( 0, 0, lshift(width, 16), lshift(height, 16) );
    dst_rect = VC_RECT_T( (info.width - width ) / 2, ( info.height - height ) / 2, width, height );
    local alpha = VC_DISPMANX_ALPHA_T( bor(ffi.C.DISPMANX_FLAGS_ALPHA_FROM_SOURCE, ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS), 120, 0 );
    local View = Display:CreateElement(dst_rect, BackingStore, src_rect, 2000, DISPMANX_PROTECTION_NONE, alpha);
 

    -- Sleep for a second so we can see the results
    local seconds = 1
    print( string.format("Sleeping for %d seconds...", seconds ));
    ffi.C.sleep( seconds )

end


Run(400, 200);
