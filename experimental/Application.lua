
local ffi = require "ffi"

local ev = require "ev_utils"
local S = require "syscall"
local UI = require "input"

Application = {
	IdleWatchers = {},
	MouseWatchers = {},
	KeyboardWatchers = {},
	TimerWatchers = {},
	SocketWatchers = {},
	FileWatchers = {},	
}

-- Create the primary application event loop
Application.Loop = ev.ev_loop();

Application.AddIdleObserver = function(onactivity)
	local watcher = ev.ev_idle(onactivity);
	table.insert(Application.IdleWatchers, {watcher});
end

Application.AddKeyboardObserver = function(onactivity, devicename)
	devicename = devicename or "/dev/input/event0"
	local fd, err = S.open(devicename, "O_RDONLY");
	if not fd then
		return false, err
	end

	local watcher = ev.ev_io(onactivity, fd:getfd(), ffi.C.EV_READ);
	table.insert(Application.KeyboardWatchers, {watcher, fd});

	return true;
end


Application.AddMouseObserver = function(onactivity, devicename)
	devicename = devicename or "/dev/input/event1"
	local fd = S.open(devicename, "O_RDONLY");
	if not fd then
		return false, err
	end

	local watcher = ev.ev_io(onactivity, fd:getfd(), ffi.C.EV_READ);
	table.insert(Application.MouseWatchers, {watcher, fd});

	return true;
end

Application.AddTimerObserver = function(onactivity, after, interval)
	local watcher = ev.ev_timer(onactivity, after, interval);
	table.insert(Application.TimerWatchers, {watcher});

	return true;
end

Application.Run = function()
	-- Start the various watchers
	-- Start Mouse Watchers
	for i,watcher in ipairs(Application.MouseWatchers) do
		watcher[1]:start(Application.Loop);
	end

	-- Start Keyboard Watchers
	for i,watcher in ipairs(Application.KeyboardWatchers) do
		watcher[1]:start(Application.Loop);
	end

	-- Start Socket Watchers
	for i,watcher in ipairs(Application.SocketWatchers) do
		watcher[1]:start(Application.Loop);
	end

	-- Start File Watchers
	for i,watcher in ipairs(Application.FileWatchers) do
		watcher[1]:start(Application.Loop);
	end

	-- Start Timer Watchers
	for i,watcher in ipairs(Application.TimerWatchers) do
		watcher[1]:start(Application.Loop);
	end

	-- Start the idle watchers
	for i,watcher in ipairs(Application.IdleWatchers) do
		watcher[1]:start(Application.Loop);
	end

	Application.Loop:run();
end

Application.Finish = function()
	Application.Loop:halt();
end

return Application
