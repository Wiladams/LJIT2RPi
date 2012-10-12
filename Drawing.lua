local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor

local EGL = require "egl_utils"

local OpenVG = require "OpenVG"
local OpenVGUtils = require "OpenVG_Utils"


-- Color functions
--
--

-- RGB returns a solid color from a RGB triple
function RGB(r, g, b, color)
	return RGBA(r, g, b, 1.0, color);
end


-- RGBA fills a color vectors from a RGBA quad.
function RGBA(r, g, b, a, color)
	if (r > 255) then
		r = 0;
	end
	if (g > 255) then
		g = 0;
	end
	if (b > 255) then
		b = 0;
	end
	if (a < 0.0 or a > 1.0) then
		a = 1.0;
	end

	color[0] = r / 255.0;
	color[1] = g / 255.0;
	color[2] = b / 255.0;
	color[3] = a;

	return color
end




local Renderer = {}
local Renderer_mt = {
	__index = Renderer,
}

function Renderer.new(display, width, height)
	local self = {
		Display = display;
		Width = width;
		Height = height;
		TransformStack = {};
	}

	setmetatable(self, Renderer_mt);

--[[
	self.SansTypeface = loadfont(DejaVuSans_glyphPoints,
				DejaVuSans_glyphPointIndices,
				DejaVuSans_glyphInstructions,
				DejaVuSans_glyphInstructionIndices,
				DejaVuSans_glyphInstructionCounts,
				DejaVuSans_glyphAdvances, DejaVuSans_characterMap, DejaVuSans_glyphCount);

	self.SerifTypeface = loadfont(DejaVuSerif_glyphPoints,
				 DejaVuSerif_glyphPointIndices,
				 DejaVuSerif_glyphInstructions,
				 DejaVuSerif_glyphInstructionIndices,
				 DejaVuSerif_glyphInstructionCounts,
				 DejaVuSerif_glyphAdvances, DejaVuSerif_characterMap, DejaVuSerif_glyphCount);

	self.MonoTypeface = loadfont(DejaVuSansMono_glyphPoints,
				DejaVuSansMono_glyphPointIndices,
				DejaVuSansMono_glyphInstructions,
				DejaVuSansMono_glyphInstructionIndices,
				DejaVuSansMono_glyphInstructionCounts,
				DejaVuSansMono_glyphAdvances, DejaVuSansMono_characterMap, DejaVuSansMono_glyphCount);
--]]

	return self
end


-- Start begins the picture, clearing a rectangular region with a specified color
function Renderer:Begin()

	local color = ffi.new("VGfloat[4]", 255, 255, 255, 1);
	EGL.Lib.vgSetfv(ffi.C.VG_CLEAR_COLOR, 4, color);
	EGL.Lib.vgClear(0, 0, self.Width, self.Height);

	color[0] = 0;
	color[1] = 0;
	color[2] = 0;
	self:SetFill(color);
	self:SetStrokeColor(color);
	self:StrokeWidth(0);

	EGL.Lib.vgLoadIdentity();
end

-- End checks for errors, and renders to the display
function Renderer:End()
	--assert(EGL.Lib.vgGetError() == ffi.C.VG_NO_ERROR);
	self.Display:SwapBuffers();
	--assert(EGL.Lib.eglGetError() == EGL.EGL_SUCCESS);
end

function Renderer:Flush()
	EGL.Lib.vgFlush();
end

function Renderer:Finish()
	EGL.Lib.vgFinish();
end



--
-- Transformations
--

function Renderer:PushTransform()
	local mTrans = ffi.new("VGfloat[9]");
	EGL.Lib.vgGetMatrix(mTrans);
	table.insert(self.TransformStack, mTrans);
 end

function Renderer:PopTransform()
	if #self.TransformStack < 1 then
		return
	end

	local mTrans = self.TransformStack[#self.TransformStack];
	table.remove(self.TransformStack, #self.TransformStack);

	EGL.Lib.vgLoadMatrix(mTrans);
end

-- Translate the coordinate system to x,y
function Renderer:Translate(x, y)
	EGL.Lib.vgTranslate(x, y);
end

-- Rotate around angle r
function Renderer:Rotate(r)
	EGL.Lib.vgRotate(r);
end

-- Shear shears the x coordinate by x degrees, the y coordinate by y degrees
function Renderer:Shear(x, y)
	EGL.Lib.vgShear(x, y)
end

-- Scale scales by  x, y
function Renderer:Scale(x, y)
	EGL.Lib.vgScale(x, y);
end

--
-- Style functions
--

-- setfill sets the fill color
function Renderer:SetFill(color)
	local fillPaint = OpenVGUtils.Paint();
	fillPaint:SetType(ffi.C.VG_PAINT_TYPE_COLOR);
	fillPaint:SetColor(color);
	fillPaint:SetModes(ffi.C.VG_FILL_PATH);
end

-- setstroke sets the stroke color
function Renderer:SetStrokeColor(color)
	local strokePaint = OpenVGUtils.Paint();
	strokePaint:SetType(ffi.C.VG_PAINT_TYPE_COLOR);
	strokePaint:SetColor(color);
	strokePaint:SetModes(ffi.C.VG_STROKE_PATH);
end


-- StrokeWidth sets the stroke width
function Renderer:StrokeWidth(width)
	EGL.Lib.vgSetf(ffi.C.VG_STROKE_LINE_WIDTH, width);
	EGL.Lib.vgSeti(ffi.C.VG_STROKE_CAP_STYLE, ffi.C.VG_CAP_BUTT);
	EGL.Lib.vgSeti(ffi.C.VG_STROKE_JOIN_STYLE, ffi.C.VG_JOIN_MITER);
end


-- Fill sets the fillcolor, defined as a RGBA quad.
function Renderer:Fill(r, g, b, a)
	local color = ffi.new("VGfloat[4]")
	RGBA(r, g, b, a, color);
	self:SetFill(color);
end

function Renderer:SetStroke(r,g,b,a)
	local color = ffi.new("VGfloat[4]")
	RGBA(r, g, b, a, color);
	self:SetStrokeColor(color);
end

-- clear the screen to a background color
function Renderer:Background(r, g, b)
	self:Fill(r, g, b, 1);
	self:Rect(0, 0,self.Width, self.Height);
end


--[[
		Shape drawing functions
--]]

-- Line makes a line from (x1,y1) to (x2,y2)
function Renderer:Line(x1, y1, x2, y2)
	OpenVGUtils.Paths.Line(x1, y1, x2, y2):Draw();
end

-- interleave interleaves arrays of x, y into a single array
function interleave(x, y, n, points)
	while (n>0) do
		points[0] = x[0];
		points = points + 1;
		points[0] = y[0];
		points = points + 1;
		x = x + 1;
		y = y + 1;
		n = n - 1
	end
end

-- poly makes either a polygon or polyline
function poly(x, y, n, flag)
	flag = flag or bor(ffi.C.VG_FILL_PATH, ffi.C.VG_STROKE_PATH);

	local points = ffi.new("VGfloat[?]", n * 2);

	interleave(x, y, n, points);

	OpenVGUtils.Paths.Poly(points, n):Draw(flag);
end

-- Polygon makes a filled polygon with vertices in x, y arrays
function Renderer:Polygon(x, y, n)
	poly(x, y, n, ffi.C.VG_FILL_PATH);
end

-- Polyline makes a polyline with vertices at x, y arrays
function Renderer:Polyline(x, y, n)
	poly(x, y, n, ffi.C.VG_STROKE_PATH);
end


-- makecurve makes path data using specified segments and coordinates
function drawcurve(segments, coords)
	local path = OpenVGUtils.Path();
	EGL.Lib.vgAppendPathData(path, 2, segments, coords);
	path:Draw();
end

-- CBezier makes a quadratic bezier curve
function Renderer:Cbezier(sx, sy, cx, cy, px, py, ex, ey)
	local segments = ffi.new("VGubyte[2]", ffi.C.VG_MOVE_TO_ABS, ffi.C.VG_CUBIC_TO);
	local coords = ffi.new("VGfloat[8]", sx, sy, cx, cy, px, py, ex, ey);
	drawcurve(segments, coords);
end

-- QBezier makes a quadratic bezier curve
function Renderer:Qbezier(sx, sy, cx, cy, ex, ey)
	local segments = ffi.new("VGubyte[2]", ffi.C.VG_MOVE_TO_ABS, ffi.C.VG_QUAD_TO);
	local coords = ffi.new("VGfloat[6]", sx, sy, cx, cy, ex, ey);
	drawcurve(segments, coords);
end


-- Rect makes a rectangle at the specified location and dimensions
function Renderer:Rect(x, y, w, h)
	OpenVGUtils.Paths.Rect(x,y,w,h):Draw();
end

-- Roundrect makes an rounded rectangle at the specified location and dimensions
function Renderer:Roundrect(x, y, w, h, rw, rh)
	OpenVGUtils.Paths.Roundrect(x,y,w,h, rw, rh):Draw();
end

-- Ellipse makes an ellipse at the specified location and dimensions
function Renderer:Ellipse(x, y, w, h)
	OpenVGUtils.Paths.Ellipse(x,y,w,h):Draw();
end

-- Circle makes a circle at the specified location and dimensions
function Renderer:Circle(x, y, r)
	self:Ellipse(x, y, r, r);
end

-- Arc makes an elliptical arc at the specified location and dimensions
function Arc(x, y, w, h, sa, aext)
	OpenVGUtils.Paths.Arc(x,y,w,h,sa,aext):Draw();
end


return Renderer;
