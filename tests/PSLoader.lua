local ffi = require "ffi"
local bit = require "bit"
local bor = bit.bor
local band = bit.band


local rpiui = require "rpiui"
local EGL = rpiui.EGL;
local VG = EGL.Lib;

ffi.cdef[[
typedef struct
{
	VGFillRule		m_fillRule;
	VGPaintMode		m_paintMode;
	VGCapStyle		m_capStyle;
	VGJoinStyle		m_joinStyle;
	float			m_miterLimit;
	float			m_strokeWidth;
	VGPaint			m_fillPaint;
	VGPaint			m_strokePaint;
	VGPath			m_path;
} PathData;


]]

PS = {}
PS_mt = {
	__index = PS;
}


PS.construct = function(commands, commandCount, points, pointCount)

	local ps = {
		m_paths = {};
		m_numPaths = 0;
		}
	setmetatable(ps, PS_mt);

	local p = 0;
	local c = 0;
	local i = 0;
	local paths = 0;
	local maxElements = 0;

	while(c < commandCount) do
		local elements; 
		local e;
		c = c+4;
		p = p+8;
		elements = points[p];
		p = p + 1;
		assert(elements > 0);
		if(elements > maxElements) then
			maxElements = elements;
		end

		e = 0;
		while (e<elements) do
			if commands[c] == string.byte'M' then
				p = p + 2; 
			elseif commands[c] == string.byte'L' then
				p = p + 2; 
			elseif commands[c] == string.byte'C'then
				p = p + 6; 
			elseif commands[c] == string.byte'E'then
				-- do nothing
			else
				assert(false, "unknown command"); 
			end
			c = c + 1;
			e = e + 1;
		end
		paths = paths + 1;
	end

	ps.m_numPaths = paths;
	ps.m_paths = ffi.new("PathData[?]", paths);
	local cmd = ffi.new("unsigned char[?]", maxElements);

	i = 0;
	p = 0;
	c = 0;


	while c < commandCount do
		local elements, startp, e;
		local color = ffi.new("float[4]");

		-- fill type
		local paintMode = 0;
		ps.m_paths[i].m_fillRule = ffi.C.VG_NON_ZERO;
		
		if commands[c] == string.byte'N' then
			-- nothing to do
		elseif commands[c] == string.byte'F' then
			ps.m_paths[i].m_fillRule = ffi.C.VG_NON_ZERO;
			paintMode = bor(paintMode, ffi.C.VG_FILL_PATH);
		elseif commands[c] == string.byte'E' then
			ps.m_paths[i].m_fillRule = ffi.C.VG_EVEN_ODD;
			paintMode = bor(paintMode,ffi.C.VG_FILL_PATH);
		else
			assert(false, "unknown command"); -- unknown command
		end
		c = c + 1;

		-- stroke
		if commands[c] == string.byte'N' then
			-- do nothing
		elseif commands[c] == string.byte'S' then
			paintMode = bor(paintMode, ffi.C.VG_STROKE_PATH);
		else
			assert(false, "unknown command");
		end

		ps.m_paths[i].m_paintMode = paintMode;
		c = c + 1;

		-- line cap
		if commands[c] == string.byte'B' then
			ps.m_paths[i].m_capStyle = ffi.C.VG_CAP_BUTT;
		elseif commands[c] == string.byte'R' then
			ps.m_paths[i].m_capStyle = ffi.C.VG_CAP_ROUND;
		elseif commands[c] == string.byte'S' then
			ps.m_paths[i].m_capStyle = ffi.C.VG_CAP_SQUARE;
		else
			assert(false, "unknown command");	
		end
		c = c + 1;

		-- line join
		if commands[c] == string.byte'M' then
			ps.m_paths[i].m_joinStyle = ffi.C.VG_JOIN_MITER;
		elseif commands[c] == string.byte'R' then
			ps.m_paths[i].m_joinStyle = ffi.C.VG_JOIN_ROUND;
		elseif commands[c] == string.byte'B' then
			ps.m_paths[i].m_joinStyle = ffi.C.VG_JOIN_BEVEL;
		else
			assert(false, "unknown command");  
		end
		c = c + 1;


		-- the rest of stroke attributes
		ps.m_paths[i].m_miterLimit = points[p];
		p = p + 1;
		ps.m_paths[i].m_strokeWidth = points[p];
		p = p + 1;

		-- paints
		color[0] = points[p];
		p = p + 1;
		color[1] = points[p];
		p = p + 1;
		color[2] = points[p];
		p = p + 1;
		color[3] = 1.0;
		ps.m_paths[i].m_strokePaint = VG.vgCreatePaint();
		VG.vgSetParameteri(ps.m_paths[i].m_strokePaint, ffi.C.VG_PAINT_TYPE, ffi.C.VG_PAINT_TYPE_COLOR);
		VG.vgSetParameterfv(ps.m_paths[i].m_strokePaint, ffi.C.VG_PAINT_COLOR, 4, color);

		color[0] = points[p];
		p = p + 1;
		color[1] = points[p];
		p = p + 1;
		color[2] = points[p];
		p = p + 1;
		color[3] = 1.0;
		ps.m_paths[i].m_fillPaint = VG.vgCreatePaint();
		VG.vgSetParameteri(ps.m_paths[i].m_fillPaint, ffi.C.VG_PAINT_TYPE, ffi.C.VG_PAINT_TYPE_COLOR);
		VG.vgSetParameterfv(ps.m_paths[i].m_fillPaint, ffi.C.VG_PAINT_COLOR, 4, color);

		-- read number of elements

		elements = points[p];
		p = p + 1;
		assert(elements > 0);
		startp = p;

		e = 0;
		while (e<elements) do
			if commands[c] == string.byte'M' then
				cmd[e] = bor(ffi.C.VG_MOVE_TO, ffi.C.VG_ABSOLUTE);
				p = p + 2;
			elseif commands[c] == string.byte'L' then
				cmd[e] = bor(ffi.C.VG_LINE_TO, ffi.C.VG_ABSOLUTE);
				p = p + 2;
			elseif commands[c] == string.byte'C' then
				cmd[e] = bor(ffi.C.VG_CUBIC_TO, ffi.C.VG_ABSOLUTE);
				p = p + 6;
			elseif commands[c] == string.byte'E' then
				cmd[e] = ffi.C.VG_CLOSE_PATH;
			else
				assert(false, "unknown command");
			end
			c = c + 1;
			e = e + 1;
		end

		ps.m_paths[i].m_path = VG.vgCreatePath(VG_PATH_FORMAT_STANDARD, ffi.C.VG_PATH_DATATYPE_F, 1.0, 0.0, 0, 0, ffi.C.VG_PATH_CAPABILITY_ALL);
		VG.vgAppendPathData(ps.m_paths[i].m_path, elements, cmd, points + startp);
		i = i + 1;
	end

	return ps;
end

PS.destruct = function(ps)
	local i = 0;
	while (i<ps.m_numPaths) do
		VG.vgDestroyPaint(ps.m_paths[i].m_fillPaint);
		VG.vgDestroyPaint(ps.m_paths[i].m_strokePaint);
		VG.vgDestroyPath(ps.m_paths[i].m_path);
		i = i + 1;
	end
	--free(ps.m_paths);
end

PS.render = function(ps)

	assert(ps);
	VG.vgSeti(ffi.C.VG_BLEND_MODE, ffi.C.VG_BLEND_SRC_OVER);

	local i = 0;
	while(i<ps.m_numPaths) do
	
		VG.vgSeti(ffi.C.VG_FILL_RULE, ps.m_paths[i].m_fillRule);
		VG.vgSetPaint(ps.m_paths[i].m_fillPaint, ffi.C.VG_FILL_PATH);

		if (band(tonumber(ps.m_paths[i].m_paintMode), ffi.C.VG_STROKE_PATH) > 0) then
		
			VG.vgSetf(ffi.C.VG_STROKE_LINE_WIDTH, ps.m_paths[i].m_strokeWidth);
			VG.vgSeti(ffi.C.VG_STROKE_CAP_STYLE, ps.m_paths[i].m_capStyle);
			VG.vgSeti(ffi.C.VG_STROKE_JOIN_STYLE, ps.m_paths[i].m_joinStyle);
			VG.vgSetf(ffi.C.VG_STROKE_MITER_LIMIT, ps.m_paths[i].m_miterLimit);
			VG.vgSetPaint(ps.m_paths[i].m_strokePaint, ffi.C.VG_STROKE_PATH);
		end

		VG.vgDrawPath(ps.m_paths[i].m_path, ps.m_paths[i].m_paintMode);
		i = i + 1;
	end
	--assert(tonumber(VG.vgGetError()) == tonumber(ffi.C.VG_NO_ERROR));
end

return PS
