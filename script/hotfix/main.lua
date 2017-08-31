
local M

local hotfix_helper = require("hotfix.hotfix_helper")
function M.run()
	hotfix_helper.init()
	return Timer.add_timer(3000, hotfix_helper.check, 0, true)
end

return M
