local timer_mgr = require "timer.timer"

local M = {}

local hotfix_helper = require("hotfix.helper.hotfix_helper")
function M.run()
	local startup_time = os.time()
	hotfix_helper.init()
	return timer_mgr:add_timer(3000, hotfix_helper.check, startup_time, true)
end

return M
