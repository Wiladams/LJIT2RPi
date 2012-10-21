
function WritePGM(fp, pixbuff)
    local r, c, val;

	local header = string.format("P5\n%d %d\n255\n", pixbuff.Width, pixbuff.Height)
	fp:write(header);

    for r = 0, pixbuff.Height-1 do
		for c = 0, pixbuff.Width-1 do
			local offset = (r*pixbuff.Width)+c
			local pix = pixbuff.Data[offset]:ToArray();
			fp:write(pix);
		end
	end
end



function WritePPM(fp, pixbuff)
    local r, c, val;

	local header = string.format("P6\n%d %d\n255\n", pixbuff.Width, pixbuff.Height)
	fp:write(header);

    for r = 0, pixbuff.Height-1 do
		for c = 0, pixbuff.Width-1 do
			local offset = (r*pixbuff.Width)+c
			local pix = pixbuff.Data[offset]:ToArray();
			fp:write(pix);
		end
	end
end


function WritePNMFile(filename, pixbuff, routine)
	local fp = io.open(filename, "wb")
	if fp then
		routine(fp, pixbuff)
	end
	fp:close()
end


return {
	WritePGM = WritePGM,
	WritePPM = WritePPM,
	WritePNM = WritePNMFile,
}

