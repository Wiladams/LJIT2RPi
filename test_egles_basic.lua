

-- A rotating cube rendered with OpenGL|ES. Three images used as textures on the cube faces.

local ffi = require "ffi"
local bit = require "bit"
local lshift = bit.lshift
local rshift = bit.rshift

local DMX = require "DisplayManX"

local rpiui = require "rpiui"

local GLES = rpiui.GLES
local EGL = rpiui.EGL
local OpenVG = rpiui.OpenVG;



--local egldisplay = EGL.Display.new(EGL.EGL_OPENGL_ES_API);
local egldisplay = EGL.Display.new();
assert(egldisplay, "EglDisplay not created");

local dmxdisplay = DMX.DMXDisplay();
assert(dmxdisplay, "Could not initialize DMXDisplay");


local screenWidth = 320;
local screenHeight = 240;


local IMAGE_SIZE = 128;

--[[
/***********************************************************
 * Name: init_ogl
 *
 * Arguments:
 *       CUBE_STATE_T *state - holds OGLES model info
 *
 * Description: Sets the display, OpenGL|ES context and screen stuff
 *
 * Returns: void
 *
 ***********************************************************/
--]]

function createNativeWindow(dmxdisplay, width, height)

    local dst_rect = VC_RECT_T(0,0,width, height);   
    local src_rect = VC_RECT_T(0,0, lshift(width, 16), lshift(height,16));      

    --local alpha = VC_DISPMANX_ALPHA_T(ffi.C.DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS,255,0);
    --local dmxview = dmxdisplay:CreateElement(dst_rect, nil, src_rect, 0, DISPMANX_PROTECTION_NONE, alpha);     
    local dmxview = dmxdisplay:CreateElement(dst_rect, nil, src_rect);     
    assert(dmxview, "FAILURE: Did not create dmxview");

    -- create an EGL window surface
    local nativewindow = ffi.new("EGL_DISPMANX_WINDOW_T");
    nativewindow.element = dmxview.Handle;
    nativewindow.width = width;
    nativewindow.height = height;

    return nativewindow;
end


function init_ogl(state)

    -- Get size of the display window
    state.screen_width, state.screen_height = dmxdisplay:GetSize();
    state.screen_width = screenWidth;
    state.screen_height = screenHeight;
    print("SCREEN SIZE: ", state.screen_width, state.screen_height);

    -- Setup the EGL Display
    state.display = egldisplay;
    
    state.nativewindow = createNativeWindow(dmxdisplay, state.screen_width, state.screen_height); 
    state.surface = egldisplay:CreateWindowSurface(state.nativewindow);
    print("SURFACE: ", state.surface);

    -- connect the context to the surface
    state.display:MakeCurrent();

    -- Set background color and clear buffers
    glClearColor(0.15, 0.25, 0.35, 1.0);
    glClear( GL_COLOR_BUFFER_BIT );
    glClear( GL_DEPTH_BUFFER_BIT );
end







--[[
***********************************************************
* Name: init_model_proj
*
* Arguments:
*       CUBE_STATE_T *state - holds OGLES model info
*
* Description: Sets the OpenGL|ES model to default values
*
* Returns: void
*
**********************************************************
--]]
function init_model_proj(state)

   local nearp = 1.0;
   local farp = 500.0;
   local hht;
   local hwd;

   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   glViewport(0, 0, state.screen_width, state.screen_height);
      
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();

   hht = nearp * math.tan(45.0 / 2.0 / 180.0 * math.pi);
   hwd = hht * state.screen_width / state.screen_height;

   glFrustumf(-hwd, hwd, -hht, hht, nearp, farp);
   

   reset_model(state);
end




--[[
/***********************************************************
 * Name: redraw_scene
 *
 * Arguments:
 *       CUBE_STATE_T *state - holds OGLES model info
 *
 * Description:   Draws the model and calls eglSwapBuffers
 *                to render to screen
 *
 * Returns: void
 *
 ***********************************************************/
--]]
function redraw_scene(state)

   -- Start with a clear screen
   glClear( GL_COLOR_BUFFER_BIT );
   glClear( GL_DEPTH_BUFFER_BIT );

   glFlush();

   print("SWAP: ", state.display:SwapBuffers());
end



-- ==============================================================================

function main()
    -- Clear application state
    local state = {
	distance_inc = 0,
    }
      
    -- Start OGLES
    init_ogl(state);

    redraw_scene(state);
    
    redraw_scene(state);

    -- Sleep for a second so we can see the results
    local seconds = 5
    print( string.format("Sleeping for %d seconds...", seconds ));
    ffi.C.sleep( seconds )

    return 0;
end

main();
