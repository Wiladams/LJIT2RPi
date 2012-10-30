
MouseInteractor = {}
MouseInteractor_mt = {
	__index = MouseInteractor,
}


MouseInteractor.new = function(devicename)
	local obj = {
		MouseDeviceName = devicename,	
		MouseInteractors = {},
		MouseMovers = {},
		MouseDowners = {},
		MouseUppers = {},
	}
	setmetatable(obj, MouseInteractor_mt);

	return obj;
end

MouseInteractor.OnDeviceReadyForRead = function(self)
	-- read from the device
end

MouseInteractor.OnMouseMove = function(self, x, y, flags, device)
	for i,interactor in ipairs(self.MouseInteractors) do
		observer:OnMouseMove(x, y, flags, device)
	end

	for i,mover in ipairs(self.MouseMovers) do
		mover(x,y,flags, device)
	end
end

MouseInteractor.OnMouseDown = function(self, x, y, button, flags, device)
	for i,downer in ipairs(self.MouseDowners) do
		downer(x, y, button, flags, device)
	end
end

MouseInteractor.OnMouseUp = function(self, x, y, button, flags, device)
	for i,upper in ipairs(self.MouseUppers) do
		upper(x, y, button, flags, device)
	end
end


MouseInteractor.AddMouseInteractor = function(self, observer)
	table.insert(self.MouseInteractors, observer)

	return true
end

MouseInteractor.Add
