local ffi = require "ffi"

local DMX = require "DisplayManX"


function test_image_formats()
	local result, err = DMX.query_image_formats();

	print("Result: ", result, err);

	if result then
		print("Formats: ", result, ffi.sizeof(result));


		for i=0,16 do
			print(string.format("0x%x",result[i]));
		end
	end
end

function test_display_info()
	local display = DMX.display_open();

	local info = DMX.get_info(display);

	print("Info: ", info);
	print("Size: ", info.width, info.height);
	print("Transform: ", info.transform);
	print("Input Format: ", info.input_format);
end


test_display_info();