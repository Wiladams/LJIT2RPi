
local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift


// Font handling for graphicsx
require "graphics_x_private"

#include <VG/openvg.h>
require "freetype"


local lib = ffi.load("freetype");

function vgft_init()

   if (FT_Init_FreeType(&lib) == 0) then
      return 0;
   else
   
      return -1;
   end
end

function vgft_term(void)
   FT_Done_FreeType(lib);
end

SEGMENTS_COUNT_MAX = 256;
COORDS_COUNT_MAX = 1024;

static VGuint segments_count;
static VGubyte segments[SEGMENTS_COUNT_MAX];
static VGuint coords_count;
static VGfloat coords[COORDS_COUNT_MAX];

function VGfloat float_from_26_6(x)
   return x / 64.0;
end

function convert_contour(const FT_Vector *points, const char *tags, short points_count)

   local first_coords = coords_count;

   local first = 1;
   local last_tag = 0;
   local c = 0;

   while (points_count ~= 0) do
      c = c + 1;

      char tag = *tags;
      if (first) then
         assert(band(tag, 0x1)>0);
         assert(c==1); c=0;
         segments[segments_count++] = ffi.C.VG_MOVE_TO;
         first = 0;
      elseif band(tag, 0x1)>0 then
         --[[ on curve --]]
         if band(last_tag, 0x1) > 0 then
            --[[ last point was also on -- line --]]
            assert(c==1); 
            c=0;
            segments[segments_count++] = ffi.C.VG_LINE_TO;
         else 
            --[[ last point was off -- quad or cubic --]]
            if band(last_tag, 0x2) > 0 then
               --[[ cubic --]]
               assert(c==3); 
               c=0;
               segments[segments_count++] = ffi.C.VG_CUBIC_TO;
            else 
               --[[ quad --]]
               assert(c==2); 
               c=0;
               segments[segments_count++] = ffi.C.VG_QUAD_TO;
            end
         end
      else 
         --[[ off curve --]]
         if band(tag, 0x2)>0 then
            --[[ cubic --]]
            assert((last_tag & 0x1) || (last_tag & 0x2)); --[[ last either on or off and cubic --]]
         else
            --[[ quad --]]

            if (not band(last_tag, 0x1)) then
               --[[ last was also off curve --]]

               assert(!(last_tag & 0x2)); --[[ must be quad --]]

               --[[ add on point half-way between --]]
               assert(c==2); 
               c=1;
               segments[segments_count++] = VG_QUAD_TO;
               local x = (coords[coords_count - 2] + float_from_26_6(points.x)) * 0.5;
               local y = (coords[coords_count - 1] + float_from_26_6(points.y)) * 0.5;
               coords[coords_count++] = x;
               coords[coords_count++] = y;
            end
         end
      end

      last_tag = tag;

      coords[coords_count++] = float_from_26_6(points.x);
      coords[coords_count++] = float_from_26_6(points.y);

      points = points + 1; 
      tags = tags + 1;
      points_count = points_count - 1;
   end

   if band(last_tag, 0x1)>0 then
      --[[ last point was also on -- line (implicit with close path) --]]
      assert(c==0);
   else 
      c = c + 1;

      --[[ last point was off -- quad or cubic --]]
      if band(last_tag, 0x2) > 0 then
         --[[ cubic --]]
         assert(c==3); c=0;
         segments[segments_count++] = VG_CUBIC_TO;
      else 
         --[[ quad --]]
         assert(c==2); c=0;
         segments[segments_count++] = VG_QUAD_TO;
      end

      coords[coords_count++] = coords[first_coords + 0];
      coords[coords_count++] = coords[first_coords + 1];
   end

   segments[segments_count++] = VG_CLOSE_PATH;
end

function convert_outline(const FT_Vector *points, const char *tags, const short *contours, short contours_count, short points_count)
   segments_count = 0;
   coords_count = 0;

   local last_contour = 0;
   while (contours_count != 0) do
      local contour = *contours + 1;
      convert_contour(points + last_contour, tags + last_contour, contour - last_contour);
      last_contour = contour;

      contours = contours + 1;
      contours_count = contours_count - 1;
   }
   assert(last_contour == points_count);

   assert(segments_count <= SEGMENTS_COUNT_MAX); --[[ oops... we overwrote some memory --]]
   assert(coords_count <= COORDS_COUNT_MAX);
end

local GLYPHS_COUNT_MAX = 200
--VGuint glyph_indices[GLYPHS_COUNT_MAX];
--VGfloat adjustments_x[GLYPHS_COUNT_MAX];
--VGfloat adjustments_y[GLYPHS_COUNT_MAX];



VGFTFont = {}
VGFTFont_mt = {
	__index = VGFTFont,
}

VGFTFont.init = function()
	local obj = {
		ft_face = nil;
		vg_font = vgCreateFont(0);
		glyph_indices = {},
		adjustments_x = {},
		adjustments_y = {},
	}
   	
	if (obj.vg_font == ffi.C.VG_INVALID_HANDLE) then
   	{
      		return false, "VCOS_ENOMEM";
   	}
   	
	setmetatable(obj, VGFTFont_mt);
	return obj;
end

VGFTFont.load_mem = function(self, mem, len)

   if (FT_New_Memory_Face(lib, mem, len, 0, self.ft_face)) then   
      return false, "VCOS_EINVAL";
   end

   return true;
end

VGFTFont.load_file = function(self, file)

   if (FT_New_Face(lib, file, 0, self.ft_face)) then
   
      return false, "VCOS_EINVAL";
   end

   return true;
end

VGFTFont.convert_glyphs = function(font, char_height, dpi_x, dpi_y)

   FT_UInt glyph_index;
   FT_ULong ch;

   if (FT_Set_Char_Size(font.ft_face, 0, char_height, dpi_x, dpi_y)) then
   
      FT_Done_Face(font.ft_face);
      vgDestroyFont(font.vg_font);
      return false, "VCOS_EINVAL";
   end

   local pglyph_index = ffi.new("FT_UInt[1]");
   ch = FT_Get_First_Char(font.ft_face, pglyph_index);
   local glyph_index = pglyph_index[0];

   while (ch ~= 0) do
   {
      if (FT_Load_Glyph(font.ft_face, glyph_index, FT_LOAD_DEFAULT)) then
         FT_Done_Face(font.ft_face);
         vgDestroyFont(font.vg_font);
         return VCOS_ENOMEM;
      end

      VGPath vg_path;
      local outline = font.ft_face.glyph.outline;
      if (outline.n_contours ~= 0) then
         vg_path = vgCreatePath(VG_PATH_FORMAT_STANDARD, VG_PATH_DATATYPE_F, 1.0f, 0.0f, 0, 0, VG_PATH_CAPABILITY_ALL);
         assert(vg_path != VG_INVALID_HANDLE);

         convert_outline(outline.points, outline.tags, outline.contours, outline.n_contours, outline.n_points);
         vgAppendPathData(vg_path, segments_count, segments, coords);
      else 
         vg_path = ffi.C.VG_INVALID_HANDLE;
      end

      local origin = ffi.new("VGfloat[2]",  { 0.0, 0.0});
      local escapement = ffi.new("VGfloat[2]", { float_from_26_6(font.ft_face.glyph.advance.x), float_from_26_6(font.ft_face.glyph.advance.y) });
      VG.vgSetGlyphToPath(font.vg_font, glyph_index, vg_path, VG_FALSE, origin, escapement);

      if (vg_path ~= ffi.C.VG_INVALID_HANDLE) then
         VG.vgDestroyPath(vg_path);
      end
      ch = FT_Get_Next_Char(font.ft_face, ch, pglyph_index);
   end

   return true;
end

VGFTFont.term = function(font)

   if (font.ft_face)
      FT_Done_Face(font.ft_face);
   if (font.vg_font)
      vgDestroyFont(font.vg_font);
   memset(font, 0, sizeof(*font));
end



VGFTFont.draw_line = function(font, x, y, text, glyphs_count, paint_modes)

   if (glyphs_count == 0) then
      return;
   end

   assert(glyphs_count <= GLYPHS_COUNT_MAX);

   local glor = ffi.new("VGfloat[2]", { x, y });
   VG.vgSetfv(ffi.C.VG_GLYPH_ORIGIN, 2, glor);

   local prev_glyph_index = 0;
   local i = 0;
   while (i ~= glyphs_count) do 

      local glyph_index = FT_Get_Char_Index(font.ft_face, text[i]);
      
      if (glyph_index == 0) then return; end

      glyph_indices[i] = glyph_index;

      if (i ~= 0) then
         FT_Vector kern;
         if (FT_Get_Kerning(font.ft_face, prev_glyph_index, glyph_index, FT_KERNING_DEFAULT, &kern)) {
            assert(0);
         }

         adjustments_x[i - 1] = float_from_26_6(kern.x);
         adjustments_y[i - 1] = float_from_26_6(kern.y);
      end

      prev_glyph_index = glyph_index;
      
      i = i + 1;
   end

   adjustments_x[glyphs_count - 1] = 0.0;
   adjustments_y[glyphs_count - 1] = 0.0;

   VG.vgDrawGlyphs(font.vg_font, glyphs_count, glyph_indices, adjustments_x, adjustments_y, paint_modes, VG_FALSE);
end

VGFTFont.draw = function(font, x, y, text, text_length, paint_modes)

   local descent = float_from_26_6(font.ft_face.size.metrics.descender);
   local last_draw = 0;
   local i = 0;
   y = y - descent;

   while (true) do
      local last = text[i]==0 or (text_length and i==text_length);

      if ((text[i] == string.byte'\n') or last) then
      
         draw_line(font, x, y, text + last_draw, i - last_draw, paint_modes);
         last_draw = i+1;
         y = y - float_from_26_6(font.ft_face.size.metrics.height);
      end
      if (last) then
         break;
      end
      i = i + 1;
   end
end

-- Get text extents for a single line
--
VGFTFont.line_extents = function(font, x, y, text, chars_count)
   local x;
   local y;
   local i;
   local prev_glyph_index = 0;
   
   if (chars_count == 0) then
      return;
   end

   local i = 0;
   while (i < chars_count) do
      local glyph_index = FT_Get_Char_Index(font.ft_face, text[i]);

      if (!glyph_index == 0) then
         return;
      end

      if (i ~= 0) then
      
         local kern = ffi.new("FT_Vector");
         if (FT_Get_Kerning(font.ft_face, prev_glyph_index, glyph_index,
                            FT_KERNING_DEFAULT, kern)) then
         
            assert(0);
         end
         x = x + float_from_26_6(kern.x);
         y = y + float_from_26_6(kern.y);
      end

      FT_Load_Glyph(font.ft_face, glyph_index, FT_LOAD_DEFAULT);
      x = x + float_from_26_6(font.ft_face.glyph.advance.x);
      i = i + 1;
   end

   return x, y;
end

-- Text extents for some ASCII text.
--
-- Use text_length if non-zero, otherwise look for trailing '\0'.

VGFTFont.get_text_extents = function(font, text, text_length, x, y)
   local last_draw = 0;
   local i = 0;
   local start_x = x;
   local start_y = y;
   local max_x = x;

   while (true) do 
      local last = (text[i]==0) or (text_length and i==text_length);
      if ((text[i] == string.byte'\n') or last) then
      
         x, y = font:line_extents(font, text + last_draw, i - last_draw);
         last_draw = i+1;
         y = y - float_from_26_6(font.ft_face.size.metrics.height);
         if (x > max_x) then
            max_x = x;
         end
      end

      if (last) then
         break;
      end

      i = i + 1;
   end
   local width = max_x - start_x;
   local height= start_y - y;

   return width, height;
end
