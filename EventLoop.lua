local IOAlertEmitter = require "IOAlertEmitter"

local EventLoop = {
	MaxEvents = 16,
}
local EventLoop_mt = {
	__index = EventLoop,
}

EventLoop.new = function(timeout, maxevents)
	maxevents = maxevents or EventLoop.MaxEvents

	local obj = {
		Observers = {},
		Emitter = IOAlertEmitter.new(timeout, maxevents),
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
		local alerts, count = self.Emitter:EPollWait()

		if alerts and count > 0 then
			for i=0,count-1 do
				--print("Event: ", alerts[i].data.fd, alerts[i].events);
				
				-- get the appropriate observer
				local observer = self.Observers[alerts[i].data.fd];
				if observer and observer.OnAlert then
					observer:OnAlert(self, alerts[i].data.fd, alerts[i].events)
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
