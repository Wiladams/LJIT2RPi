
local ffi = require "ffi"

-- Spatial coordinates for the cube

quadx = ffi.new("GLbyte[?]", 6*4*3, {
   -- FRONT 
   -10, -10,  10,
   10, -10,  10,
   -10,  10,  10,
   10,  10,  10,

   -- BACK 
   -10, -10, -10,
   -10,  10, -10,
   10, -10, -10,
   10,  10, -10,

   -- LEFT 
   -10, -10,  10,
   -10,  10,  10,
   -10, -10, -10,
   -10,  10, -10,

   -- RIGHT 
   10, -10, -10,
   10,  10, -10,
   10, -10,  10,
   10,  10,  10,

   -- TOP 
   -10,  10,  10,
   10,  10,  10,
   -10,  10, -10,
   10,  10, -10,

   -- BOTTOM 
   -10, -10,  10,
   -10, -10, -10,
   10, -10,  10,
   10, -10, -10,
});

-- Texture coordinates for the quad. 
texCoords = ffi.new("GLfloat[?]", 6 * 4 * 2, {
   0,  0,
   0,  1,
   1,  0,
   1,  1,

   0,  0,
   0,  1,
   1,  0,
   1,  1,

   0,  0,
   0,  1,
   1,  0,
   1,  1,

   0,  0,
   0,  1,
   1,  0,
   1,  1,

   0,  0,
   0,  1,
   1,  0,
   1,  1,

   0,  0,
   0,  1,
   1,  0,
   1,  1
});

-- Colors are invisible when textures appear on all 6 faces.
-- If textures are disabled, e.g. by commenting out glEnable(GL_TEXTURE_2D),
-- the colours will appear.

colorsf = ffi.new("float[?]", 6*4*4, {
   1,  0,  0,  1,  --red
   1,  0,  0,  1,
   1,  0,  0,  1,
   1,  0,  0,  1,

   0,  1,  0,  1,  -- blue
   0,  1,  0,  1,
   0,  1,  0,  1,
   0,  1,  0,  1,

   0,  0,  1,  1, -- green
   0,  0,  1,  1,
   0,  0,  1,  1,
   0,  0,  1,  1,

   0, 0.5, 0.5,  1, -- teal
   0, 0.5, 0.5,  1,
   0, 0.5, 0.5,  1,
   0, 0.5, 0.5,  1,

   0.5, 0.5,  0,  1, -- yellow
   0.5, 0.5,  0,  1,
   0.5, 0.5,  0,  1,
   0.5, 0.5,  0,  1,

   0.5,  0, 0.5,  1, -- purple
   0.5,  0, 0.5,  1,
   0.5,  0, 0.5,  1,
   0.5,  0, 0.5,  1
});
