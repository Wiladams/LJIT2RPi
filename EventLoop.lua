local IOAlertEmitter = require "IOAlertEmitter"

local EventLoop = {}
local EventLoop_mt = {
	__index = EventLoop,
}

EventLoop.new = function()
	local obj = {
		Observers = {},
		Emitter = IOAlertEmitter.new(),
		Running = false;
	}

	setmetatable(obj, EventLoop_mt);

	return obj;
end


EventLoop.AddObservable = function(self, observable, observer)
	observer = observer or observable
	self.Observers[observable.AlertHandle:getfd()] = observer;

	return self.Emitter:AddAlertable(observable.AlertHandle, observer.OnAlert, observable.WhichAlerts);
end

EventLoop.Halt = function(self)
	self.Running = false;
end

EventLoop.Run = function(self, timeout)
	timeout = timeout or 0

	self.Running = true;

	while self.Running do
		local alerts, err = self.Emitter:Wait(timeout)

		if alerts and #alerts > 0 then
			for i=1,#alerts do
				--print("Event: ", alerts[i].fd, alerts[i].events);
				
				-- get the appropriate observer
				local observer = self.Observers[alerts[i].fd];
				if observer and observer.OnAlert then
					observer:OnAlert(self, alerts[i].fd, alerts[i].events)
				end
			end
		end

		-- Allow some idle work to occur
		if self.OnIdle then
			self.OnIdle(self)
		end
	end
end


return EventLoop;
