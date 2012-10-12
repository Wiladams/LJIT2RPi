local ffi = require "ffi"

local bit = require "bit"
local bor = bit.bor

local OpenVG = require "OpenVG"

ffi.cdef[[
typedef struct {
	VGPaint	Handle;
} OVGPaint;

typedef struct {
	VGPath Handle;
} OVGPath;
]]

--[[
	Paint object
--]]
Paint = ffi.typeof("OVGPaint")
Paint_mt = {
	__new = function(ct, paintMode)
		local handle

		if not paintMode then
			handle = OpenVG.Lib.vgCreatePaint();
		else
			handle = OpenVG.Lib.vgGetPaint(paintMode);
		end

		if handle == VG_INVALID_HANDLE then
			return nil
		end

		local obj = ffi.new(ct, handle);
		return obj
	end,

	__gc = function(self)
		OpenVG.Lib.vgDestroyPaint(self.Handle);
	end,

	__index = {
		SetModes = function(self, paintModes)
			OpenVG.Lib.vgSetPaint(self.Handle, paintModes);
		end,

		SetColor = function(self, rgba)
			--OpenVG.Lib.vgSetColor(self.Handle, rgba);
			OpenVG.Lib.vgSetParameterfv(self.Handle, ffi.C.VG_PAINT_COLOR, 4, rgba);
		end,

		GetColor = function(self)
			return OpenVG.Lib.vgGetColor(self.Handle);
		end,

		SetPattern = function(self, pattern)
			OpenVG.Lib.vgPaintPattern(self.Handle, pattern);
		end,

		SetType = function(self, pType)
			OpenVG.Lib.vgSetParameteri(self.Handle, ffi.C.VG_PAINT_TYPE, pType);
		end,
	},
}
Paint = ffi.metatype(Paint, Paint_mt);



--[[
	Paths
--]]

Path = ffi.typeof("OVGPath");
Path_mt = {
	__new = function(ct, pathFormat, datatype, scale, bias, segmentCapacityHint, coordCapacityHint, capabilities)
		pathFormat = pathFormat or VG_PATH_FORMAT_STANDARD;
		datatype = datatype or ffi.C.VG_PATH_DATATYPE_F
		scale = scale or 1
		bias = bias or 0
		segmentCapacityHint = segmentCapacityHint or 0
		coordCapacityHint = coordCapacityHint or 0
		capabilities = capabilities or ffi.C.VG_PATH_CAPABILITY_ALL

		local handle = OpenVG.Lib.vgCreatePath(pathFormat, datatype, scale, bias, segmentCapacityHint, coordCapacityHint, capabilities);
		--print("Path Handle: ", handle);

		local obj = ffi.new(ct, handle);
		return obj
	end,

	__gc = function(self)
		OpenVG.Lib.vgDestroyPath(self.Handle);
	end,

	__index = {
		Clear = function(self, capabilities)
			capabilities = capabilities or ffi.C.VG_PATH_CAPABILITY_ALL

			OpenVG.Lib.vgClearPath(self.Handle, capabilities);
		end,

		RemoveCapabilities = function(self, capabilities)
			capabilities = capabilities or ffi.C.VG_PATH_CAPABILITY_ALL

			OpenVG.Lib.vgRemovePathCapabilities(self.Handle, capabilities);
		end,

		GetCapabilities = function(self)
			return OpenVG.Lib.vgGetPathCapabilities(self.Handle);
		end,

		AppendPath = function(self, path)
			OpenVG.Lib.vgAppendPath(self.Handle, path.Handle);
		end,

		AppendPathData = function(self, numSegments, pathSegments, pathData)
			OpenVG.Lib.vgAppendPathData(self.Handle, numSegments, pathSegments, pathData);
		end,

		ModifyPathCoords = function(self, startIndex, numSegments, pathData)
			OpenVG.Lib.vgModifyPathCoords(self.Handle, startIndex, numSegments, pathData);
		end,

		TransformPath = function(self, srcPath)
			OpenVG.Lib.vgTransformPath(self.Handle, srcPath.Handle);
		end,

		InterpolatePath = function(self, startPath, endPath, amount)
			return OpenVG.Lib.vgInterpolatePath(self.Handle, startPath.Handle, endPath.Handle, amount);
		end,

		PathLength = function(self, startSegment, numSegments)
			return OpenVG.Lib.vgPathLength(self.Handle, startSegment, numSegments);
		end,

		PointAlongPath = function(self, startSegment, numSegments, distance)
			local x = ffi.new("VGfloat[1]");
			local y = ffi.new("VGFloat[1]");
            local tangentX = ffi.new("VGFloat[1]");
			local tangentY = ffi.new("VGFloat[1]");

			OpenVG.Lib.vgPointAlongPath(self.Handle, startSegment, numSegments, distance,
                                  x, y, tangentX, tangentY);
			return x[0], y[0], tangentX[0], tangentY[0];
		end,

		Bounds = function(self)
			local minX = ffi.new("VGfloat[1]");
			local minY = ffi.new("VGfloat[1]");
			local width = ffi.new("VGfloat[1]");
			local height = ffi.new("VGfloat[1]");

			OpenVG.Lib.vgPathBounds(self.Handle,
                              minX, minY,
                              width, height);
			return minX[0], minY[0], width[0], height[0];
		end,

		TransformedBounds = function(self)
			local minX = ffi.new("VGfloat[1]");
			local minY = ffi.new("VGfloat[1]");
			local width = ffi.new("VGfloat[1]");
			local height = ffi.new("VGfloat[1]");

			OpenVG.Lib.vgPathTransformedBounds(self.Handle, minX, minY, width, height);

			return minX[0], minY[0], width[0], height[0];
		end,

		Draw = function(self, paintModes)
			paintModes = paintModes or bor(ffi.C.VG_FILL_PATH, ffi.C.VG_STROKE_PATH)
			OpenVG.Lib.vgDrawPath(self.Handle, paintModes);
			return self;
		end,



	},
}
Path = ffi.metatype(Path, Path_mt);



--[[
	Shapes

	A simple factory to create various types of path
	objects.
--]]
local Paths = {
	Line = function(x1, y1, x2, y2)
		local path = Path();
		OpenVG.Lib.vguLine(path.Handle, x1, y1, x2, y2);

		return path;
	end,

	-- poly makes either a polygon or polyline
	Poly = function(points, n)
		local path = Path();
		OpenVG.Lib.vguPolygon(path.Handle, points, n, ffi.C.VG_FALSE);
		return path;
	end,

	-- Rect makes a rectangle at the specified location and dimensions
	Rect = function(x, y, w, h)
		local path = Path();
		OpenVG.Lib.vguRect(path.Handle, x, y, w, h);
		return path
	end,

	-- Roundrect makes an rounded rectangle at the specified location and dimensions
	Roundrect = function(x, y, w, h, rw, rh)
		local path = Path();
		OpenVG.Lib.vguRoundRect(path.Handle, x, y, w, h, rw, rh);
		return path;
	end,

	-- Ellipse makes an ellipse at the specified location and dimensions
	Ellipse = function(x, y, w, h)
		local path = Path();
		OpenVG.Lib.vguEllipse(path.Handle, x, y, w, h);
		return path;
	end,

	-- Arc makes an elliptical arc at the specified location and dimensions
	Arc = function(x, y, w, h, sa, aext)
		local path = Path();
		OpenVG.Lib.vguArc(path.Handle, x, y, w, h, sa, aext, ffi.C.VGU_ARC_OPEN);
		return path;
	end,
}

return {
	Lib = OpenVG.Lib;

	Path = Path;
	Paths = Paths;
	Paint = Paint;

}
