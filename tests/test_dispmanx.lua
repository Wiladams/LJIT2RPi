

-- A simple demo using dispmanx to display an overlay

local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift

local DMX = require "DisplayManX"


-- This is a very simple graphics rendering routine.
-- It will fill in a rectangle, and that's it.
function FillRect( pbuff, x,  y,  w,  h, val)
    local dataPtr = ffi.cast("uint8_t *", pbuff.Data);

    local row;
    local col;
    for row=y, y+h-1  do
    	local rowPtr = ffi.cast("int16_t *", (dataPtr + (pbuff.Pitch*row)));
        for col=x, x+w-1 do
            rowPtr[col] = val;
        end
    end
end

-- Setup the display
width = 400
height = 200

-- Get a connection to the display
local Display = DMXDisplay();
Display:SetBackground(125, 65, 65);

local info = Display:GetInfo();
    
print(string.format("Display is %d x %d", info.width, info.height) );

-- Create an image to be displayed
local pbuff = DMX.DMXPixelData(width, height);

--FillRect( pbuff,  0,  0, width,      height,      0xffff );
FillRect( pbuff,  0,  0, width,      height,      0xF800 );
FillRect( pbuff, 20, 20, width - 40, height - 40, 0x07E0 );
FillRect( pbuff, 40, 40, width - 80, height - 80, 0x001F );


--    local alpha = VC_DISPMANX_ALPHA_T( bor(ffi.C.DISPMANX_FLAGS_ALPHA_FROM_SOURCE, ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS), 120, 0 );
mainView = Display:CreateView(width, height, 0, info.height-height, nil, nil, 0.5);
mainView:CopyPixelBuffer(pbuff, 0, 0, width, height);
 
ffi.C.sleep( 2 )

-- Copy a different picture
FillRect( pbuff,  0,  0, width,      height,      0xffff );
mainView:CopyPixelBuffer(pbuff, 0, 0, width, height);

ffi.C.sleep( 2 )


