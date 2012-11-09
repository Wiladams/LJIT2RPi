package.path = package.path..";../?.lua"

-- A rotating cube rendered with OpenGL|ES. 
-- Three images used as textures on the cube faces.

local ffi = require "ffi"
local bit = require "bit"
local lshift = bit.lshift
local rshift = bit.rshift


local rpiui = require "rpiui"

local GLES = rpiui.GLES
local EGL = rpiui.EGL
local OpenVG = rpiui.OpenVG;





local windowWidth = 640;
local windowHeight = 480;


local IMAGE_SIZE = 128;

require "cube_texture_and_coords";

-- Setup window
local mainWindow = EGL.Window.new(windowWidth, windowHeight);


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


function init_ogl(state, width, height)
    -- Set background color and clear buffers
    glClearColor(0.15, 0.25, 0.35, 1.0);
    glClear( GL_COLOR_BUFFER_BIT );
    glClear( GL_DEPTH_BUFFER_BIT );
    glShadeModel(GL_FLAT);

    -- Enable back face culling.
    glEnable(GL_CULL_FACE);
end

--[[
/***********************************************************
 * Name: load_tex_images
 *
 * Arguments:
 *       void
 *
 * Description: Loads three raw images to use as textures on faces
 *
 * Returns: void
 *
 ***********************************************************/
--]]

function load_tex_images(state)
   local PATH = "./";
 
   local image_sz = IMAGE_SIZE*IMAGE_SIZE*3;

   function loadImage(filename, chksize)
      local file = io.open(PATH..filename, "rb");
      assert(file);
      local image = file:read("*a");
      assert(#image == chksize, string.format("Image Size: %d Differs from loaded: %d", chksize, #image));
      file:close();
      return image;
   end

   state.tex_buf1 = loadImage("Lucca_128_128.raw", image_sz);
   state.tex_buf2 = loadImage("Djenne_128_128.raw", image_sz);
   state.tex_buf3 = loadImage("Gaudi_128_128.raw", image_sz);
 
end

--[[
/***********************************************************
 * Name: init_textures
 *
 * Arguments:
 *       CUBE_STATE_T *state - holds OGLES model info
 *
 * Description:   Initialise OGL|ES texture surfaces to use image
 *                buffers
 *
 * Returns: void
 *
 ***********************************************************/
--]]
function init_textures(state)

   -- load three texture buffers but use them on six OGL|ES texture surfaces
   load_tex_images(state);
   state.tex = ffi.new("GLuint[6]");
   glGenTextures(6, state.tex);

   -- setup first texture
   glBindTexture(GL_TEXTURE_2D, state.tex[0]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf1);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   -- setup second texture - reuse first image
   glBindTexture(GL_TEXTURE_2D, state.tex[1]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf1);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   -- third texture
   glBindTexture(GL_TEXTURE_2D, state.tex[2]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf2);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   -- fourth texture  - reuse second image
   glBindTexture(GL_TEXTURE_2D, state.tex[3]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf2);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   --fifth texture
   glBindTexture(GL_TEXTURE_2D, state.tex[4]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf3);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   -- sixth texture  - reuse third image
   glBindTexture(GL_TEXTURE_2D, state.tex[5]);
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                GL_RGB, GL_UNSIGNED_BYTE, state.tex_buf3);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

   -- setup overall texture environment
   glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);
end

--[[
/***********************************************************
 * Name: reset_model
 *
 * Arguments:
 *       CUBE_STATE_T *state - holds OGLES model info
 *
 * Description: Resets the Model projection and rotation direction
 *
 * Returns: void
 *
 ***********************************************************/
--]]
function reset_model(state)

   -- reset model position
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
   glTranslatef(0, 0, -50);

   -- reset model rotation
   state.rot_angle_x = 45; 
   state.rot_angle_y = 30; 
   state.rot_angle_z = 0;
   state.rot_angle_x_inc = 0; 
   state.rot_angle_y_inc = 0.5; 
   state.rot_angle_z_inc = 0;
   
   state.distance = 40;
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

   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

   glViewport(0, 0, state.screen_width, state.screen_height);
      
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();

   local hht = nearp * math.tan(45.0 / 2.0 / 180.0 * math.pi);
   local hwd = hht * state.screen_width / state.screen_height;

   glFrustumf(-hwd, hwd, -hht, hht, nearp, farp);
   
   glEnableClientState( GL_VERTEX_ARRAY );
   glVertexPointer( 3, GL_BYTE, 0, quadx );

   glEnableClientState( GL_COLOR_ARRAY );
   glColorPointer(4, GL_FLOAT, 0, colorsf);

   reset_model(state);
end



--[[
/***********************************************************
 * Name: inc_and_wrap_angle
 *
 * Arguments:
 *       GLfloat angle     current angle
 *       GLfloat angle_inc angle increment
 *
 * Description:   Increments or decrements angle by angle_inc degrees
 *                Wraps to 0 at 360 deg.
 *
 * Returns: new value of angle
 *
 ***********************************************************/
--]]
function inc_and_wrap_angle(angle, angle_inc)

   angle = angle + angle_inc;

   if (angle >= 360.0) then
      angle = angle - 360;
   elseif (angle <=0) then
      angle = angle + 360;
   end

   return angle;
end



--[[
/***********************************************************
 * Name: update_model
 *
 * Arguments:
 *       CUBE_STATE_T *state - holds OGLES model info
 *
 * Description: Updates model projection to current position/rotation
 *
 * Returns: void
 *
 ***********************************************************/
--]]
function update_model(state)

   -- update position
   state.rot_angle_x = inc_and_wrap_angle(state.rot_angle_x, state.rot_angle_x_inc);
   state.rot_angle_y = inc_and_wrap_angle(state.rot_angle_y, state.rot_angle_y_inc);
   state.rot_angle_z = inc_and_wrap_angle(state.rot_angle_z, state.rot_angle_z_inc);
   state.distance    = inc_and_clip_distance(state.distance, state.distance_inc);

   glLoadIdentity();
   -- move camera back to see the cube
   glTranslatef(0, 0, -state.distance);

   -- Rotate model to new position
   glRotatef(state.rot_angle_x, 1, 0, 0);
   glRotatef(state.rot_angle_y, 0, 1, 0);
   glRotatef(state.rot_angle_z, 0, 0, 1);
end


--[[
/***********************************************************
 * Name: inc_and_clip_distance
 *
 * Arguments:
 *       GLfloat distance     current distance
 *       GLfloat distance_inc distance increment
 *
 * Description:   Increments or decrements distance by distance_inc units
 *                Clips to range
 *
 * Returns: new value of angle
 *
 ***********************************************************/
--]]
function inc_and_clip_distance(distance, distance_inc)

   distance = distance + distance_inc;

   if (distance >= 120.0) then
      distance = 120;
   elseif (distance <= 40.0) then
      distance = 40.0;
   end

   return distance;
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
   glMatrixMode(GL_MODELVIEW);

   glEnable(GL_TEXTURE_2D);
   glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

   -- Draw first (front) face:
   -- Bind texture surface to current vertices
   glBindTexture(GL_TEXTURE_2D, state.tex[0]);

   -- Need to rotate textures - do this by rotating each cube face
   glRotatef(270, 0, 0, 1 ); -- front face normal along z axis

   -- draw first 4 vertices
   glDrawArrays( GL_TRIANGLE_STRIP, 0, 4);

   -- same pattern for other 5 faces - rotation chosen to make image orientation 'nice'
   glBindTexture(GL_TEXTURE_2D, state.tex[1]);
   glRotatef(90, 0, 0, 1 ); -- back face normal along z axis
   glDrawArrays( GL_TRIANGLE_STRIP, 4, 4);


   glBindTexture(GL_TEXTURE_2D, state.tex[2]);
   glRotatef(90, 1, 0, 0 ); -- left face normal along x axis
   glDrawArrays( GL_TRIANGLE_STRIP, 8, 4);


   glBindTexture(GL_TEXTURE_2D, state.tex[3]);
   glRotatef(90, 1, 0, 0 ); -- right face normal along x axis
   glDrawArrays( GL_TRIANGLE_STRIP, 12, 4);

   glBindTexture(GL_TEXTURE_2D, state.tex[4]);
   glRotatef(270, 0, 1, 0 ); -- top face normal along y axis
   glDrawArrays( GL_TRIANGLE_STRIP, 16, 4);

   glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

   glBindTexture(GL_TEXTURE_2D, state.tex[5]);
   glRotatef(90, 0, 1, 0 ); -- bottom face normal along y axis
   glDrawArrays( GL_TRIANGLE_STRIP, 20, 4);

   glDisable(GL_TEXTURE_2D);

   mainWindow:SwapBuffers();
end


-- Function to be passed to atexit().
function exit_func()

   -- clear screen
   glClear( GL_COLOR_BUFFER_BIT );
   mainWindow:SwapBuffers();
 
   -- Release OpenGL resources
   --eglMakeCurrent( state.display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT );
   --eglDestroySurface( state.display, state.surface );
   --eglDestroyContext( state.display, state.context );
   --eglTerminate( state.display );


   print("\ncube closed");
end

-- ==============================================================================

function main()

   -- Clear application state
   local state = {
	-- model rotation vector and direction
   	rot_angle_x_inc = 0;
   	rot_angle_y_inc = 0;
   	rot_angle_z_inc = 0;
	-- current model rotation angles
   	rot_angle_x = 0;
   	rot_angle_y = 0;
   	rot_angle_z = 0;
	-- current distance from camera
   	distance = 0;
   	distance_inc = 0;
   }
      
   -- Get size of the display window
   state.screen_width = windowWidth;
   state.screen_height = windowHeight;
   --print("SCREEN SIZE: ", state.screen_width, state.screen_height);

   -- Start OGLES
   init_ogl(state, windowWidth, windowHeight);

   -- Setup the model world
   init_model_proj(state);

   -- initialise the OGLES texture(s)
   init_textures(state);

   while not terminate do
   
      ffi.C.sleep(1);
      update_model(state);
      redraw_scene(state);
   end

   --exit_func();
   
   return 0;
end

main();
