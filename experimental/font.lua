
local ffi = require "ffi"
local bit = require "bit"
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local S = require "syscall"

--[[
// Font handling for graphicsx

/** @file font.c
  *
  * Fairly primitive font handling, just enough to emulate the old API.
  *
  * Hinting and Font Size
  *
  * The old API does not create fonts explicitly, it just renders them
  * as needed. That works fine for unhinted fonts, but for hinted fonts we
  * care about font size.
  *
  * Since we now *can* do hinted fonts, we should do. Regenerating the
  * fonts each time becomes quite slow, so we maintain a cache of fonts.
  *
  * For the typical applications which use graphics_x this is fine, but
  * won't work well if lots of fonts sizes are used.
  *
  * Unicode
  *
  * This API doesn't support unicode at all at present, nor UTF-8.
  */
--]]


#include "graphics_x_private.h"
#include "vgft.h"

VMCS_INSTALL_PREFIX = "";

ffi.cdef[[
/** The one and only (default) font we support for now.
  */
static struct
{
   const char *file;
   void *mem;
   size_t len;
} default_font = { "Vera.ttf" };

/** An entry in our list of fonts
  */
typedef struct gx_font_cache_entry_t
{
   struct gx_font_cache_entry_t *next;
   VGFT_FONT_T font;
   uint32_t ptsize;                    /** size in points, 26.6 */
} gx_font_cache_entry_t;
]]

--[[
static gx_font_cache_entry_t *fonts;
--]
local fname;
local inited;

local fonts = {}


function gx_priv_font_init(font_dir)

   local ret;
   local len;
   local rc;

   if (not vgft_init()) then
      ret = VCOS_ENOMEM;
      goto fail_init;
   end

   local fd = -1;
   
   // search for the font
   fname = string.format("%s/%s", font_dir, default_font.file);
   fd = S.open(fname, S.O.RDONLY);

   if (not fd) then
      GX_ERROR("Could not open font file '%s'", default_font.file);
      ret = VCOS_ENOENT;
      goto fail_open;
   end

   len = fd:lseek(0, SEEK_END);
   fd:lseek(0, SEEK_SET);

   default_font.mem = vcos_malloc(len, default_font.file);
   if (default_font.mem == nil) then
   
      GX_ERROR("No memory for font %s", fname);
      ret = VCOS_ENOMEM;
      goto fail_mem;
   end

   rc = fd:read(default_font.mem, len);
   if (rc ~= len) then
   
      GX_ERROR("Could not read font %s", fname);
      ret = VCOS_EINVAL;
      goto fail_rd;
   end

   default_font.len = len;
   fd:close();

   GX_TRACE("Opened font file '%s'", fname);

   inited = true;
   return VCOS_SUCCESS;

::fail_rd::
   vcos_free(default_font.mem);
::fail_mem::
   if (fd ) then fd:close(); end
::fail_open::
   vgft_term();
::fail_init::
   return ret;
end


function gx_priv_font_term()
   gx_font_cache_flush();
   vgft_term();
   vcos_free(default_font.mem);
end

/** Render text.
  *
  * FIXME: Not at all optimal - re-renders each time.
  * FIXME: Not UTF-8 aware
  * FIXME: better caching
  */
function gx_priv_render_text( GX_DISPLAY_T *disp,
                                   GRAPHICS_RESOURCE_HANDLE res,
                                   uint32_t x,
                                   uint32_t y,
                                   uint32_t width,
                                   uint32_t height,
                                   uint32_t fg_colour,
                                   uint32_t bg_colour,
                                   const char *text,
                                   uint32_t text_length,
                                   uint32_t text_size )

   local vg_colour = ffi.new("VGfloat[4]");
   local font = ffi.new("VGFT_FONT_T");
   VGPaint fg;
   local save = ffi.new("GX_CLIENT_STATE_T");
   local status = ffi.C.VCOS_SUCCESS;
   local clip = true;

   vcos_demand(inited); -- has gx_font_init() been called?

   gx_priv_save(save, res);

   if (width == GRAPHICS_RESOURCE_WIDTH and
       height == GRAPHICS_RESOURCE_HEIGHT) then
   
      clip = false;
   end

   if (width == GRAPHICS_RESOURCE_WIDTH) then
	width = res->width
   end

   if (height == GRAPHICS_RESOURCE_HEIGHT) then
      height = res.height
   end

   font = find_font(text, text_size);

   if (not font) then
      status = VCOS_ENOMEM;
      goto finish;
   end

   -- setup the clipping rectangle
   if (clip) then
   
      VGint coords[] = {x,y,width,height};
      vgSeti(VG_SCISSORING, VG_TRUE);
      vgSetiv(VG_SCISSOR_RECTS, 4, coords);
   end

   -- setup the background colour if needed
   if (bg_colour ~= GRAPHICS_TRANSPARENT_COLOUR) then
      local err;
      local rendered_w; rendered_h;
      local vg_bg_colour = ffi.new("VGfloat[4]");

      -- setup the background colour...
      gx_priv_colour_to_paint(bg_colour, vg_bg_colour);
      VG.vgSetfv(ffi.C.VG_CLEAR_COLOR, 4, vg_bg_colour);

      -- fill in a rectangle...
      vgft_get_text_extents(font, text, text_length, (VGfloat)x, (VGfloat)y, &rendered_w, &rendered_h);

      if ( ( 0 < rendered_w ) and ( 0 < rendered_h ) ) then
      
         VG.vgClear(x, y, rendered_w, rendered_h);
         err = VG.vgGetError();
         if (err) then
         
            GX_LOG("Error %d clearing bg text %d %d %g %g",
                   err, x, y, rendered_w, rendered_h);
            vcos_assert(0);
         end
      end
   } 
   -- setup the foreground colour
   fg = VG.vgCreatePaint();
   if (not fg) then
      status = ffi.C.VCOS_ENOMEM;
      goto finish;
   end

   -- draw the foreground text
   VG.vgSetParameteri(fg, ffi.C.VG_PAINT_TYPE, ffi.C.VG_PAINT_TYPE_COLOR);
   gx_priv_colour_to_paint(fg_colour, vg_colour);
   VG.vgSetParameterfv(fg, ffi.C.VG_PAINT_COLOR, 4, vg_colour);
   VG.vgSetPaint(fg, ffi.C.VG_FILL_PATH);

   VG.vgft_font_draw(font, x, y, text, text_length, ffi.C.VG_FILL_PATH);

   VG.vgDestroyPaint(fg);

   assert(VG.vgGetError() == 0);
   VG.vgSeti(ffi.C.VG_SCISSORING, ffi.C.VG_FALSE);

::finish::
   gx_priv_restore(save);

   return status;
end

--[[
/** Find a font in our cache, or create a new entry in the cache.
  *
  * Very primitive at present.
  */
--]]
function find_font(text, text_size)

   int ptsize, dpi_x = 0, dpi_y = 0;
   VCOS_STATUS_T status;
   gx_font_cache_entry_t *font;

   ptsize = lshift(text_size, 6); -- freetype takes size in points, in 26.6 format.

   local font = fonts;
   while ( font; font = font->next) do
   
      if (font->ptsize == ptsize)
         return &font->font;
      font = font.next;
   end

   font = vcos_malloc(sizeof(*font), "font");
   if (not font) then
      return nil;
   end

   font.ptsize = ptsize;

   status = vgft_font_init(&font.font);
   if (status ~= ffi.C.VCOS_SUCCESS) then
      vcos_free(font);
      return nil;
   end

   // load the font
   status = vgft_font_load_mem(&font.font, default_font.mem, default_font.len);
   if (status ~= ffi.C.VCOS_SUCCESS) then
   
      GX_LOG("Could not load font from memory: %d", status);
      vgft_font_term(&font->font);
      vcos_free(font);
      return nil;
   end

   status = vgft_font_convert_glyphs(&font->font, ptsize, dpi_x, dpi_y);
   if (status ~= VCOS_SUCCESS) then
   
      GX_LOG("Could not convert font '%s' at size %d", fname, ptsize);
      vgft_font_term(&font->font);
      vcos_free(font);
      return NULL;
   end

   font.next = fonts;
   fonts = font;

   return &font->font;
end

function gx_font_cache_flush()
   local count = #fonts
   for i=1,count do
      local font = table.remove(fonts)
      vgft_font_term(font);
   end
end

function graphics_resource_text_dimensions_ext(GRAPHICS_RESOURCE_HANDLE res,
                                              const char *text,
                                              const uint32_t text_length,
                                              uint32_t *width,
                                              uint32_t *height,
                                              const uint32_t text_size )

   local save = ffi.new("GX_CLIENT_STATE_T");
   local ret = -1;

   gx_priv_save(save, res);

   local font = find_font(text, text_size);
   if (not font) then
      goto finish;
   end


   width, height = vgft_get_text_extents(font, text, text_length, 0.0, 0.0);
   ret = 0;

::finish::
   gx_priv_restore(save);
   return ret;
end


/*
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
*/
