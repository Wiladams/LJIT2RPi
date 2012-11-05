local IOAlertEmitter = require "IOAlertEmitter"

local EventLoop = {}
local EventLoop_mt = {
	__index = EventLoop,
}

EventLoop.new = function()
	local obj = {
		Observers = {},
		Emitter = IOAlertEmitter.new(),
	}

	setmetatable(obj, EventLoop_mt);

	return obj;
end


EventLoop.AddEmitter = function(self, emitter, observer)
	observer = observer or emitter
	self.Observers[emitter.AlertHandle:getfd()] = observer;

	return self.Emitter:AddAlertable(emitter.AlertHandle, observer.OnAlert, emitter.WhichAlerts);
end

EventLoop.Run = function(self, timeout)
	timeout = timeout or 0

	while true do
		local alerts, err = self.Emitter:Wait(timeout)

		if alerts and #alerts > 0 then
			for i=1,#alerts do
				--print("Event: ", alerts[i].fd, alerts[i].events);
				
				-- get the appropriate observer
				local observer = self.Observers[alerts[i].fd];
				if observer and observer.OnAlert then
					observer:OnAlert(alerts[i])
				end
			end
		end

		-- Allow some idle work to occur
		if self.OnIdle then
			self.OnIdle()
		end
	end
end


return EventLoop;
