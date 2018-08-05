
CoroutineMgr = class()

function CoroutineMgr:ctor()
	self._cor_list = {}
end

function CoroutineMgr:create(func)
	-- 1. first resume in create, pass the call func, and yield self coroutine
	-- 2. second resume in logic code, pass params for func, and call func
	-- 3. if no yield in func, just yield func ret

	local cor = table.remove(self._cor_list)
	if cor then
		coroutine.resume(cor, func)
		return cor	
	end
	cor = coroutine.create(function(f)
		local params = table.pack(coroutine.yield(coroutine.running()))
		while true do
			local ret = table.pack(f(table.unpack(params)))
			table.insert(self._cor_list, coroutine.running())
			f = coroutine.yield(table.unpack(ret))
			params = table.pack(coroutine.yield(coroutine.running()))
		end
	end)
	return select(2, coroutine.resume(cor, func))
end

function CoroutineMgr:resume(cor, ...)
	return coroutine.resume(cor, ...)
end

function CoroutineMgr:yield(...)
	return coroutine.yield(...)
end

return CoroutineMgr
